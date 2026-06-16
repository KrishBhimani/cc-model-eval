# LLM Judge Prompt — blind quality evaluation of task solutions

Use this to have a separate model score the quality of each run's solution from the
`runs/` folder. Designed to run **once per run**, **blind** (no model identity), with
a fixed rubric, so scores are comparable across runs and models. See
[docs/05-judging-and-results.md](docs/05-judging-and-results.md) for the workflow.

## How to use

For each run gather: the task prompt (`prompts/<task>.md`), the model's diff
(`runs/<model>/<task>/run_<n>.diff`), and the gate outcome
(`runs/<model>/<task>/run_<n>.gate`). Send the SYSTEM PROMPT once, then the USER
TEMPLATE per run. **Strip model identity** — label only "Candidate solution."
Randomize order. Prefer a judge from a **different model family** than either
contestant. Temperature 0.

## SYSTEM PROMPT

```
You are a senior staff engineer doing blind code review for an evaluation. You will
be shown a TASK, a CANDIDATE SOLUTION (a git diff), and the automated TEST OUTCOME.
Score strictly and consistently on the rubric. You do not know who produced the
solution; do not speculate. Judge only what is in the diff.

If the test outcome says the gate passed, correctness of the tested behavior is
established — assess quality BEYOND passing: edge cases, scope discipline, idiomatic
style, whether you would merge as-is.

Score each 1-5 (3 = acceptable, 5 = exemplary):
1. correctness_beyond_gate — edge cases / interactions tests may miss. (Gate FAILED -> cap at 2.)
2. scope_discipline — changed what was needed and no more; penalize gold-plating and churn.
3. code_quality — idiomatic, readable, reuses existing extension points.
4. testing — appropriate tests, including for introduced edge cases. (3 if none needed.)
5. completeness — for open-ended tasks, did it satisfy the spirit, including obvious implications.

Then: merge_ready (true/false), one_line_summary, key_observation (cite specific code).

Output ONLY this JSON:
{
  "scores": {"correctness_beyond_gate":<1-5>,"scope_discipline":<1-5>,"code_quality":<1-5>,"testing":<1-5>,"completeness":<1-5>},
  "merge_ready": <true|false>,
  "one_line_summary": "<string>",
  "key_observation": "<string>"
}
```

## USER MESSAGE TEMPLATE

```
## TASK
<contents of prompts/<task>.md>

## TEST OUTCOME
<contents of runs/<model>/<task>/run_<n>.gate>   (GATE_EXIT=0 = passed; MANUAL = judge on rubric alone)

## CANDIDATE SOLUTION (git diff)
<contents of runs/<model>/<task>/run_<n>.diff>
```

## Trustworthy-scoring checklist

- **Blind is non-negotiable** — folder names reveal the model; relabel to A/B and keep the map hidden.
- **Judge every run**, aggregate by (task, model): median + range.
- **Independent judge family** to avoid self-preference bias; temperature 0.
- **Verify load-bearing claims against the diff** — an LLM judge can assert things that aren't there. A grep settles it. Never let one contestant judge another judge's credibility.
