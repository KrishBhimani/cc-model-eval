There's a bug in how `click.echo` handles empty byte strings. When an empty
bytes value is written to a binary stream, it raises a TypeError instead of
writing the trailing newline. A test covering the correct behavior is failing.

Run the test with: python -m pytest tests/test_utils.py::test_echo_custom_file
Done when: that test passes and the full test suite still passes.
