"""
`rendercv.cli.commands` module contains all the command-line interface (CLI) commands of
RenderCV.
"""

import os
import pathlib
import shutil
from typing import Annotated, Optional

import pydantic
import typer
from rich import print

from .. import __version__
from .. import data_models as dm
from .. import renderer as r
from .printer import (
    LiveProgressReporter,
    error,
    information,
    warn_if_new_version_is_available,
    warning,
    welcome,
)
from .utilities import (
    copy_templates,
    handle_exceptions,
    parse_render_command_override_arguments,
)

app = typer.Typer(
    rich_markup_mode="rich",
    add_completion=False,
    # to make `rendercv --version` work:
    invoke_without_command=True,
    no_args_is_help=True,
    context_settings={"help_option_names": ["-h", "--help"]},
    # don't show local variables in unhandled exceptions:
    pretty_exceptions_show_locals=False,
)


@app.command(
    name="render",
    help=(
        "Render a YAML input file. Example: [yellow]rendercv render"
        " John_Doe_CV.yaml[/yellow]. Details: [cyan]rendercv render --help[/cyan]"
    ),
    # allow extra arguments for updating the data model:
    context_settings={"allow_extra_args": True, "ignore_unknown_options": True},
)
@handle_exceptions
def cli_command_render(
    input_file_name: Annotated[
        str, typer.Argument(help="Name of the YAML input file.")
    ],
    use_local_latex_command: Annotated[
        Optional[str],
        typer.Option(
            "--use-local-latex-command",
            "-use",
            help=(
                "Use the local LaTeX installation with the given command instead of the"
                " RenderCV's TinyTeX."
            ),
        ),
    ] = None,
    output_folder_name: Annotated[
        str,
        typer.Option(
            "--output-folder-name",
            "-o",
            help="Name of the output folder.",
        ),
    ] = "rendercv_output",
    latex_path: Annotated[
        Optional[str],
        typer.Option(
            "--latex-path",
            "-latex",
            help="Copy the LaTeX file to the given path.",
        ),
    ] = None,
    pdf_path: Annotated[
        Optional[str],
        typer.Option(
            "--pdf-path",
            "-pdf",
            help="Copy the PDF file to the given path.",
        ),
    ] = None,
    markdown_path: Annotated[
        Optional[str],
        typer.Option(
            "--markdown-path",
            "-md",
            help="Copy the Markdown file to the given path.",
        ),
    ] = None,
    html_path: Annotated[
        Optional[str],
        typer.Option(
            "--html-path",
            "-html",
            help="Copy the HTML file to the given path.",
        ),
    ] = None,
    png_path: Annotated[
        Optional[str],
        typer.Option(
            "--png-path",
            "-png",
            help="Copy the PNG file to the given path.",
        ),
    ] = None,
    dont_generate_markdown: Annotated[
        bool,
        typer.Option(
            "--dont-generate-markdown",
            "-nomd",
            help="Don't generate the Markdown and HTML file.",
        ),
    ] = False,
    dont_generate_html: Annotated[
        bool,
        typer.Option(
            "--dont-generate-html",
            "-nohtml",
            help="Don't generate the HTML file.",
        ),
    ] = False,
    dont_generate_png: Annotated[
        bool,
        typer.Option(
            "--dont-generate-png",
            "-nopng",
            help="Don't generate the PNG file.",
        ),
    ] = False,
    _: Annotated[  # This is a dummy argument for the help message.
        Optional[str],
        typer.Option(
            "--YAMLLOCATION",
            help="Overrides the value of YAMLLOCATION. For example,"
            ' [cyan bold]--cv.phone "123-456-7890"[/cyan bold].',
        ),
    ] = None,
    extra_data_model_override_argumets: typer.Context = None,
):
    """Render a CV from a YAML input file."""
    welcome()

    input_file_path = pathlib.Path(input_file_name).absolute()
    output_directory = pathlib.Path.cwd() / output_folder_name

    # change the current working directory to the input file's directory (because
    # the template overrides are looked up in the current working directory):
    os.chdir(input_file_path.parent)

    # compute the number of steps
    # 1. read and validate the input file
    # 2. generate the LaTeX file
    # 3. render the LaTeX file to a PDF
    # 4. render PNG files from the PDF
    # 5. generate the Markdown file
    # 6. render the Markdown file to a HTML (for Grammarly)
    number_of_steps = 6
    if dont_generate_png:
        number_of_steps = number_of_steps - 1
    if dont_generate_markdown:
        number_of_steps = number_of_steps - 2
    else:
        if dont_generate_html:
            number_of_steps = number_of_steps - 1

    with LiveProgressReporter(number_of_steps) as progress:
        progress.start_a_step("Reading and validating the input file")
        data_model = dm.read_input_file(input_file_path)

        # update the data model if there are extra arguments:
        key_and_values = dict()

        if extra_data_model_override_argumets:
            key_and_values = parse_render_command_override_arguments(
                extra_data_model_override_argumets
            )
            for key, value in key_and_values.items():
                try:
                    # set the key (for example, cv.sections.education.0.institution) to
                    # the value
                    data_model = dm.set_or_update_a_value(data_model, key, value)
                except pydantic.ValidationError as e:
                    raise e
                except (ValueError, KeyError, IndexError, AttributeError):
                    raise ValueError(
                        f'The key "{key}" does not exist in the data model!'
                    )

        progress.finish_the_current_step()

        progress.start_a_step("Generating the LaTeX file")
        latex_file_path_in_output_folder = r.generate_latex_file_and_copy_theme_files(
            data_model, output_directory
        )
        if latex_path:
            shutil.copy2(latex_file_path_in_output_folder, latex_path)
        progress.finish_the_current_step()

        progress.start_a_step("Rendering the LaTeX file to a PDF")
        pdf_file_path_in_output_folder = r.latex_to_pdf(
            latex_file_path_in_output_folder, use_local_latex_command
        )
        if pdf_path:
            shutil.copy2(pdf_file_path_in_output_folder, pdf_path)
        progress.finish_the_current_step()

        if not dont_generate_png:
            progress.start_a_step("Rendering PNG files from the PDF")
            png_file_paths_in_output_folder = r.pdf_to_pngs(
                pdf_file_path_in_output_folder
            )
            if png_path:
                if len(png_file_paths_in_output_folder) == 1:
                    shutil.copy2(png_file_paths_in_output_folder[0], png_path)
                else:
                    for i, png_file_path in enumerate(png_file_paths_in_output_folder):
                        # append the page number to the file name
                        page_number = i + 1
                        png_path_with_page_number = (
                            pathlib.Path(png_path).parent
                            / f"{pathlib.Path(png_path).stem}_{page_number}.png"
                        )
                        shutil.copy2(png_file_path, png_path_with_page_number)
            progress.finish_the_current_step()

        if not dont_generate_markdown:
            progress.start_a_step("Generating the Markdown file")
            markdown_file_path_in_output_folder = r.generate_markdown_file(
                data_model, output_directory
            )
            if markdown_path:
                shutil.copy2(markdown_file_path_in_output_folder, markdown_path)
            progress.finish_the_current_step()

            if not dont_generate_html:
                progress.start_a_step(
                    "Rendering the Markdown file to a HTML (for Grammarly)"
                )
                html_file_path_in_output_folder = r.markdown_to_html(
                    markdown_file_path_in_output_folder
                )
                if html_path:
                    shutil.copy2(html_file_path_in_output_folder, html_path)
                progress.finish_the_current_step()


