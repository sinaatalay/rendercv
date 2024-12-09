"""
The `rendercv.cli.utilities` module contains utility functions that are required by CLI.
"""

import inspect
import json
import os
import pathlib
import re
import shutil
import sys
import time
import urllib.request
from collections.abc import Callable
from typing import Any, Optional

import typer
import watchdog.events
import watchdog.observers

from .. import data, renderer
from . import printer


def set_or_update_a_value(
    dictionary: dict,
    key: str,
    value: str,
    sub_dictionary: Optional[dict | list] = None,
) -> dict:  # type: ignore
    """Set or update a value in a dictionary for the given key. For example, a key can
    be `cv.sections.education.3.institution` and the value can be "Bogazici University".

    Args:
        dictionary: The dictionary to set or update the value.
        key: The key to set or update the value.
        value: The value to set or update.
        sub_dictionary: The sub dictionary to set or update the value. This is used for
            recursive calls. Defaults to None.
    """
    # Recursively call this function until the last key is reached:

    keys = key.split(".")

    updated_dict = sub_dictionary if sub_dictionary is not None else dictionary

    if len(keys) == 1:
        # Set the value:
        if value.startswith("{") and value.endswith("}"):
            # Allow users to assign dictionaries:
            value = eval(value)
        elif value.startswith("[") and value.endswith("]"):
            # Allow users to assign lists:
            value = eval(value)

        if isinstance(updated_dict, list):
            key = int(key)  # type: ignore

        updated_dict[key] = value  # type: ignore

    else:
        # get the first key and call the function with remaining keys:
        first_key = keys[0]
        key = ".".join(keys[1:])

        if isinstance(updated_dict, list):
            first_key = int(first_key)

        if isinstance(first_key, int) or first_key in updated_dict:
            # Key exists, get the sub dictionary:
            sub_dictionary = updated_dict[first_key]  # type: ignore
        else:
            # Key does not exist, create a new sub dictionary:
            sub_dictionary = {}

        updated_sub_dict = set_or_update_a_value(dictionary, key, value, sub_dictionary)
        updated_dict[first_key] = updated_sub_dict  # type: ignore

    return updated_dict  # type: ignore


def set_or_update_values(
    dictionary: dict,
    key_and_values: dict[str, str],
) -> dict:
    """Set or update values in a dictionary for the given keys. It uses the
    `set_or_update_a_value` function to set or update the values.

    Args:
        dictionary: The dictionary to set or update the values.
        key_and_values: The key and value pairs to set or update.
    """
    for key, value in key_and_values.items():
        dictionary = set_or_update_a_value(dictionary, key, value)  # type: ignore

    return dictionary


def copy_files(paths: list[pathlib.Path] | pathlib.Path, new_path: pathlib.Path):
    """Copy files to the given path. If there are multiple files, then rename the new
    path by adding a number to the end of the path.

    Args:
        paths: The paths of the files to be copied.
        new_path: The path to copy the files to.
    """
    if isinstance(paths, pathlib.Path):
        paths = [paths]

    if len(paths) == 1:
        shutil.copy2(paths[0], new_path)
    else:
        for i, file_path in enumerate(paths):
            # append a number to the end of the path:
            number = i + 1
            png_path_with_page_number = (
                pathlib.Path(new_path).parent
                / f"{pathlib.Path(new_path).stem}_{number}.png"
            )
            shutil.copy2(file_path, png_path_with_page_number)


def get_latest_version_number_from_pypi() -> Optional[str]:
    """Get the latest version number of RenderCV from PyPI.

    Example:
        ```python
        get_latest_version_number_from_pypi()
        ```
        returns
        `"1.1"`

    Returns:
        The latest version number of RenderCV from PyPI. Returns None if the version
        number cannot be fetched.
    """
    version = None
    url = "https://pypi.org/pypi/rendercv/json"
    try:
        with urllib.request.urlopen(url) as response:
            data = response.read()
            encoding = response.info().get_content_charset("utf-8")
            json_data = json.loads(data.decode(encoding))
            version = json_data["info"]["version"]
    except Exception:
        pass

    return version


