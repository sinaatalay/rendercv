import json
import pathlib
from typing import Annotated

import typer
import ruamel.yaml


from . import user_communicator as uc
from . import data_models as dm
from . import renderer as r


app = typer.Typer(
    help="RenderCV - A LaTeX CV generator from YAML",
    rich_markup_mode=(  # see https://typer.tiangolo.com/tutorial/commands/help/#rich-markdown
        "markdown"
    ),
)


@app.command(help="Render a YAML input file")
@uc.handle_exceptions
def render(
    input_file_path: Annotated[
        pathlib.Path,
        typer.Argument(help="Name of the YAML input file"),
    ],
):
    """Generate a LaTeX CV from a YAML input file.

    Args:
        input_file (str): Name of the YAML input file
    """
    uc.welcome()
    output_directory = input_file_path.parent / "rendercv_output"

    with uc.LiveProgressReporter(number_of_steps=3) as progress:
        progress.start_a_step("Reading and validating the input file")
        data_model = dm.read_input_file(input_file_path)
        progress.finish_the_current_step()

        progress.start_a_step("Generating the LaTeX file")
        latex_file_path = r.generate_latex_file(data_model, output_directory)
        progress.finish_the_current_step()

        progress.start_a_step("Rendering the LaTeX file to a PDF")
        r.latex_to_pdf(latex_file_path)
        progress.finish_the_current_step()


@app.command(help="Generate a YAML input file to get started.")
def new(full_name: Annotated[str, typer.Argument(help="Your full name")]):
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
    with open(file_path, "w") as file:
        yaml.dump(data_model_as_dictionary, file)

    uc.information(f"Your RenderCV input file has been created at {file_path}!")


def cli():
    """Start the CLI application.

    This function is the entry point of the RenderCV. The execution starts here.
    """
    app()
