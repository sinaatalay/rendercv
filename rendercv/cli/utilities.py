"""
The `rendercv.cli.utilities` module contains utility functions that are required by CLI.
"""

import json
import pathlib
import re
import shutil
import urllib.request
from typing import Optional

import pydantic
import typer

from .. import data


def string_to_file_path(string: Optional[str]) -> Optional[pathlib.Path]:
    """Convert a string to a pathlib.Path object. If the string is None, then return
    None.

    Args:
        string (str): The string to be converted to a pathlib.Path object.
    Returns:
        pathlib.Path: The pathlib.Path object.
    """
    if string is not None:
        return pathlib.Path(string).absolute()
    else:
        return None


def set_or_update_a_value(
    data_model: pydantic.BaseModel,
    key: str,
    value: str,
    sub_model: Optional[pydantic.BaseModel | dict | list] = None,
) -> pydantic.BaseModel:  # type: ignore
    """Set or update a value in a data model for a specific key. For example, a key can
    be `cv.sections.education.3.institution` and the value can be "Bogazici University".

    Args:
        data_model (pydantic.BaseModel | dict | list): The data model to set or update
            the value.
        key (str): The key to set or update the value.
        value (Any): The value to set or update.
        sub_model (pydantic.BaseModel | dict | list, optional): The sub model to set or
            update the value. This is used for recursive calls. When the value is set
            to a sub model, the original data model is validated. Defaults to None.
    """
    # Recursively call this function until the last key is reached:

    # Rename `sections` with `sections_input` since the key is `sections` is an alias:
    key = key.replace("sections.", "sections_input.")
    keys = key.split(".")

    if sub_model is not None:
        model = sub_model
    else:
        model = data_model

    if len(keys) == 1:
        # Set the value:
        if value.startswith("{") and value.endswith("}"):
            # Allow users to assign dictionaries:
            value = eval(value)
        elif value.startswith("[") and value.endswith("]"):
            # Allow users to assign lists:
            value = eval(value)

        if isinstance(model, pydantic.BaseModel):
            setattr(model, key, value)
        elif isinstance(model, dict):
            model[key] = value
        elif isinstance(model, list):
            model[int(key)] = value
        else:
            raise ValueError(
                "The data model should be either a Pydantic data model, dictionary, or"
                " list.",
            )

        data_model = type(data_model).model_validate(
            (data_model.model_dump(by_alias=True))
        )
        return data_model
    else:
        # get the first key and call the function with remaining keys:
        first_key = keys[0]
        key = ".".join(keys[1:])
        if isinstance(model, pydantic.BaseModel):
            sub_model = getattr(model, first_key)
        elif isinstance(model, dict):
            sub_model = model[first_key]
        elif isinstance(model, list):
            sub_model = model[int(first_key)]
        else:
            raise ValueError(
                "The data model should be either a Pydantic data model, dictionary, or"
                " list.",
            )

        set_or_update_a_value(data_model, key, value, sub_model)


def set_or_update_values(
    data_model: data.RenderCVDataModel,
    key_and_values: dict[str, str],
) -> data.RenderCVDataModel:
    """Set or update values in `RenderCVDataModel` for specific keys. It uses the
    `set_or_update_a_value` function to set or update the values.

    Args:
        data_model (data.RenderCVDataModel): The data model to set or update the values.
        key_and_values (dict[str, str]): The key and value pairs to set or update.
    """
    for key, value in key_and_values.items():
        try:
            data_model = set_or_update_a_value(data_model, key, value)  # type: ignore
        except pydantic.ValidationError as e:
            raise e
        except (ValueError, KeyError, IndexError, AttributeError):
            raise ValueError(f'The key "{key}" does not exist in the data model!')

    return data_model


def copy_files(paths: list[pathlib.Path] | pathlib.Path, new_path: pathlib.Path):
    """Copy files to the given path. If there are multiple files, then rename the new
    path by adding a number to the end of the path.

    Args:
        paths (list[pathlib.Path]): The paths of the files to be copied.
        new_path (pathlib.Path): The path to copy the files to.
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
    sent from `rendercv.data.reader.read_input_file`. If it is, then return the custom
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
) -> Optional[pathlib.Path]:
    """Copy one of the folders found in `rendercv.templates` to `copy_to`.

    Args:
        folder_name (str): The name of the folder to be copied.
        copy_to (pathlib.Path): The path to copy the folder to.
    Returns:
        Optional[pathlib.Path]: The path to the copied folder.
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
