import os
import shutil
import subprocess
import sys
from datetime import date as Date

import pydantic
import pytest
import ruamel.yaml
import typer.testing

import rendercv.cli as cli
import rendercv.data_models as dm
from rendercv import __version__


def run_render_command(input_file_path, working_path, extra_arguments=[]):
    # copy input file to the temporary directory to create the output directory there:
    if not input_file_path == working_path / input_file_path.name:
        shutil.copy(input_file_path, working_path)

    # change the current working directory to the temporary directory:
    os.chdir(working_path)

    result = runner.invoke(cli.app, ["render", "John_Doe_CV.yaml"] + extra_arguments)

    return result


def test_welcome():
    cli.welcome()


def test_warning():
    cli.warning("This is a warning message.")


def test_error():
    with pytest.raises(typer.Exit):
        cli.error("This is an error message.")


def test_error_without_text():
    with pytest.raises(typer.Exit):
        cli.error()


def test_error_without_text_with_exception():
    with pytest.raises(typer.Exit):
        cli.error(exception=ValueError("This is an error message."))


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
                "position": Date(2020, 10, 1),
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
            dm.ExperienceEntry,
            {
                "company": "CERN",
                "position": "Researcher",
                "highlights": "This is not a list.",
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
        (
            dm.RenderCVDataModel,
            {
                "cv": {
                    "name": "John Doe",
                },
                "design": {"theme": "UPPERCASE"},
            },
        ),
    ],
)
def test_handle_validation_error(data_model_class, invalid_model):
    try:
        data_model_class(**invalid_model)
    except pydantic.ValidationError as e:
        with pytest.raises(typer.Exit):
            cli.handle_validation_error(e)


@pytest.mark.parametrize(
    "exception",
    [
        ruamel.yaml.YAMLError("message"),
        RuntimeError("message"),
        FileNotFoundError("message"),
        ValueError("message"),
        UnicodeDecodeError("utf-8", b"", 1, 2, "message"),
    ],
)
def test_handle_exceptions(exception):
    @cli.handle_exceptions
    def function_that_raises_exception():
        raise exception

    with pytest.raises(typer.Exit):
        function_that_raises_exception()


def test_live_progress_reporter_class():
    with cli.LiveProgressReporter(number_of_steps=3) as progress:
        progress.start_a_step("Test step 1")
        progress.finish_the_current_step()

        progress.start_a_step("Test step 2")
        progress.finish_the_current_step()

        progress.start_a_step("Test step 3")
        progress.finish_the_current_step()


@pytest.mark.parametrize(
    "folder_name",
    ["markdown"] + dm.available_themes,
)
def test_copy_templates(tmp_path, folder_name):
    copied_path = cli.copy_templates(
        folder_name=folder_name,
        copy_to=tmp_path,
    )
    assert copied_path.exists()


def test_copy_templates_with_new_folder_name(tmp_path):
    copied_path = cli.copy_templates(
        folder_name="markdown",
        copy_to=tmp_path,
        new_folder_name="new_folder",
    )
    assert copied_path.exists()


@pytest.mark.parametrize(
    "folder_name",
    ["markdown"] + dm.available_themes,
)
def test_copy_templates_destinations_exist(tmp_path, folder_name):
    (tmp_path / folder_name).mkdir()

    copied_path = cli.copy_templates(
        folder_name=folder_name,
        copy_to=tmp_path,
    )

    assert copied_path is None


runner = typer.testing.CliRunner()


def test_render_command(tmp_path, input_file_path):
    result = run_render_command(
        input_file_path,
        tmp_path,
    )

    output_folder_path = tmp_path / "rendercv_output"
    pdf_file_path = output_folder_path / "John_Doe_CV.pdf"
    latex_file_path = output_folder_path / "John_Doe_CV.tex"
    markdown_file_path = output_folder_path / "John_Doe_CV.md"
    html_file_path = output_folder_path / "John_Doe_CV.html"
    png_file_path = output_folder_path / "John_Doe_CV_1.png"

    assert output_folder_path.exists()
    assert pdf_file_path.exists()
    assert latex_file_path.exists()
    assert markdown_file_path.exists()
    assert html_file_path.exists()
    assert png_file_path.exists()
    assert "Your CV is rendered!" in result.stdout


