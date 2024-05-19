"""
This module contains the functions and classes that handle the command line interface
(CLI) of RenderCV. It uses [Typer](https://typer.tiangolo.com/) to create the CLI and
[Rich](https://rich.readthedocs.io/en/latest/) to provide a nice looking terminal
output.
"""

import json
import pathlib
from typing import Annotated, Callable, Optional
import re
import functools
import shutil
import os

from rich import print
import rich.console
import rich.panel
import rich.live
import rich.table
import rich.text
import rich.progress
import pydantic
import ruamel.yaml
import ruamel.yaml.parser

import typer
import ruamel.yaml


from . import data_models as dm
from . import renderer as r


app = typer.Typer(
    rich_markup_mode="rich",
    add_completion=False,
)


def welcome():
    """Print a welcome message to the terminal."""
    table = rich.table.Table(
        title=(
            "\nWelcome to [bold]Render[dodger_blue3]CV[/dodger_blue3][/bold]! Some"
            " useful links:"
        ),
        title_justify="left",
    )

    table.add_column("Title", style="magenta")
    table.add_column("Link", style="cyan", justify="right", no_wrap=True)

    table.add_row("Documentation", "https://docs.rendercv.com")
    table.add_row("Source code", "https://github.com/sinaatalay/rendercv/")
    table.add_row("Bug reports", "https://github.com/sinaatalay/rendercv/issues/")
    table.add_row("Feature requests", "https://github.com/sinaatalay/rendercv/issues/")
    table.add_row("Discussions", "https://github.com/sinaatalay/rendercv/discussions/")

    print(table)


def warning(text: str):
    """Print a warning message to the terminal.

    Args:
        text (str): The text of the warning message.
    """
    print(f"[bold yellow]{text}")


def error(text: Optional[str] = None, exception: Optional[Exception] = None):
    """Print an error message to the terminal.

    Args:
        text (str): The text of the error message.
        exception (Exception, optional): An exception object. Defaults to None.
    """
    if exception is not None:
        exception_messages = [str(arg) for arg in exception.args]
        exception_message = "\n\n".join(exception_messages)
        print(
            f"\n[bold red]{text}[/bold red]\n\n[orange4]{exception_message}[/orange4]\n"
        )
    else:
        if text:
            print(f"\n[bold red]{text}\n")
        else:
            print()

    raise typer.Exit(code=4)


def information(text: str):
    """Print an information message to the terminal.

    Args:
        text (str): The text of the information message.
    """
    print(f"[bold green]{text}")


def get_error_message_and_location_and_value_from_a_custom_error(
    error_string: str,
) -> tuple[Optional[str], Optional[str], Optional[str]]:
    """Look at a string and figure out if it's a custom error message that has been
    sent from [`data_models.py`](data_models.md). If it is, then return the custom
    message, location, and the input value.

    This is done because sometimes we raise an error about a specific field in the model
    validation level, but Pydantic doesn't give us the exact location of the error
    because it's a model-level error. So, we raise a custom error with three string
    arguments: message, location, and input value. Those arguments then combined into a
    string by Python. This function is used to parse that custom error message and
    return the three values.

    Args:
        error_string (str): The error message.
    Returns:
        tuple[Optional[str], Optional[str], Optional[str]]: The custom message,
            location, and the input value.
    """
    pattern = r"""\(['"](.*)['"], '(.*)', '(.*)'\)"""
    match = re.search(pattern, error_string)
    if match:
        return match.group(1), match.group(2), match.group(3)
    else:
        return None, None, None


