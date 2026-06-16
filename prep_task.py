#!/usr/bin/env python3
"""
prep_task.py — turn a merged GitHub PR into an eval task (SWE-bench style).

For a given PR it:
  1. reports scope (files touched, +/- lines, which are tests vs source)
  2. splits the PR diff into:
       - tests.patch   -> apply to the base checkout so the gate test FAILS
       - solution.patch -> the reference fix (withhold from the model)
  3. prints the base commit to check out (PR merge commit's first parent)

Usage:
    export GITHUB_TOKEN=ghp_...        # avoids the 60/hr unauth limit
    python3 prep_task.py pallets/click 3493 --out tasks/task_01

Then in your container harness:
    git checkout <BASE_SHA printed below>
    git apply tasks/task_01/tests.patch     # gate test now present & failing
    # ... let the model work ...
    pytest <the failing test>               # YOUR independent gate
"""
import argparse, json, os, subprocess, sys, urllib.request, pathlib

def gh(url, token, media=None):
    req = urllib.request.Request(url)
    req.add_header("Accept", media or "application/vnd.github+json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req) as r:
        return r.read()

def is_test(path):
    p = path.lower()
    return "test" in p and (p.startswith("tests/") or "/test" in p or p.startswith("test"))

def split_diff(diff_text):
    """Split a unified diff into (tests_chunks, source_chunks) by file header."""
    tests, source, current, cur_is_test = [], [], [], False
    for line in diff_text.splitlines(keepends=True):
        if line.startswith("diff --git "):
            if current:
                (tests if cur_is_test else source).append("".join(current))
            current = [line]
            # path is the 'b/...' target
            parts = line.split(" b/")
            cur_is_test = is_test(parts[-1].strip()) if len(parts) > 1 else False
        else:
            current.append(line)
    if current:
        (tests if cur_is_test else source).append("".join(current))
    return "".join(tests), "".join(source)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("repo", help="owner/name, e.g. pallets/click")
    ap.add_argument("pr", type=int)
    ap.add_argument("--out", default=None, help="output dir for patches")
    args = ap.parse_args()
    token = os.environ.get("GITHUB_TOKEN")

    pr = json.loads(gh(f"https://api.github.com/repos/{args.repo}/pulls/{args.pr}", token))
    merge_sha = pr.get("merge_commit_sha")
    base_branch = pr["base"]["ref"]
    print(f"PR #{args.pr}: {pr['title']}")
    print(f"merged_at: {pr.get('merged_at')}  base_branch: {base_branch}")
    print(f"merge_commit_sha: {merge_sha}")
    print(f"==> BASE_SHA to check out (just before the PR): {merge_sha}~1")
    print()

    files = json.loads(gh(f"https://api.github.com/repos/{args.repo}/pulls/{args.pr}/files?per_page=100", token))
    add = sum(f["additions"] for f in files); dele = sum(f["deletions"] for f in files)
    print(f"scope: {len(files)} files, +{add}/-{dele}")
    for f in files:
        tag = "TEST" if is_test(f["filename"]) else ("DOC " if f["filename"].startswith(("docs/",)) or f["filename"].endswith((".rst", ".md")) else "SRC ")
        print(f"  [{tag}] {f['filename']}  (+{f['additions']}/-{f['deletions']})")
    print()

    diff = gh(f"https://api.github.com/repos/{args.repo}/pulls/{args.pr}",
              token, media="application/vnd.github.v3.diff").decode("utf-8", "replace")
    tests_patch, source_patch = split_diff(diff)

    has_tests = bool(tests_patch.strip())
    print(f"test changes present: {has_tests}  "
          f"({'usable as fail-to-pass gate' if has_tests else 'NO new test — needs a custom gate (refactor-style)'})")

    if args.out:
        d = pathlib.Path(args.out); d.mkdir(parents=True, exist_ok=True)
        (d / "tests.patch").write_text(tests_patch)
        (d / "solution.patch").write_text(source_patch)
        (d / "meta.json").write_text(json.dumps(
            {"repo": args.repo, "pr": args.pr, "base_sha": f"{merge_sha}~1",
             "title": pr["title"], "merged_at": pr.get("merged_at"),
             "has_test_gate": has_tests}, indent=2))
        print(f"\nwrote: {d}/tests.patch  {d}/solution.patch  {d}/meta.json")

if __name__ == "__main__":
    sys.exit(main())
