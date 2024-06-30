"""
`rendercv.cli.printer` module contains all the functions and classes that are used to
print nice-looking messages to the terminal.
"""

from typing import Optional

import rich
import typer
from rich import print

from .. import __version__
from .utilities import get_latest_version_number_from_pypi


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
            description=f"[yellow]{self.end_message}",
        )


def warn_if_new_version_is_available() -> bool:
    """Check if a new version of RenderCV is available and print a warning message if
    there is a new version. Also, return True if there is a new version, and False
    otherwise.

    Returns:
        bool: True if there is a new version, and False otherwise.
    """
    latest_version = get_latest_version_number_from_pypi()
    if latest_version is not None and __version__ != latest_version:
        warning(
            f"A new version of RenderCV is available! You are using v{__version__},"
            f" and the latest version is v{latest_version}."
        )
        return True
    else:
        return False


def welcome():
    """Print a welcome message to the terminal."""
    warn_if_new_version_is_available()

    table = rich.table.Table(
        title=(
            "\nWelcome to [bold]Render[dodger_blue3]CV[/dodger_blue3][/bold]! Some"
            " useful links:"
        ),
        title_justify="left",
    )

    table.add_column("Title", style="magenta", justify="left")
    table.add_column("Link", style="cyan", justify="right", no_wrap=True)

    table.add_row("Documentation", "https://docs.rendercv.com")
    table.add_row("Source code", "https://github.com/sinaatalay/rendercv/")
    table.add_row("Bug reports", "https://github.com/sinaatalay/rendercv/issues/")
    table.add_row("Feature requests", "https://github.com/sinaatalay/rendercv/issues/")
    table.add_row("Discussions", "https://github.com/sinaatalay/rendercv/discussions/")
    table.add_row(
        "RenderCV Pipeline", "https://github.com/sinaatalay/rendercv-pipeline/"
    )

    print(table)


def warning(text: str):
    """Print a warning message to the terminal.

    Args:
        text (str): The text of the warning message.
    """
    print(f"[bold yellow]{text}")


def error(text: Optional[str] = None, exception: Optional[Exception] = None):
    """Print an error message to the terminal and exit the program. If an exception is
    given, then print the exception's message as well. If neither text nor exception is
    given, then print an empty line and exit the program.

    Args:
        text (str): The text of the error message.
        exception (Exception, optional): An exception object. Defaults to None.
    """
    if exception is not None:
        exception_messages = [str(arg) for arg in exception.args]
        exception_message = "\n\n".join(exception_messages)
        if text is None:
            text = "An error occurred:"

        print(
            f"\n[bold red]{text}[/bold red]\n\n[orange4]{exception_message}[/orange4]\n"
        )
    elif text is not None:
        print(f"\n[bold red]{text}\n")
    else:
        print()

    raise typer.Exit(code=4)


def information(text: str):
    """Print an information message to the terminal.

    Args:
        text (str): The text of the information message.
    """
    print(f"[yellow]{text}")
