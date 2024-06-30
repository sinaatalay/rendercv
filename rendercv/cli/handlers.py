"""
The `rendercv.cli.handlers` contains all the functions that are used to handle all
exceptions that can be raised by `rendercv` during the execution of the CLI.
"""

import functools
from typing import Callable

import jinja2
import pydantic
import ruamel.yaml
import ruamel.yaml.parser
import typer

from .printer import error, print_validation_errors


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
            print_validation_errors(e)
        except ruamel.yaml.YAMLError as e:
            error(
                "There is a YAML error in the input file!\n\nTry to use quotation marks"
                " to make sure the YAML parser understands the field is a string.",
                e,
            )
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
        except jinja2.exceptions.TemplateSyntaxError as e:
            error(
                f"There is a problem with the template ({e.filename}) at line"
                f" {e.lineno}!",
                e,
            )
        except RuntimeError as e:
            error(e)

    return wrapper
