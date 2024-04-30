import os
import shutil

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
    with pytest.raises(typer.Exit):
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
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    result = runner.invoke(cli.app, ["render", str(input_file_path)])

    output_folder_path = tmp_path / "rendercv_output"
    pdf_file_path = output_folder_path / "John_Doe_CV.pdf"
    latex_file_path = output_folder_path / "John_Doe_CV.tex"
    markdown_file_path = output_folder_path / "John_Doe_CV.md"
    html_file_path = output_folder_path / "John_Doe_CV_PASTETOGRAMMARLY.html"
    png_file_path = output_folder_path / "John_Doe_CV_1.png"

    assert output_folder_path.exists()
    assert pdf_file_path.exists()
    assert latex_file_path.exists()
    assert markdown_file_path.exists()
    assert html_file_path.exists()
    assert png_file_path.exists()
    assert "Your CV is rendered!" in result.stdout


def test_render_command_with_different_output_path(tmp_path, input_file_path):
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    output_folder_path = tmp_path / "test"

    result = runner.invoke(
        cli.app,
        [
            "render",
            str(input_file_path),
            "--output-folder-name",
            "test",
        ],
    )

    assert result.exit_code == 0
    assert output_folder_path.exists()
    assert "Your CV is rendered!" in result.stdout


def test_render_command_with_custom_latex_path(tmp_path, input_file_path):
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    latex_file_path = tmp_path / "test.tex"

    runner.invoke(
        cli.app,
        [
            "render",
            str(input_file_path),
            "--latex-path",
            str(latex_file_path),
        ],
    )

    assert latex_file_path.exists()


def test_render_command_with_custom_pdf_path(tmp_path, input_file_path):
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    pdf_file_path = tmp_path / "test.pdf"

    runner.invoke(
        cli.app,
        [
            "render",
            str(input_file_path),
            "--pdf-path",
            str(pdf_file_path),
        ],
    )

    assert pdf_file_path.exists()


def test_render_command_with_custom_markdown_path(tmp_path, input_file_path):
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    markdown_file_path = tmp_path / "test.md"

    runner.invoke(
        cli.app,
        [
            "render",
            str(input_file_path),
            "--markdown-path",
            str(markdown_file_path),
        ],
    )

    assert markdown_file_path.exists()


def test_render_command_with_custom_html_path(tmp_path, input_file_path):
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    html_file_path = tmp_path / "test.html"

    runner.invoke(
        cli.app,
        [
            "render",
            str(input_file_path),
            "--html-path",
            str(html_file_path),
        ],
    )

    assert html_file_path.exists()


def test_render_command_with_custom_png_path(tmp_path, input_file_path):
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    png_file_path = tmp_path / "test.png"

    runner.invoke(
        cli.app,
        [
            "render",
            str(input_file_path),
            "--png-path",
            str(png_file_path),
        ],
    )

    assert png_file_path.exists()


def test_render_command_with_custom_png_path_multiple_pages(tmp_path):
    # create a new input file (for a CV with multiple pages) in the temporary directory:
    os.chdir(tmp_path)
    runner.invoke(cli.app, ["new", "John Doe"])
    input_file_path = tmp_path / "John_Doe_CV.yaml"

    png_file_path = tmp_path / "test.png"
    runner.invoke(
        cli.app,
        [
            "render",
            str(input_file_path),
            "--png-path",
            str(png_file_path),
        ],
    )

    png_page1_file_path = tmp_path / "test_1.png"
    png_page2_file_path = tmp_path / "test_2.png"

    assert png_page1_file_path.exists()
    assert png_page2_file_path.exists()


def test_render_command_with_dont_generate_markdown(tmp_path, input_file_path):
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    markdown_file_path = tmp_path / "rendercv_output" / "John_Doe_CV.md"

    runner.invoke(
        cli.app,
        [
            "render",
            str(input_file_path),
            "--dont-generate-markdown",
        ],
    )

    assert not markdown_file_path.exists()


def test_render_command_with_dont_generate_html(tmp_path, input_file_path):
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    html_file_path = tmp_path / "rendercv_output" / "John_Doe_CV_PASTETOGRAMMARLY.html"

    runner.invoke(
        cli.app,
        [
            "render",
            str(input_file_path),
            "--dont-generate-html",
        ],
    )

    assert not html_file_path.exists()


def test_render_command_with_dont_generate_png(tmp_path, input_file_path):
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    png_file_path = tmp_path / "rendercv_output" / "John_Doe_CV_1.png"

    runner.invoke(
        cli.app,
        [
            "render",
            str(input_file_path),
            "--dont-generate-png",
        ],
    )

    assert not png_file_path.exists()


def test_render_command_with_local_latex_command(tmp_path, input_file_path):
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    runner.invoke(
        cli.app,
        ["render", str(input_file_path), "--use-local-latex-command", "pdflatex"],
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
    # copy input file to the temporary directory to create the output directory there:
    input_file_path = shutil.copy(input_file_path, tmp_path)

    result = runner.invoke(
        cli.app,
        ["render", str(input_file_path)] + invalid_arguments,
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
    runner.invoke(cli.app, ["new", "John Doe"])

    markdown_source_files_path = tmp_path / "markdown"
    theme_source_files_path = tmp_path / "classic"
    input_file_path = tmp_path / "John_Doe_CV.yaml"

    assert markdown_source_files_path.exists()
    assert theme_source_files_path.exists()
    assert input_file_path.exists()


def test_new_command_with_invalid_theme(tmp_path):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)

    result = runner.invoke(cli.app, ["new", "John Doe", "--theme", "invalid_theme"])

    assert "The theme should be one of the following" in result.stdout


def test_new_command_with_dont_create_theme_source_files(tmp_path):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)
    runner.invoke(cli.app, ["new", "John Doe", "--dont-create-theme-source-files"])

    theme_source_files_path = tmp_path / "classic"

    assert not theme_source_files_path.exists()


def test_new_command_with_dont_create_markdown_source_files(tmp_path):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)
    runner.invoke(cli.app, ["new", "John Doe", "--dont-create-markdown-source-files"])

    markdown_source_files_path = tmp_path / "markdown"

    assert not markdown_source_files_path.exists()


def test_new_command_with_only_input_file(tmp_path):
    # change the current working directory to the temporary directory:
    os.chdir(tmp_path)
    runner.invoke(
        cli.app,
        [
            "new",
            "John Doe",
            "--dont-create-markdown-source-files",
            "--dont-create-theme-source-files",
        ],
    )

    markdown_source_files_path = tmp_path / "markdown"
    theme_source_files_path = tmp_path / "classic"
    input_file_path = tmp_path / "John_Doe_CV.yaml"

    assert not markdown_source_files_path.exists()
    assert not theme_source_files_path.exists()
    assert input_file_path.exists()


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
    html_file_path = output_folder_path / "John_Doe_CV_PASTETOGRAMMARLY.html"
    png_file_path = output_folder_path / "John_Doe_CV_1.png"

    assert output_folder_path.exists()
    assert pdf_file_path.exists()
    assert latex_file_path.exists()
    assert markdown_file_path.exists()
    assert html_file_path.exists()
    assert png_file_path.exists()
    assert "Your CV is rendered!" in result.stdout
