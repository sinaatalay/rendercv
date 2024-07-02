"""
The `rendercv.data_models.models` module contains all the Pydantic data models used in
RenderCV. These data models define the data format and the usage of computed fields and
the validators.
"""

import functools
from typing import Annotated, Optional
import pathlib

import annotated_types as at
import pydantic
import pydantic_extra_types.phone_numbers as pydantic_phone_numbers

from ..themes.classic import ClassicThemeOptions
from . import computed_fields as cf
from . import field_types
from . import utilities as util
from . import entry_validators
from . import entry_types

# Disable Pydantic warnings:
# warnings.filterwarnings("ignore")

from . import cv_model
from . import design_model
from . import locale_catalog_model


class RenderCVDataModel(entry_types.RenderCVBaseModel):
    """This class binds both the CV and the design information together."""

    cv: cv_model.CurriculumVitae = pydantic.Field(
        title="Curriculum Vitae",
        description="The data of the CV.",
    )
    design: design_model.RenderCVDesign = pydantic.Field(
        default=ClassicThemeOptions(theme="classic"),
        title="Design",
        description=(
            "The design information of the CV. The default is the classic theme."
        ),
    )
    locale_catalog: Optional[locale_catalog_model.LocaleCatalog] = pydantic.Field(
        default=None,
        title="Locale Catalog",
        description=(
            "The locale catalog of the CV to allow the support of multiple languages."
        ),
    )


def read_input_file(
    file_path_or_contents: pathlib.Path | str,
) -> RenderCVDataModel:
    """Read the input file (YAML or JSON) and return them as an instance of
    `RenderCVDataModel`, which is a Pydantic data model of RenderCV's data format.

    Args:
        file_path_or_contents (str): The path to the input file or the contents of the
            input file as a string.

    Returns:
        RenderCVDataModel: The data models with $\\LaTeX$ and Markdown strings.
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

    input_as_dictionary: dict[str, Any] = ruamel.yaml.YAML().load(file_content)  # type: ignore

    # Validate the parsed dictionary by creating an instance of RenderCVDataModel:
    rendercv_data_model = RenderCVDataModel(**input_as_dictionary)

    return rendercv_data_model
