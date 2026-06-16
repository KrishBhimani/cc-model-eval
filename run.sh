#!/usr/bin/env bash
# run.sh — run every task, for both models, REPS times each.
# Each run: reset repo -> copy task test in -> run the model -> run the gate ->
# save the model's diff and the outcome.  No patches, no PR logic.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/config.sh"; source "$HERE/lib.sh"

DRY=0; [[ "${1:-}" == "--dry-run" ]] && DRY=1

mkdir -p "$RUNS_DIR"
echo "=== run matrix ==="
echo "models: ${MODELS[*]}   reps: $REPS   $([[ $DRY == 1 ]] && echo '(dry run)')"

for task_dir in "$TASKS_DIR"/*/; do
  task="$(basename "$task_dir")"
  gate="$(gate_of "$task")"
  prompt_file="$task_dir/prompt.md"
  [[ -f "$prompt_file" ]] || { err "$task has no prompt.md — skipping"; continue; }

  for model in "${MODELS[@]}"; do
    for rep in $(seq 1 "$REPS"); do
      run_id="${task}__${model}__run${rep}"
      out_dir="$RUNS_DIR/$run_id"
      echo "--- $run_id ---"

      if [[ $DRY == 1 ]]; then
        echo "    would: reset, install test, run $model, gate='$gate'"
        continue
      fi

      mkdir -p "$out_dir"
      reset_repo
      install_task_tests "$task" || true   # MANUAL tasks have no test; that's fine

      # run the model headlessly inside the repo
      ( cd "$REPO_DIR" && cat "$prompt_file" | \
        claude -p \
          --model "$model" \
          --max-turns "$MAX_TURNS" \
          --allowedTools "$ALLOWED_TOOLS" \
          --output-format stream-json --verbose \
        > "$out_dir/run.jsonl" 2> "$out_dir/run.err" )

      # record what the model changed
      git -C "$REPO_DIR" diff > "$out_dir/model.diff"

      # run the gate (skip for MANUAL); save full pytest output either way
      if [[ "$gate" == "MANUAL" ]]; then
        echo "MANUAL" > "$out_dir/gate_result.txt"
        echo "    done (manual — score by hand/LLM)"
      else
        if run_gate "$task" "$out_dir/gate_output.txt"; then
          echo "PASS" > "$out_dir/gate_result.txt"; echo "    gate: PASS"
        else
          echo "FAIL" > "$out_dir/gate_result.txt"; echo "    gate: FAIL"
          # show the failing lines inline so you don't have to open the file
          grep -E "FAILED|Error|assert" "$out_dir/gate_output.txt" | head -5 | sed 's/^/        /'
        fi
      fi
      reset_repo
    done
  done
done

echo
echo "all runs in $RUNS_DIR"
echo "next:  python3 parse.py        # writes metrics.csv (one row per run)"
echo "       then judge quality with judge_prompt.md (blind, independent model)"
