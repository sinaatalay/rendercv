"""
The `rendercv.cli.commands` module contains all the command-line interface (CLI)
commands of RenderCV.
"""

import os
import pathlib
from typing import Annotated, Literal, Optional

import typer
from rich import print

from .. import __version__, data, renderer
from . import printer, utilities

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
@printer.handle_and_print_raised_exceptions
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
    # This is a dummy argument for the help message for
    # extra_data_model_override_argumets:
    _: Annotated[
        Optional[str],
        typer.Option(
            "--YAMLLOCATION",
            help="Overrides the value of YAMLLOCATION. For example,"
            ' [cyan bold]--cv.phone "123-456-7890"[/cyan bold].',
        ),
    ] = None,
    extra_data_model_override_argumets: typer.Context = None,  # type: ignore
):
    """Render a CV from a YAML input file."""
    printer.welcome()

    # Get paths:
    input_file_path: pathlib.Path = utilities.string_to_file_path(
        input_file_name
    )  # type: ignore
    output_directory = pathlib.Path.cwd() / output_folder_name

    paths: dict[
        Literal["latex", "pdf", "markdown", "html", "png"], Optional[pathlib.Path]
    ] = {
        "latex": utilities.string_to_file_path(latex_path),
        "pdf": utilities.string_to_file_path(pdf_path),
        "markdown": utilities.string_to_file_path(markdown_path),
        "html": utilities.string_to_file_path(html_path),
        "png": utilities.string_to_file_path(png_path),
    }

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
        # if the Markdown file is not generated, then the HTML file is not generated
        number_of_steps = number_of_steps - 2
    else:
        if dont_generate_html:
            number_of_steps = number_of_steps - 1

    with printer.LiveProgressReporter(number_of_steps) as progress:
        progress.start_a_step("Reading and validating the input file")
        data_model = data.read_input_file(input_file_path)

        # update the data model if there are extra arguments:
        if extra_data_model_override_argumets:
            key_and_values = dict()
            key_and_values = utilities.parse_render_command_override_arguments(
                extra_data_model_override_argumets
            )
            data_model = utilities.set_or_update_values(data_model, key_and_values)

        progress.finish_the_current_step()

        progress.start_a_step("Generating the LaTeX file")
        latex_file_path_in_output_folder = (
            renderer.render_a_latex_file_and_copy_theme_files(
                data_model, output_directory
            )
        )
        if paths["latex"]:
            utilities.copy_files(latex_file_path_in_output_folder, paths["latex"])
        progress.finish_the_current_step()

        progress.start_a_step("Rendering the LaTeX file to a PDF")
        pdf_file_path_in_output_folder = renderer.render_a_pdf_from_latex(
            latex_file_path_in_output_folder, use_local_latex_command
        )
        if paths["pdf"]:
            utilities.copy_files(pdf_file_path_in_output_folder, paths["pdf"])
        progress.finish_the_current_step()

        if not dont_generate_png:
            progress.start_a_step("Rendering PNG files from the PDF")
            png_file_paths_in_output_folder = renderer.render_pngs_from_pdf(
                pdf_file_path_in_output_folder
            )
            if paths["png"]:
                utilities.copy_files(png_file_paths_in_output_folder, paths["png"])
            progress.finish_the_current_step()

        if not dont_generate_markdown:
            progress.start_a_step("Generating the Markdown file")
            markdown_file_path_in_output_folder = renderer.render_a_markdown_file(
                data_model, output_directory
            )
            if paths["markdown"]:
                utilities.copy_files(
                    markdown_file_path_in_output_folder, paths["markdown"]
                )
            progress.finish_the_current_step()

            if not dont_generate_html:
                progress.start_a_step(
                    "Rendering the Markdown file to a HTML (for Grammarly)"
                )
                html_file_path_in_output_folder = renderer.render_an_html_from_markdown(
                    markdown_file_path_in_output_folder
                )
                if paths["html"]:
                    utilities.copy_files(html_file_path_in_output_folder, paths["html"])
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
                f" {', '.join(data.available_themes)}."
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
        printer.warning(
            f'The input file "{input_file_name}" already exists! A new input file is'
            " not created."
        )
    else:
        try:
            data.create_a_sample_yaml_input_file(
                input_file_path, name=full_name, theme=theme
            )
            created_files_and_folders.append(input_file_path.name)
        except ValueError as e:
            # if the theme is not in the available themes, then raise an error
            printer.error(exception=e)

    if not dont_create_theme_source_files:
        # copy the package's theme files to the current directory
        theme_folder = utilities.copy_templates(theme, pathlib.Path.cwd())
        if theme_folder is not None:
            created_files_and_folders.append(theme_folder.name)
        else:
            printer.warning(
                f'The theme folder "{theme}" already exists! The theme files are not'
                " created."
            )

    if not dont_create_markdown_source_files:
        # copy the package's markdown files to the current directory
        markdown_folder = utilities.copy_templates("markdown", pathlib.Path.cwd())
        if markdown_folder is not None:
            created_files_and_folders.append(markdown_folder.name)
        else:
            printer.warning(
                'The "markdown" folder already exists! The Markdown files are not'
                " created."
            )

    if len(created_files_and_folders) > 0:
        created_files_and_folders_string = ",\n".join(created_files_and_folders)
        printer.information(
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
                f" themes are: {', '.join(data.available_themes)}."
            )
        ),
    ] = "classic",
):
    """Create a custom theme based on an existing theme."""
    if based_on not in data.available_themes:
        printer.error(
            f'The theme "{based_on}" is not in the list of available themes:'
            f' {", ".join(data.available_themes)}'
        )

    theme_folder = utilities.copy_templates(
        based_on, pathlib.Path.cwd(), new_folder_name=theme_name
    )

    if theme_folder is None:
        printer.warning(
            f'The theme folder "{theme_name}" already exists! The theme files are not'
            " created."
        )
        return

    based_on_theme_directory = (
        pathlib.Path(__file__).parent.parent / "themes" / based_on
    )
    based_on_theme_init_file = based_on_theme_directory / "__init__.py"
    based_on_theme_init_file_contents = based_on_theme_init_file.read_text()

    # generate the new init file:
    class_name = f"{theme_name.capitalize()}ThemeOptions"
    literal_name = f'Literal["{theme_name}"]'
    new_init_file_contents = based_on_theme_init_file_contents.replace(
        f'Literal["{based_on}"]', literal_name
    ).replace(f"{based_on.capitalize()}ThemeOptions", class_name)

    # create the new __init__.py file:
    (theme_folder / "__init__.py").write_text(new_init_file_contents)

    printer.information(f'The theme folder "{theme_folder.name}" has been created.')


@app.callback()
def cli_command_no_args(
    version_requested: Annotated[
        Optional[bool], typer.Option("--version", "-v", help="Show the version.")
    ] = None,
):
    """If the `--version` option is used, then show the version. Otherwise, show the
    help message (see `no_args_is_help` argument of `typer.Typer` object)."""
    if version_requested:
        there_is_a_new_version = printer.warn_if_new_version_is_available()
        if not there_is_a_new_version:
            print(f"RenderCV v{__version__}")
