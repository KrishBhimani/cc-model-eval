# cc-model-eval

A small, reproducible harness for **comparing two coding-agent models head-to-head
on real engineering tasks**, run headlessly through Claude Code (`claude -p`).

It runs each model over a ladder of tasks, many times each, with a machine-checked
success gate per task — then reports success rates plus quality (blind-judged) and token efficiency, conditioned on success (tokens, tool calls, turns). It ships configured to compare two
Claude models on [`pallets/click`](https://github.com/pallets/click), but every
part is configurable and it ports to any repo or private codebase.

> **Why the ceremony?** The goal is *measurement*, not just running a model. That
> needs three things a bare `claude -p` doesn't give you: an objective definition
> of "done" (the gate), tasks the model couldn't have memorized (recent/private
> code), and an identical starting state so the **only** variable between runs is
> the model.

## The idea in one line

> **A task = a base commit + a prompt + a gate.** The model edits the code; the
> gate (a test that's red before, green after) decides success mechanically.

## Repo layout in one line

The **root is the generic harness** (scripts + docs); each concrete experiment —
target repo, task prompts, results — lives under **`examples/<name>/`**. The shipped
`examples/click/` is the worked example. Make your own by copying it.

## Quickstart

```bash
git clone <your-fork-url> cc-model-eval && cd cc-model-eval
export ANTHROPIC_API_KEY=sk-ant-...   # or a Claude subscription
export GITHUB_TOKEN=ghp_...           # avoids GitHub's 60/hr unauth limit

EXAMPLE=click bash setup.sh   # clone repo, venv, install, prep + verify tasks
                              # (click is the default example; omit EXAMPLE to use it)
bash run_matrix.sh --dry-run  # exercises setup with no model calls / no cost
bash run_matrix.sh            # MODELS x TASKS x REPS (default 2 x 4 x 5 = 40)
python3 parse_runs.py --runs ./runs   # -> runs/metrics.csv + summary
```

## Documentation

| Doc | What it covers |
|-----|----------------|
| [docs/01-how-it-works.md](docs/01-how-it-works.md) | the mental model and a single run's lifecycle |
| [docs/02-configuration.md](docs/02-configuration.md) | `config.sh` — where to change what |
| [docs/03-writing-tasks.md](docs/03-writing-tasks.md) | adding tasks: **from a PR, custom/no-PR, and open-ended**; how to write gates |
| [docs/04-porting-to-your-repo.md](docs/04-porting-to-your-repo.md) | targeting another repo or a private codebase |
| [docs/05-judging-and-results.md](docs/05-judging-and-results.md) | reading metrics, blind LLM judging, verifying the judge |

## Files

```
config.sh           all tunables (single source of truth)
setup.sh            clone + venv + install + prep/verify tasks
run_matrix.sh       the experiment loop
parse_runs.py       logs -> runs/metrics.csv + summary
prep_task.py        PR -> (tests.patch, solution.patch, meta.json)
make_custom_task.sh scaffold a custom (no-PR) task from a test you wrote
lib.sh              shared helpers
judge_prompt.md     blind LLM-judge rubric for quality scoring
docs/               full guide (start here)
examples/click/     a complete worked experiment (config, prompts, RESULTS.md, reviews/)
.work/ .venv/ tasks/ runs/   generated locally (gitignored)
```

## Requirements

- **Claude Code** (`claude`) + **Node.js** — https://docs.claude.com/en/docs/claude-code
- **Python 3.10+**, **git**
- Anthropic auth: `ANTHROPIC_API_KEY` (recommended) or a Claude subscription
- A `GITHUB_TOKEN` for PR-based task prep
- Recommended: run inside a **container** so liberal tool permissions are sandboxed

## Status of the shipped example

The included examples/click/RESULTS.md is a worked example comparing two Claude models (one since withdrawn) at a point in time. The headline finding was that they came out roughly tied on objective gated tasks, with the only real separation on the open-ended task — where two independent judges disagreed. Treat the methodology as the reusable artifact, not the verdict; point the harness at whatever two models are available to you and re-run.
