"""
The `rendercv.data.reader` module contains the functions that are used to read the input
file (YAML or JSON) and return them as an instance of `RenderCVDataModel`, which is a
Pydantic data model of RenderCV's data format.
"""

import pathlib

import ruamel.yaml

from . import models


def read_a_yaml_file(file_path_or_contents: pathlib.Path | str) -> dict:
    """Read a YAML file and return its content as a dictionary. The YAML file can be
    given as a path to the file or as the contents of the file as a string.

    Args:
        file_path_or_contents: The path to the YAML file or the contents of the YAML
            file as a string.

    Returns:
        The content of the YAML file as a dictionary.
    """
    if isinstance(file_path_or_contents, pathlib.Path):
        # Check if the file exists:
        if not file_path_or_contents.exists():
            raise FileNotFoundError(
                f"The input file [magenta]{file_path_or_contents}[/magenta] doesn't"
                " exist!"
            )

        # Check the file extension:
        accepted_extensions = [".yaml", ".yml", ".json", ".json5"]
        if file_path_or_contents.suffix not in accepted_extensions:
            user_friendly_accepted_extensions = [
                f"[green]{ext}[/green]" for ext in accepted_extensions
            ]
            user_friendly_accepted_extensions = ", ".join(
                user_friendly_accepted_extensions
            )
            raise ValueError(
                "The input file should have one of the following extensions:"
                f" {user_friendly_accepted_extensions}. The input file is"
                f" [magenta]{file_path_or_contents}[/magenta]."
            )

        file_content = file_path_or_contents.read_text(encoding="utf-8")
    else:
        file_content = file_path_or_contents

    yaml_as_a_dictionary: dict = ruamel.yaml.YAML().load(file_content)

    return yaml_as_a_dictionary


def validate_input_dictionary_and_return_the_data_model(
    input_dictionary: dict,
) -> models.RenderCVDataModel:
    """Validate the input dictionary by creating an instance of `RenderCVDataModel`,
    which is a Pydantic data model of RenderCV's data format.

    Args:
        input_dictionary: The input dictionary.

    Returns:
        The data model.
    """

    # Validate the parsed dictionary by creating an instance of RenderCVDataModel:
    rendercv_data_model = models.RenderCVDataModel(**input_dictionary)

    return rendercv_data_model


def read_input_file(
    file_path_or_contents: pathlib.Path | str,
) -> models.RenderCVDataModel:
    """Read the input file (YAML or JSON) and return them as an instance of
    `RenderCVDataModel`, which is a Pydantic data model of RenderCV's data format.

    Args:
        file_path_or_contents: The path to the input file or the contents of the input
            file as a string.

    Returns:
        The data model.
    """
    input_as_dictionary = read_a_yaml_file(file_path_or_contents)

    rendercv_data_model = validate_input_dictionary_and_return_the_data_model(
        input_as_dictionary
    )

    return rendercv_data_model
