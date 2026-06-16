# Task_05 Review

> **Judge:** GPT-5.5 (independent — neither of the two models under test). Scoring was
> **blind**: each diff was presented only as "Model 1" / "Model 2" with identities
> withheld. Identities are revealed only in `overall_model_comparison.md`.
> **Note:** point-in-time comparison; one of the two models was later withdrawn.
> This is the only open-ended task and carries most of the evaluation's signal —
> read its caveats accordingly (n=5, one task, one judge).

## Task Summary
Open-ended: "When a command has several options, it's hard for users to tell at a glance which ones are required. Make that easier." Gate: MANUAL — no automated gate; judged on execution.

**Gate outcome:** MANUAL for all 10 runs — no automated gate ran. The task prescribes no specific mechanism; usage-line surfacing, marker columns, and label repositioning are all legitimate interpretations, judged on execution.

---

## Model 1

### run_1
```json
{{
  "scores": {"correctness_beyond_gate": 3, "scope_discipline": 3, "code_quality": 3, "testing": 3, "completeness": 3},
  "merge_ready": false,
  "one_line_summary": "Makes required options visible in usage, but misses important option forms and prompt interactions.",
  "key_observation": "Option.get_usage_pieces renders required options but only handles basic names/flags, with no secondary option, multiple, or prompt-aware handling."
}}
```

### run_2
```json
{{
  "scores": {"correctness_beyond_gate": 3, "scope_discipline": 4, "code_quality": 4, "testing": 4, "completeness": 3},
  "merge_ready": false,
  "one_line_summary": "A reasonable usage-line direction, but incomplete for prompt and repeatable required options.",
  "key_observation": "Option.get_usage_pieces handles `secondary_opts` but never suppresses `required=True, prompt=True` and does not render `multiple` with an ellipsis."
}}
```

### run_3
```json
{{
  "scores": {"correctness_beyond_gate": 4, "scope_discipline": 4, "code_quality": 4, "testing": 5, "completeness": 4},
  "merge_ready": true,
  "one_line_summary": "Comprehensive usage-line implementation with good edge-case tests for the chosen design.",
  "key_observation": "Command.collect_usage_pieces groups required options before operands, and Option.get_usage_pieces handles prompt, secondary opts, and repeatable options."
}}
```

### run_4
```json
{{
  "scores": {"correctness_beyond_gate": 4, "scope_discipline": 4, "code_quality": 4, "testing": 5, "completeness": 4},
  "merge_ready": false,
  "one_line_summary": "Mostly complete usage-line implementation, but it overstates prompt-backed required options as command-line requirements.",
  "key_observation": "Option.get_usage_pieces skips hidden options but not `self.prompt is not None`, so promptable required options are still pulled into Usage."
}}
```

### run_5
```json
{{
  "scores": {"correctness_beyond_gate": 4, "scope_discipline": 4, "code_quality": 4, "testing": 3, "completeness": 4},
  "merge_ready": false,
  "one_line_summary": "Adds a scannable required marker, but leaves the new `*` convention unexplained in help output and lightly tested.",
  "key_observation": "Command.format_options prefixes required rows with `*` and optional rows with a space, while still leaving `[required]` in the description."
}}
```


## Model 2

### run_1
```json
{{
  "scores": {"correctness_beyond_gate": 3, "scope_discipline": 4, "code_quality": 3, "testing": 3, "completeness": 3},
  "merge_ready": false,
  "one_line_summary": "Makes required options visible in usage, but the implementation is too narrow for Click's option surface.",
  "key_observation": "Option.get_usage_pieces chooses `max(self.opts, key=lambda o: len(_split_opt(o)[1]))` and omits secondary options, repeatable options, and prompt handling."
}}
```

### run_2
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 5, "code_quality": 5, "testing": 4, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Minimal and effective change that moves the existing required marker where users can scan it.",
  "key_observation": "Option.get_help_record removes `required` from trailing `extra_items` and prepends `[{_(extra['required'])}]` to the help text."
}}
```

### run_3
```json
{{
  "scores": {"correctness_beyond_gate": 4, "scope_discipline": 4, "code_quality": 4, "testing": 4, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Readable star-marker design with a legend, though it changes the option name column more than necessary.",
  "key_observation": "Command.format_options wraps records as `(required, rv)`, prefixes required terms with `* `, and omits the old inline `[required]` label."
}}
```

### run_4
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 5, "code_quality": 5, "testing": 4, "completeness": 4},
  "merge_ready": true,
  "one_line_summary": "Minimal, high-quality improvement that makes the existing required label scannable.",
  "key_observation": "Option.get_help_record prepends `[required]` before the help text and keeps range/default extras at the end."
}}
```

### run_5
```json
{{
  "scores": {"correctness_beyond_gate": 5, "scope_discipline": 4, "code_quality": 4, "testing": 5, "completeness": 5},
  "merge_ready": true,
  "one_line_summary": "Complete star-marker design with docs, tests, and a legend, at the cost of a broader help-format change.",
  "key_observation": "Command.format_options uses `isinstance(param, Option) and param.required` to prefix required option names with `* ` and writes a legend below the list."
}}
```

---

# Model Comparison

| Metric | Model 1 | Model 2 |
|---|---|---|
| Correctness (beyond gate) | 3.60 | 4.40 |
| Scope Discipline | 3.80 | 4.40 |
| Code Quality | 3.80 | 4.20 |
| Testing | 4.00 | 4.00 |
| Completeness | 3.60 | 4.40 |
| Avg score (of 5) | 3.76 | 4.28 |
| Total (of 25) | 18.8 | 21.4 |
| Merge-ready runs | 1/5 | 4/5 |

## Key Findings

- This open-ended task is where the models actually separate — and **the independent judge's verdict here is the reverse of the contestant-authored review** that preceded it. GPT-5.5 scored **Model 2 higher (4.28 vs 3.76), with 4/5 merge-ready vs 1/5.**
- Three legitimate design families appeared: usage-line surfacing (required options shown unbracketed next to `[OPTIONS]`), a `*` marker column with a legend, and repositioning the existing `[required]` label to the front of the help text.
- GPT-5.5 penalized several **Model 1** usage-line runs for incompleteness and a prompt-handling bug: promptable required options (`required=True, prompt=True`) were wrongly pulled into the usage line as if they must be supplied on the command line. It rated **Model 2's** marker/label-repositioning designs as clean, scannable, and merge-ready.
- **Verified against the diffs:** the `[required]`-label changes the earlier review flagged as "regressions" are real edits — but whether removing/repositioning the inline label is a *regression* or a *legitimate design choice* is exactly where the two judges disagree. GPT-5.5 read them as acceptable; the contestant judge read them as breaking. The facts are agreed; the *evaluation* of those facts is not.

## Verdict

**Edge: Model 2 (4.28 vs 3.76; 4/5 vs 1/5 merge-ready)** — per GPT-5.5.

> **Caveat — this is the least-firm finding in the whole evaluation.** It is a single
> open-ended task, n=5, and the two independent judges reached **opposite** verdicts on
> it. Two of Model 2's runs also used `AskUserQuestion` (an interactive call a headless
> harness cannot answer), which may have slightly hampered them. Treat task_05 as
> "models diverge on subjective judgment, and expert judges disagree about who's right"
> rather than a settled win for either side. A second open-ended task and a third judge
> would be the cheapest way to resolve it.