def get_error_message_and_location_and_value_from_a_custom_error(
    error_string: str,
) -> tuple[Optional[str], Optional[str], Optional[str]]:
    """Look at a string and figure out if it's a custom error message that has been
    sent from `rendercv.data.reader.read_input_file`. If it is, then return the custom
    message, location, and the input value.

    This is done because sometimes we raise an error about a specific field in the model
    validation level, but Pydantic doesn't give us the exact location of the error
    because it's a model-level error. So, we raise a custom error with three string
    arguments: message, location, and input value. Those arguments then combined into a
    string by Python. This function is used to parse that custom error message and
    return the three values.

    Args:
        error_string: The error message.

    Returns:
        The custom message, location, and the input value.
    """
    pattern = r"""\(['"](.*)['"], '(.*)', '(.*)'\)"""
    match = re.search(pattern, error_string)
    if match:
        return match.group(1), match.group(2), match.group(3)
    return None, None, None


def copy_templates(
    folder_name: str,
    copy_to: pathlib.Path,
    new_folder_name: Optional[str] = None,
) -> Optional[pathlib.Path]:
    """Copy one of the folders found in `rendercv.templates` to `copy_to`.

    Args:
        folder_name: The name of the folder to be copied.
        copy_to: The path to copy the folder to.

    Returns:
        The path to the copied folder.
    """
    # copy the package's theme files to the current directory
    template_directory = pathlib.Path(__file__).parent.parent / "themes" / folder_name
    if new_folder_name:
        destination = copy_to / new_folder_name
    else:
        destination = copy_to / folder_name

    if destination.exists():
        return None
    # copy the folder but don't include __init__.py:
    shutil.copytree(
        template_directory,
        destination,
        ignore=shutil.ignore_patterns("__init__.py", "__pycache__"),
    )

    return destination


def parse_render_command_override_arguments(
    extra_arguments: typer.Context,
) -> dict["str", "str"]:
    """Parse extra arguments given to the `render` command as data model key and value
    pairs and return them as a dictionary.

    Args:
        extra_arguments: The extra arguments context.

    Returns:
        The key and value pairs.
    """
    key_and_values: dict[str, str] = {}

    # `extra_arguments.args` is a list of arbitrary arguments that haven't been
    # specified in `cli_render_command` function's definition. They are used to allow
    # users to edit their data model in CLI. The elements with even indexes in this list
    # are keys that start with double dashed, such as
    # `--cv.sections.education.0.institution`. The following elements are the
    # corresponding values of the key, such as `"Bogazici University"`. The for loop
    # below parses `ctx.args` accordingly.

    if len(extra_arguments.args) % 2 != 0:
        message = (
            "There is a problem with the extra arguments! Each key should have a"
            " corresponding value."
        )
        raise ValueError(message)

    for i in range(0, len(extra_arguments.args), 2):
        key = extra_arguments.args[i]
        value = extra_arguments.args[i + 1]
        if not key.startswith("--"):
            message = f"The key ({key}) should start with double dashes!"
            raise ValueError(message)

        key = key.replace("--", "")

        key_and_values[key] = value

    return key_and_values


def get_default_render_command_cli_arguments() -> dict:
    """Get the default values of the `render` command's CLI arguments.

    Returns:
        The default values of the `render` command's CLI arguments.
    """
    from .commands import cli_command_render

    sig = inspect.signature(cli_command_render)
    return {
        k: v.default
        for k, v in sig.parameters.items()
        if v.default is not inspect.Parameter.empty
    }


