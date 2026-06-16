# Judging and reading results

## Automatic metrics

After a run, `parse_runs.py` turns the raw logs into a table:

```bash
python3 parse_runs.py --runs ./runs
```

It writes `runs/metrics.csv` (one row per run) and prints a per-(model, task)
summary. Key columns: `outcome` (pass/fail/manual/did_not_converge), `total_cost_usd`,
token counts split by type, `tool_calls_total`, `num_turns`, `regressed`.

**Read it correctly:**
- **Efficiency only among passes.** Cost/tokens of failed runs don't count — a
  model cheap at being *wrong* shouldn't win.
- **Distributions, not points.** Report median + range across replications. If
  ranges overlap, the gap isn't real.
- **Per task, not just pooled.** A model can win small tasks and lose large ones.
- **Cost caveat:** on a subscription, `total_cost_usd` is the API *list-price
  equivalent*, not money spent — a proxy for resource intensity. Trust ratios, not absolutes.

## Judging quality (gated outcome ≠ quality)

Passing the gate proves correctness of the *tested* behavior. It does not measure
edge cases, scope discipline, or "would I merge this." For that, score the diffs.

Use `judge_prompt.md`. The two rules that make scores trustworthy:

1. **Blind.** Strip model identity — the folder names (`runs/<model>/...`) reveal
   it, so rename to neutral labels (`solution_A` / `solution_B`) and keep the
   mapping in a file you don't show the judge.
2. **Independent judge.** Use a model family that is **neither contestant** (else
   it may favor its own style — self-preference bias). Judge one run per call, at
   temperature 0, against the same rubric.

Then aggregate the per-run JSON scores by (task, model), same as the metrics —
median and range, judging all runs (not just one) so you see whether quality is stable.

## Trust, but verify the judge

LLM judges can assert things that aren't in the diff. For any finding that decides
a verdict, **check it against the actual diff** (a `grep` is enough): did the run
really delete that line, edit that file, add that test? Verified facts beat any
judge's prose. Never let one contestant adjudicate another judge's credibility —
check the code yourself.
