When a user passes a value to a `click.Choice` option that isn't one of the
allowed choices, Click rejects it and lists the valid options. But if the value
is an obvious near miss — a small typo of a real choice — Click gives no hint
about what the user probably meant.

For example, a command whose `--color` option only accepts `red`, `green`, `blue`:

    $ mycli --color grene
    Error: Invalid value for '--color': 'grene' is not one of 'red', 'green', 'blue'.

The user clearly meant `green`, but nothing points them there. Many modern
command-line tools add a short "Did you mean ...?" hint when the input is close
to a valid value. Click should do the same for `Choice`.

Improve the invalid-choice error for `click.Choice` so that, when the rejected
value is a close match to one of the valid choices, the error also suggests the
nearest choice (e.g. `Did you mean 'green'?`).

- Only suggest when the value is genuinely close to a real choice; if nothing is
  close, don't invent a suggestion.
- Preserve existing behaviour: the error still reports the bad value and still
  lists the valid choices, and valid input keeps working unchanged.
- Keep the change scoped to the choice-handling code.
