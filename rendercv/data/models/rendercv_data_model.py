"""
The `rendercv.data.models.rendercv_data_model` module contains the `RenderCVDataModel`
data model, which is the main data model that defines the whole input file structure.
"""

from typing import Optional

import pydantic

from ...themes import ClassicThemeOptions
from .base import RenderCVBaseModelWithoutExtraKeys
from .curriculum_vitae import CurriculumVitae
from .design import RenderCVDesign
from .locale_catalog import LocaleCatalog
from .rendercv_settings import RenderCVSettings


class RenderCVDataModel(RenderCVBaseModelWithoutExtraKeys):
    """This class binds both the CV and the design information together."""

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
        validate_default=True,
    )
    rendercv_settings: Optional[RenderCVSettings] = pydantic.Field(
        default=None,
        title="RenderCV Settings",
        description="The settings of the RenderCV.",
    )

    @pydantic.field_validator("locale_catalog")
    @classmethod
    def initialize_locale_catalog(cls, locale_catalog: LocaleCatalog) -> LocaleCatalog:
        """Even if the locale catalog is not provided, initialize it with the default
        values."""
        if locale_catalog is None:
            LocaleCatalog()

        return locale_catalog

    @pydantic.field_validator("rendercv_settings")
    @classmethod
    def initialize_rendercv_settings(
        cls, rendercv_settings: RenderCVSettings
    ) -> RenderCVSettings:
        """Even if the rendercv settings are not provided, initialize them with
        the default values."""
        if rendercv_settings is None:
            RenderCVSettings()

        return rendercv_settings
