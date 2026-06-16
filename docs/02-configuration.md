# Configuration — where to change what

Everything tunable lives in **`config.sh`**. You should never need to edit the
other scripts to run your own experiment.

## The knobs

```bash
REPO_URL="https://github.com/pallets/click"   # the codebase under test
WORK_REPO="$EVAL_HOME/.work/repo"             # where it gets cloned
PIP_INSTALL=".[dev]"                          # how to install its deps

REPS=5                          # runs per (model, task) — more = tighter confidence
MAX_TURNS=60                    # cap; hitting it counts as "did not converge"
ALLOWED_TOOLS="Bash,Read,Edit,Write"   # identical for both models

MODEL_A="claude-opus-4-8"        # \
MODEL_B="claude-sonnet-4-6"      #  > the two models compared
MODELS=("$MODEL_A" "$MODEL_B")  # /   (add a third string for a 3-way)
```

## The task list

```bash
TASKS=(
  "task_01|3493|1|tests/test_utils.py::test_echo_custom_file"
  # name | source | apply_tests | gate
)
```

Each task is a single `|`-delimited line:

| Field | Meaning | Values |
|-------|---------|--------|
| **name** | folder name under `tasks/` and `prompts/` | e.g. `task_07` |
| **source** | where the task comes from | a **PR number**, or `0` for authored/custom |
| **apply_tests** | apply a `tests.patch` before the model runs? | `1` (yes) or `0` (no) |
| **gate** | how success is judged | pytest target, `AUTO`, or `MANUAL` |

### Gate values

- **explicit** — `tests/test_x.py::test_y` (or a whole file) — run exactly this.
- **`AUTO`** — run whatever test files the PR's `tests.patch` touched. Handy so you don't have to look up names.
- **`MANUAL`** — no command can judge it (open-ended task); scored by human/LLM from the saved diff.

## Common edits at a glance

| You want to… | Change |
|--------------|--------|
| Run more/fewer replications | `REPS` |
| Compare different models | `MODEL_A` / `MODEL_B` (any strings your auth can reach) |
| Test a different repo | `REPO_URL` (+ `PIP_INSTALL` if its extras differ) |
| Add a task from a PR | add `"<name>|<PR#>|1|AUTO"` |
| Add a custom/no-PR task | see [03-writing-tasks](03-writing-tasks.md) |
| Give the model more headroom on hard tasks | `MAX_TURNS` |

## Generic vs example-specific config

`config.sh` (repo root) holds **generic** settings: models, reps, turn cap, paths.
The **repo-specific** bits — target `REPO_URL`, `PIP_INSTALL`, `PROMPTS_DIR`, and the
`TASKS` ladder — live in `examples/<name>/config.sh` and are loaded by setting:

```bash
EXAMPLE=click bash setup.sh     # default; loads examples/click/config.sh
```

To make your own experiment, copy the example and point at it:

```bash
cp -r examples/click examples/myrepo
# edit examples/myrepo/config.sh (REPO_URL, TASKS) and examples/myrepo/prompts/
EXAMPLE=myrepo bash setup.sh
EXAMPLE=myrepo bash run_matrix.sh
```