def test_render_command_with_relative_input_file_path(tmp_path, input_file_path):
    new_folder = tmp_path / "another_folder"
    new_folder.mkdir()
    new_input_file_path = new_folder / input_file_path.name

    shutil.copy(input_file_path, new_input_file_path)

    os.chdir(tmp_path)
    result = runner.invoke(
        cli.app, ["render", str(new_input_file_path.relative_to(tmp_path))]
    )

    output_folder_path = tmp_path / "rendercv_output"
    pdf_file_path = output_folder_path / "John_Doe_CV.pdf"
    latex_file_path = output_folder_path / "John_Doe_CV.tex"
    markdown_file_path = output_folder_path / "John_Doe_CV.md"
    html_file_path = output_folder_path / "John_Doe_CV.html"
    png_file_path = output_folder_path / "John_Doe_CV_1.png"

    assert output_folder_path.exists()
    assert pdf_file_path.exists()
    assert latex_file_path.exists()
    assert markdown_file_path.exists()
    assert html_file_path.exists()
    assert png_file_path.exists()
    assert "Your CV is rendered!" in result.stdout


def test_render_command_with_different_output_path(input_file_path, tmp_path):
    result = run_render_command(
        input_file_path,
        tmp_path,
        [
            "--output-folder-name",
            "test",
        ],
    )

    output_folder_path = tmp_path / "test"

    assert result.exit_code == 0
    assert output_folder_path.exists()
    assert "Your CV is rendered!" in result.stdout


@pytest.mark.parametrize(
    ("option", "file_name"),
    [
        ("--pdf-path", "test.pdf"),
        ("--latex-path", "test.tex"),
        ("--markdown-path", "test.md"),
        ("--html-path", "test.html"),
        ("--png-path", "test.png"),
    ],
)
def test_render_command_with_different_output_path_for_each_file(
    option, file_name, tmp_path, input_file_path
):
    run_render_command(
        input_file_path,
        tmp_path,
        [
            option,
            file_name,
        ],
    )

    file_path = tmp_path / file_name

    assert file_path.exists()


def test_render_command_with_custom_png_path_multiple_pages(tmp_path):
    # create a new input file (for a CV with multiple pages) in the temporary directory:
    os.chdir(tmp_path)
    runner.invoke(cli.app, ["new", "John Doe"])
    input_file_path = tmp_path / "John_Doe_CV.yaml"

    run_render_command(
        input_file_path,
        tmp_path,
        [
            "--png-path",
            "test.png",
        ],
    )

    png_page1_file_path = tmp_path / "test_1.png"
    png_page2_file_path = tmp_path / "test_2.png"

    assert png_page1_file_path.exists()
    assert png_page2_file_path.exists()


@pytest.mark.parametrize(
    ("option", "file_name"),
    [
        ("--dont-generate-markdown", "John_Doe_CV.md"),
        ("--dont-generate-html", "John_Doe_CV.html"),
        ("--dont-generate-png", "John_Doe_CV_1.png"),
    ],
)
def test_render_command_with_dont_generate_files(
    tmp_path, input_file_path, option, file_name
):
    run_render_command(
        input_file_path,
        tmp_path,
        [
            option,
        ],
    )

    file_path = tmp_path / "rendercv_output" / file_name

    assert not file_path.exists()


def test_render_command_with_local_latex_command(tmp_path, input_file_path):
    run_render_command(
        input_file_path,
        tmp_path,
        [
            "--use-local-latex-command",
            "pdflatex",
        ],
    )


@pytest.mark.parametrize(
    "invalid_arguments",
    [
        ["--keywithoutvalue"],
        ["--key", "value", "--keywithoutvalue"],
        ["keywithoutdashes", "value"],
        ["--cv.phone", "invalidphonenumber"],
        ["--cv.sections.arbitrary.10", "value"],
    ],
)
def test_render_command_with_invalid_arguments(
    tmp_path, input_file_path, invalid_arguments
):
    result = run_render_command(
        input_file_path,
        tmp_path,
        invalid_arguments,
    )

    assert (
        "There is a problem with the extra arguments!" in result.stdout
        or "should start with double dashes!" in result.stdout
        or "does not exist in the data model!" in result.stdout
        or "There are some errors in the data model!" in result.stdout
    )


def test_new_command(tmp_path):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)
    result = runner.invoke(cli.app, ["new", "Jahn Doe"])

    markdown_source_files_path = tmp_path / "markdown"
    theme_source_files_path = tmp_path / "classic"
    input_file_path = tmp_path / "Jahn_Doe_CV.yaml"

    assert "Jahn_Doe_CV.yaml" in result.stdout
    assert "markdown" in result.stdout
    assert "classic" in result.stdout

    assert markdown_source_files_path.exists()
    assert theme_source_files_path.exists()
    assert input_file_path.exists()


def test_new_command_with_invalid_theme(tmp_path):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)

    result = runner.invoke(cli.app, ["new", "Jahn Doe", "--theme", "invalid_theme"])

    assert "The theme should be one of the following" in result.stdout


