"""
The `rendercv.data_models.generators` module contains the functions that are used to
generate a sample YAML input file and the JSON schema of RenderCV based on the data
models defined in `rendercv.data_models.models`.
"""

import json
import pathlib
from typing import Any, Optional

import pydantic

from ..themes.classic import ClassicThemeOptions
from . import models
from . import utilities as utils
from . import validators as val


def get_a_sample_data_model(
    name: str = "John Doe", theme: str = "classic"
) -> models.RenderCVDataModel:
    """Return a sample data model for new users to start with.

    Args:
        name (str, optional): The name of the person. Defaults to "John Doe".
    Returns:
        RenderCVDataModel: A sample data model.
    """
    # Check if the theme is valid:
    if theme not in models.available_themes:
        available_themes_string = ", ".join(models.available_themes)
        raise ValueError(
            f"The theme should be one of the following: {available_themes_string}!"
            f' The provided theme is "{theme}".'
        )

    name = name.encode().decode("unicode-escape")

    sections = {
        "welcome_to_RenderCV!": [
            (
                "[RenderCV](https://github.com/sinaatalay/rendercv) is a LaTeX-based"
                " CV/resume framework. It allows you to create a high-quality CV or"
                " resume as a PDF file from a YAML file, with **Markdown syntax"
                " support** and **complete control over the LaTeX code**."
            ),
            (
                "The boilerplate content is taken from"
                " [here](https://github.com/dnl-blkv/mcdowell-cv), where a"
                " *clean and tidy CV* pattern is proposed by"
                " **[Gayle Laakmann McDowell](https://www.gayle.com/)**."
            ),
        ],
        "quick_guide": [
            models.BulletEntry(
                bullet=(
                    "Each section title is arbitrary, and each section contains a list"
                    " of entries."
                ),
            ),
            models.BulletEntry(
                bullet=(
                    "There are 7 unique entry types: *models.BulletEntry*, *TextEntry*,"
                    " *models.EducationEntry*, *models.ExperienceEntry*,"
                    " *models.NormalEntry*, *models.PublicationEntry*, and"
                    " *models.OneLineEntry*."
                ),
            ),
            models.BulletEntry(
                bullet=(
                    "Select a section title, pick an entry type, and start writing your"
                    " section!"
                )
            ),
            models.BulletEntry(
                bullet=(
                    "[Here](https://docs.rendercv.com/user_guide/), you can find a"
                    " comprehensive user guide for RenderCV."
                )
            ),
        ],
        "education": [
            models.EducationEntry(
                institution="University of Pennsylvania",
                area="Computer Science",
                degree="BS",
                start_date="2000-09",
                end_date="2005-05",
                highlights=[
                    "GPA: 3.9/4.0 ([Transcript](https://example.com))",
                    (
                        "**Coursework:** Computer Architecture, Artificial"
                        " Intelligence, Comparison of Learning Algorithms,"
                        " Computational Theory"
                    ),
                ],
            ),
        ],
        "experience": [
            models.ExperienceEntry(
                company="Apple",
                position="Software Engineer",
                start_date="2005-06",
                end_date="2007-08",
                location="Cupertino, CA",
                highlights=[
                    (
                        "Reduced time to render the user's buddy list by 75% by"
                        " implementing a prediction algorithm"
                    ),
                    (
                        "Implemented iChat integration with OS X Spotlight Search by"
                        " creating a tool to extract metadata from saved chat"
                        " transcripts and provide metadata to a system-wide search"
                        " database"
                    ),
                    (
                        "Redesigned chat file format and implemented backward"
                        " compatibility for search"
                    ),
                ],
            ),
            models.ExperienceEntry(
                company="Microsoft",
                position="Lead Student Ambassador",
                start_date="2003-09",
                end_date="2005-04",
                location="Redmond, WA",
                highlights=[
                    (
                        "Promoted to Lead Student Ambassador in the Fall of 2004,"
                        " supervised 10-15 Student Ambassadors"
                    ),
                    (
                        "Created and taught a computer science course, CSE 099:"
                        " Software Design and Development"
                    ),
                ],
            ),
            models.ExperienceEntry(
                company="University of Pennsylvania",
                position="Head Teaching Assistant",
                start_date="2001-10",
                end_date="2003-05",
                location="Philadelphia, PA",
                highlights=[
                    (
                        "Implemented a user interface for the VS open file switcher"
                        " (ctrl-tab) and extended it to tool windows"
                    ),
                    (
                        "Created a service to provide gradient across VS and VS"
                        " add-ins, optimized its performance via caching"
                    ),
                    "Programmer Productivity Research Center (Summers 2001, 2002)",
                    (
                        "Built an app to compute the similarity of all methods in a"
                        " code base, reducing the time from $\\mathcal{O}(n^2)$ to"
                        " $\\mathcal{O}(n \\log n)$"
                    ),
                    (
                        "Created a test case generation tool that creates random XML"
                        " docs from XML Schema"
                    ),
                ],
            ),
            models.ExperienceEntry(
                company="Microsoft",
                position="Software Engineer, Intern",
                start_date="2003-06",
                end_date="2003-08",
                location="Redmond, WA",
                highlights=[
                    (
                        "Automated the extraction and processing of large datasets from"
                        " legacy systems using SQL and Perl scripts"
                    ),
                ],
            ),
        ],
        "publications": [
            models.PublicationEntry(
                title=(
                    "Magneto-Thermal Thin Shell Approximation for 3D Finite Element"
                    " Analysis of No-Insulation Coils"
                ),
                authors=[
                    "Albert Smith",
                    f"***{name}***",
                    "Jane Derry",
                    "Harry Tom",
                    "Frodo Baggins",
                ],
                date="2004-01",
                doi="10.1109/TASC.2023.3340648",
            )
        ],
        "projects": [
            models.NormalEntry(
                name="Multi-User Drawing Tool",
                date="[github.com/name/repo](https://github.com/sinaatalay/rendercv)",
                highlights=[
                    (
                        "Developed an electronic classroom where multiple users can"
                        ' view and simultaneously draw on a "chalkboard" with each'
                        " person's edits synchronized"
                    ),
                    "Tools Used: C++, MFC",
                ],
            ),
            models.NormalEntry(
                name="Synchronized Calendar",
                date="[github.com/name/repo](https://github.com/sinaatalay/rendercv)",
                highlights=[
                    (
                        "Developed a desktop calendar with globally shared and"
                        " synchronized calendars, allowing users to schedule meetings"
                        " with other users"
                    ),
                    "Tools Used: C#, .NET, SQL, XML",
                ],
            ),
            models.NormalEntry(
                name="Operating System",
                date="2002",
                highlights=[
                    (
                        "Developed a UNIX-style OS with a scheduler, file system, text"
                        " editor, and calculator"
                    ),
                    "Tools Used: C",
                ],
            ),
        ],
        "additional_experience_and_awards": [
            models.OneLineEntry(
                label="Instructor (2003-2005)",
                details="Taught 2 full-credit computer science courses",
            ),
            models.OneLineEntry(
                label="Third Prize, Senior Design Project",
                details=(
                    "Awarded 3rd prize for a synchronized calendar project out of 100"
                    " entries"
                ),
            ),
        ],
        "technologies": [
            models.OneLineEntry(
                label="Languages",
                details="C++, C, Java, Objective-C, C#, SQL, JavaScript",
            ),
            models.OneLineEntry(
                label="Software",
                details=".NET, Microsoft SQL Server, XCode, Interface Builder",
            ),
        ],
    }
    cv = models.CurriculumVitae(
        name=name,
        location="Your Location",
        email="youremail@yourdomain.com",
        phone="+905419999999",  # type: ignore
        website="https://yourwebsite.com",  # type: ignore
        social_networks=[
            models.SocialNetwork(network="LinkedIn", username="yourusername"),
            models.SocialNetwork(network="GitHub", username="yourusername"),
        ],
        sections=sections,  # type: ignore
    )

    if theme == "classic":
        design = ClassicThemeOptions(theme="classic", show_timespan_in=["Experience"])
    else:
        design = val.rendercv_design_validator.validate_python({"theme": theme})

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
    data_model = get_a_sample_data_model(name=name, theme=theme)

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

    yaml_string = utils.dictionary_to_yaml(data_model_as_dictionary)

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
