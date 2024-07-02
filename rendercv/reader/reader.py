"""
The `rendercv.data_models.generators` module contains the functions that are used to
generate a sample YAML input file and the JSON schema of RenderCV based on the data
models defined in `rendercv.data_models.models`.
"""

import json
import pathlib
from typing import Any, Optional
import io
import pydantic

import ruamel.yaml

from . import models


def dictionary_to_yaml(dictionary: dict[str, Any]):
    """Converts a dictionary to a YAML string.

    Args:
        dictionary (dict[str, Any]): The dictionary to be converted to YAML.
    Returns:
        str: The YAML string.
    """
    yaml_object = ruamel.yaml.YAML()
    yaml_object.encoding = "utf-8"
    yaml_object.width = 60
    yaml_object.indent(mapping=2, sequence=4, offset=2)
    with io.StringIO() as string_stream:
        yaml_object.dump(dictionary, string_stream)
        yaml_string = string_stream.getvalue()
    return yaml_string


def read_a_yaml_file(file_path_or_contents: pathlib.Path) -> dict[str, Any]:
    """Read a YAML file and return its content as a dictionary. The YAML file can be
    given as a path to the file or as the contents of the file as a string.

    Args:
        file_path_or_contents (pathlib.Path): The path to the YAML file or the contents
            of the YAML file as a string.
    Returns:
        dict: The content of the YAML file as a dictionary.
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

    yaml_as_a_dictionary: dict[str, Any] = ruamel.yaml.YAML().load(file_content)

    return yaml_as_a_dictionary


def create_a_sample_data_model(
    name: str = "John Doe", theme: str = "classic"
) -> models.RenderCVDataModel:
    """Return a sample data model for new users to start with.

    Args:
        name (str, optional): The name of the person. Defaults to "John Doe".
    Returns:
        RenderCVDataModel: A sample data model.
    """
    # Check if the theme is valid:
    if theme not in models.available_theme_options:
        available_themes_string = ", ".join(models.available_theme_options.keys())
        raise ValueError(
            f"The theme should be one of the following: {available_themes_string}!"
            f' The provided theme is "{theme}".'
        )

    # read the sample_content.yaml file
    sample_content = pathlib.Path(__file__).parent / "sample_content.yaml"
    sample_content_dictionary = read_a_yaml_file(sample_content)
    cv = models.CurriculumVitae(**sample_content_dictionary)

    # Update the name:
    name = name.encode().decode("unicode-escape")
    cv.name = name

    design = models.available_theme_options[theme](theme=theme)

    return models.RenderCVDataModel(cv=cv, design=design)


def create_a_sample_yaml_input_file(
    input_file_path: Optional[pathlib.Path] = None,
    name: str = "John Doe",
    theme: str = "classic",
) -> str:
    """Create a sample YAML input file and return it as a string. If the input file path
    is provided, then also save the contents to the file.

    Args:
        input_file_path (pathlib.Path, optional): The path to save the input file.
            Defaults to None.
        name (str, optional): The name of the person. Defaults to "John Doe".
        theme (str, optional): The theme of the CV. Defaults to "classic".
    Returns:
        str: The sample YAML input file as a string.
    """
    data_model = create_a_sample_data_model(name=name, theme=theme)

    # Instead of getting the dictionary with data_model.model_dump() directly, we
    # convert it to JSON and then to a dictionary. Because the YAML library we are
    # using sometimes has problems with the dictionary returned by model_dump().

    # We exclude "cv.sections" because the data model automatically generates them.
    # The user's "cv.sections" input is actually "cv.sections_input" in the data
    # model. It is shown as "cv.sections" in the YAML file because an alias is being
    # used. If"cv.sections" were not excluded, the automatically generated
    # "cv.sections" would overwrite the "cv.sections_input". "cv.sections" are
    # automatically generated from "cv.sections_input" to make the templating
    # process easier. "cv.sections_input" exists for the convenience of the user.
    data_model_as_json = data_model.model_dump_json(
        exclude_none=True, by_alias=True, exclude={"cv": {"sections"}}
    )
    data_model_as_dictionary = json.loads(data_model_as_json)

    yaml_string = dictionary_to_yaml(data_model_as_dictionary)

    if input_file_path is not None:
        input_file_path.write_text(yaml_string, encoding="utf-8")

    return yaml_string


def generate_json_schema() -> dict[str, Any]:
    """Generate the JSON schema of RenderCV.

    JSON schema is generated for the users to make it easier for them to write the input
    file. The JSON Schema of RenderCV is saved in the `docs` directory of the repository
    and distributed to the users with the
    [JSON Schema Store](https://www.schemastore.org/).

    Returns:
        dict: The JSON schema of RenderCV.
    """

    class RenderCVSchemaGenerator(pydantic.json_schema.GenerateJsonSchema):
        def generate(self, schema, mode="validation"):  # type: ignore
            json_schema = super().generate(schema, mode=mode)

            # Basic information about the schema:
            json_schema["title"] = "RenderCV"
            json_schema["description"] = "RenderCV data model."
            json_schema["$id"] = (
                "https://raw.githubusercontent.com/sinaatalay/rendercv/main/schema.json"
            )
            json_schema["$schema"] = "http://json-schema.org/draft-07/schema#"

            # Loop through $defs and remove docstring descriptions and fix optional
            # fields
            for object_name, value in json_schema["$defs"].items():
                # Don't allow additional properties
                value["additionalProperties"] = False

                # If a type is optional, then Pydantic sets the type to a list of two
                # types, one of which is null. The null type can be removed since we
                # already have the required field. Moreover, we would like to warn
                # users if they provide null values. They can remove the fields if they
                # don't want to provide them.
                null_type_dict = {
                    "type": "null",
                }
                for field_name, field in value["properties"].items():
                    if "anyOf" in field:
                        if null_type_dict in field["anyOf"]:
                            field["anyOf"].remove(null_type_dict)

                        field["oneOf"] = field["anyOf"]
                        del field["anyOf"]

            return json_schema

    schema = models.RenderCVDataModel.model_json_schema(
        schema_generator=RenderCVSchemaGenerator
    )

    return schema


def generate_json_schema_file(json_schema_path: pathlib.Path):
    """Generate the JSON schema of RenderCV and save it to a file.

    Args:
        json_schema_path (pathlib.Path): The path to save the JSON schema.
    """
    schema = generate_json_schema()
    schema_json = json.dumps(schema, indent=2, ensure_ascii=False)
    json_schema_path.write_text(schema_json, encoding="utf-8")


def set_or_update_a_value(
    data_model: pydantic.BaseModel | dict | list,
    key: str,
    value: str,
    sub_model: pydantic.BaseModel | dict | list = None,
):
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


def read_input_file(
    file_path_or_contents: pathlib.Path | str,
) -> models.RenderCVDataModel:
    """Read the input file (YAML or JSON) and return them as an instance of
    `RenderCVDataModel`, which is a Pydantic data model of RenderCV's data format.

    Args:
        file_path_or_contents (str): The path to the input file or the contents of the
            input file as a string.

    Returns:
        RenderCVDataModel: The data models with $\\LaTeX$ and Markdown strings.
    """
    input_as_dictionary = read_a_yaml_file(file_path_or_contents)

    # Validate the parsed dictionary by creating an instance of RenderCVDataModel:
    rendercv_data_model = models.RenderCVDataModel(**input_as_dictionary)

    return rendercv_data_model
