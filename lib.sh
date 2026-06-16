#!/usr/bin/env bash
# lib.sh — shared helpers. No git patching, no PRs. Tasks are plain files.

ok()   { printf "OK    %s\n" "$*"; }
warn() { printf "NOTE  %s\n" "$*"; }
err()  { printf "FAIL  %s\n" "$*" >&2; }

PY() { "$VENV_DIR/bin/python" "$@"; }
PYTEST() { "$VENV_DIR/bin/python" -m pytest "$@"; }

# Reset the repo to a pristine checkout (discard everything the model changed).
reset_repo() {
  git -C "$REPO_DIR" reset --hard -q
  git -C "$REPO_DIR" clean -fdq
}

# Copy a task's test file(s) into the repo's test directory (TESTS_SUBDIR).
# A task is gated if it has any test_*.py file.
install_task_tests() {
  local task="$1"
  local dest="$REPO_DIR/${TESTS_SUBDIR:-tests}"
  mkdir -p "$dest"
  local found=0
  shopt -s nullglob
  for f in "$TASKS_DIR/$task"/test_*.py; do
    cp "$f" "$dest/$(basename "$f")"
    found=1
  done
  shopt -u nullglob
  return $((1 - found))   # 0 if a test was copied, 1 if none
}

# Read a task's gate target (pytest target, or "MANUAL").
gate_of() { tr -d '\r\n' < "$TASKS_DIR/$1/gate.txt"; }

# Run a task's gate. Returns 0 if it passes. Writes full pytest output to $2 if given.
run_gate() {
  local task="$1" outfile="${2:-/dev/null}" gate
  gate="$(gate_of "$task")"
  [[ "$gate" == "MANUAL" ]] && return 0
  # $gate may name multiple targets (space-separated); pytest takes them all.
  ( cd "$REPO_DIR" && "$VENV_DIR/bin/python" -m pytest $gate -v ) >"$outfile" 2>&1
}
