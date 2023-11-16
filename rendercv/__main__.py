import os
import logging
from typing import Annotated, Callable
from functools import wraps

from .data_model import read_input_file
from .rendering import render_template, run_latex

import typer
from jinja2 import Environment, PackageLoader
from pydantic import ValidationError
from pydantic_core import ErrorDetails
from ruamel.yaml.parser import ParserError

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
            error_messages.append("There are some problems with your input.")

            # Translate Pydantic's error messages to make them more user-friendly
            custom_error_messages_by_type = {
                "url_scheme": "This is not a valid URL.",
                "string_type": "This is not a valid string.",
                "missing": "This field is required, but it is missing.",
                "literal_error": "Only the following values are allowed: {expected}.",
            }
            custom_error_messages_by_msg = {
                "value is not a valid phone number": (
                    "This is not a valid phone number."
                ),
                "String should match pattern '\\d+\\.?\\d* *(cm|in|pt|mm|ex|em)'": (
                    "This is not a valid length! Use a number followed by a unit "
                    "of length (cm, in, pt, mm, ex, em)."
                ),
            }
            new_errors: list[ErrorDetails] = []
            for error in e.errors():
                # Modify Pydantic's error message to make it more user-friendly

                # Remove url:
                error["url"] = None

                # Make sure the entries of loc (location) are strings
                error["loc"] = [str(loc) for loc in error["loc"]]

                # Assign a custom error message if there is one
                custom_message = None
                if error["type"] in custom_error_messages_by_type:
                    custom_message = custom_error_messages_by_type[error["type"]]
                elif error["msg"] in custom_error_messages_by_msg:
                    custom_message = custom_error_messages_by_msg[error["msg"]]

                if custom_message:
                    ctx = error.get("ctx")
                    ctx_error = ctx.get("error") if ctx else None
                    if ctx_error:
                        # This means that there is a custom validation error that
                        # comes from data_model.py
                        error["msg"] = ctx["error"].args[0]
                    elif ctx:
                        # Some Pydantic errors have a context, see the custom message
                        # for "literal_error" above
                        error["msg"] = custom_message.format(**ctx)
                    else:
                        # If there is no context, just use the custom message
                        error["msg"] = custom_message

                if error["input"] is not None:
                    # If the input value is a dictionary, remove it
                    if isinstance(error["input"], dict):
                        error["input"] = None
                    elif isinstance(error["input"], (float, int, bool, str)):
                        # Or if the input value is in the error message, remove it
                        input_value = str(error["input"])
                        if input_value in error["msg"]:
                            error["input"] = None

                new_errors.append(error)

            # Create a custom error message for RenderCV users
            for error in new_errors:
                if len(error["loc"]) > 0:
                    location = ".".join(error["loc"])
                    error_messages.append(f"{location}:\n    {error['msg']}")
                else:
                    error_messages.append(f"{error['msg']}")

                if error["input"]:
                    error_messages[-1] += f"\n    Your input was \"{error['input']}\""
            error_message = "\n\n  ".join(error_messages)
            logger.error(error_message)

        except ParserError as e:
            # It is a YAML parser error
            new_args = list(e.args)
            new_args = [str(arg).strip() for arg in new_args]
            new_args[0] = "There is a problem with your input file.‍"
            error_message = "\n\n  ".join(new_args)
            logger.error(error_message)

        except Exception as e:
            # It is not a Pydantic error
            new_args = list(e.args)
            new_args = [str(arg).strip() for arg in new_args]
            error_message = "\n\n  ".join(new_args)
            logger.error(error_message)

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
