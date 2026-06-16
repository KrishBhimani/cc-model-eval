#!/usr/bin/env bash
# setup.sh — clone the repo, make a venv, install, and check each task is valid.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/config.sh"; source "$HERE/lib.sh"

echo "=== setup ==="
echo "EVAL_HOME=$EVAL_HOME"

# 1. clone (or reuse) the repo
if [[ -d "$REPO_DIR/.git" ]]; then
  ok "repo already at $REPO_DIR"
  reset_repo
else
  echo "cloning $REPO_URL ..."
  git clone -q "$REPO_URL" "$REPO_DIR" || { err "clone failed"; exit 1; }
  ok "cloned to $REPO_DIR"
fi

# 2. venv + install
if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR" && ok "created venv"
fi
echo "installing ..."
# upgrade pip — needed for modern build backends; fail loudly if it can't
if ! "$VENV_DIR/bin/pip" install --upgrade pip >/tmp/eval_pip.log 2>&1; then
  err "could not upgrade pip:"; tail -20 /tmp/eval_pip.log; exit 1
fi
# install the repo under test (editable). Show the error if it fails — don't swallow it.
if ! ( cd "$REPO_DIR" && "$VENV_DIR/bin/pip" install $PIP_INSTALL ) >/tmp/eval_pip.log 2>&1; then
  err "installing the repo ($PIP_INSTALL) failed:"; tail -30 /tmp/eval_pip.log
  err "fix the install (often: PIP_INSTALL or a missing build dep), then re-run setup.sh"
  exit 1
fi
# extra deps (pytest etc.)
if [[ -n "$EXTRA_PIP" ]]; then
  if ! "$VENV_DIR/bin/pip" install $EXTRA_PIP >/tmp/eval_pip.log 2>&1; then
    err "installing EXTRA_PIP ($EXTRA_PIP) failed:"; tail -20 /tmp/eval_pip.log; exit 1
  fi
fi
# Optional: verify the package imports, if the user set VERIFY_IMPORT.
# Skipped entirely when VERIFY_IMPORT is empty (the default) so nothing is
# assumed about which repo you're testing.
if [[ -n "${VERIFY_IMPORT:-}" ]]; then
  if ! "$VENV_DIR/bin/python" -c "import $VERIFY_IMPORT" 2>/tmp/eval_pip.log; then
    err "installed, but 'import $VERIFY_IMPORT' fails — the package isn't importable:"
    tail -20 /tmp/eval_pip.log
    err "(check VERIFY_IMPORT in config.sh — it must match the module the repo installs as)"
    exit 1
  fi
  ok "deps installed; '$VERIFY_IMPORT' imports cleanly"
else
  ok "deps installed"
fi

# 3. validate each task: a gated task's test must FAIL on clean code
echo
declare -A STATUS
for task_dir in "$TASKS_DIR"/*/; do
  task="$(basename "$task_dir")"
  gate="$(gate_of "$task")"
  echo "---- $task ----"

  if [[ "$gate" == "MANUAL" ]]; then
    warn "$task is MANUAL (open-ended, hand/LLM scored — no test gate)"
    STATUS[$task]="MANUAL"
    continue
  fi

  reset_repo
  if ! install_task_tests "$task"; then
    err "$task has gate '$gate' but no test_*.py file in its folder"
    STATUS[$task]="NO-TEST"; continue
  fi

  # the gate should FAIL now (proves the task is real and unsolved)
  if run_gate "$task" /dev/null; then
    err "$task gate PASSES on untouched code — the feature/fix already exists, or the test is wrong"
    STATUS[$task]="ALREADY-PASSES"
  else
    ok "$task valid (gate fails on clean code, as it should)"
    STATUS[$task]="READY"
  fi
  reset_repo
done

# 4. summary
echo
echo "===================== SETUP SUMMARY ====================="
for task_dir in "$TASKS_DIR"/*/; do
  task="$(basename "$task_dir")"
  printf "  %-26s %s\n" "$task" "${STATUS[$task]:-UNKNOWN}"
done
echo "next:  bash run.sh --dry-run    then    bash run.sh"
echo "========================================================="
