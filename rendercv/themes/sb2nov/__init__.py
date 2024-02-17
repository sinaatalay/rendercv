from typing import Literal

import pydantic

from .. import ThemeOptions, LaTeXDimension


class Sb2novThemeOptions(ThemeOptions):
    """ """

    theme: Literal["sb2nov"]

    header_font_size: LaTeXDimension = pydantic.Field(
        default="24 pt",
        title="Header Font Size",
        description=(
            "The font size of the header (the name of the person). The default value is"
            " 24 pt. Unfortunately, sb2nov does not support font sizes bigger than"
            " 24 pt."
        ),
    )
