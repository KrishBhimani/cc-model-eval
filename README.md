# cc-model-eval — compare two AI coding models on a real repo

Give two models the same coding tasks against a real codebase, run each task
several times, and check the result with a test. No PRs, no patches — a task is
just a folder with a prompt and a test file.

## Run it

    bash setup.sh            # clone the repo, make a venv, install, validate tasks
    bash run.sh --dry-run    # see what will run
    bash run.sh              # run every task × both models × REPS
    python3 parse.py         # write metrics.csv (per-run metrics)

You need: `claude` (Claude Code) + Node, Python 3.10+, git. Auth via
`ANTHROPIC_API_KEY` or a Claude subscription. Optionally set `GITHUB_TOKEN`.

## Change what it does — edit `config.sh`

Open `config.sh`. Everything you change is in the **EDIT THIS** block at the top;
the plumbing below it is internal. The three things that define an experiment:

1. **The repo under test** — `REPO_URL`, `PIP_INSTALL` (keep `-e` for an editable
   install so the model's edits are what the gate runs against), `EXTRA_PIP`
   (e.g. `pytest`), and `TESTS_SUBDIR` (where that repo keeps its tests — `tests`,
   `test`, `.`, etc.). `VERIFY_IMPORT` is an optional import-check.
2. **The models** — `MODEL_A` / `MODEL_B`.
3. **The tasks** — folders under `tasks/` (see below), not set in `config.sh`.

**To retarget to another repo/stack:** edit the four repo lines in section 1.
The bottom of the EDIT block has ready-made presets (Flask, Requests, requirements
files, root-level tests) you can copy up. Nothing about the target repo is
hardcoded in any script — it all comes from `config.sh`.

## Add a task — make a folder under `tasks/`

A task is a folder containing:

    tasks/my_task/
      prompt.md     # what the model is asked to do — describe the SYMPTOM, never the fix
      gate.txt      # pytest target(s) on one line, OR the word MANUAL
      test_*.py     # (gated tasks) one or more test files; ALL test_*.py in the
                    #   folder are copied into the repo's tests/ as-is

**Multiple tests for one task:** drop as many `test_*.py` files in the folder as
you want — they're all copied in. In `gate.txt`, list every target the gate
should run, space-separated on one line, e.g.:

    tests/test_choice_suggestion.py tests/test_choice_extra.py

or target specific tests:

    tests/test_choice_suggestion.py::test_suggests_closest_choice_on_typo tests/test_other.py

The gate passes only if **all** listed targets pass.

How it works:
- For a **gated** task, `setup.sh` copies your `test_*.py` files into the repo and
  checks the gate **fails** on the untouched code (proving the task is real). At run
  time the model attempts the task, then the same gate runs again — pass/fail is the
  result.
- For a **MANUAL** task (`gate.txt` = `MANUAL`), there's no test; you score the
  results by hand or with an LLM judge (see `judge_prompt.md`).

Writing a good gated task: write a `test_*.py` that fails today because the
feature/fix doesn't exist yet. If `setup.sh` says `ALREADY-PASSES`, the behavior
already exists — pick something else or tighten the test.

## Judge quality (beyond pass/fail)

Passing a test means the code works, not that it's good. Collect the `model.diff`
files from `runs/`, strip identities, and have an INDEPENDENT third model score
them with `judge_prompt.md`. Then verify its load-bearing claims against the diffs.

## Layout

    config.sh     all settings
    setup.sh      clone + install + validate tasks
    run.sh        the run loop
    parse.py      runs/ -> table
    judge_prompt.md   blind review rubric
    tasks/        one folder per task
    .repo .venv runs/   generated locally

## What each run saves

Every run writes a folder `runs/<task>__<model>__run<N>/` containing:

    run.jsonl         the model's full session (every step/tool call), stream-json
    run.err           anything claude printed to stderr (check here first if a run breaks)
    model.diff        the code the model changed — its actual answer
    gate_result.txt   PASS / FAIL / MANUAL
    gate_output.txt   the full pytest output (so you can see WHY it failed)

`python3 parse.py` then rolls all runs up into **metrics.csv**, one row per run:
model, task, run, outcome, gate_exit, num_turns, tool_calls_total,
tool_calls_failed, files_read, files_edited, input_tokens, output_tokens,
cache_read, cache_creation, duration_ms, num_retries, tools. (No dollar cost —
raw token/tool usage is the fair lens for subscription runs.)

## See what a model actually changed

Each run saves the model's edits as `model.diff`. To read it as a diff:

    cat runs/<task>__<model>__run<N>/model.diff

To actually apply it to the repo and inspect/run the result yourself:

    cd .repo
    git reset --hard && git clean -fd            # start clean
    git apply ../runs/<task>__<model>__run<N>/model.diff
    # ...now the repo contains that run's changes. look around, run tests, etc.
    git diff                                      # review what was applied
    git reset --hard && git clean -fd            # undo when done

This is also how you'd verify a judge's claim about a specific run: apply that
run's diff, look at the actual code, and confirm the claim holds.