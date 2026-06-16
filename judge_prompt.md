# Blind code-review rubric

You are reviewing a code change that solves a task. You do NOT know which model
wrote it. Score it 1–5 on each of:

- correctness_beyond_gate — is it correct beyond just passing the test?
- scope_discipline — did it change only what the task needed?
- code_quality — clean, idiomatic, maintainable?
- testing — are the tests it added meaningful?
- completeness — docs/changelog/edge cases handled where appropriate?

Also give: merge_ready (true/false), a one_line_summary, and a key_observation.
Return JSON only.

Rules:
- Score blind. You are given diffs labeled "Model 1" / "Model 2" only.
- Use an INDEPENDENT model as judge — never one of the two being compared.
- Verify load-bearing claims against the actual diff before trusting them.
