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

    table.add_row("Documentation", "https://sinaatalay.github.io/rendercv/")
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


def error(text: str, exception: Optional[Exception] = None):
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
        print(f"\n[bold red]{text}\n")


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

    Pydantic's ValidationError object is a complex object that contains a lot of
    information about the error. This function takes a ValidationError object and
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
        "Value error, day is out of range for month": (
            "The day is out of range for the month!"
        ),
        "Extra inputs are not permitted": (
            "This field is unknown for this object! Please remove it."
        ),
        "Input should be a valid string": "This field should be a string!",
        "Input should be a valid list": (
            "This field should contain a list of items but it doesn't!"
        ),
    }

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
    unwanted_locations = ["tagged-union", "list", "literal"]
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

        # Convert the error message to a more user-friendly message if it's in the
        # error_dictionary:
        if message in error_dictionary:
            message = error_dictionary[message]

        # Don't show "Value error, ", since the message is already clear.
        message = message.replace("Value error, ", "")

        # Special case for end_date because Pydantic returns multiple end_date errors
        # since it has multiple valid formats:
        if "end_date." in location:
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

        new_errors.append(
            {
                "loc": str(location),
                "msg": message,
                "input": str(input),
            }
        )

    # Print the errors in a nice table:
    table = rich.table.Table(
        title="[bold red]\nThere are some errors in the input file!\n",
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
    print()  # Add an empty line at the end to make it look better.


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


@app.command(
    name="render",
    help=(
        "Render a YAML input file. Example: [bold green]rendercv render"
        " John_Doe_CV.yaml[/bold green]"
    ),
)
@handle_exceptions
def cli_command_render(
    input_file_name: Annotated[
        str,
        typer.Argument(help="Name of the YAML input file."),
    ],
    local_latex_command: Annotated[
        Optional[str],
        typer.Option(
            "--use-local-latex-command",
            help=(
                "Use the local LaTeX installation with the given command instead of the"
                " RenderCV's TinyTeX."
            ),
        ),
    ] = None,
):
    """Generate a $\\LaTeX$ CV from a YAML input file.

    Args:
        input_file_path (str): Path to the YAML input file as a string.
        use_local_latex (bool, optional): Use the local LaTeX installation instead of
            the RenderCV's TinyTeX. The default is False.
    """
    welcome()

    input_file_path = pathlib.Path(input_file_name)

    output_directory = input_file_path.parent / "rendercv_output"

    with LiveProgressReporter(number_of_steps=5) as progress:
        progress.start_a_step("Reading and validating the input file")
        data_model = dm.read_input_file(input_file_path)
        progress.finish_the_current_step()

        progress.start_a_step("Generating the LaTeX file")
        latex_file_path = r.generate_latex_file_and_copy_theme_files(
            data_model, output_directory
        )
        progress.finish_the_current_step()

        progress.start_a_step("Generating the Markdown file")
        markdown_file_path = r.generate_markdown_file(data_model, output_directory)
        progress.finish_the_current_step()

        progress.start_a_step("Rendering the LaTeX file to a PDF")
        r.latex_to_pdf(latex_file_path, local_latex_command)
        progress.finish_the_current_step()

        progress.start_a_step("Rendering the Markdown file to a HTML (for Grammarly)")
        r.markdown_to_html(markdown_file_path)
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
    theme: Annotated[str, typer.Option(help="The theme of the CV.")] = "classic",
):
    """Generate a YAML input file to get started."""
    data_model = dm.get_a_sample_data_model(full_name, theme)
    file_name = f"{full_name.replace(' ', '_')}_CV.yaml"
    file_path = pathlib.Path(file_name)

    # Instead of getting the dictionary with data_model.model_dump() directly, we
    # convert it to JSON and then to a dictionary. Because the YAML library we are using
    # sometimes has problems with the dictionary returned by model_dump().
    data_model_as_json = data_model.model_dump_json(
        exclude_none=True, by_alias=True, exclude={"cv": {"sections"}}
    )
    data_model_as_dictionary = json.loads(data_model_as_json)

    yaml_object = ruamel.yaml.YAML()
    yaml_object.encoding = "utf-8"
    yaml_object.indent(mapping=2, sequence=4, offset=2)
    yaml_object.dump(data_model_as_dictionary, file_path)

    information(f"Your RenderCV input file has been created: {file_path}!")
