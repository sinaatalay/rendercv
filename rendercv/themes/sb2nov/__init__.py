from typing import Literal

import pydantic

from .. import ThemeOptions, LaTeXDimension


class Sb2novThemeOptions(ThemeOptions):
    """This class is the data model of the theme options for the `sb2nov` theme."""

    theme: Literal["sb2nov"]
    font: Literal[
        "Latin Modern Serif",
        "Latin Modern Sans Serif",
        "Latin Modern Mono",
        "Source Sans 3",
        "Charter",
    ] = pydantic.Field(
        default="Latin Modern Serif",
        title="Font",
        description=(
            "The font family of the CV. The default value is Latin Modern Serif."
        ),
    )
    header_font_size: LaTeXDimension = pydantic.Field(
        default="24 pt",
        title="Header Font Size",
        description=(
            "The font size of the header (the name of the person). The default value is"
            " 24 pt. Unfortunately, sb2nov does not support font sizes bigger than"
            " 24 pt."
        ),
    )
