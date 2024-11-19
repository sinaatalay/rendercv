"""
The `rendercv.cli.utilities` module contains utility functions that are required by CLI.
"""

import inspect
import json
import pathlib
import re
import shutil
import urllib.request
from typing import Optional

import typer


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

    if sub_dictionary is not None:
        updated_dict = sub_dictionary
    else:
        updated_dict = dictionary

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
            sub_dictionary = dict()

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
    else:
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
    else:
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
    key_and_values: dict["str", "str"] = dict()

    # `extra_arguments.args` is a list of arbitrary arguments that haven't been
    # specified in `cli_render_command` function's definition. They are used to allow
    # users to edit their data model in CLI. The elements with even indexes in this list
    # are keys that start with double dashed, such as
    # `--cv.sections.education.0.institution`. The following elements are the
    # corresponding values of the key, such as `"Bogazici University"`. The for loop
    # below parses `ctx.args` accordingly.

    if len(extra_arguments.args) % 2 != 0:
        raise ValueError(
            "There is a problem with the extra arguments! Each key should have"
            " a corresponding value."
        )

    for i in range(0, len(extra_arguments.args), 2):
        key = extra_arguments.args[i]
        value = extra_arguments.args[i + 1]
        if not key.startswith("--"):
            raise ValueError(f"The key ({key}) should start with double dashes!")

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
    default_render_command_cli_arguments = {
        k: v.default
        for k, v in sig.parameters.items()
        if v.default is not inspect.Parameter.empty
    }

    return default_render_command_cli_arguments


def update_render_command_settings_of_the_input_file(
    input_file_as_a_dict: dict,
    render_command_cli_arguments: dict,
) -> dict:
    """Update the input file's `rendercv_settings.render_command` field with the given
    (non-default) values of the `render` command's CLI arguments.

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
        input_file_as_a_dict["rendercv_settings"] = dict()

    if "render_command" not in input_file_as_a_dict["rendercv_settings"]:
        input_file_as_a_dict["rendercv_settings"]["render_command"] = dict()

    render_command_field = input_file_as_a_dict["rendercv_settings"]["render_command"]
    for key, value in render_command_cli_arguments.items():
        if value != default_render_command_cli_arguments[key]:
            render_command_field[key] = value
        elif key not in render_command_field:
            render_command_field[key] = value

    input_file_as_a_dict["rendercv_settings"]["render_command"] = render_command_field

    return input_file_as_a_dict
