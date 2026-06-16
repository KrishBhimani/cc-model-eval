#!/usr/bin/env bash
# examples/click/config.sh — the Click worked example.
# Selected by setting EXAMPLE=click (the default) before sourcing root config.sh.
# Defines only what differs from the generic template: target repo + task ladder.

REPO_URL="https://github.com/pallets/click"
PIP_INSTALL=".[dev]"

# prompts for this example live alongside this file
PROMPTS_DIR="$EVAL_HOME/examples/click/prompts"

# task ladder — name | source(PR# or 0) | apply_tests(1/0) | gate
TASKS=(
  "task_01|3493|1|tests/test_utils.py::test_echo_custom_file"
  "task_02|3473|1|tests/test_arguments.py tests/test_info_dict.py"
  "task_04|3484|1|tests/test_defaults.py tests/test_options.py"
  "task_05|0|0|MANUAL"
)
