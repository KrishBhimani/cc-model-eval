Running the test suite produces the failures below. Diagnose the root cause and
fix it.

3 failed, 680 passed:

FAILED tests/test_defaults.py::test_parameter_source_during_paramtype_convert
  In a ParamType.convert(), ctx.get_parameter_source(param.name) returns None
  for an option that took its default value:
    assert "'source': None}" not in ...   ->  output was {'value': '/tmp/file', 'source': None}

FAILED tests/test_defaults.py::test_parameter_source_during_eager_callback
  In an eager callback, get_parameter_source(param.name) is None instead of DEFAULT:
    assert 'callback source=DEFAULT' in 'callback source=None\nfinal source=DEFAULT\n'

FAILED tests/test_defaults.py::test_flask_debug_env_not_stomped_by_default_flag
  An eager callback that checks the parameter source to skip default values runs
  anyway, because the source is not yet set during the callback:
    assert result.output.strip() == "APP_DEBUG=1"   ->  got "APP_DEBUG=0"

The common thread: get_parameter_source() is not available (returns None) during
ParamType.convert and during eager callbacks, when it should already reflect that
the value came from the DEFAULT source.

Run the suite with: python -m pytest tests/test_defaults.py tests/test_options.py
Done when: the suite is green.
