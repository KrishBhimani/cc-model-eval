#!/usr/bin/env bash
#
# setup.sh — one-shot setup. Clones the target repo, builds the venv,
# installs deps, and preps + verifies every task in config.sh.
#
# Usage:
#   export GITHUB_TOKEN=ghp_...     # avoids GitHub's 60/hr unauth limit
#   bash setup.sh
#
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/config.sh"
source "$HERE/lib.sh"

echo "=== cc-model-eval setup ==="
echo "EVAL_HOME=$EVAL_HOME"

# ---- prerequisites -------------------------------------------------------
need() { command -v "$1" >/dev/null 2>&1 || { err "missing prerequisite: $1"; exit 1; }; }
need git; need python3; need claude
command -v node >/dev/null 2>&1 || warn "node not found — Claude Code needs Node.js"
[[ -z "${GITHUB_TOKEN:-}" ]] && warn "GITHUB_TOKEN not set — prep may hit GitHub's 60/hr unauth limit"

# ---- clone target repo ---------------------------------------------------
if [[ -d "$WORK_REPO/.git" ]]; then
  ok "repo already cloned at $WORK_REPO"
else
  mkdir -p "$(dirname "$WORK_REPO")"
  echo "cloning $REPO_URL ..."
  git clone --quiet "$REPO_URL" "$WORK_REPO" || { err "clone failed"; exit 1; }
  ok "cloned to $WORK_REPO"
fi

# ---- venv + deps ---------------------------------------------------------
if [[ ! -d "$VENV_DIR" ]]; then
  python3 -m venv "$VENV_DIR"; ok "created venv at $VENV_DIR"
fi
"$VENV_DIR/bin/pip" install --quiet --upgrade pip
echo "installing $REPO_URL deps ($PIP_INSTALL) ..."
if ! ( cd "$WORK_REPO" && "$VENV_DIR/bin/pip" install --quiet -e "$PIP_INSTALL" ) 2>/dev/null; then
  warn "'$PIP_INSTALL' failed; falling back to '.' + pytest"
  ( cd "$WORK_REPO" && "$VENV_DIR/bin/pip" install --quiet -e . && "$VENV_DIR/bin/pip" install --quiet pytest ) \
    || { err "dependency install failed"; exit 1; }
fi
ok "deps installed"

# ---- prep + verify each task --------------------------------------------
mkdir -p "$TASKS_DIR"
declare -A STATUS
for entry in "${TASKS[@]}"; do
  IFS='|' read -r TASK PR APPLY GATE <<< "$entry"
  echo; echo "---- $TASK (pr=$PR) ----"

  if [[ "$PR" == "0" ]]; then
    # No PR — an authored task. Two flavours:
    #   gate=MANUAL          -> open-ended, hand/LLM scored (no test gate)
    #   gate=<pytest target> -> CUSTOM gated task; you supply tasks/<task>/tests.patch
    # Base: keep an existing meta.json (lets make_custom_task.sh pin a base);
    # otherwise pin to current main HEAD.
    mkdir -p "$TASKS_DIR/$TASK"
    if [[ ! -f "$TASKS_DIR/$TASK/meta.json" ]]; then
      BASE="$(git -C "$WORK_REPO" rev-parse origin/HEAD 2>/dev/null || git -C "$WORK_REPO" rev-parse HEAD)"
      PY -c "import json;open('$TASKS_DIR/$TASK/meta.json','w').write(json.dumps({'base_sha':'$BASE','authored':True}))"
    fi
    if [[ "$GATE" == "MANUAL" ]]; then
      warn "$TASK authored (open-ended) — hand/LLM scored, no test gate"
      STATUS[$TASK]="AUTHORED"
    elif [[ -f "$TASKS_DIR/$TASK/tests.patch" ]]; then
      # custom gated task: verify the gate FAILS at base (no reference to check the pass side)
      if verify_fail_at_base "$TASK" "$GATE"; then STATUS[$TASK]="CUSTOM-OK"; else STATUS[$TASK]="NEEDS-ATTENTION"; fi
    else
      err "$TASK has a gate but no tasks/$TASK/tests.patch — run make_custom_task.sh first"
      STATUS[$TASK]="NO-PATCH"
    fi
    continue
  fi

  prep_one "$TASK" "$PR" || { STATUS[$TASK]="PREP-FAIL"; continue; }
  if [[ "$APPLY" == "1" ]]; then
    if verify_one "$TASK" "$GATE"; then STATUS[$TASK]="LOCKED"; else STATUS[$TASK]="NEEDS-ATTENTION"; fi
  else
    STATUS[$TASK]="NO-VERIFY"
  fi
done

# ---- summary -------------------------------------------------------------
echo; echo "======================= SETUP SUMMARY ======================="
for entry in "${TASKS[@]}"; do
  IFS='|' read -r TASK _ _ _ <<< "$entry"
  s="${STATUS[$TASK]:-UNKNOWN}"
  case "$s" in
    LOCKED)   echo "  ${c_grn}$TASK: LOCKED${c_rst}";;
    CUSTOM-OK) echo "  ${c_grn}$TASK: custom gate OK (fails at base)${c_rst}";;
    AUTHORED) echo "  ${c_yel}$TASK: authored (hand-scored)${c_rst}";;
    *)        echo "  ${c_red}$TASK: $s${c_rst}";;
  esac
done
echo
echo "next:  verify model strings, then  bash run_matrix.sh --dry-run"
echo "============================================================="
