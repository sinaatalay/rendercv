from typing import Literal

import pydantic
import pydantic_extra_types.color as pydantic_color

from .. import (
    ThemeOptions,
    EntryAreaMargins,
    HighlightsAreaMargins,
    HeaderMargins,
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


class HeaderMarginsForEngineeringresumes(HeaderMargins):
    """This class is a data model for the header margins."""

    vertical_between_name_and_connections: LaTeXDimension = pydantic.Field(
        default="5 pt",
        title="Vertical Margin Between the Name and Connections",
        description=(
            "The vertical margin between the name of the person and the connections."
            " The default value is 5 pt."
        ),
    )
    bottom: LaTeXDimension = pydantic.Field(
        default="5 pt",
        title="Bottom Margin",
        description=(
            "The bottom margin of the header, i.e., the vertical margin between the"
            " connections and the first section title. The default value is 5 pt."
        ),
    )
    horizontal_between_connections: LaTeXDimension = pydantic.Field(
        default="10 pt",
        title="Space Between Connections",
        description=(
            "The space between the connections (like phone, email, and website). The"
            " default value is 20 pt."
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
    header: HeaderMarginsForEngineeringresumes = pydantic.Field(
        default=HeaderMarginsForEngineeringresumes(),
        title="Header Margins",
        description="Header margins.",
    )


class EngineeringresumesThemeOptions(ThemeOptions):
    """This class is the data model of the theme options for the `engineeringresumes`
    theme.
    """

    theme: Literal["engineeringresumes"]
    font: Literal[
        "Latin Modern Serif",
        "Latin Modern Sans Serif",
        "Latin Modern Mono",
        "Source Sans 3",
        "Charter",
    ] = pydantic.Field(
        default="Charter",
        title="Font",
        description="The font family of the CV. The default value is Charter.",
    )
    header_font_size: LaTeXDimension = pydantic.Field(
        default="25 pt",
        title="Header Font Size",
        description=(
            "The font size of the header (the name of the person). The default value is"
            " 25 pt."
        ),
    )
    color: pydantic_color.Color = pydantic.Field(
        default="rgb(0,0,0)",
        validate_default=True,
        title="Primary Color",
        description=(
            "The primary color of the theme. \nThe color can be specified either with"
            " their [name](https://www.w3.org/TR/SVG11/types.html#ColorKeywords),"
            " hexadecimal value, RGB value, or HSL value. The default value is"
            " rgb(0,0,0)."
        ),
        examples=["Black", "7fffd4", "rgb(0,79,144)", "hsl(270, 60%, 70%)"],
    )
    disable_external_link_icons: bool = pydantic.Field(
        default=True,
        title="Disable External Link Icons",
        description=(
            "If this option is set to true, then the external link icons will not be"
            " shown next to the links. The default value is true."
        ),
    )
    disable_page_numbering: bool = pydantic.Field(
        default=True,
        title="Disable Page Numbering",
        description=(
            "If this option is set to true, then the page numbering will not be shown."
            " The default value is true."
        ),
    )
    disable_last_updated_date: bool = pydantic.Field(
        default=True,
        title="Disable Last Updated Date",
        description=(
            "If this option is set to true, then the last updated date will not be"
            " shown in the header. The default value is true."
        ),
    )
    text_alignment: Literal[
        "left-aligned", "justified", "justified-with-no-hyphenation"
    ] = pydantic.Field(
        default="left-aligned",
        title="Text Alignment",
        description="The alignment of the text. The default value is left-aligned.",
    )
    margins: MarginsForEngineeringresumes = pydantic.Field(
        default=MarginsForEngineeringresumes(),
        title="Margins",
        description="Page, section title, entry field, and highlights field margins.",
    )
