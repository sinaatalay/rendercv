"""
The `rendercv.cli.utilities` module contains utility functions that are required by CLI.
"""

import json
import pathlib
import re
import shutil
import urllib.request
from typing import Optional

import typer

from .printer import error, warning


def get_latest_version_number_from_pypi() -> Optional[str]:
    """Get the latest version number of RenderCV from PyPI.

    Example:
        ```python
        get_latest_version_number_from_pypi()
        ```
        returns
        `#!python "1.1"`

    Returns:
        Optional[str]: The latest version number of RenderCV from PyPI. Returns None if
            the version number cannot be fetched.
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
    sent from [`data_models.py`](data_models.md). If it is, then return the custom
    message, location, and the input value.

    This is done because sometimes we raise an error about a specific field in the model
    validation level, but Pydantic doesn't give us the exact location of the error
    because it's a model-level error. So, we raise a custom error with three string
    arguments: message, location, and input value. Those arguments then combined into a
    string by Python. This function is used to parse that custom error message and
    return the three values.

    Args:
        error_string (str): The error message.
    Returns:
        tuple[Optional[str], Optional[str], Optional[str]]: The custom message,
            location, and the input value.
    """
    pattern = r"""\(['"](.*)['"], '(.*)', '(.*)'\)"""
    match = re.search(pattern, error_string)
    if match:
        return match.group(1), match.group(2), match.group(3)
    else:
        return None, None, None


def copy_templates(
    folder_name: str,
    copy_to: pathlib.Path,
    new_folder_name: Optional[str] = None,
    suppress_warning: bool = False,
) -> Optional[pathlib.Path]:
    """Copy one of the folders found in `rendercv.templates` to `copy_to`.

    Args:
        folder_name (str): The name of the folder to be copied.
        copy_to (pathlib.Path): The path to copy the folder to.
    Returns:
        Optional[pathlib.Path]: The path to the copied folder.
    """
    # copy the package's theme files to the current directory
    template_directory = pathlib.Path(__file__).parent / "themes" / folder_name
    if new_folder_name:
        destination = copy_to / new_folder_name
    else:
        destination = copy_to / folder_name

    if destination.exists():
        if not suppress_warning:
            if folder_name != "markdown":
                warning(
                    f'The theme folder "{folder_name}" already exists! New theme files'
                    " are not created."
                )
            else:
                warning(
                    'The folder "markdown" already exists! New Markdown files are not'
                    " created."
                )

        return None
    else:
        # copy the folder but don't include __init__.py:
        shutil.copytree(
            template_directory,
            destination,
            ignore=shutil.ignore_patterns("__init__.py"),
        )

        return destination


def parse_render_command_override_arguments(
    extra_arguments: typer.Context,
) -> dict["str", "str"]:
    """Parse extra arguments given to the `render` command as data model key and value
    pairs and return them as a dictionary.

    Args:
        extra_arguments (typer.Context): The extra arguments context.
    Returns:
        dict["str", "str"]: The key and value pairs.
    """
    key_and_values: dict["str", "str"] = dict()

    # `extra_arguments.args` is a list of arbitrary arguments that haven't been
    # specified in `cli_render_command` function's definition. They are used to allow
    # users to edit their data model in CLI. The elements with even indexes in this list
    # are keys that start with double dashed, such as
    # `--cv.sections.education.0.institution`. The following elements are the
    # corresponding values of the key, such as `"Bogazici University"`. The for loop
    # below parses `ctx.args` accordingly.

    if len(extra_arguments.args) % 2 != 0:
        error(
            "There is a problem with the extra arguments! Each key should have"
            " a corresponding value."
        )

    for i in range(0, len(extra_arguments.args), 2):
        key = extra_arguments.args[i]
        value = extra_arguments.args[i + 1]
        if not key.startswith("--"):
            error(f"The key ({key}) should start with double dashes!")

        key = key.replace("--", "")

        key_and_values[key] = value

    return key_and_values