def update_render_command_settings_of_the_input_file(
    input_file_as_a_dict: dict,
    render_command_cli_arguments: dict,
) -> dict:
    """Update the input file's `rendercv_settings.render_command` field with the given
    values (only the non-default ones) of the `render` command's CLI arguments.

    Args:
        input_file_as_a_dict: The input file as a dictionary.
        render_command_cli_arguments: The command line arguments of the `render`
            command.

    Returns:
        The updated input file as a dictionary.
    """
    default_render_command_cli_arguments = get_default_render_command_cli_arguments()

    # Loop through `render_command_cli_arguments` and if the value is not the default
    # value, overwrite the value in the input file's `rendercv_settings.render_command`
    # field. If the field is the default value, check if it exists in the input file.
    # If it doesn't exist, add it to the input file. If it exists, don't do anything.
    if "rendercv_settings" not in input_file_as_a_dict:
        input_file_as_a_dict["rendercv_settings"] = {}

    if "render_command" not in input_file_as_a_dict["rendercv_settings"]:
        input_file_as_a_dict["rendercv_settings"]["render_command"] = {}

    render_command_field = input_file_as_a_dict["rendercv_settings"]["render_command"]
    for key, value in render_command_cli_arguments.items():
        if (
            value != default_render_command_cli_arguments[key]
            or key not in render_command_field
        ):
            render_command_field[key] = value

    input_file_as_a_dict["rendercv_settings"]["render_command"] = render_command_field

    return input_file_as_a_dict


def run_rendercv_with_printer(
    input_file_as_a_dict: dict,
    working_directory: pathlib.Path,
    input_file_path: pathlib.Path,
):
    """Run RenderCV with a live progress reporter. Working dictionary is where the
    output files will be saved. Input file path is required for accessing the template
    overrides.

    Args:
        input_file_as_a_dict: The input file as a dictionary.
        working_directory: The working directory where the output files will be saved.
        input_file_path: The path of the input file.
    """
    render_command_settings_dict = input_file_as_a_dict["rendercv_settings"][
        "render_command"
    ]

    # Compute the number of steps
    # 1. Validate the input file.
    # 2. Create the LaTeX file.
    # 3. Render PDF from LaTeX.
    # 4. Render PNGs from PDF.
    # 5. Create the Markdown file.
    # 6. Render HTML from Markdown.
    number_of_steps = 6
    if render_command_settings_dict["dont_generate_png"]:
        number_of_steps -= 1

    if render_command_settings_dict["dont_generate_markdown"]:
        number_of_steps -= 2
    else:
        if render_command_settings_dict["dont_generate_html"]:
            number_of_steps -= 1

    with printer.LiveProgressReporter(number_of_steps=number_of_steps) as progress:
        progress.start_a_step("Validating the input file")

        data_model = data.validate_input_dictionary_and_return_the_data_model(
            input_file_as_a_dict,
            context={"input_file_directory": input_file_path.parent},
        )

        # Change the current working directory to the input file's directory (because
        # the template overrides are looked up in the current working directory). The
        # output files will be in the original working directory. It should be done
        # after the input file is validated (because of the rendercv_settings).
        os.chdir(input_file_path.parent)

        render_command_settings: data.models.RenderCommandSettings = (
            data_model.rendercv_settings.render_command  # type: ignore
        )  # type: ignore
        output_directory = (
            working_directory / render_command_settings.output_folder_name  # type: ignore
        )

        progress.finish_the_current_step()

        progress.start_a_step("Generating the LaTeX file")

        latex_file_path_in_output_folder = (
            renderer.create_a_latex_file_and_copy_theme_files(
                data_model, output_directory
            )
        )
        if render_command_settings.latex_path:
            copy_files(
                latex_file_path_in_output_folder,
                render_command_settings.latex_path,
            )

        progress.finish_the_current_step()

        progress.start_a_step("Rendering the LaTeX file to a PDF")

        pdf_file_path_in_output_folder = renderer.render_a_pdf_from_latex(
            latex_file_path_in_output_folder,
            render_command_settings.use_local_latex_command,
        )
        if render_command_settings.pdf_path:
            copy_files(
                pdf_file_path_in_output_folder,
                render_command_settings.pdf_path,
            )

        progress.finish_the_current_step()

        if not render_command_settings.dont_generate_png:
            progress.start_a_step("Rendering PNG files from the PDF")

            png_file_paths_in_output_folder = renderer.render_pngs_from_pdf(
                pdf_file_path_in_output_folder
            )
            if render_command_settings.png_path:
                copy_files(
                    png_file_paths_in_output_folder,
                    render_command_settings.png_path,
                )

            progress.finish_the_current_step()

        if not render_command_settings.dont_generate_markdown:
            progress.start_a_step("Generating the Markdown file")

            markdown_file_path_in_output_folder = renderer.create_a_markdown_file(
                data_model, output_directory
            )
            if render_command_settings.markdown_path:
                copy_files(
                    markdown_file_path_in_output_folder,
                    render_command_settings.markdown_path,
                )

            progress.finish_the_current_step()

            if not render_command_settings.dont_generate_html:
                progress.start_a_step(
                    "Rendering the Markdown file to a HTML (for Grammarly)"
                )

                html_file_path_in_output_folder = renderer.render_an_html_from_markdown(
                    markdown_file_path_in_output_folder
                )
                if render_command_settings.html_path:
                    copy_files(
                        html_file_path_in_output_folder,
                        render_command_settings.html_path,
                    )

                progress.finish_the_current_step()


