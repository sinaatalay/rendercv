import os
import logging
from typing import Annotated

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


@app.command(help="Render a YAML input file")
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
    try:
        file_path = os.path.abspath(input_file)
        data = read_input_file(file_path)
        output_latex_file = render_template(data)
        run_latex(output_latex_file)
    except Exception as e:
        logger.critical(e)
        typer.Abort()


@app.command(help="Generate a YAML input file to get started")
def new(name: Annotated[str, typer.Argument(help="Full name")]):
    """Generate a YAML input file to get started.

    Args:
        name (str): Full name
    """
    try:
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
    except Exception as e:
        logger.critical(e)
        typer.Abort()


def cli():
    """Start the CLI application.

    This function is the entry point for RenderCV.
    """
    app()

if __name__ == "__main__":
    cli()