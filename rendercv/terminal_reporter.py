import time
from typing import Callable

from rich import print


def welcome():
    """Print a welcome message to the terminal.

    The ASCII art is from https://ascii-generator.site/ and the font is "big".
    """
    rendercv_art = (
        ""
        "[bright_white] _____                    _            "
        " [/bright_white][bright_blue]  _____ __      __[/bright_blue]\n[bright_white]|"
        "  __ \\                  | |            [/bright_white][bright_blue] / ____|\\"
        " \\    / /[/bright_blue]\n[bright_white]| |__) |  ___  _ __    __| |  ___  _"
        " __ [/bright_white][bright_blue]| |      \\ \\  / /"
        " [/bright_blue]\n[bright_white]|  _  /  / _ \\| '_ \\  / _` | / _ \\|"
        " '__|[/bright_white][bright_blue]| |       \\ \\/ / "
        " [/bright_blue]\n[bright_white]| | \\ \\ |  __/| | | || (_| ||  __/| |  "
        " [/bright_white][bright_blue]| |____    \\  /  "
        " [/bright_blue]\n[bright_white]|_|  \\_\\ \\___||_| |_| \\__,_| \\___||_|  "
        " [/bright_white][bright_blue] \\_____|    \\/ [/bright_blue]"
        ""
    )

    print(rendercv_art)


def warning(text):
    """Print a warning message to the terminal."""
    print(f"[bold yellow]{text}[/bold yellow]")


def error(text):
    """Print an error message to the terminal."""
    print(f"[bold red]{text}[/bold red]")


def information(text):
    """Print an information message to the terminal."""
    print(f"[cyan]{text}[/cyan]")


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
            information(f"{event_name} has started.")
            result = function(*args, **kwargs)
            end_time = time.time()
            information(
                f"{event_name} has finished in {end_time - start_time} seconds."
            )
            return result

        return wrapped_function

    return wrapper
