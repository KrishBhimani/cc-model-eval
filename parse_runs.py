#!/usr/bin/env python3
"""
parse_runs.py — turn the raw matrix output into an analysis table.

Reads:   $HOME/runs/<model>/<task>/run_<n>.jsonl   (claude -p stream-json)
         $HOME/runs/<model>/<task>/run_<n>.gate    (independent gate result)
Writes:  $HOME/runs/metrics.csv  (one row per run)
Prints:  a per-(model,task) summary — passes/N and median cost/tokens AMONG PASSES.

Usage:
    python3 parse_runs.py                 # uses $HOME/runs
    python3 parse_runs.py --runs /path    # custom runs dir
"""
import argparse, json, os, csv, statistics, glob, collections

def parse_gate(path):
    """Return dict with outcome + exit codes from a .gate file."""
    d = {"gate_exit": None, "full_exit": None, "setup_fail": None, "manual": False}
    if not os.path.exists(path):
        return d
    for line in open(path):
        line = line.strip()
        if line.startswith("GATE_EXIT="):       d["gate_exit"] = int(line.split("=")[1])
        elif line.startswith("FULL_SUITE_EXIT="):d["full_exit"] = int(line.split("=")[1])
        elif line.startswith("SETUP_FAIL="):     d["setup_fail"] = line.split("=", 1)[1]
        elif line == "GATE=MANUAL":              d["manual"] = True
    return d

def parse_jsonl(path):
    """Extract per-run metrics from a stream-json log."""
    m = {
        "model_id": None, "num_turns": None, "duration_ms": None,
        "input_tokens": 0, "output_tokens": 0,
        "cache_read": 0, "cache_creation": 0,
        "total_cost_usd": None, "is_error": None, "result_subtype": None,
        "num_retries": 0, "did_not_converge": False,
        "tool_calls_total": 0,
    }
    tools = collections.Counter()
    files_read, files_edited = set(), set()
    saw_result = False
    if not os.path.exists(path):
        m["tools"] = tools; m["files_read"] = files_read; m["files_edited"] = files_edited
        m["no_log"] = True
        return m
    m["no_log"] = False

    for line in open(path):
        line = line.strip()
        if not line:
            continue
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        t = ev.get("type")

        if t == "system" and ev.get("subtype") == "init":
            m["model_id"] = ev.get("model") or m["model_id"]
        elif t == "system" and ev.get("subtype") == "api_retry":
            m["num_retries"] += 1
        elif t == "assistant":
            for blk in ev.get("message", {}).get("content", []):
                if blk.get("type") == "tool_use":
                    name = blk.get("name", "?")
                    tools[name] += 1
                    m["tool_calls_total"] += 1
                    inp = blk.get("input", {}) or {}
                    path_arg = inp.get("file_path") or inp.get("path")
                    if name in ("Read",) and path_arg:
                        files_read.add(path_arg)
                    if name in ("Edit", "Write") and path_arg:
                        files_edited.add(path_arg)
        elif t == "result":
            saw_result = True
            m["total_cost_usd"] = ev.get("total_cost_usd", m["total_cost_usd"])
            m["num_turns"] = ev.get("num_turns", m["num_turns"])
            m["duration_ms"] = ev.get("duration_ms", m["duration_ms"])
            m["is_error"] = ev.get("is_error")
            m["result_subtype"] = ev.get("subtype")
            u = ev.get("usage", {}) or {}
            m["input_tokens"]   = u.get("input_tokens", 0)
            m["output_tokens"]  = u.get("output_tokens", 0)
            m["cache_read"]     = u.get("cache_read_input_tokens", 0)
            m["cache_creation"] = u.get("cache_creation_input_tokens", 0)

    # did-not-converge: hit max turns, or no result event at all
    if (m["result_subtype"] and "max_turns" in str(m["result_subtype"])) or not saw_result:
        m["did_not_converge"] = True

    m["tools"] = tools
    m["files_read"] = files_read
    m["files_edited"] = files_edited
    return m

def outcome(gate, jm):
    if gate["setup_fail"]:        return "setup_fail"
    if jm["did_not_converge"]:    return "did_not_converge"
    if gate["manual"]:            return "manual"
    if gate["gate_exit"] == 0:    return "pass"
    if gate["gate_exit"] is None: return "unknown"
    return "fail"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", default=os.path.join(os.path.expanduser("~"), "runs"))
    args = ap.parse_args()

    rows = []
    for jpath in sorted(glob.glob(os.path.join(args.runs, "*", "*", "run_*.jsonl"))):
        parts = jpath.split(os.sep)
        model, task = parts[-3], parts[-2]
        run = parts[-1].replace("run_", "").replace(".jsonl", "")
        gate = parse_gate(jpath.replace(".jsonl", ".gate"))
        jm = parse_jsonl(jpath)
        oc = outcome(gate, jm)
        regressed = (gate["full_exit"] not in (0, None)) and oc == "pass"
        rows.append({
            "model": model, "task": task, "run": run,
            "outcome": oc,
            "model_id": jm["model_id"],
            "gate_exit": gate["gate_exit"], "full_exit": gate["full_exit"],
            "regressed": int(regressed),
            "num_turns": jm["num_turns"],
            "tool_calls_total": jm["tool_calls_total"],
            "files_read": len(jm["files_read"]),
            "files_edited": len(jm["files_edited"]),
            "input_tokens": jm["input_tokens"], "output_tokens": jm["output_tokens"],
            "cache_read": jm["cache_read"], "cache_creation": jm["cache_creation"],
            "total_cost_usd": jm["total_cost_usd"],
            "duration_ms": jm["duration_ms"],
            "num_retries": jm["num_retries"],
            "tools": ";".join(f"{k}={v}" for k, v in sorted(jm["tools"].items())),
        })

    if not rows:
        print(f"no runs found under {args.runs}"); return

    out_csv = os.path.join(args.runs, "metrics.csv")
    with open(out_csv, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)
    print(f"wrote {out_csv}  ({len(rows)} runs)\n")

    # ---- summary: per (model, task), efficiency conditioned on success ----
    def med(xs):
        xs = [x for x in xs if x is not None]
        return round(statistics.median(xs), 4) if xs else None

    cells = collections.defaultdict(list)
    for r in rows:
        cells[(r["model"], r["task"])].append(r)

    print(f"{'model':<22}{'task':<10}{'pass':<8}{'med_cost$':<11}{'med_out_tok':<12}{'med_turns':<10}{'med_tools':<10}")
    print("-" * 83)
    for (model, task) in sorted(cells):
        rs = cells[(model, task)]
        n = len(rs)
        passes = [r for r in rs if r["outcome"] == "pass"]
        manual = sum(1 for r in rs if r["outcome"] == "manual")
        dnc = sum(1 for r in rs if r["outcome"] == "did_not_converge")
        pass_str = f"{len(passes)}/{n}" + (f"(M{manual})" if manual else "") + (f"(X{dnc})" if dnc else "")
        # efficiency medians AMONG PASSES ONLY
        print(f"{model:<22}{task:<10}{pass_str:<8}"
              f"{str(med([r['total_cost_usd'] for r in passes])):<11}"
              f"{str(med([r['output_tokens'] for r in passes])):<12}"
              f"{str(med([r['num_turns'] for r in passes])):<10}"
              f"{str(med([r['tool_calls_total'] for r in passes])):<10}")
    print("\nlegend: pass = passes/N; (M#)=manual-scored; (X#)=did-not-converge.")
    print("efficiency columns are medians AMONG PASSING runs only.")

if __name__ == "__main__":
    main()
