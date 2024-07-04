"""
The `rendercv.data_models.models` module contains all the Pydantic data models used in
RenderCV. These data models define the data format and the usage of computed fields and
the validators.
"""

from typing import Optional

import pydantic

from ...themes.classic import ClassicThemeOptions

# Disable Pydantic warnings:
# warnings.filterwarnings("ignore")
from .base import RenderCVBaseModel
from .curriculum_vitae import CurriculumVitae
from .design import RenderCVDesign
from .locale_catalog import LocaleCatalog


class RenderCVDataModel(RenderCVBaseModel):
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
    )
