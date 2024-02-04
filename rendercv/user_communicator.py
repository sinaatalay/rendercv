import time
from typing import Callable

from rich import print
from rich.console import Console, Group
from rich.panel import Panel
from rich.live import Live
from rich.progress import (
    BarColumn,
    Progress,
    ProgressColumn,
    TextColumn,
    Task,
)
from rich.text import Text

import pydantic

error_console = Console(stderr=True)


def welcome():
    """Print a welcome message to the terminal."""
    print("Welcome to [bold blue]RenderCV[/bold blue]!")
    print("Documentation: [link=https://sinaatalay.github.io/rendercv/]")
    print("Source code: [link=https://github.com/sinaatalay/rendercv/]")
    print("Report bugs: [link=https://github.com/sinaatalay/rendercv/issues/]")


def warning(text):
    """Print a warning message to the terminal."""
    print(f"[bold yellow]{text}[/bold yellow]")


def error(text):
    """Print an error message to the terminal."""
    error_console.print(f"[bold red]{text}[/bold red]")


def information(text):
    """Print an information message to the terminal."""
    print(f"[bold blue]{text}[/bold blue]")


def time_the_event_below(event_name: str) -> Callable:
    """Return a wrapper function that times the wrapped function.

    A decorator in Python is a syntactic convenience that allows a Python to interpret
    the code below:

    ```python
    @time_the_event_below("My event")
    def my_function():
        pass
    ```
    as
    ```python
    time_the_event_below("My event")(my_function)()
    ```
    which is step by step equivalent to

    1.  Execute `#!python time_the_event_below("My event")` which will return the
        function called `wrapper`.
    2.  Execute `#!python wrapper(my_function)`, which will return another function
        called `wrapped_function`, which does some modifications to `my_function.`
    3.  Execute `#!python wrapped_function()`
    """

    def wrapper(function: Callable) -> Callable:
        def wrapped_function(*args, **kwargs):
            start_time = time.time()
            # information(f"{event_name} has started.")
            result = function(*args, **kwargs)
            end_time = time.time()
            # compute the time took in 2 decimal places
            time_took = round(end_time - start_time, 2)
            information(f"{event_name} has finished in {time_took} seconds.\n")
            return result

        return wrapped_function

    return wrapper


def handle_exceptions(function: Callable) -> Callable:
    """ """

    def wrapper(*args, **kwargs):
        return function(*args, **kwargs)

    return wrapper


class TimeElapsedColumn(ProgressColumn):
    """Renders time elapsed."""

    def render(self, task: "Task") -> Text:
        """Show time elapsed."""
        elapsed = task.finished_time if task.finished else task.elapsed
        if elapsed is None:
            return Text("--.-", style="progress.elapsed")
        delta = f"{elapsed:.1f} s"
        return Text(str(delta), style="progress.elapsed")


class LiveProgress(Live):
    def __init__(self, step_progress, overall_progress, group, overall_task_id):
        super().__init__()
        self.step_progress = step_progress
        self.overall_progress = overall_progress
        self.group = group

        self.overall_task_id = overall_task_id
        self.number_of_tasks = 3
        self.overall_progress.update(
            self.overall_task_id,
            description=(
                f"[bold #AAAAAA](0 out of {self.number_of_tasks} steps finished)"
            ),
        )

    def __enter__(self) -> "LiveProgress":
        self.start(refresh=self._renderable is not None)
        return self

    def start_a_step(self, step_name: str):
        self.current_step_name = step_name
        self.current_step_id = self.step_progress.add_task(
            f"{self.current_step_name} has started."
        )

    def finish_the_current_step(self):
        self.step_progress.stop_task(self.current_step_id)
        self.step_progress.update(
            self.current_step_id, description=f"{self.current_step_name} has finished."
        )
        self.overall_progress.update(self.overall_task_id, advance=1)

    def end(self):
        self.overall_progress.update(
            self.overall_task_id,
            description="[bold green]Your CV is rendered!",
        )
