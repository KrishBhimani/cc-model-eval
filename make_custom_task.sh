#!/usr/bin/env bash
#
# make_custom_task.sh — scaffold a CUSTOM (no-PR) task from a test you wrote.
#
# Workflow:
#   1. Edit the target repo (.work/repo) at its base state and ADD a test that
#      FAILS today (because the bug/feature isn't done). Do NOT write the fix.
#   2. Run this script. It captures your test as tests.patch, pins the base,
#      writes meta.json, confirms the gate fails at base, and resets the repo.
#   3. Add a line to config.sh:  <name>|0|1|<gate>
#   4. Write prompts/<name>.md (symptom only, never the fix).
#
# Usage:
#   bash make_custom_task.sh <task_name> "<gate pytest target>"
#   e.g. bash make_custom_task.sh task_99 "tests/test_orders.py::test_discount_cap"
#
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/config.sh"; source "$HERE/lib.sh"

TASK="${1:?usage: make_custom_task.sh <task_name> \"<gate>\"}"
GATE="${2:?provide a pytest gate target, e.g. tests/test_x.py::test_y}"
DIR="$TASKS_DIR/$TASK"; mkdir -p "$DIR"

# capture whatever is currently changed in the repo as the test patch
DIFF="$(git -C "$WORK_REPO" diff)"
if [[ -z "$DIFF" ]]; then
  err "no uncommitted changes in $WORK_REPO — add your failing test first, then re-run"; exit 1
fi
echo "$DIFF" > "$DIR/tests.patch"

# pin base = current HEAD (the state your test was written against)
BASE="$(git -C "$WORK_REPO" rev-parse HEAD)"
PY -c "import json;open('$DIR/meta.json','w').write(json.dumps({'base_sha':'$BASE','authored':True,'custom':True}))"
ok "captured tests.patch and pinned base $BASE"

# stash the working test, verify it FAILS at clean base, then leave repo clean
git -C "$WORK_REPO" stash -q
if verify_fail_at_base "$TASK" "$GATE"; then
  echo
  ok "$TASK scaffolded. Now:"
  echo "   1. add to config.sh TASKS:   \"$TASK|0|1|$GATE\""
  echo "   2. write prompts/$TASK.md (symptom only)"
else
  err "the gate did NOT fail at base — your test may already pass, or names are wrong"
fi
git -C "$WORK_REPO" stash drop -q 2>/dev/null || true
