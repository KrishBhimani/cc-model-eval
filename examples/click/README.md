# reviews/

Blind quality evaluation of all 40 runs.

- **Judge:** GPT-5.5 — an independent model, neither of the two under test.
- **Blind:** diffs were labeled only "Model 1" / "Model 2"; identities attached after scoring.
- **Identities** (revealed in `overall_model_comparison.md` only): Model 1 = Claude Fable 5, Model 2 = Claude Opus 4.8.

Files:
- `overall_model_comparison.md` — aggregate scores, per-task verdicts, judge-disagreement discussion.
- `task_0N_review.md` — per-run JSON scores, comparison table, findings, verdict for each task.

Load-bearing factual claims (label edits, docs fix, prompt-handling gap) were verified
directly against the run diffs, independent of the judge.
