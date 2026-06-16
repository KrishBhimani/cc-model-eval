# Writing tasks

> Tasks belong to an **example** under `examples/<name>/`: the prompt files go in
> `examples/<name>/prompts/`, and the task list lives in `examples/<name>/config.sh`.
> The walkthrough below uses the shipped `click` example; substitute your own name.

There are two ways to make a task. Both end up as the same three pieces (base +
prompt + gate); they differ only in **where the gate's test comes from**.

- **From a PR** — you harvest a real merged pull request. Least work.
- **Custom (no PR)** — you write the test yourself. More work, zero contamination
  risk, and shaped around your own codebase.

---

## A) From a merged PR (recommended when PRs exist)

A merged PR already contains the fix *and* a test that proves it. `prep_task.py`
splits the PR into:

- `tests.patch` — the proving test → becomes your **gate** (applied before the model runs)
- `solution.patch` — the actual fix → **withheld** (this is the reference answer)

The model sees the failing test and must reproduce the fix.

**Steps**

1. Pick a PR merged **after the model's knowledge cutoff** (so it can't have memorized the fix).
2. Add a line to `config.sh`:
   ```bash
   "task_07|1234|1|AUTO"      # name | PR# | apply_tests=1 | AUTO gate
   ```
3. Run `bash setup.sh`. It fetches the PR, splits it, records the base commit in
   `tasks/task_07/meta.json`, and verifies the gate **fails at base, passes with the reference** (prints `LOCKED`).
4. Write `examples/<name>/prompts/task_07.md` describing the **symptom**, never the fix.

That's it — base commit and patches are tracked for you.

---

## B) Custom task (no PR / private codebase)

When there's no suitable PR, you supply the test. The helper does the bookkeeping.

**Steps**

1. Open the cloned repo at `.work/repo` and **add a test that fails today**
   because the bug/feature isn't done. **Do not write the fix.**

   ```python
   # .work/repo/tests/test_orders.py
   def test_discount_caps_at_50_percent():
       # apply_discount currently returns 90 here — should cap at 50
       assert apply_discount(100, 0.9) == 50
   ```

2. Scaffold the task (captures your test as `tests.patch`, pins the base,
   confirms it fails at base, resets the repo):

   ```bash
   bash make_custom_task.sh task_99 "tests/test_orders.py::test_discount_caps_at_50_percent"
   ```

3. Add it to `config.sh` (source `0` = no PR, `apply_tests=1`, explicit gate):

   ```bash
   "task_99|0|1|tests/test_orders.py::test_discount_caps_at_50_percent"
   ```

4. Write `examples/<name>/prompts/task_99.md` — symptom only:

   ```
   Discounts above 50% are applied in full instead of being capped at 50%.
   Run: pytest tests/test_orders.py::test_discount_caps_at_50_percent
   Done when: that test passes and the suite stays green.
   ```

Note: for custom tasks the harness verifies the **fail-at-base** half only —
there's no reference solution to check the pass side (that's the model's job).
Confirm solvability once yourself by writing a throwaway fix, then discard it.

---

## C) Open-ended task (no objective gate)

Some tasks have no single right answer ("make the help output easier to scan").
Use a `MANUAL` gate — the model runs, you save the diff, and a human/LLM scores it
(see [05-judging-and-results](05-judging-and-results.md)).

```bash
"task_05|0|0|MANUAL"      # no PR, no patch, hand/LLM scored
```

Prompt: deliberately leave the gap.
```
When a command has several options, it's hard to tell which are required.
Make that easier.
```

---

## What makes a good task

- **Verifiable** — for gated tasks, a test that mechanically proves done. No test, no objective outcome.
- **Symptom-only prompt** — say what's wrong and how to run tests; never how to fix. Spell out the fix and every model "passes," measuring nothing.
- **Right-sized** — big enough to force navigating the codebase (that's the signal), small enough to finish within `MAX_TURNS`.
- **Independent** — no task depends on another's output.
- **Varied by type** — bug fix, multi-file feature, refactor, debug-from-traceback, under-specified. Different types stress different behaviors; that's where models separate.

## The rule that never bends

The gate must **fail at base** and **pass with a correct fix**, verified *before*
you trust any model result. `setup.sh` (PR tasks) and `make_custom_task.sh`
(custom tasks) check the fail-at-base half automatically. A gate green at base =
broken task, not a successful model.
