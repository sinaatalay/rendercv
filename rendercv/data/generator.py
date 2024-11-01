"""
The `rendercv.data.generator` module contains all the functions for generating the JSON
Schema of the input data format and a sample YAML input file.
"""

import io
import json
import pathlib
from typing import Optional

import pydantic
import ruamel.yaml

from . import models, reader


def dictionary_to_yaml(dictionary: dict) -> str:
    """Converts a dictionary to a YAML string.

    Args:
        dictionary: The dictionary to be converted to YAML.

    Returns:
        The YAML string.
    """
    yaml_object = ruamel.yaml.YAML()
    yaml_object.encoding = "utf-8"
    yaml_object.width = 60
    yaml_object.indent(mapping=2, sequence=4, offset=2)
    with io.StringIO() as string_stream:
        yaml_object.dump(dictionary, string_stream)
        yaml_string = string_stream.getvalue()

    return yaml_string


def create_a_sample_data_model(
    name: str = "John Doe", theme: str = "classic"
) -> models.RenderCVDataModel:
    """Return a sample data model for new users to start with.

    Args:
        name: The name of the person. Defaults to "John Doe".

    Returns:
        A sample data model.
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
    sample_content_dictionary = reader.read_a_yaml_file(sample_content)
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
        input_file_path: The path to save the input file. Defaults to None.
        name: The name of the person. Defaults to "John Doe".
        theme: The theme of the CV. Defaults to "classic".

    Returns:
        The sample YAML input file as a string.
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


def generate_json_schema() -> dict:
    """Generate the JSON schema of RenderCV.

    JSON schema is generated for the users to make it easier for them to write the input
    file. The JSON Schema of RenderCV is saved in the root directory of the repository
    and distributed to the users with the
    [JSON Schema Store](https://www.schemastore.org/).

    Returns:
        The JSON schema of RenderCV.
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

            # Currently, YAML extension in VS Code doesn't work properly with the
            # `ListOfEntries` objects. For the best user experience, we will update
            # the JSON Schema. If YAML extension in VS Code starts to work properly,
            # then we should remove the following code for the correct JSON Schema.
            ListOfEntriesForJsonSchema = list[models.Entry]
            list_of_entries_json_schema = pydantic.TypeAdapter(
                ListOfEntriesForJsonSchema
            ).json_schema()
            del list_of_entries_json_schema["$defs"]

            # Update the JSON Schema:
            json_schema["$defs"]["CurriculumVitae"]["properties"]["sections"]["oneOf"][
                0
            ]["additionalProperties"] = list_of_entries_json_schema

            return json_schema

    schema = models.RenderCVDataModel.model_json_schema(
        schema_generator=RenderCVSchemaGenerator
    )

    return schema


def generate_json_schema_file(json_schema_path: pathlib.Path):
    """Generate the JSON schema of RenderCV and save it to a file.

    Args:
        json_schema_path: The path to save the JSON schema.
    """
    schema = generate_json_schema()
    schema_json = json.dumps(schema, indent=2, ensure_ascii=False)
    json_schema_path.write_text(schema_json, encoding="utf-8")
