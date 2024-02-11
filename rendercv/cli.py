"""
to be continued...
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
    help="RenderCV - A LaTeX CV generator from YAML",
)


def welcome():
    """Print a welcome message to the terminal."""
    table = rich.table.Table(
        title="\nWelcome to [bold]Render[dodger_blue3]CV[/dodger_blue3][/bold]!",
        title_justify="left",
    )

    table.add_column("Title", style="magenta")
    table.add_column("Link", style="cyan", justify="right", no_wrap=True)

    table.add_row("Documentation", "https://sinaatalay.github.io/rendercv/")
    table.add_row("Source code", "https://github.com/sinaatalay/rendercv/")
    table.add_row("Bug reports", "https://github.com/sinaatalay/rendercv/issues/")
    table.add_row("Feature requests", "https://github.com/sinaatalay/rendercv/issues/")

    print(table)


def warning(text):
    """Print a warning message to the terminal."""
    print(f"[bold yellow]{text}")


def error(text, exception=None):
    """Print an error message to the terminal."""
    if exception is not None:
        exception_messages = [str(arg) for arg in exception.args]
        exception_message = "\n\n".join(exception_messages)
        print(
            f"\n[bold red]{text}[/bold red]\n\n[orange4]{exception_message}[/orange4]"
        )
    else:
        print(f"[bold red]{text}")


def information(text):
    """Print an information message to the terminal."""
    print(f"[bold green]{text}")


def get_error_message_and_location_and_value_from_a_custom_error(
    error_string: str,
) -> Optional[tuple[str, str, str]]:
    pattern = r"\('(.*)', '(.*)', '(.*)'\)"
    match = re.search(pattern, error_string)
    if match:
        return match.group(1), match.group(2), match.group(3)
    else:
        return None


def handle_validation_error(exception: pydantic.ValidationError):
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
            "This field is unknown for this object. Are you sure you are following the"
            " correct schema?"
        ),
    }
    new_errors: list[dict[str, str]] = []
    end_date_error_is_found = False
    for error_object in exception.errors():
        message = error_object["msg"]
        location = ".".join([str(loc) for loc in error_object["loc"]])
        input = error_object["input"]

        # remove `.entries.` because that location is not user's location but
        # RenderCV's own data model's location
        location = location.replace(".entries", "")

        custom_error = get_error_message_and_location_and_value_from_a_custom_error(
            message
        )
        if custom_error is not None:
            message = custom_error[0]
            if custom_error[1] != "":
                location = f"{location}.{custom_error[1]}"
            input = custom_error[2]

        if message in error_dictionary:
            message = error_dictionary[message]

        # Special case for end_date because Pydantic returns multiple end_date errors
        # since it has multiple valid formats:
        if "end_date." in location:
            if end_date_error_is_found:
                continue
            end_date_error_is_found = True
            # omit the next location after .end_date
            # (e.g. avoid stuff like .end_date.literal['present'])
            # location = re.sub(r"(\.end_date)\..*", r"\1", location)
            message = (
                "This is not a valid end date! Please use either YYYY-MM-DD, YYYY-MM,"
                ' or YYYY format or "present"!'
            )

        new_errors.append({
            "loc": str(location),
            "msg": message,
            "input": str(input),
        })

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
    print()


def handle_exceptions(function: Callable) -> Callable:
    """ """

    @functools.wraps(function)
    def wrapper(*args, **kwargs):
        try:
            function(*args, **kwargs)
        except pydantic.ValidationError as e:
            handle_validation_error(e)
        except ruamel.yaml.YAMLError as e:
            error("There is a YAML error in the input file!", e)
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


@app.command(name="render", help="Render a YAML input file")
@handle_exceptions
def cli_command_render(
    input_file_path: Annotated[
        str,
        typer.Argument(help="Name of the YAML input file"),
    ],
):
    """Generate a LaTeX CV from a YAML input file.

    Args:
        input_file (str): Name of the YAML input file
    """
    welcome()

    input_file_path_obj = pathlib.Path(input_file_path)

    output_directory = input_file_path_obj.parent / "rendercv_output"

    with LiveProgressReporter(number_of_steps=3) as progress:
        progress.start_a_step("Reading and validating the input file")
        data_model = dm.read_input_file(input_file_path_obj)
        progress.finish_the_current_step()

        progress.start_a_step("Generating the LaTeX file")
        latex_file_path = r.generate_latex_file_and_copy_theme_files(
            data_model, output_directory
        )
        progress.finish_the_current_step()

        progress.start_a_step("Rendering the LaTeX file to a PDF")
        r.latex_to_pdf(latex_file_path)
        progress.finish_the_current_step()


@app.command(name="new", help="Generate a YAML input file to get started.")
def cli_command_new(full_name: Annotated[str, typer.Argument(help="Your full name")]):
    """Generate a YAML input file to get started."""
    data_model = dm.get_a_sample_data_model(full_name)
    file_name = f"{full_name.replace(' ', '_')}_CV.yaml"
    file_path = pathlib.Path(file_name)

    # Instead of getting the dictionary with data_model.model_dump() directy, we convert
    # it to JSON and then to a dictionary. Because the YAML library we are using
    # sometimes has problems with the dictionary returned by model_dump().
    data_model_as_json = data_model.model_dump_json(
        exclude_none=True, by_alias=True, exclude={"cv": {"sections"}}
    )
    data_model_as_dictionary = json.loads(data_model_as_json)

    yaml = ruamel.yaml.YAML()
    yaml.indent(mapping=2, sequence=4, offset=2)
    yaml.dump(data_model_as_dictionary, file_path)

    information(f"Your RenderCV input file has been created: {file_path}!")
