import os
import importlib.machinery

import rendercv.cli as cli
import rendercv.data_models as dm

import pydantic
import ruamel.yaml
import pytest
import typer.testing


def test_welcome():
    cli.welcome()


def test_warning():
    cli.warning("This is a warning message.")


def test_error():
    cli.error("This is an error message.")


def test_information():
    cli.information("This is an information message.")


def test_get_error_message_and_location_and_value_from_a_custom_error():
    error_string = "('error message', 'location', 'value')"
    result = cli.get_error_message_and_location_and_value_from_a_custom_error(
        error_string
    )
    assert result == ("error message", "location", "value")

    error_string = """("er'ror message", 'location', 'value')"""
    result = cli.get_error_message_and_location_and_value_from_a_custom_error(
        error_string
    )
    assert result == ("er'ror message", "location", "value")

    error_string = "error message"
    result = cli.get_error_message_and_location_and_value_from_a_custom_error(
        error_string
    )
    assert result == (None, None, None)


@pytest.mark.parametrize(
    "data_model_class, invalid_model",
    [
        (
            dm.EducationEntry,
            {
                "institution": "Boğaziçi University",
                "area": "Mechanical Engineering",
                "degree": "BS",
                "date": "2028-12-08",
            },
        ),
        (
            dm.EducationEntry,
            {
                "area": "Mechanical Engineering",
                "extra": "Extra",
            },
        ),
        (
            dm.ExperienceEntry,
            {
                "company": "CERN",
            },
        ),
        (
            dm.ExperienceEntry,
            {
                "position": "Researcher",
            },
        ),
        (
            dm.ExperienceEntry,
            {
                "company": "CERN",
                "position": "Researcher",
                "stat_date": "2023-12-08",
                "end_date": "INVALID END DATE",
            },
        ),
        (
            dm.PublicationEntry,
            {
                "doi": "10.1109/TASC.2023.3340648",
            },
        ),
        (
            dm.ExperienceEntry,
            {
                "authors": ["John Doe", "Jane Doe"],
            },
        ),
        (
            dm.OneLineEntry,
            {
                "name": "My One Line Entry",
            },
        ),
        (
            dm.NormalEntry,
            {
                "name": "My Entry",
            },
        ),
        (
            dm.CurriculumVitae,
            {
                "name": "John Doe",
                "sections": {
                    "education": [
                        {
                            "institution": "Boğaziçi University",
                            "area": "Mechanical Engineering",
                            "degree": "BS",
                            "date": "2028-12-08",
                        },
                        {
                            "degree": "BS",
                        },
                    ]
                },
            },
        ),
    ],
)
def test_handle_validation_error(data_model_class, invalid_model):
    try:
        data_model_class(**invalid_model)
    except pydantic.ValidationError as e:
        cli.handle_validation_error(e)


@pytest.mark.parametrize(
    "exception",
    [ruamel.yaml.YAMLError, RuntimeError],
)
def test_handle_exceptions(exception):
    @cli.handle_exceptions
    def function_that_raises_exception():
        raise exception("This is an exception!")

    function_that_raises_exception()


def test_live_progress_reporter_class():
    with cli.LiveProgressReporter(number_of_steps=3) as progress:
        progress.start_a_step("Test step 1")
        progress.finish_the_current_step()

        progress.start_a_step("Test step 2")
        progress.finish_the_current_step()

        progress.start_a_step("Test step 3")
        progress.finish_the_current_step()


runner = typer.testing.CliRunner()


def test_render_command(input_file_path):
    str_input_file_path = str(input_file_path)
    result = runner.invoke(cli.app, ["render", str_input_file_path])
    assert result.exit_code == 0
    assert "Your CV is rendered!" in result.stdout


def test_new_command(tmp_path):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)
    result = runner.invoke(cli.app, ["new", "John Doe"])
    assert result.exit_code == 0
    assert "Your RenderCV input file has been created" in result.stdout
