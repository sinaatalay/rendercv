import json
import pathlib
from typing import Annotated

import typer
from rich.prompt import Prompt
import ruamel.yaml
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


from .user_communicator import handle_exceptions, welcome, LiveProgress
from . import data_models as dm
from . import renderer as r


app = typer.Typer(
    callback=welcome(),
    help="RenderCV - A LateX CV generator from YAML",
    rich_markup_mode=(  # see https://typer.tiangolo.com/tutorial/commands/help/#rich-markdown
        "markdown"
    ),
)


@app.command(help="Render a YAML input file")
@handle_exceptions
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
    output_directory = input_file_path.parent / "rendercv_output"

    number_of_steps = 3

    class TimeElapsedColumn(ProgressColumn):
        """Renders time elapsed."""

        def render(self, task: "Task") -> Text:
            """Show time elapsed."""
            elapsed = task.finished_time if task.finished else task.elapsed
            if elapsed is None:
                return Text("--.-", style="progress.elapsed")
            delta = f"{elapsed:.1f} s"
            return Text(str(delta), style="progress.elapsed")

    step_progress = Progress(TimeElapsedColumn(), TextColumn("{task.description}"))

    # overall progress bar
    overall_progress = Progress(
        TimeElapsedColumn(),
        BarColumn(),
        TextColumn("{task.description}"),
    )

    # group of progress bars;
    # some are always visible, others will disappear when progress is complete
    group = Group(
        Panel(Group(step_progress)),
        overall_progress,
    )

    overall_task_id = overall_progress.add_task("", total=number_of_steps)

    overall_progress.update(
        overall_task_id,
        description=f"[bold #AAAAAA](0 out of 3 steps finished)",
    )
    with LiveProgress(
        step_progress, overall_progress, group, overall_task_id
    ) as progress:
        progress.start_a_step("Reading the input file")
        data_model = dm.read_input_file(input_file_path)
        progress.finish_the_current_step()
        latex_file_path = r.generate_latex_file(data_model, output_directory)
        r.latex_to_pdf(latex_file_path)


@app.command(help="Generate a YAML input file to get started.")
def new():
    """ """
    name = Prompt.ask("What is your name?")
    data_model = dm.get_a_sample_data_model(name)
    file_name = f"{name.replace(' ', '_')}_CV.yaml"
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


def cli():
    """Start the CLI application.

    This function is the entry point for RenderCV.
    """
    app()


if __name__ == "__main__":
    cli()
