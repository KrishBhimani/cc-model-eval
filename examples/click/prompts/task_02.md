`click.Argument` currently has no way to attach help text, unlike `click.Option`
which accepts a `help=` parameter. Add support for a `help` parameter on
arguments so it can be supplied when defining an argument and is surfaced in the
command's help output.

Run the suite with: python -m pytest tests/test_arguments.py tests/test_info_dict.py
Done when: arguments accept a `help=` value, it appears in --help output, and
the suite passes.