@pytest.mark.parametrize(
    ("option", "folder_name"),
    [
        ("--dont-create-theme-source-files", "classic"),
        ("--dont-create-markdown-source-files", "markdown"),
    ],
)
def test_new_command_with_dont_create_files(tmp_path, option, folder_name):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)
    result = runner.invoke(cli.app, ["new", "Jahn Doe", option])

    source_files_path = tmp_path / folder_name

    assert folder_name not in result.stdout

    assert not source_files_path.exists()


def test_new_command_with_only_input_file(tmp_path):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)
    runner.invoke(
        cli.app,
        [
            "new",
            "Jahn Doe",
            "--dont-create-markdown-source-files",
            "--dont-create-theme-source-files",
        ],
    )

    markdown_source_files_path = tmp_path / "markdown"
    theme_source_files_path = tmp_path / "classic"
    input_file_path = tmp_path / "Jahn_Doe_CV.yaml"

    assert not markdown_source_files_path.exists()
    assert not theme_source_files_path.exists()
    assert input_file_path.exists()


@pytest.mark.parametrize(
    "file_or_folder_name",
    [
        "Jahn_Doe_CV.yaml",
        "markdown",
        "classic",
    ],
)
def test_new_command_with_existing_files(tmp_path, file_or_folder_name):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)

    if file_or_folder_name == "Jahn_Doe_CV.yaml":
        (tmp_path / file_or_folder_name).touch()
    else:
        (tmp_path / file_or_folder_name).mkdir()

    result = runner.invoke(cli.app, ["new", "Jahn Doe"])

    assert "already exists!" in result.stdout


@pytest.mark.parametrize(
    "based_on",
    dm.available_themes,
)
def test_create_theme_command(tmp_path, input_file_path, based_on):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)

    runner.invoke(cli.app, ["create-theme", "newtheme", "--based-on", based_on])

    new_theme_source_files_path = tmp_path / "newtheme"

    assert new_theme_source_files_path.exists()

    # test if the new theme is actually working:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    result = runner.invoke(
        cli.app, ["render", str(input_file_path), "--design", "{'theme':'newtheme'}"]
    )

    output_folder_path = tmp_path / "rendercv_output"
    pdf_file_path = output_folder_path / "John_Doe_CV.pdf"
    latex_file_path = output_folder_path / "John_Doe_CV.tex"
    markdown_file_path = output_folder_path / "John_Doe_CV.md"
    html_file_path = output_folder_path / "John_Doe_CV.html"
    png_file_path = output_folder_path / "John_Doe_CV_1.png"

    assert output_folder_path.exists()
    assert pdf_file_path.exists()
    assert latex_file_path.exists()
    assert markdown_file_path.exists()
    assert html_file_path.exists()
    assert png_file_path.exists()
    assert "Your CV is rendered!" in result.stdout


def test_create_theme_command_invalid_based_on_theme(tmp_path):
    result = runner.invoke(
        cli.app, ["create-theme", "newtheme", "--based-on", "invalid_theme"]
    )

    assert "is not in the list of available themes" in result.stdout


def test_create_theme_command_theme_already_exists(tmp_path):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)

    (tmp_path / "newtheme").mkdir()

    result = runner.invoke(cli.app, ["create-theme", "newtheme"])

    assert "already exists!" in result.stdout


def test_main_file():
    subprocess.run([sys.executable, "-m", "rendercv", "--help"], check=True)


def test_get_latest_version_number_from_pypi():
    version = cli.get_latest_version_number_from_pypi()
    assert isinstance(version, str)


def test_if_welcome_prints_new_version_available(monkeypatch):
    monkeypatch.setattr(cli, "get_latest_version_number_from_pypi", lambda: "99999")
    import contextlib
    import io

    with contextlib.redirect_stdout(io.StringIO()) as f:
        cli.welcome()
        output = f.getvalue()

    assert "A new version of RenderCV is available!" in output


def test_rendercv_version_when_there_is_a_new_version(monkeypatch):
    monkeypatch.setattr(cli, "get_latest_version_number_from_pypi", lambda: "99999")

    result = runner.invoke(cli.app, ["--version"])

    assert "A new version of RenderCV is available!" in result.stdout


def test_rendercv_version_when_there_is_not_a_new_version(monkeypatch):
    monkeypatch.setattr(cli, "get_latest_version_number_from_pypi", lambda: __version__)

    result = runner.invoke(cli.app, ["--version"])

    assert __version__ in result.stdout


def test_warn_if_new_version_is_available(monkeypatch):
    monkeypatch.setattr(cli, "get_latest_version_number_from_pypi", lambda: __version__)

    assert not cli.warn_if_new_version_is_available()

    monkeypatch.setattr(cli, "get_latest_version_number_from_pypi", lambda: "999")

    assert cli.warn_if_new_version_is_available()