@app.command(
    name="new",
    help=(
        "Generate a YAML input file to get started. Example: [yellow]rendercv new"
        ' "John Doe"[/yellow]. Details: [cyan]rendercv new --help[/cyan]'
    ),
)
def cli_command_new(
    full_name: Annotated[str, typer.Argument(help="Your full name.")],
    theme: Annotated[
        str,
        typer.Option(
            help=(
                "The name of the theme. Available themes are:"
                f" {', '.join(dm.available_themes)}."
            )
        ),
    ] = "classic",
    dont_create_theme_source_files: Annotated[
        bool,
        typer.Option(
            "--dont-create-theme-source-files",
            "-nolatex",
            help="Don't create theme source files.",
        ),
    ] = False,
    dont_create_markdown_source_files: Annotated[
        bool,
        typer.Option(
            "--dont-create-markdown-source-files",
            "-nomd",
            help="Don't create the Markdown source files.",
        ),
    ] = False,
):
    """Generate a YAML input file and the LaTeX and Markdown source files."""
    created_files_and_folders = []

    input_file_name = f"{full_name.replace(' ', '_')}_CV.yaml"
    input_file_path = pathlib.Path(input_file_name)

    if input_file_path.exists():
        warning(
            f'The input file "{input_file_name}" already exists! A new input file is'
            " not created."
        )
    else:
        try:
            dm.create_a_sample_yaml_input_file(
                input_file_path, name=full_name, theme=theme
            )
            created_files_and_folders.append(input_file_path.name)
        except ValueError as e:
            # if the theme is not in the available themes, then raise an error
            error(e)

    if not dont_create_theme_source_files:
        # copy the package's theme files to the current directory
        theme_folder = copy_templates(theme, pathlib.Path.cwd())
        if theme_folder is not None:
            created_files_and_folders.append(theme_folder.name)

    if not dont_create_markdown_source_files:
        # copy the package's markdown files to the current directory
        markdown_folder = copy_templates("markdown", pathlib.Path.cwd())
        if markdown_folder is not None:
            created_files_and_folders.append(markdown_folder.name)

    if len(created_files_and_folders) > 0:
        created_files_and_folders_string = ",\n".join(created_files_and_folders)
        information(
            "The following RenderCV input file and folders have been"
            f" created:\n{created_files_and_folders_string}"
        )