def run_a_function_if_a_file_changes(file_path: pathlib.Path, function: Callable):
    """Watch the file located at `file_path` and call the `function` when the file is
    modified. The function should not take any arguments.

    Args:
        file_path (pathlib.Path): The path of the file to watch for.
        function (Callable): The function to be called on file modification.
    """
    # Run the function immediately for the first time
    function()

    path_to_watch = str(file_path.absolute())
    if sys.platform == "win32":
        # Windows does not support single file watching, so we watch the directory
        path_to_watch = str(file_path.parent.absolute())

    class EventHandler(watchdog.events.FileSystemEventHandler):
        def __init__(self, function: Callable):
            super().__init__()
            self.function_to_call = function

        def on_modified(self, event: watchdog.events.FileModifiedEvent) -> None:
            if sys.platform == "win32":
                # Windows does not support single file watching, so we watch the
                # directory
                if event.src_path != str(file_path.absolute()):
                    return

            printer.information(
                "\n\nThe input file has been updated. Re-running RenderCV..."
            )
            self.function_to_call()

    event_handler = EventHandler(function)

    observer = watchdog.observers.Observer()
    observer.schedule(event_handler, path_to_watch, recursive=True)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()


def read_and_construct_the_input(
    input_file_path: pathlib.Path,
    cli_render_arguments: dict[str, Any],
    extra_data_model_override_arguments: Optional[typer.Context] = None,
) -> dict:
    """Read RenderCV YAML files and CLI to construct the user's input as a dictionary.
    Input file is read, CLI arguments override the input file, and individual design,
    locale catalog, etc. files are read if they are provided.

    Args:
        input_file_path: The path of the input file.
        cli_render_arguments: The command line arguments of the `render` command.
        extra_data_model_override_arguments: The extra arguments context. Defaults to
            None.

    Returns:
        The input of the user as a dictionary.
    """
    input_file_as_a_dict = data.read_a_yaml_file(input_file_path)

    # Read individual `design`, `locale_catalog`, etc. files if they are provided in the
    # input file:
    for field in data.rendercv_data_model_fields:
        if field in cli_render_arguments and cli_render_arguments[field] is not None:
            yaml_path = pathlib.Path(cli_render_arguments[field]).absolute()
            yaml_file_as_a_dict = data.read_a_yaml_file(yaml_path)
            input_file_as_a_dict[field] = yaml_file_as_a_dict[field]

    # Update the input file if there are extra override arguments (for example,
    # --cv.phone "123-456-7890"):
    if extra_data_model_override_arguments:
        key_and_values = parse_render_command_override_arguments(
            extra_data_model_override_arguments
        )
        input_file_as_a_dict = set_or_update_values(
            input_file_as_a_dict, key_and_values
        )

    # If non-default CLI arguments are provided, override the
    # `rendercv_settings.render_command`:
    return update_render_command_settings_of_the_input_file(
        input_file_as_a_dict, cli_render_arguments
    )
