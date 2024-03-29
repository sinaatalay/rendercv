from typing import Literal
from typing import ClassVar as NotUsedInput

import pydantic

from .. import ThemeOptions, LaTeXDimension
from .. import Margins as MarginsBase


class Margins(MarginsBase):
    """This class is a data model for the margins."""

    entry_area: NotUsedInput
    highlights_area: NotUsedInput


class EngineeringresumesThemeOptions(ThemeOptions):
    """This class is the data model of the theme options for the engineeringresumes
    theme.
    """

    theme: Literal["engineeringresumes"]
    header_font_size: LaTeXDimension = pydantic.Field(
        default="25 pt",
        title="Header Font Size",
        description=(
            "The font size of the header (the name of the person). The default value is"
            " 25 pt."
        ),
    )
    margins: Margins = pydantic.Field(
        default=Margins(),
        title="Margins",
        description="Page, section title, entry field, and highlights field margins.",
    )