def handle_validation_error(exception: pydantic.ValidationError):
    """Take a Pydantic validation error and print the error messages in a nice table.

    Pydantic's `ValidationError` object is a complex object that contains a lot of
    information about the error. This function takes a `ValidationError` object and
    extracts the error messages, locations, and the input values. Then, it prints them
    in a nice table with [Rich](https://rich.readthedocs.io/en/latest/).

    Args:
        exception (pydantic.ValidationError): The Pydantic validation error object.
    """
    # This dictionary is used to convert the error messages that Pydantic returns to
    # more user-friendly messages.
    error_dictionary: dict[str, str] = {
        "Input should be 'present'": (
            "This is not a valid date! Please use either YYYY-MM-DD, YYYY-MM, or YYYY"
            ' format or "present"!'
        ),
        "Input should be a valid integer, unable to parse string as an integer": (
            "This is not a valid date! Please use either YYYY-MM-DD, YYYY-MM, or YYYY"
            " format!"
        ),
        "String should match pattern '\\d{4}-\\d{2}(-\\d{2})?'": (
            "This is not a valid date! Please use either YYYY-MM-DD, YYYY-MM, or YYYY"
            " format!"
        ),
        "URL scheme should be 'http' or 'https'": "This is not a valid URL!",
        "Field required": "This field is required!",
        "value is not a valid phone number": "This is not a valid phone number!",
        "month must be in 1..12": "The month must be between 1 and 12!",
        "day is out of range for month": "The day is out of range for the month!",
        "Extra inputs are not permitted": (
            "This field is unknown for this object! Please remove it."
        ),
        "Input should be a valid string": "This field should be a string!",
        "Input should be a valid list": (
            "This field should contain a list of items but it doesn't!"
        ),
    }

    unwanted_texts = ["value is not a valid email address: ", "Value error, "]

    # Check if this is a section error. If it is, we need to handle it differently.
    # This is needed because how dm.validate_section_input function raises an exception.
    # This is done to tell the user which which EntryType RenderCV excepts to see.
    errors = exception.errors()
    for error_object in errors.copy():
        if (
            "There are problems with the entries." in error_object["msg"]
            and "ctx" in error_object
        ):
            location = error_object["loc"]
            ctx_object = error_object["ctx"]
            if "error" in ctx_object:
                error_object = ctx_object["error"]
                if hasattr(error_object, "__cause__"):
                    cause_object = error_object.__cause__
                    cause_object_errors = cause_object.errors()
                    for cause_error_object in cause_object_errors:
                        # we use [1:] to avoid `entries` location. It is a location for
                        # RenderCV's own data model, not the user's data model.
                        cause_error_object["loc"] = tuple(
                            list(location) + list(cause_error_object["loc"][1:])
                        )
                    errors.extend(cause_object_errors)

    # some locations are not really the locations in the input file, but some
    # information about the model coming from Pydantic. We need to remove them.
    # (e.g. avoid stuff like .end_date.literal['present'])
    unwanted_locations = ["tagged-union", "list", "literal", "int", "constrained-str"]
    for error_object in errors:
        location = error_object["loc"]
        new_location = [str(location_element) for location_element in location]
        for location_element in location:
            location_element = str(location_element)
            for unwanted_location in unwanted_locations:
                if unwanted_location in location_element:
                    new_location.remove(location_element)
        error_object["loc"] = new_location  # type: ignore

    # Parse all the errors and create a new list of errors.
    new_errors: list[dict[str, str]] = []
    end_date_error_is_found = False
    for error_object in errors:
        message = error_object["msg"]
        location = ".".join(error_object["loc"])  # type: ignore
        input = error_object["input"]

        # Check if this is a custom error message:
        custom_message, custom_location, custom_input_value = (
            get_error_message_and_location_and_value_from_a_custom_error(message)
        )
        if custom_message is not None:
            message = custom_message
            if custom_location != "":
                # If the custom location is not empty, then add it to the location.
                location = f"{location}.{custom_location}"
            input = custom_input_value

        # Don't show unwanted texts in the error message:
        for unwanted_text in unwanted_texts:
            message = message.replace(unwanted_text, "")

        # Convert the error message to a more user-friendly message if it's in the
        # error_dictionary:
        if message in error_dictionary:
            message = error_dictionary[message]

        # Special case for end_date because Pydantic returns multiple end_date errors
        # since it has multiple valid formats:
        if "end_date" in location:
            if end_date_error_is_found:
                continue
            end_date_error_is_found = True
            message = (
                "This is not a valid end date! Please use either YYYY-MM-DD, YYYY-MM,"
                ' or YYYY format or "present"!'
            )

        # If the input is a dictionary or a list (the model itself fails to validate),
        # then don't show the input. It looks confusing and it is not helpful.
        if isinstance(input, (dict, list)):
            input = ""

        new_error = {
            "loc": str(location),
            "msg": message,
            "input": str(input),
        }

        # if new_error is not in new_errors, then add it to new_errors
        if new_error not in new_errors:
            new_errors.append(new_error)

    # Print the errors in a nice table:
    table = rich.table.Table(
        title="[bold red]\nThere are some errors in the data model!\n",
        title_justify="left",
        show_lines=True,
    )
    table.add_column("Location", style="cyan", no_wrap=True)
    table.add_column("Input Value", style="magenta")
    table.add_column("Error Message", style="orange4")

    for error_object in new_errors:
        table.add_row(
            error_object["loc"],
            error_object["input"],
            error_object["msg"],
        )

    print(table)
    error()  # exit the program


