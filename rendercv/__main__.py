import os
import logging
import re
from typing import Annotated, Callable
from functools import wraps

from .rendering import read_input_file, render_template, run_latex

import typer
from jinja2 import Environment, PackageLoader

logger = logging.getLogger(__name__)

app = typer.Typer(
    help="RenderCV - A LateX CV generator from YAML",
    add_completion=False,
    pretty_exceptions_enable=True,
    pretty_exceptions_short=True,
    pretty_exceptions_show_locals=True,
)


def user_friendly_errors(func: Callable) -> Callable:
    """Function decorator to make Pydantic's error messages more user-friendly.

    Args:
        func (Callable): Function to decorate
    Returns:
        Callable: Decorated function
    """
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            func(*args, **kwargs)
        except Exception as e:
            # Modify Pydantic's error message to make it more user-friendly
            error_message = e.__repr__()
            error_messages = error_message.split("\n")
            for error_line in error_messages.copy():
                new_error_line = None

                if "function-after" in error_line:
                    # Remove this line and the next one
                    next_error_line = error_messages[error_messages.index(error_line) + 1]
                    error_messages.remove(error_line)
                    error_messages.remove(next_error_line)

                if "validation" in error_line:
                    new_error_line = "There are validation errors!"

                if "For further information" in error_line:
                    # Remove further information line
                    error_messages.remove(error_line)

                # Modify Pydantic's error message:
                match = re.match(
                    r"(.*) \[type=\w+, input_value=(.*), input_type=\w+\]",
                    error_line,
                )
                if match:
                    new_error_line = f"{match.group(1)}"

                    # Add a period at the end of the sentence if there is none
                    if not (new_error_line[-1] == "." or new_error_line[-1] == "!"):
                        new_error_line = new_error_line + "."

                    # If the input value is not a dictionary, add it to the error
                    # message
                    if "{" not in match.group(2):
                        new_error_line = (
                            new_error_line + f" The input was {match.group(2)}!"
                        )
                # If the error line was modified, replace it
                if new_error_line is not None:
                    try:
                        error_messages[error_messages.index(error_line)] = new_error_line
                    except ValueError:
                        # This error line was already removed
                        pass

            error_message = "\n           ".join(error_messages)

            # Print the error message
            logger.critical(error_message)

            # Abort the program
            logger.info("Aborting RenderCV.")
            typer.Abort()

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
