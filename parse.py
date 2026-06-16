#!/usr/bin/env python3
"""
parse.py — turn runs/ into metrics.csv (same schema as the original harness,
minus cost). Reads each run's stream-json log + gate result.

Columns:
  model, task, run, outcome, gate_exit, full_exit, regressed,
  num_turns, tool_calls_total, tool_calls_failed, files_read, files_edited,
  input_tokens, output_tokens, cache_read, cache_creation,
  duration_ms, num_retries, tools

Usage:  python3 parse.py            # writes metrics.csv next to this script
        python3 parse.py --print    # also echo a short summary to stdout
"""
import csv, json, os, sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
RUNS = os.path.join(HERE, "runs")
OUT = os.path.join(HERE, "metrics.csv")

FIELDS = [
    "model", "task", "run", "outcome",
    "gate_exit", "full_exit", "regressed",
    "num_turns", "tool_calls_total", "tool_calls_failed", "files_read", "files_edited",
    "input_tokens", "output_tokens", "cache_read", "cache_creation",
    "duration_ms", "num_retries", "tools",
]


def _iter_events(path):
    """Yield parsed JSON objects from a stream-json (one per line) file."""
    if not os.path.exists(path):
        return
    with open(path, errors="ignore") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def parse_run(run_dir):
    """Extract one row of metrics from a single run folder."""
    jsonl = os.path.join(run_dir, "run.jsonl")

    # accumulators
    tool_counts = defaultdict(int)     # e.g. {"Bash": 4, "Edit": 1}
    tool_calls_failed = 0              # tool_result blocks marked is_error
    files_read = 0
    files_edited = 0
    in_tok = out_tok = cache_read = cache_create = 0
    num_turns = 0
    duration_ms = 0
    num_retries = 0
    result_seen = False

    for ev in _iter_events(jsonl):
        etype = ev.get("type")

        # tool calls + usage live inside assistant messages
        if etype == "assistant":
            msg = ev.get("message", {}) or {}
            for block in msg.get("content", []) or []:
                if isinstance(block, dict) and block.get("type") == "tool_use":
                    name = block.get("name", "?")
                    tool_counts[name] += 1
                    if name == "Read":
                        files_read += 1
                    elif name in ("Edit", "Write"):
                        files_edited += 1
            usage = msg.get("usage", {}) or {}
            in_tok += usage.get("input_tokens", 0) or 0
            out_tok += usage.get("output_tokens", 0) or 0
            cache_read += usage.get("cache_read_input_tokens", 0) or 0
            cache_create += usage.get("cache_creation_input_tokens", 0) or 0

        # tool RESULTS come back in user-role messages; a failed tool call is
        # marked with is_error=true on its tool_result block.
        elif etype == "user":
            msg = ev.get("message", {}) or {}
            for block in msg.get("content", []) or []:
                if isinstance(block, dict) and block.get("type") == "tool_result":
                    if block.get("is_error"):
                        tool_calls_failed += 1

        # the final result event carries the authoritative summary
        elif etype == "result":
            result_seen = True
            num_turns = ev.get("num_turns", num_turns) or num_turns
            duration_ms = ev.get("duration_ms", duration_ms) or duration_ms
            num_retries = ev.get("num_retries", num_retries) or num_retries
            # prefer the result event's own usage totals if present
            usage = ev.get("usage", {}) or {}
            if usage:
                in_tok = usage.get("input_tokens", in_tok) or in_tok
                out_tok = usage.get("output_tokens", out_tok) or out_tok
                cache_read = usage.get("cache_read_input_tokens", cache_read) or cache_read
                cache_create = usage.get("cache_creation_input_tokens", cache_create) or cache_create

    # if no result event gave turns, approximate by counting assistant messages
    if not num_turns:
        num_turns = sum(1 for ev in _iter_events(jsonl) if ev.get("type") == "assistant")

    tool_calls_total = sum(tool_counts.values())
    tools_str = ";".join(f"{k}={v}" for k, v in sorted(tool_counts.items()))

    # gate result -> outcome + gate_exit
    gate_result = ""
    grp = os.path.join(run_dir, "gate_result.txt")
    if os.path.exists(grp):
        gate_result = open(grp).read().strip()

    if gate_result == "PASS":
        outcome, gate_exit = "pass", 0
    elif gate_result == "FAIL":
        outcome, gate_exit = "fail", 1
    elif gate_result == "MANUAL":
        outcome, gate_exit = "manual", ""
    else:
        outcome, gate_exit = "unknown", ""

    # full_exit / regressed: this simple harness runs only the task gate, not a
    # separate full-suite pass, so we leave them blank rather than fake them.
    full_exit = ""
    regressed = ""

    return {
        "outcome": outcome,
        "gate_exit": gate_exit,
        "full_exit": full_exit,
        "regressed": regressed,
        "num_turns": num_turns,
        "tool_calls_total": tool_calls_total,
        "tool_calls_failed": tool_calls_failed,
        "files_read": files_read,
        "files_edited": files_edited,
        "input_tokens": in_tok,
        "output_tokens": out_tok,
        "cache_read": cache_read,
        "cache_creation": cache_create,
        "duration_ms": duration_ms,
        "num_retries": num_retries,
        "tools": tools_str,
    }


def main():
    if not os.path.isdir(RUNS):
        print(f"no runs/ directory at {RUNS} — run run.sh first", file=sys.stderr)
        sys.exit(1)

    rows = []
    for run_id in sorted(os.listdir(RUNS)):
        d = os.path.join(RUNS, run_id)
        if not os.path.isdir(d):
            continue
        try:
            task, model, rep = run_id.split("__")
            rep = rep.replace("run", "")
        except ValueError:
            continue
        row = {"model": model, "task": task, "run": rep}
        row.update(parse_run(d))
        rows.append(row)

    with open(OUT, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=FIELDS)
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in FIELDS})

    print(f"wrote {OUT}  ({len(rows)} runs)", file=sys.stderr)

    if "--print" in sys.argv:
        # quick per-(model,task) gate tally
        agg = defaultdict(lambda: [0, 0])  # passes, total
        for r in rows:
            key = (r["model"], r["task"])
            agg[key][1] += 1
            if r["outcome"] == "pass":
                agg[key][0] += 1
        print("\nmodel               task        gate-pass")
        for (m, t), (p, n) in sorted(agg.items()):
            print(f"{m:<18}  {t:<10}  {p}/{n}")


if __name__ == "__main__":
    main()