def handle_exceptions(function: Callable) -> Callable:
    """Return a wrapper function that handles exceptions.

    A decorator in Python is a syntactic convenience that allows a Python to interpret
    the code below:

    ```python
    @handle_exceptions
    def my_function():
        pass
    ```
    as
    ```python
    handle_exceptions(my_function)()
    ```
    which is step by step equivalent to

    1.  Execute `#!python handle_exceptions(my_function)` which will return the
        function called `wrapper`.
    2.  Execute `#!python wrapper()`.

    Args:
        function (Callable): The function to be wrapped.
    Returns:
        Callable: The wrapped function.
    """

    @functools.wraps(function)
    def wrapper(*args, **kwargs):
        try:
            function(*args, **kwargs)
        except pydantic.ValidationError as e:
            handle_validation_error(e)
        except ruamel.yaml.YAMLError as e:
            error("There is a YAML error in the input file!", e)
        except FileNotFoundError as e:
            error(e)
        except UnicodeDecodeError as e:
            # find the problematic character that cannot be decoded with utf-8
            bad_character = str(e.object[e.start : e.end])
            try:
                bad_character_context = str(e.object[e.start - 16 : e.end + 16])
            except IndexError:
                bad_character_context = ""

            error(
                "The input file contains a character that cannot be decoded with"
                f" UTF-8 ({bad_character}):\n {bad_character_context}",
            )
        except ValueError as e:
            error(e)
        except typer.Exit:
            pass
        except RuntimeError as e:
            error("An error occurred:", e)

    return wrapper


class LiveProgressReporter(rich.live.Live):
    """This class is a wrapper around `rich.live.Live` that provides the live progress
    reporting functionality.

    Args:
        number_of_steps (int): The number of steps to be finished.
    """

    def __init__(self, number_of_steps: int, end_message: str = "Your CV is rendered!"):
        class TimeElapsedColumn(rich.progress.ProgressColumn):
            def render(self, task: "rich.progress.Task") -> rich.text.Text:
                elapsed = task.finished_time if task.finished else task.elapsed
                delta = f"{elapsed:.1f} s"
                return rich.text.Text(str(delta), style="progress.elapsed")

        self.step_progress = rich.progress.Progress(
            TimeElapsedColumn(), rich.progress.TextColumn("{task.description}")
        )

        self.overall_progress = rich.progress.Progress(
            TimeElapsedColumn(),
            rich.progress.BarColumn(),
            rich.progress.TextColumn("{task.description}"),
        )

        self.group = rich.console.Group(
            rich.panel.Panel(rich.console.Group(self.step_progress)),
            self.overall_progress,
        )

        self.overall_task_id = self.overall_progress.add_task("", total=number_of_steps)
        self.number_of_steps = number_of_steps
        self.end_message = end_message
        self.current_step = 0
        self.overall_progress.update(
            self.overall_task_id,
            description=(
                f"[bold #AAAAAA]({self.current_step} out of"
                f" {self.number_of_steps} steps finished)"
            ),
        )
        super().__init__(self.group)

    def __enter__(self) -> "LiveProgressReporter":
        """Overwrite the `__enter__` method for the correct return type."""
        self.start(refresh=self._renderable is not None)
        return self

    def start_a_step(self, step_name: str):
        """Start a step and update the progress bars."""
        self.current_step_name = step_name
        self.current_step_id = self.step_progress.add_task(
            f"{self.current_step_name} has started."
        )

    def finish_the_current_step(self):
        """Finish the current step and update the progress bars."""
        self.step_progress.stop_task(self.current_step_id)
        self.step_progress.update(
            self.current_step_id, description=f"{self.current_step_name} has finished."
        )
        self.current_step += 1
        self.overall_progress.update(
            self.overall_task_id,
            description=(
                f"[bold #AAAAAA]({self.current_step} out of"
                f" {self.number_of_steps} steps finished)"
            ),
            advance=1,
        )
        if self.current_step == self.number_of_steps:
            self.end()

    def end(self):
        """End the live progress reporting."""
        self.overall_progress.update(
            self.overall_task_id,
            description=f"[bold green]{self.end_message}",
        )


