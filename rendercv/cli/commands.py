"""
The `rendercv.cli.commands` module contains all the command-line interface (CLI)
commands of RenderCV.
"""

import os
import pathlib
from typing import Annotated, Optional

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
    # allow extra arguments for updating the data model (for overriding the values of
    # the input file):
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

    input_file_path: pathlib.Path = pathlib.Path(input_file_name).absolute()
    original_working_directory = pathlib.Path.cwd()

    input_file_as_a_dict = data.read_a_yaml_file(input_file_path)

    # Update the input file if there are extra override arguments (for example,
    # --cv.phone "123-456-7890"):
    if extra_data_model_override_argumets:
        key_and_values = utilities.parse_render_command_override_arguments(
            extra_data_model_override_argumets
        )
        input_file_as_a_dict = utilities.set_or_update_values(
            input_file_as_a_dict, key_and_values
        )

    # If non-default CLI arguments are provided, override the `rendercv_settings.render_command`:
    cli_render_arguments = {
        "use_local_latex_command": use_local_latex_command,
        "output_folder_name": output_folder_name,
        "latex_path": latex_path,
        "pdf_path": pdf_path,
        "markdown_path": markdown_path,
        "html_path": html_path,
        "png_path": png_path,
        "dont_generate_png": dont_generate_png,
        "dont_generate_markdown": dont_generate_markdown,
        "dont_generate_html": dont_generate_html,
    }
    input_file_as_a_dict = utilities.update_render_command_settings_of_the_input_file(
        input_file_as_a_dict, cli_render_arguments
    )
    render_command_settings_dict = input_file_as_a_dict["rendercv_settings"][
        "render_command"
    ]

    # Compute the number of steps
    # 1. Validate the input file.
    # 2. Create the LaTeX file.
    # 3. Render PDF from LaTeX.
    # 4. Render PNGs from PDF.
    # 5. Create the Markdown file.
    # 6. Render HTML from Markdown.
    number_of_steps = 6
    if render_command_settings_dict["dont_generate_png"]:
        number_of_steps -= 1

    if render_command_settings_dict["dont_generate_markdown"]:
        number_of_steps -= 2
    else:
        if render_command_settings_dict["dont_generate_html"]:
            number_of_steps -= 1

    with printer.LiveProgressReporter(number_of_steps=number_of_steps) as progress:
        progress.start_a_step("Validating the input file")

        data_model = data.validate_input_dictionary_and_return_the_data_model(
            input_file_as_a_dict, input_file_path=input_file_path
        )

        render_command_settings: data.models.RenderCommandSettings = (
            data_model.rendercv_settings.render_command  # type: ignore
        )  # type: ignore
        output_directory = (
            original_working_directory / render_command_settings.output_folder_name  # type: ignore
        )

        progress.finish_the_current_step()

        # Change the current working directory to the input file's directory (because
        # the template overrides are looked up in the current working directory). The
        # output files will be in the original working directory.
        os.chdir(input_file_path.parent)

        progress.start_a_step("Generating the LaTeX file")

        latex_file_path_in_output_folder = (
            renderer.create_a_latex_file_and_copy_theme_files(
                data_model, output_directory
            )
        )
        if render_command_settings.latex_path:
            utilities.copy_files(
                latex_file_path_in_output_folder,
                render_command_settings.latex_path,
            )

        progress.finish_the_current_step()

        progress.start_a_step("Rendering the LaTeX file to a PDF")

        pdf_file_path_in_output_folder = renderer.render_a_pdf_from_latex(
            latex_file_path_in_output_folder,
            render_command_settings.use_local_latex_command,
        )
        if render_command_settings.pdf_path:
            utilities.copy_files(
                pdf_file_path_in_output_folder,
                render_command_settings.pdf_path,
            )

        progress.finish_the_current_step()

        if not render_command_settings.dont_generate_png:
            progress.start_a_step("Rendering PNG files from the PDF")

            png_file_paths_in_output_folder = renderer.render_pngs_from_pdf(
                pdf_file_path_in_output_folder
            )
            if render_command_settings.png_path:
                utilities.copy_files(
                    png_file_paths_in_output_folder,
                    render_command_settings.png_path,
                )

            progress.finish_the_current_step()

        if not render_command_settings.dont_generate_markdown:
            progress.start_a_step("Generating the Markdown file")

            markdown_file_path_in_output_folder = renderer.create_a_markdown_file(
                data_model, output_directory
            )
            if render_command_settings.markdown_path:
                utilities.copy_files(
                    markdown_file_path_in_output_folder,
                    render_command_settings.markdown_path,
                )

            progress.finish_the_current_step()

            if not render_command_settings.dont_generate_html:
                progress.start_a_step(
                    "Rendering the Markdown file to a HTML (for Grammarly)"
                )

                html_file_path_in_output_folder = renderer.render_an_html_from_markdown(
                    markdown_file_path_in_output_folder
                )
                if render_command_settings.html_path:
                    utilities.copy_files(
                        html_file_path_in_output_folder,
                        render_command_settings.html_path,
                    )

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
    if version_requested:
        there_is_a_new_version = printer.warn_if_new_version_is_available()
        if not there_is_a_new_version:
            print(f"RenderCV v{__version__}")
