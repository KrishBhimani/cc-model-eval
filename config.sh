#!/usr/bin/env bash
# config.sh — generic settings shared by every experiment.
# Repo-specific bits (target repo + task ladder + prompts) live in an EXAMPLE file
# under examples/<name>/config.sh, selected via the EXAMPLE variable.
#
# To run your own: copy examples/click/ to examples/<yours>/, edit it, and set
# EXAMPLE=<yours>  (or just edit examples/click in place).

EVAL_HOME="${EVAL_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# ---- which example to run -------------------------------------------------
EXAMPLE="${EXAMPLE:-click}"

# ---- environment (generic) -----------------------------------------------
WORK_REPO="$EVAL_HOME/.work/repo"
VENV_DIR="$EVAL_HOME/.venv"
TASKS_DIR="$EVAL_HOME/tasks"
RUNS_DIR="$EVAL_HOME/runs"
# PROMPTS_DIR and REPO_URL/PIP_INSTALL/TASKS are set by the example file below.

# ---- experiment knobs (generic) ------------------------------------------
REPS=5
MAX_TURNS=60
ALLOWED_TOOLS="Bash,Read,Edit,Write"

# ---- models (verify these resolve under your auth) -----------------------
MODEL_A="${MODEL_A:-claude-opus-4-8}"
MODEL_B="${MODEL_B:-claude-sonnet-4-6}"
MODELS=("$MODEL_A" "$MODEL_B")

# ---- load the selected example (defines REPO_URL, PIP_INSTALL, PROMPTS_DIR, TASKS)
EXAMPLE_CONFIG="$EVAL_HOME/examples/$EXAMPLE/config.sh"
if [[ -f "$EXAMPLE_CONFIG" ]]; then
  source "$EXAMPLE_CONFIG"
else
  echo "ERROR: example '$EXAMPLE' not found at $EXAMPLE_CONFIG" >&2
  return 1 2>/dev/null || exit 1
fi