def copy_templates(
    folder_name: str,
    copy_to: pathlib.Path,
    new_folder_name: Optional[str] = None,
    suppress_warning: bool = False,
) -> Optional[pathlib.Path]:
    """Copy one of the folders found in `rendercv.templates` to `copy_to`.

    Args:
        folder_name (str): The name of the folder to be copied.
        copy_to (pathlib.Path): The path to copy the folder to.
    Returns:
        Optional[pathlib.Path]: The path to the copied folder.
    """
    # copy the package's theme files to the current directory
    template_directory = pathlib.Path(__file__).parent / "themes" / folder_name
    if new_folder_name:
        destination = copy_to / new_folder_name
    else:
        destination = copy_to / folder_name

    if destination.exists():
        if not suppress_warning:
            if folder_name != "markdown":
                warning(
                    f'The theme folder "{folder_name}" already exists! The theme files'
                    " are not copied."
                )
            else:
                warning(
                    'The folder "markdown" already exists! The markdown files are not'
                    " copied."
                )

        return None
    else:
        # copy the folder but don't include __init__.py:
        shutil.copytree(
            template_directory,
            destination,
            ignore=shutil.ignore_patterns("__init__.py"),
        )

        return destination


def parse_data_model_override_arguments(
    extra_arguments: typer.Context,
) -> dict["str", "str"]:
    """Parse extra arguments as data model key and value pairs and return them as a
    dictionary.

    Args:
        extra_arguments (typer.Context): The extra arguments context.
    Returns:
        dict["str", "str"]: The key and value pairs.
    """
    key_and_values: dict["str", "str"] = dict()

    # `extra_arguments.args` is a list of arbitrary arguments that haven't been
    # specified in `cli_render_command` function's definition. They are used to allow
    # users to edit their data model in CLI. The elements with even indexes in this list
    # are keys that start with double dashed, such as
    # `--cv.sections.education.0.institution`. The following elements are the
    # corresponding values of the key, such as `"Bogazici University"`. The for loop
    # below parses `ctx.args` accordingly.

    if len(extra_arguments.args) % 2 != 0:
        error(
            "There is a problem with the extra arguments! Each key should have"
            " a corresponding value."
        )

    for i in range(0, len(extra_arguments.args), 2):
        key = extra_arguments.args[i]
        value = extra_arguments.args[i + 1]
        if not key.startswith("--"):
            error(f"The key ({key}) should start with double dashes!")

        key = key.replace("--", "")

        key_and_values[key] = value

    return key_and_values


