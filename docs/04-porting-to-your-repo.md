# Porting to another repo or a private codebase

The harness is repo-agnostic. Pointing it at something new is mostly `config.sh`
plus authoring tasks.

## Steps

1. **Set the target** in `config.sh`:
   ```bash
   REPO_URL="https://github.com/your-org/your-repo"
   PIP_INSTALL=".[dev]"     # or ".[test]", or "-r requirements.txt" — match your repo
   ```
   Private repo? Clone it to `.work/repo` yourself (with your credentials) before
   running `setup.sh`; the script reuses an existing clone.

2. **Choose tasks** (see [03-writing-tasks](03-writing-tasks.md)):
   - repo has good recent PRs → harvest them (`name|PR#|1|AUTO`)
   - private/no PRs → write custom tasks (`make_custom_task.sh`)

3. **Run** `bash setup.sh`, then the model-string check, dry-run, and matrix
   (see the main README quickstart).

## Picking a good target repo

- **Pure-Python, fast test suite** installs in seconds → cheap to spin per run.
  Heavy native builds (numpy/scipy/cython) or huge suites tax every one of your runs.
- **Medium-sized** — big enough that the agent must search/navigate (that's the
  agentic signal), small enough to build quickly.
- **A real test runner** — `pytest` here. Other runners work; adjust the gate
  commands and the `run_gate`/pytest calls accordingly.

## Contamination — the thing to watch

If a model saw the fix during training, you measure memorization, not skill.

- **Public repos:** pick PRs merged **after** the model's knowledge cutoff. The
  more recent, the safer.
- **Private codebases:** inherently safe — the code was never public, so custom
  tasks can't have been memorized. This is the strongest position for a fair test.

## Non-Python repos

Nothing is Python-specific except the gate commands and `PIP_INSTALL`. To target,
say, a Node repo: change `PIP_INSTALL` to your install step, and write gates as
the test command for that stack (e.g. a `jest` invocation). The base+prompt+gate
model is identical; only the words in the gate change.
