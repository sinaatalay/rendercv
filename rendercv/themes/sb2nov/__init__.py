from typing import Literal

import pydantic

from .. import ThemeOptions, LaTeXDimension, Margins, EntryAreaMargins


class EntryAreaMarginsForSb2nov(EntryAreaMargins):
    """This class is a data model for the entry area margins."""

    bullet_width: LaTeXDimension = pydantic.Field(
        default="0.6 cm",
        title="Width of the Entry Bullet",
        description=(
            "The width of the bullet for each entry. The default value is 1 cm."
        ),
    )


class MarginsForSb2nov(Margins):
    """This class is a data model for the margins."""

    entry_area: EntryAreaMarginsForSb2nov = pydantic.Field(
        default=EntryAreaMarginsForSb2nov(),
        title="Entry Area Margins",
        description="Entry area margins.",
    )


class Sb2novThemeOptions(ThemeOptions):
    """This class is the data model of the theme options for the `sb2nov` theme."""

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
    margins: MarginsForSb2nov = pydantic.Field(
        default=MarginsForSb2nov(),
        title="Margins",
        description="Page, section title, entry field, and highlights field margins.",
    )