@app.command(
    name="render",
    help=(
        "Render a YAML input file. Example: [bold green]rendercv render"
        " John_Doe_CV.yaml[/bold green]"
    ),
    # allow extra arguments for updating the data model:
    context_settings={"allow_extra_args": True, "ignore_unknown_options": True},
)
@handle_exceptions
def cli_command_render(
    input_file_name: Annotated[
        str,
        typer.Argument(help="Name of the YAML input file."),
    ],
    use_local_latex_command: Annotated[
        Optional[str],
        typer.Option(
            help=(
                "Use the local LaTeX installation with the given command instead of the"
                " RenderCV's TinyTeX."
            ),
        ),
    ] = None,
    output_folder_name: Annotated[
        str,
        typer.Option(
            help="Name of the output folder.",
        ),
    ] = "rendercv_output",
    latex_path: Annotated[
        Optional[str],
        typer.Option(
            help="Copy the LaTeX file to the given path.",
        ),
    ] = None,
    pdf_path: Annotated[
        Optional[str],
        typer.Option(
            help="Copy the PDF file to the given path.",
        ),
    ] = None,
    markdown_path: Annotated[
        Optional[str],
        typer.Option(
            help="Copy the Markdown file to the given path.",
        ),
    ] = None,
    html_path: Annotated[
        Optional[str],
        typer.Option(
            help="Copy the HTML file to the given path.",
        ),
    ] = None,
    png_path: Annotated[
        Optional[str],
        typer.Option(
            help="Copy the PNG file to the given path.",
        ),
    ] = None,
    dont_generate_markdown: Annotated[
        bool,
        typer.Option(
            "--dont-generate-markdown",
            help="Don't generate the Markdown and HTML file.",
        ),
    ] = False,
    dont_generate_html: Annotated[
        bool,
        typer.Option(
            "--dont-generate-html",
            help="Don't generate the HTML file.",
        ),
    ] = False,
    dont_generate_png: Annotated[
        bool,
        typer.Option(
            "--dont-generate-png",
            help="Don't generate the PNG file.",
        ),
    ] = False,
    extra_data_model_override_argumets: typer.Context = None,
):
    """Generate a $\\LaTeX$ CV from a YAML input file."""
    welcome()

    input_file_path = pathlib.Path(input_file_name)
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
            key_and_values = parse_data_model_override_arguments(
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
        "Generate a YAML input file to get started. Example: [bold green]rendercv new"
        ' "John Doe"[/bold green]'
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
            help="Don't create theme source files.",
        ),
    ] = False,
    dont_create_markdown_source_files: Annotated[
        bool,
        typer.Option(
            "--dont-create-markdown-source-files",
            help="Don't create the Markdown source files.",
        ),
    ] = False,
):
    """Generate a YAML input file to get started."""
    try:
        data_model = dm.get_a_sample_data_model(full_name, theme)
    except ValueError as e:
        error(e)

    file_name = f"{full_name.replace(' ', '_')}_CV.yaml"
    file_path = pathlib.Path(file_name)

    # Instead of getting the dictionary with data_model.model_dump() directly, we
    # convert it to JSON and then to a dictionary. Because the YAML library we are using
    # sometimes has problems with the dictionary returned by model_dump().

    # We exclude "cv.sections" because the data model automatically generates them. The
    # user's "cv.sections" input is actually "cv.sections_input" in the data model. It
    # is shown as "cv.sections" in the YAML file because an alias is being used. If
    # "cv.sections" were not excluded, the automatically generated "cv.sections" would
    # overwrite the "cv.sections_input". "cv.sections" are automatically generated from
    # "cv.sections_input" to make the templating process easier. "cv.sections_input"
    # exists for the convenience of the user.
    data_model_as_json = data_model.model_dump_json(
        exclude_none=True, by_alias=True, exclude={"cv": {"sections"}}
    )
    data_model_as_dictionary = json.loads(data_model_as_json)

    yaml_object = ruamel.yaml.YAML()
    yaml_object.encoding = "utf-8"
    yaml_object.indent(mapping=2, sequence=4, offset=2)
    yaml_object.dump(data_model_as_dictionary, file_path)

    created_files_and_folders = [file_name]
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

    if len(created_files_and_folders) == 1:
        information(f"The RenderCV input file has been created:\n{file_name}")
    else:
        created_files_and_folders_string = ",\n".join(created_files_and_folders)
        information(
            "The following RenderCV input file and folders have been"
            f" created:\n{created_files_and_folders_string}"
        )


@app.command(
    name="create-theme",
    help=(
        "Create a custom theme folder based on an existing theme. Example: [bold"
        " green]rendercv create-theme --based-on classic customtheme[/bold green]"
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
    """Create a custom theme folder based on an existing theme."""
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
