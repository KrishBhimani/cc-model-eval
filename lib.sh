#!/usr/bin/env bash
# lib.sh — shared helpers. Sourced after config.sh.

c_red=$'\e[31m'; c_grn=$'\e[32m'; c_yel=$'\e[33m'; c_rst=$'\e[0m'
ok()   { echo "${c_grn}OK${c_rst}    $*"; }
warn() { echo "${c_yel}NOTE${c_rst}  $*"; }
err()  { echo "${c_red}FAIL${c_rst}  $*"; }

# use the venv's python if present
PY() { if [[ -x "$VENV_DIR/bin/python" ]]; then "$VENV_DIR/bin/python" "$@"; else python3 "$@"; fi; }

meta() { PY -c "import json,sys;print(json.load(open(sys.argv[1])).get(sys.argv[2],''))" "$1" "$2"; }

reset_repo() {
  git -C "$WORK_REPO" checkout -q . 2>/dev/null
  git -C "$WORK_REPO" clean -qfdx 2>/dev/null   # -x wipes __pycache__ etc.
}

base_sha_for() { meta "$TASKS_DIR/$1/meta.json" base_sha; }

# resolve the gate target for a task (handles AUTO)
gate_target() {
  local task="$1" gate="$2"
  if [[ "$gate" == "AUTO" ]]; then
    grep '^+++ b/' "$TASKS_DIR/$task/tests.patch" 2>/dev/null \
      | sed 's|^+++ b/||' | grep -iE '(^|/)test' | tr '\n' ' '
  else
    echo "$gate"
  fi
}

# run pytest on a target; 0 = passes, non-zero = fails
run_gate() ( cd "$WORK_REPO" && PY -m pytest $1 -q >/dev/null 2>&1 )

# prep one PR-derived task -> patches + meta.json
prep_one() {
  local task="$1" pr="$2"
  PY "$EVAL_HOME/prep_task.py" "${REPO_URL#https://github.com/}" "$pr" --out "$TASKS_DIR/$task" >/dev/null \
    || { err "$task prep_task.py failed"; return 1; }
}

# verify a CUSTOM task: only that the gate FAILS at base (no reference solution exists)
verify_fail_at_base() {
  local task="$1" gate="$2"
  local base; base="$(base_sha_for "$task")"
  local target; target="$(gate_target "$task" "$gate")"
  reset_repo
  git -C "$WORK_REPO" checkout -q "$base" || { err "$task checkout failed"; return 1; }
  git -C "$WORK_REPO" apply --check "$TASKS_DIR/$task/tests.patch" 2>/dev/null \
    || { err "$task tests.patch does not apply on base"; return 1; }
  git -C "$WORK_REPO" apply "$TASKS_DIR/$task/tests.patch"
  if run_gate "$target"; then err "$task gate PASSES at base (the bug/feature is already present — invalid)"; reset_repo; return 1; fi
  reset_repo
  ok "$task custom gate fails at base as expected (pass side is the model's job)"
}

# verify a fail-to-pass task is well-formed (base fails, solution passes)
verify_one() {
  local task="$1" gate="$2"
  local base; base="$(base_sha_for "$task")"
  local target; target="$(gate_target "$task" "$gate")"
  reset_repo
  git -C "$WORK_REPO" checkout -q "$base" || { err "$task checkout failed"; return 1; }
  git -C "$WORK_REPO" apply --check "$TASKS_DIR/$task/tests.patch" 2>/dev/null \
    || { err "$task tests.patch does not apply"; return 1; }
  git -C "$WORK_REPO" apply "$TASKS_DIR/$task/tests.patch"
  if run_gate "$target"; then err "$task gate PASSES at base (invalid)"; return 1; fi
  git -C "$WORK_REPO" apply --check "$TASKS_DIR/$task/solution.patch" 2>/dev/null \
    || { err "$task solution.patch does not apply"; return 1; }
  git -C "$WORK_REPO" apply "$TASKS_DIR/$task/solution.patch"
  if ! run_gate "$target"; then err "$task gate still fails with reference (unsolvable)"; return 1; fi
  reset_repo
  ok "$task LOCKED (fails at base, passes with reference)"
}
