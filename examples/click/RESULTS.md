# Results: a worked example (two Claude models on `pallets/click`)

A complete run of this harness: **2 models × 4 tasks × 5 replications = 40 runs**,
headless via `claude -p`. Three tasks have machine-checked gates; one is open-ended.
Quality was scored **blind by an independent judge (GPT-5.5)** — neither contestant.

> **Identities:** Model 1 = Claude Fable 5, Model 2 = Claude Opus 4.8.
> **Cost note:** run on a Claude *subscription*, so dollar figures are list-price
> *equivalents*, not spend; the fair lens here is raw token usage. **Availability:**
> Fable 5 was later withdrawn — treat this as a dated snapshot; the *methodology* is the
> reusable artifact.

## Headline

| Axis | Result |
|------|--------|
| Reliability (gated tasks) | **tie** — both 5/5 on every gated task, 0 regressions, 0 non-convergence |
| Aggregate quality (GPT-5.5, blind) | **tie** — identical 4.61 / 5 mean across 20 runs each |
| Merge-ready rate | **Model 2 (Opus)** — 18/20 (90%) vs 15/20 (75%) |
| Open-ended task (the only real gap) | **Model 2 (Opus)** — 4.28 vs 3.76, 4/5 vs 1/5 merge-ready |
| Token usage | **~tie** — within ~3% |

**The honest summary:** on objectively-checkable tasks the two models are
indistinguishable — same gate pass rate, same mean rubric score, near-identical token
usage. The only separation is on the single open-ended task, and even there an *earlier
independent judge reached the opposite verdict*. The durable finding is methodological:
careful evaluation shrank an expected capability gap to noise and pushed all the signal
onto subjective judgment, where expert judges disagree.

## Per-task (GPT-5.5 blind scores)

| Task | Type | M1 (Fable) /5 | M2 (Opus) /5 | M1 mr | M2 mr |
|---|---|---|---|---|---|
| task_01 — echo empty-bytes bug | gated | 5.00 | 4.76 | 5/5 | 5/5 |
| task_02 — Argument `help=` | gated | 4.68 | 4.48 | 4/5 | 4/5 |
| task_04 — parameter-source timing | gated | 5.00 | 4.92 | 5/5 | 5/5 |
| task_05 — required-option visibility | open-ended | 3.76 | **4.28** | 1/5 | **4/5** |

Per-task detail in `reviews/`; the full reasoning and judge-disagreement discussion in
`reviews/overall_model_comparison.md`.

## Why replication mattered

Within each (model, task) cell, token usage and timing varied substantially run to run.
A single run per cell could have shown a very different ratio. n=5 makes the central
tendency trustworthy. One-shot comparisons of stochastic agents are not reliable.

## Two independent judges, one disagreement

Quality was first scored by an evaluation authored by one of the contestants, then
re-scored blind by GPT-5.5. They **agree** on the three gated tasks (near-ties) and
**disagree** on the open-ended task_05 — opposite winners. The underlying code facts
(label edits, a docs fix, a prompt-handling gap) were **verified directly against the
diffs** and hold regardless of judge; what differs is the *judgment* of whether those
choices are good. We report the independent (GPT-5.5) verdict as primary and flag the
disagreement rather than hiding it.

## Limitations

- Gated tasks barely discriminated (30/30 passed) — signal concentrated in one
  open-ended task and in side-effects gates can't see.
- The deciding task is n=5, single task, judge-dependent (two judges, opposite verdicts).
- One codebase, headless only; two task_05 runs used an interactive call the harness
  can't answer.
- Fable 5 withdrawn — not reproducible; re-run with current models.

## Reproduce / extend

Point `examples/<name>/config.sh` at any two currently-available models and re-run. See
`docs/` for adding harder tasks (to probe capability), more open-ended tasks (to firm up
the subjective axis), or a third independent judge.
