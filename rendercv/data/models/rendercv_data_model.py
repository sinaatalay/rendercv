"""
The `rendercv.data.models.rendercv_data_model` module contains the `RenderCVDataModel`
data model, which is the main data model that defines the whole input file structure.
"""

import pathlib
from typing import Optional

import pydantic

from ...themes import ClassicThemeOptions
from .base import RenderCVBaseModelWithoutExtraKeys
from .curriculum_vitae import CurriculumVitae
from .design import RenderCVDesign
from .locale_catalog import LocaleCatalog
from .rendercv_settings import RenderCVSettings

INPUT_FILE_DIRECTORY: pathlib.Path


class RenderCVDataModel(RenderCVBaseModelWithoutExtraKeys):
    """This class binds both the CV and the design information together."""

    # `cv` is normally required, but don't enforce it in JSON Schema to allow
    # `design` or `locale_catalog` fields to have individual YAML files.
    model_config = pydantic.ConfigDict(json_schema_extra={"required": []})
    cv: CurriculumVitae = pydantic.Field(
        title="Curriculum Vitae",
        description="The data of the CV.",
    )
    design: RenderCVDesign = pydantic.Field(
        default=ClassicThemeOptions(theme="classic"),
        title="Design",
        description=(
            "The design information of the CV. The default is the classic theme."
        ),
    )
    locale_catalog: Optional[LocaleCatalog] = pydantic.Field(
        default=None,
        title="Locale Catalog",
        description=(
            "The locale catalog of the CV to allow the support of multiple languages."
        ),
    )
    rendercv_settings: Optional[RenderCVSettings] = pydantic.Field(
        default=None,
        title="RenderCV Settings",
        description="The settings of the RenderCV.",
    )

    @pydantic.field_validator("cv")
    @classmethod
    def update_paths(
        cls, rendercv_settings, info: pydantic.ValidationInfo
    ) -> Optional[RenderCVSettings]:
        """Update the paths in the RenderCV settings."""
        context = info.context
        global INPUT_FILE_DIRECTORY  # NOQA: PLW0603
        if context:
            input_file_directory = context.get(
                "input_file_directory", pathlib.Path.cwd()
            )
            INPUT_FILE_DIRECTORY = input_file_directory
        else:
            INPUT_FILE_DIRECTORY = pathlib.Path.cwd()

        return rendercv_settings

    @pydantic.field_validator("locale_catalog")
    @classmethod
    def initialize_locale_catalog(
        cls, locale_catalog: Optional[LocaleCatalog]
    ) -> Optional[LocaleCatalog]:
        """Even if the locale catalog is not provided, initialize it with the default
        values."""
        if locale_catalog is None:
            LocaleCatalog()

        return locale_catalog


rendercv_data_model_fields = tuple(RenderCVDataModel.model_fields.keys())
