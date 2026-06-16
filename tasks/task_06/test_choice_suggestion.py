"""Gate for task_06 — Choice 'did you mean' suggestion on a near-miss typo."""
import click
from click.testing import CliRunner


def _cli():
    @click.command()
    @click.option("--color", type=click.Choice(["red", "green", "blue"]))
    def cli(color):
        click.echo(color)

    return cli


def test_suggests_closest_choice_on_typo():
    result = CliRunner().invoke(_cli(), ["--color", "grene"])
    assert result.exit_code == 2
    out = result.output.lower()
    assert "did you mean" in out
    assert "green" in out


def test_no_suggestion_when_nothing_is_close():
    result = CliRunner().invoke(_cli(), ["--color", "zzzzzz"])
    assert result.exit_code == 2
    assert "did you mean" not in result.output.lower()


def test_still_lists_valid_choices():
    result = CliRunner().invoke(_cli(), ["--color", "grene"])
    assert "green" in result.output
    assert "red" in result.output


def test_exact_choice_still_works():
    result = CliRunner().invoke(_cli(), ["--color", "red"])
    assert result.exit_code == 0
    assert result.output.strip() == "red"