@app.command(
    name="create-theme",
    help=(
        "Create a custom theme folder based on an existing theme. Example:"
        " [yellow]rendercv create-theme customtheme[/yellow]. Details: [cyan]rendercv"
        " create-theme --help[/cyan]"
    ),
)
def cli_command_create_theme(
    theme_name: Annotated[
        str,
        typer.Argument(help="The name of the new theme."),
    ],
    based_on: Annotated[
        str,
        typer.Option(
            help=(
                "The name of the existing theme to base the new theme on. Available"
                f" themes are: {', '.join(dm.available_themes)}."
            )
        ),
    ] = "classic",
):
    """Create a custom theme based on an existing theme."""
    if based_on not in dm.available_themes:
        error(
            f'The theme "{based_on}" is not in the list of available themes:'
            f' {", ".join(dm.available_themes)}'
        )

    theme_folder = copy_templates(
        based_on, pathlib.Path.cwd(), new_folder_name=theme_name, suppress_warning=True
    )

    if theme_folder is None:
        warning(
            f'The theme folder "{theme_name}" already exists! The theme files are not'
            " created."
        )
        return

    based_on_theme_directory = pathlib.Path(__file__).parent / "themes" / based_on
    based_on_theme_init_file = based_on_theme_directory / "__init__.py"
    based_on_theme_init_file_contents = based_on_theme_init_file.read_text()

    # generate the new init file:
    class_name = f"{theme_name.capitalize()}ThemeOptions"
    literal_name = f'Literal["{theme_name}"]'
    new_init_file_contents = (
        based_on_theme_init_file_contents.replace(
            f'Literal["{based_on}"]', literal_name
        )
        .replace(f"{based_on.capitalize()}ThemeOptions", class_name)
        .replace("..", "rendercv.themes")
    )

    # create the new __init__.py file:
    (theme_folder / "__init__.py").write_text(new_init_file_contents)

    information(f'The theme folder "{theme_folder.name}" has been created.')


@app.callback()
def main(
    version_requested: Annotated[
        Optional[bool], typer.Option("--version", "-v", help="Show the version.")
    ] = None,
):
    """If the `--version` option is used, then show the version. Otherwise, show the
    help message (see `no_args_is_help` argument of `typer.Typer` object)."""
    if version_requested:
        there_is_a_new_version = warn_if_new_version_is_available()
        if not there_is_a_new_version:
            print(f"RenderCV v{__version__}")
