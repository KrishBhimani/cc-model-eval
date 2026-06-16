#!/usr/bin/env bash
# =============================================================================
#  config.sh — THE ONLY FILE YOU EDIT.
#
#  Everything you change to point this at a different repo/stack is in the
#  "EDIT THIS" block below. The "DON'T TOUCH" block at the bottom is internal
#  plumbing — leave it alone.
#
#  Three things define an experiment:
#    1. the repo under test          (REPO_URL + how to install/test it)
#    2. the two models to compare    (MODEL_A / MODEL_B)
#    3. the tasks                    (folders under tasks/ — not set here)
#
#  Quick-start presets for common stacks are at the bottom of the EDIT block.
# =============================================================================


# #############################################################################
#  EDIT THIS  ▼▼▼
# #############################################################################

# ---- 1. THE REPO UNDER TEST --------------------------------------------------

# Git URL of the repo you want to test the models against.
REPO_URL="https://github.com/pallets/click"

# How to install that repo into the throwaway venv.
#   Use an EDITABLE install ("-e ...") so the model's source edits are what the
#   gate actually runs against. Examples:
#     "-e ."                 most Python packages
#     "-e .[test]"           package with a "test" extras group
#     "-e .[dev]"            package with a "dev" extras group
#     "-r requirements.txt"  repos that use a requirements file
PIP_INSTALL="-e ."

# Extra packages to install (the test runner, plugins, etc.).
# Space-separated, or "" for none.
EXTRA_PIP="pytest"

# Where this repo keeps its tests, relative to the repo root. Your task's
# test_*.py files are copied here. Common values: "tests", "test", "src/tests",
# or "." (repo root). Open the target repo and check where its tests live.
TESTS_SUBDIR="tests"

# OPTIONAL: a module name to import-check right after install, so a broken
# install fails immediately with a clear message instead of as confusing gate
# errors later. Usually the package's import name. Leave "" to skip.
VERIFY_IMPORT=""


# ---- 2. THE MODELS TO COMPARE ------------------------------------------------

# The two models. Must be valid model strings for your Claude Code auth.
# (Can also be overridden at run time: MODEL_A=... MODEL_B=... bash run.sh)
MODEL_A="${MODEL_A:-claude-opus-4-8}"
MODEL_B="${MODEL_B:-claude-sonnet-4-6}"


# ---- 3. HOW THE RUN BEHAVES --------------------------------------------------

REPS=5                                 # runs per (model, task) — stochastic, so >1
MAX_TURNS=60                           # cap per run; hitting it counts as "did not finish"
ALLOWED_TOOLS="Bash,Read,Edit,Write"   # identical for both models


# ---- TASKS -------------------------------------------------------------------
# Tasks are NOT listed here. Each task is a folder under tasks/ containing:
#     prompt.md   - what the model is asked (describe the symptom, never the fix)
#     gate.txt    - one line: pytest target(s), OR the word MANUAL
#     test_*.py   - (gated tasks) test file(s), copied into TESTS_SUBDIR as-is
# To add a task: make a folder under tasks/ with those files. See README.md.


# ---- PRESETS for other stacks (copy values up into section 1) ----------------
# Flask:
#     REPO_URL="https://github.com/pallets/flask"
#     PIP_INSTALL="-e .[dev]"   EXTRA_PIP="pytest"   TESTS_SUBDIR="tests"
# Requests:
#     REPO_URL="https://github.com/psf/requests"
#     PIP_INSTALL="-e .[tests]" EXTRA_PIP="pytest"   TESTS_SUBDIR="tests"
# A repo using a requirements file:
#     PIP_INSTALL="-r requirements-dev.txt"   (still add "-e ." too if it's a package)
# A repo whose tests live at the root:
#     TESTS_SUBDIR="."

# #############################################################################
#  EDIT THIS  ▲▲▲   (you shouldn't need to change anything below)
# #############################################################################


# ---- DON'T TOUCH: internal plumbing -----------------------------------------
EVAL_HOME="${EVAL_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
REPO_DIR="$EVAL_HOME/.repo"
VENV_DIR="$EVAL_HOME/.venv"
TASKS_DIR="$EVAL_HOME/tasks"
RUNS_DIR="$EVAL_HOME/runs"
MODELS=("$MODEL_A" "$MODEL_B")