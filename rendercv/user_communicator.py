from typing import Callable
import re

import rich
import rich.console
import rich.panel
import rich.live
import rich.table
import rich.text
import rich.progress
import pydantic_core
import pydantic
import ruamel.yaml
import ruamel.yaml.parser

console = rich.console.Console()


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

    console.print(table)


def warning(text):
    """Print a warning message to the terminal."""
    console.print(f"[bold yellow]{text}")


def error(text, exception=None):
    """Print an error message to the terminal."""
    console.print(f"\n[bold red]{text}[/bold red]\n\n[orange4]{exception}")


def information(text):
    """Print an information message to the terminal."""
    console.print(f"[bold green]{text}")


def handle_validation_error(exception: pydantic.ValidationError):
    error_dictionary: dict[str, str] = {
        r"Value error, Invalid isoformat string: '(.*)'": (
            "This is not a valid date! Please use either YYYY-MM-DD, YYYY-MM, or"
            " YYYY format."
        ),
        r"URL scheme should be 'http' or 'https'": "This is not a valid URL!",
        r"Field( )required": "This field is required!",
        r"value is not a valid phone number": "This is not a valid phone number!",
        r"String should match pattern '\\d\+\\\.\?\\d\* \*\(cm\|in\|pt\|mm\|ex\|em\)'": (
            'This is not a valid dimension! For example, use "2 cm" or "3.5 in"'
        ),
    }
    new_errors: list[pydantic_core.ErrorDetails] = []
    for error_object in exception.errors():
        for key, value in error_dictionary.items():
            match = re.match(key, error_object["msg"])
            if match:
                error_object["msg"] = value
                try:
                    error_object["input"] = match.group(1)
                except IndexError:
                    pass

        new_errors.append(error_object)

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
            ".".join([str(i) for i in error_object["loc"]]),
            error_object["input"],
            error_object["msg"],
        )

    console.print(table)


def handle_exceptions(function: Callable) -> Callable:
    """ """

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
                if elapsed is None:
                    return rich.text.Text("--.-", style="progress.elapsed")
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
