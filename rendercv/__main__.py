import os
import logging
import re
from typing import Annotated, Callable
from functools import wraps

from .data_model import read_input_file
from .rendering import render_template, run_latex

import typer
from jinja2 import Environment, PackageLoader
from pydantic import ValidationError
from pydantic_core import ErrorDetails

logger = logging.getLogger(__name__)

app = typer.Typer(
    help="RenderCV - A LateX CV generator from YAML",
    add_completion=False,
    pretty_exceptions_enable=True,
    pretty_exceptions_short=True,
    pretty_exceptions_show_locals=True,
)


def user_friendly_errors(func: Callable) -> Callable:
    """Function decorator to make RenderCV's error messages more user-friendly.

    Args:
        func (Callable): Function to decorate
    Returns:
        Callable: Decorated function
    """

    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            func(*args, **kwargs)
        except ValidationError as e:
            # It is a Pydantic error
            error_messages = []
            error_messages.append("There are validation errors!")

            # Translate Pydantic's error messages to make them more user-friendly
            custom_error_messages_by_type = {
                "url_scheme": "This is not a valid URL 😿",
            }
            custom_error_messages_by_msg = {
                "value is not a valid phone number": (
                    "This is not a valid phone number 👺"
                )
            }
            new_errors: list[ErrorDetails] = []
            for error in e.errors():
                # Modify Pydantic's error message to make it more user-friendly

                # Remove url:
                error["url"] = None

                # Make sure the entries of loc are strings
                error["loc"] = [str(loc) for loc in error["loc"]]

                # Assign a custom error message if there is one
                custom_message = None
                if error["type"] in custom_error_messages_by_type:
                    custom_message = custom_error_messages_by_type[error["type"]]
                elif error["msg"] in custom_error_messages_by_msg:
                    custom_message = custom_error_messages_by_msg[error["msg"]]

                if custom_message:
                    ctx = error.get("ctx")
                    error["msg"] = (
                        custom_message.format(**ctx) if ctx else custom_message
                    )

                # If the input value is a dictionary or if the input value is in the
                # error message, remove it
                if isinstance(error["input"], dict) or error["input"] in error["msg"]:
                    error["input"] = None

                new_errors.append(error)

            # Create a custom error message for RenderCV users
            for error in new_errors:
                location = ".".join(error["loc"])
                error_messages.append(f"{location}:\n    {error['msg']}")
                if error["input"]:
                    error_messages[-1] += f"\n    Your input was \"{error['input']}\""
            error_message = "\n\n  ".join(error_messages)
            logger.error(error_message)

        except Exception as e:
            # It is not a Pydantic error
            logging.error(e)

    return wrapper


@app.command(help="Render a YAML input file")
@user_friendly_errors
def render(
    input_file: Annotated[
        str,
        typer.Argument(help="Name of the YAML input file"),
    ]
):
    """Generate a LaTeX CV from a YAML input file.

    Args:
        input_file (str): Name of the YAML input file
    """
    file_path = os.path.abspath(input_file)
    data = read_input_file(file_path)
    output_latex_file = render_template(data)
    run_latex(output_latex_file)


@app.command(help="Generate a YAML input file to get started")
@user_friendly_errors
def new(name: Annotated[str, typer.Argument(help="Full name")]):
    """Generate a YAML input file to get started.

    Args:
        name (str): Full name
    """
    environment = Environment(
        loader=PackageLoader("rendercv", os.path.join("templates")),
    )
    environment.variable_start_string = "<<"
    environment.variable_end_string = ">>"

    template = environment.get_template("new_input.yaml.j2")
    new_input_file = template.render(name=name)

    name = name.replace(" ", "_")
    file_name = f"{name}_CV.yaml"
    with open(file_name, "w", encoding="utf-8") as file:
        file.write(new_input_file)

    logger.info(f"New input file created: {file_name}")


def cli():
    """Start the CLI application.

    This function is the entry point for RenderCV.
    """
    app()


if __name__ == "__main__":
    cli()
