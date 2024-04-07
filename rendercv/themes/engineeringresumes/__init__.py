from typing import Literal
from typing import ClassVar as NotUsedInput

import pydantic
import pydantic_extra_types.color as pydantic_color

from .. import (
    ThemeOptions,
    EntryAreaMargins,
    HighlightsAreaMargins,
    Margins,
    LaTeXDimension,
)


class EntryAreaMarginsForEngineeringresumes(EntryAreaMargins):
    """This class is a data model for the entry area margins."""

    left_and_right: LaTeXDimension = pydantic.Field(
        default="0 cm",
        title="Left Margin",
        description="The left margin of entry areas. The default value is 0 cm.",
    )

    vertical_between: LaTeXDimension = pydantic.Field(
        default="0.1 cm",
        title="Vertical Margin Between Entry Areas",
        description=(
            "The vertical margin between entry areas. The default value is 0.1 cm."
        ),
    )

    date_and_location_width: NotUsedInput


class HighlightsAreaMarginsForEngineeringresumes(HighlightsAreaMargins):
    """This class is a data model for the highlights area margins."""

    top: LaTeXDimension = pydantic.Field(
        default="0.10 cm",
        title="Top Margin",
        description="The top margin of highlights areas. The default value is 0.10 cm.",
    )
    left: LaTeXDimension = pydantic.Field(
        default="0 cm",
        title="Left Margin",
        description="The left margin of highlights areas. The default value is 0 cm.",
    )
    vertical_between_bullet_points: LaTeXDimension = pydantic.Field(
        default="0.10 cm",
        title="Vertical Margin Between Bullet Points",
        description=(
            "The vertical margin between bullet points. The default value is 0.10 cm."
        ),
    )


class MarginsForEngineeringresumes(Margins):
    """This class is a data model for the margins."""

    entry_area: EntryAreaMarginsForEngineeringresumes = pydantic.Field(
        default=EntryAreaMarginsForEngineeringresumes(),
        title="Entry Area Margins",
        description="Entry area margins.",
    )
    highlights_area: HighlightsAreaMarginsForEngineeringresumes = pydantic.Field(
        default=HighlightsAreaMarginsForEngineeringresumes(),
        title="Highlights Area Margins",
        description="Highlights area margins.",
    )


class EngineeringresumesThemeOptions(ThemeOptions):
    """This class is the data model of the theme options for the `engineeringresumes`
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
    margins: MarginsForEngineeringresumes = pydantic.Field(
        default=MarginsForEngineeringresumes(),
        title="Margins",
        description="Page, section title, entry field, and highlights field margins.",
    )
