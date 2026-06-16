# Task_04 Review

> **Judge:** GPT-5.5 (independent — neither of the two models under test). Scoring was
> **blind**: each diff was presented only as "Model 1" / "Model 2" with identities
> withheld. Identities are revealed only in `overall_model_comparison.md`.
> **Note:** point-in-time comparison; one of the two models was later withdrawn.

## Task Summary
Diagnose and fix three failures: `ctx.get_parameter_source()` returns `None` during `ParamType.convert()` and eager callbacks when the value came from the `DEFAULT` source. Gate: `tests/test_defaults.py` and `tests/test_options.py` plus the full suite.

**Gate outcome:** all 10 runs passed (GATE_EXIT=0, FULL_SUITE_EXIT=0).

---

## Model 1

### run_1
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 5, "code_quality": 5, "testing": 5, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Cleanly fixes source visibility during conversion/callbacks while preserving slot arbitration.",
  "key_observation": "Parameter processing provisionally calls `ctx.set_parameter_source(self.name, source)` before `process_value`, then restores `existing_source` if arbitration loses."
}}
```

### run_2
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 5, "code_quality": 5, "testing": 5, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Cleanly fixes source visibility during conversion/callbacks while preserving slot arbitration.",
  "key_observation": "Parameter processing provisionally calls `ctx.set_parameter_source(self.name, source)` before `process_value`, then restores `existing_source` if arbitration loses."
}}
```

### run_3
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 5, "code_quality": 5, "testing": 5, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Cleanly fixes source visibility during conversion/callbacks while preserving slot arbitration.",
  "key_observation": "Parameter processing provisionally calls `ctx.set_parameter_source(self.name, source)` before `process_value`, then restores `existing_source` if arbitration loses."
}}
```

### run_4
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 5, "code_quality": 5, "testing": 5, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Cleanly fixes source visibility during conversion/callbacks while preserving slot arbitration.",
  "key_observation": "Parameter processing provisionally calls `ctx.set_parameter_source(self.name, source)` before `process_value`, then restores `existing_source` if arbitration loses."
}}
```

### run_5
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 5, "code_quality": 5, "testing": 5, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Cleanly fixes source visibility during conversion/callbacks while preserving slot arbitration.",
  "key_observation": "Parameter processing provisionally calls `ctx.set_parameter_source(self.name, source)` before `process_value`, then restores `existing_source` if arbitration loses."
}}
```


## Model 2

### run_1
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 5, "code_quality": 5, "testing": 5, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Cleanly fixes source visibility during conversion/callbacks while preserving slot arbitration.",
  "key_observation": "Parameter processing provisionally calls `ctx.set_parameter_source(self.name, source)` before `process_value`, then restores `existing_source` if arbitration loses."
}}
```

### run_2
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 4, "code_quality": 4, "testing": 5, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Correctly fixes the bug, but moves the full arbitration block before value processing, creating extra churn.",
  "key_observation": "The diff precomputes `is_winner` before `process_value` and then only writes `ctx.params[self.name] = value` after conversion."
}}
```

### run_3
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 5, "code_quality": 5, "testing": 5, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Cleanly fixes source visibility during conversion/callbacks while preserving slot arbitration.",
  "key_observation": "Parameter processing provisionally calls `ctx.set_parameter_source(self.name, source)` before `process_value`, then restores `existing_source` if arbitration loses."
}}
```

### run_4
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 5, "code_quality": 5, "testing": 5, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Cleanly fixes source visibility during conversion/callbacks while preserving slot arbitration.",
  "key_observation": "Parameter processing provisionally calls `ctx.set_parameter_source(self.name, source)` before `process_value`, then restores `existing_source` if arbitration loses."
}}
```

### run_5
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 5, "code_quality": 5, "testing": 5, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Cleanly fixes source visibility during conversion/callbacks while preserving slot arbitration.",
  "key_observation": "Parameter processing provisionally calls `ctx.set_parameter_source(self.name, source)` before `process_value`, then restores `existing_source` if arbitration loses."
}}
```

---

# Model Comparison

| Metric | Model 1 | Model 2 |
|---|---|---|
| Correctness (beyond gate) | 5.00 | 5.00 |
| Scope Discipline | 5.00 | 4.80 |
| Code Quality | 5.00 | 4.80 |
| Testing | 5.00 | 5.00 |
| Completeness | 5.00 | 5.00 |
| Avg score (of 5) | 5.00 | 4.92 |
| Total (of 25) | 25.0 | 24.6 |
| Merge-ready runs | 5/5 | 5/5 |

## Key Findings

- **The strongest task for both models** — nine of ten runs converge on the same correct pattern: publish the parameter source provisionally before `process_value()`, then restore the prior winner's source if the parameter loses slot arbitration.
- **All ten runs are merge-ready.** The only differentiators GPT-5.5 noted are hygiene (a harmless redundant winner-branch write in a few runs) and one Model 2 run that moves the whole arbitration block earlier — correct, but more churn.

## Verdict

**Near-tie, marginal edge Model 1 (5.00 vs 4.92).** Both effectively perfect; the gap is a single churn penalty on one Model 2 run.
