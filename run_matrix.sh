#!/usr/bin/env bash
#
# run_matrix.sh — the experiment loop. MODELS x TASKS x REPS (from config.sh).
# Per run: reset -> checkout base -> [apply tests.patch + guard] ->
#          claude -p (model swapped) -> independent gate -> persist -> reset
#
# Output: $RUNS_DIR/<model>/<task>/run_<n>.{jsonl,gate,diff}
#
# Usage:
#   source .venv/bin/activate    # or let the script use .venv automatically
#   bash run_matrix.sh
#   bash run_matrix.sh --dry-run # setup only, no model calls, no cost
#
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/config.sh"
source "$HERE/lib.sh"

DRY=0; [[ "${1:-}" == "--dry-run" ]] && DRY=1
export CLAUDE_CODE_ENABLE_TELEMETRY=1

[[ -d "$WORK_REPO/.git" ]] || { err "no repo at $WORK_REPO — run setup.sh first"; exit 1; }

for MODEL in "${MODELS[@]}"; do
  for entry in "${TASKS[@]}"; do
    IFS='|' read -r TASK PR APPLY GATE <<< "$entry"
    BASE="$(base_sha_for "$TASK")"
    TARGET="$(gate_target "$TASK" "$GATE")"
    OUT="$RUNS_DIR/$MODEL/$TASK"; mkdir -p "$OUT"

    for RUN in $(seq 1 "$REPS"); do
      echo; echo "===== model=$MODEL task=$TASK run=$RUN/$REPS base=$BASE ====="
      reset_repo
      git -C "$WORK_REPO" checkout -q "$BASE" || { err "checkout failed"; echo "SETUP_FAIL=checkout" > "$OUT/run_${RUN}.gate"; continue; }

      if [[ "$APPLY" == "1" ]]; then
        git -C "$WORK_REPO" apply --check "$TASKS_DIR/$TASK/tests.patch" 2>/dev/null \
          || { err "tests.patch does not apply"; echo "SETUP_FAIL=patch" > "$OUT/run_${RUN}.gate"; continue; }
        git -C "$WORK_REPO" apply "$TASKS_DIR/$TASK/tests.patch"
        if run_gate "$TARGET"; then err "gate PASSES at base — invalid"; echo "SETUP_FAIL=base_passes" > "$OUT/run_${RUN}.gate"; continue; fi
      fi

      if [[ $DRY -eq 1 ]]; then ok "[dry-run] would run claude -p ($TASK / $MODEL)"; reset_repo; continue; fi

      # run the model — only --model varies
      ( cd "$WORK_REPO" && CLAUDE_CODE_ENABLE_TELEMETRY=1 \
        claude -p "$(cat "$PROMPTS_DIR/$TASK.md")" \
          --model "$MODEL" \
          --output-format stream-json --verbose \
          --allowedTools "$ALLOWED_TOOLS" \
          --max-turns "$MAX_TURNS" \
        ) > "$OUT/run_${RUN}.jsonl" 2>&1

      # independent gate = recorded outcome
      if [[ "$GATE" == "MANUAL" ]]; then
        echo "GATE=MANUAL" > "$OUT/run_${RUN}.gate"; warn "$TASK hand-scored from diff"
      else
        ( cd "$WORK_REPO" && PY -m pytest $TARGET -q >/dev/null 2>&1 ); G=$?
        ( cd "$WORK_REPO" && PY -m pytest -q >/dev/null 2>&1 ); F=$?
        { echo "GATE_EXIT=$G"; echo "FULL_SUITE_EXIT=$F"; } > "$OUT/run_${RUN}.gate"
        [[ $G -eq 0 ]] && ok "gate passed" || err "gate failed (GATE_EXIT=$G)"
      fi

      git -C "$WORK_REPO" diff > "$OUT/run_${RUN}.diff"
      reset_repo
    done
  done
done

echo; ok "matrix complete — results in $RUNS_DIR/"
echo "analyze with:  python3 parse_runs.py --runs \"$RUNS_DIR\""
