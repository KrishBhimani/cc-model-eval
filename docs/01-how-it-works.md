# How it works

The harness compares two models by running each one over the same set of tasks,
many times, and measuring what happened. The core idea is tiny:

> **A task = a base commit + a prompt + a gate.**
> The model edits the code; the gate decides, mechanically, whether it succeeded.

Everything else (containers, replication, metrics, judging) is generic plumbing
that never changes when you add tasks or swap repos.

## The three pieces

| Piece | What it is | Where it comes from |
|-------|-----------|---------------------|
| **Base commit** | the exact code state the model starts from | tracked automatically in `tasks/<task>/meta.json` |
| **Prompt** | describes the symptom/goal, never the fix | `prompts/<task>.md` (you write it) |
| **Gate** | a command that's RED before, GREEN after | a test command (or `MANUAL`) |

## A single run, start to finish

1. **Reset** the repo to a clean slate (`git clean -fdx`) and check out the task's base commit.
2. *(gated tasks)* **Apply the test** and confirm it **fails** — proof the task is really unsolved at the start. If it already passes, the harness aborts: the task is malformed, not the model.
3. **Run the model** (`claude -p`) with the prompt. Only `--model` differs between the two contestants; everything else is identical.
4. **Re-run the gate yourself.** That exit code is the recorded outcome — never the model's claim of success.
5. **Save** the model's `git diff` for scoring.
6. **Reset** for the next run.

## Why the before/after flip matters

The gate is a thermometer. It must read "sick" before treatment and "healthy"
after. If it reads healthy *before* the model starts, the thermometer is broken
(bad task setup). This is the one rule that never bends, and `setup.sh` enforces it.

## Why many runs

Models are stochastic — the same model on the same task varies run to run (we
saw 30–60% cost swings). One run is an anecdote; 5 runs is a measurement. Always
read distributions (median + range), never a single number.
