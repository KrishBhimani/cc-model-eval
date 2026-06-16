# Overall Model Comparison — GPT-5.5 Blind Evaluation
## 40 runs (2 models × 4 tasks × 5 runs); judged blind by an independent model

> **Judge:** GPT-5.5 — neither of the two contestants (this is the key property that
> makes the scores defensible; an earlier evaluation authored by one of the contestants
> reached a different verdict on the open-ended task, see "Judge disagreement" below).
> **Blinding:** diffs were labeled only "Model 1" / "Model 2"; identities and token
> metrics were attached only after scoring.
> **Identities (revealed here only):** model1 = Claude Fable 5, model2 = Claude Opus 4.8.
> **Note:** point-in-time comparison; Fable 5 was later withdrawn. Treat the
> *methodology* as the reusable artifact and the verdict as a dated snapshot.

---

## Executive summary

**On the aggregate, the two models tie:** identical mean rubric score of **4.61 / 5**
across all 20 runs each. They also passed every automated gate (30/30 gated runs green,
full suite included), so on objectively-checkable tasks they are **indistinguishable in
capability**.

The differences are at the margins and they pull in opposite directions:

- **Model 1 (Fable)** edges the three gated tasks by tiny amounts (5.00 vs 4.76; 4.68
  vs 4.48; 5.00 vs 4.92) — differences of style, churn, and fidelity, not function.
- **Model 2 (Opus)** has the **higher merge-ready rate overall (18/20 = 90% vs 15/20 =
  75%)** and wins the one task with real spread — the open-ended task_05 (4.28 vs 3.76).

So "who won" depends entirely on which lens you weight. By average score it is a tie; by
merge-readiness Model 2 is ahead; by count-of-tasks Model 1 leads 3–1 but only because
three of the four tasks were near-ties it nudged.

**Headline:** *a tie on objective tasks; the only real separation is on subjective
judgment, and even there a second independent judge disagrees about who's better.*

---

## Scores

| Dimension (avg over 20 runs) | Model 1 (Fable) | Model 2 (Opus) | Edge |
|---|---|---|---|
| Correctness beyond gate | 4.60 | 4.65 | ~tie |
| Scope discipline | 4.65 | 4.55 | ~tie |
| Code quality | 4.45 | 4.30 | slight M1 |
| Testing | 4.75 | 4.75 | tie |
| Completeness | 4.60 | 4.80 | slight M2 |
| **Average (of 5)** | **4.61** | **4.61** | **tie** |
| Merge-ready runs | 15/20 (75%) | 18/20 (90%) | **M2** |

## Per-task verdicts

| Task | Type | M1 avg/5 | M2 avg/5 | M1 mr | M2 mr | GPT-5.5 verdict |
|---|---|---|---|---|---|---|
| task_01 — echo empty-bytes bug | gated | 5.00 | 4.76 | 5/5 | 5/5 | near-tie, marginal M1 (style only) |
| task_02 — Argument `help=` | gated | 4.68 | 4.48 | 4/5 | 4/5 | slight M1 (hygiene/scope) |
| task_04 — parameter-source timing | gated | 5.00 | 4.92 | 5/5 | 5/5 | near-tie, marginal M1 |
| task_05 — required-option visibility | **open-ended** | 3.76 | **4.28** | 1/5 | **4/5** | **M2** (the only real gap) |

## Resource usage (tokens, not dollars)

On a subscription the fair lens is raw usage, not cost. The two are within ~3%:
Model 1 averaged ~9,623 active tokens/run, Model 2 ~9,950. Model 2 was slightly faster
in wall time. There is no meaningful efficiency separation. (Dollar cost is excluded
deliberately — subscription usage; if deploying via API, Fable's higher tier price would
make it cost more per token, but that is a pricing fact, not a usage difference.)

---

## Judge disagreement (a finding in itself)

This evaluation (GPT-5.5, independent) and an earlier one authored by one of the two
contestants **agree on tasks 01/02/04** (near-ties) but **reach opposite verdicts on the
open-ended task_05**:

- The contestant-authored review scored **Model 1** the task_05 winner and called Model
  2's `[required]`-label changes *regressions*.
- GPT-5.5 scored **Model 2** the task_05 winner and read the same changes as *legitimate,
  merge-ready design choices*, while penalizing Model 1's usage-line runs for a
  prompt-handling bug.

The underlying code facts are **verified and agreed** (the label edits, the docs fix, the
prompt-handling gap all exist in the diffs). What differs is the *judgment* of whether
those choices are good. That disagreement, on the one subjective task, is the most
honest result in the study: **objective tasks don't separate these models, and on the
subjective one, expert judges don't agree on a winner.**

## Limitations

- **Gated tasks barely discriminated** — 30/30 passed; all signal came from one
  open-ended task and from side-effects gates can't catch.
- **The deciding task is n=5, single task, and judge-dependent** (two judges, opposite
  verdicts). It is suggestive, not conclusive.
- **One codebase, one harness, headless only** — two task_05 Model 2 runs used an
  interactive `AskUserQuestion` call the harness can't answer, possibly hampering them.
- **Fable 5 is withdrawn** — not reproducible; re-run with currently-available models.

## Bottom line

By every aggregate that pools the data, **this is a tie** — same mean score, same gate
pass rate, near-identical token usage. If forced to differentiate: **Model 2 (Opus) is
marginally more shippable** (90% vs 75% merge-ready) and won the only task with real
spread, while **Model 1 (Fable) was marginally cleaner** on the easy gated tasks. The
gap, either way, is "a preference, not a verdict." The durable takeaway is methodological:
rigorous evaluation shrank an expected capability gap to noise, and pushed all the real
signal onto subjective judgment where even independent judges disagree.
