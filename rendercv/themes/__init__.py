"""This module containts some general-purpose data models for the themes. The themes
are encouraged to inherit from these data models and add their own options, to avoid
code duplication.
"""

from typing import Literal, Annotated

import pydantic
import pydantic_extra_types.color as pydantic_color

# Create a custom type called LaTeXDimension that accepts only strings in a specified
# format.
# This type is used to validate the dimension fields in the design data.
# See https://docs.pydantic.dev/2.5/concepts/types/#custom-types for more information
# about custom types.
LaTeXDimension = Annotated[
    str,
    pydantic.Field(
        pattern=r"\d+\.?\d* *(cm|in|pt|mm|ex|em)",
    ),
]


class PageMargins(pydantic.BaseModel):
    """This class is a data model for the page margins."""

    top: LaTeXDimension = pydantic.Field(
        default="2 cm",
        title="Top Margin",
        description="The top margin of the page with units. The default value is 2 cm.",
    )
    bottom: LaTeXDimension = pydantic.Field(
        default="2 cm",
        title="Bottom Margin",
        description=(
            "The bottom margin of the page with units. The default value is 2 cm."
        ),
    )
    left: LaTeXDimension = pydantic.Field(
        default="2 cm",
        title="Left Margin",
        description=(
            "The left margin of the page with units. The default value is 2 cm."
        ),
    )
    right: LaTeXDimension = pydantic.Field(
        default="2 cm",
        title="Right Margin",
        description=(
            "The right margin of the page with units. The default value is 2 cm."
        ),
    )


class SectionTitleMargins(pydantic.BaseModel):
    """This class is a data model for the section title margins."""

    top: LaTeXDimension = pydantic.Field(
        default="0.3 cm",
        title="Top Margin",
        description="The top margin of section titles. The default value is 0.3 cm.",
    )
    bottom: LaTeXDimension = pydantic.Field(
        default="0.2 cm",
        title="Bottom Margin",
        description="The bottom margin of section titles. The default value is 0.3 cm.",
    )


class EntryAreaMargins(pydantic.BaseModel):
    """This class is a data model for the entry area margins."""

    left_and_right: LaTeXDimension = pydantic.Field(
        default="0.2 cm",
        title="Left Margin",
        description="The left margin of entry areas. The default value is 0.2 cm.",
    )

    vertical_between: LaTeXDimension = pydantic.Field(
        default="0.2 cm",
        title="Vertical Margin Between Entry Areas",
        description=(
            "The vertical margin between entry areas. The default value is 0.2 cm."
        ),
    )

    date_and_location_width: LaTeXDimension = pydantic.Field(
        default="4.5 cm",
        title="Date and Location Column Width",
        description=(
            "The width of the date and location column. The default value is 4.5 cm."
        ),
    )


class HighlightsAreaMargins(pydantic.BaseModel):
    """This class is a data model for the highlights area margins."""

    top: LaTeXDimension = pydantic.Field(
        default="0.10 cm",
        title="Top Margin",
        description="The top margin of highlights areas. The default value is 0.10 cm.",
    )
    left: LaTeXDimension = pydantic.Field(
        default="0.4 cm",
        title="Left Margin",
        description="The left margin of highlights areas. The default value is 0.4 cm.",
    )
    vertical_between_bullet_points: LaTeXDimension = pydantic.Field(
        default="0.10 cm",
        title="Vertical Margin Between Bullet Points",
        description=(
            "The vertical margin between bullet points. The default value is 0.10 cm."
        ),
    )


class HeaderMargins(pydantic.BaseModel):
    """This class is a data model for the header margins."""

    vertical_between_name_and_connections: LaTeXDimension = pydantic.Field(
        default="0.3 cm",
        title="Vertical Margin Between the Name and Connections",
        description=(
            "The vertical margin between the name of the person and the connections."
            " The default value is 0.3 cm."
        ),
    )
    bottom: LaTeXDimension = pydantic.Field(
        default="0.3 cm",
        title="Bottom Margin",
        description=(
            "The bottom margin of the header, i.e., the vertical margin between the"
            " connections and the first section title. The default value is 0.3 cm."
        ),
    )
    horizontal_between_connections: LaTeXDimension = pydantic.Field(
        default="0.5 cm",
        title="Space Between Connections",
        description=(
            "The space between the connections (like phone, email, and website). The"
            " default value is 0.5 cm."
        ),
    )


class Margins(pydantic.BaseModel):
    """This class is a data model for the margins."""

    page: PageMargins = pydantic.Field(
        default=PageMargins(),
        title="Page Margins",
        description="Page margins.",
    )
    section_title: SectionTitleMargins = pydantic.Field(
        default=SectionTitleMargins(),
        title="Section Title Margins",
        description="Section title margins.",
    )
    entry_area: EntryAreaMargins = pydantic.Field(
        default=EntryAreaMargins(),
        title="Entry Area Margins",
        description="Entry area margins.",
    )
    highlights_area: HighlightsAreaMargins = pydantic.Field(
        default=HighlightsAreaMargins(),
        title="Highlights Area Margins",
        description="Highlights area margins.",
    )
    header: HeaderMargins = pydantic.Field(
        default=HeaderMargins(),
        title="Header Margins",
        description="Header margins.",
    )


class ThemeOptions(pydantic.BaseModel):
    """This class is a generic data model for the theme options. The themes are
    encouraged to inherit from this data model and add their own options, to avoid code
    duplication.
    """

    model_config = pydantic.ConfigDict(extra="forbid")

    theme: Literal["tobeoverwritten"]

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
    font_size: Literal["10pt", "11pt", "12pt"] = pydantic.Field(
        default="10pt",
        title="Font Size",
        description="The font size of the CV. The default value is 10pt.",
    )
    page_size: Literal["a4paper", "letterpaper"] = pydantic.Field(
        default="letterpaper",
        title="Page Size",
        description=(
            "The page size of the CV. It can be a4paper or letterpaper. The default"
            " value is letterpaper."
        ),
    )
    color: pydantic_color.Color = pydantic.Field(
        default="rgb(0,79,144)",
        validate_default=True,
        title="Primary Color",
        description=(
            "The primary color of the theme. \nThe color can be specified either with"
            " their name (https://www.w3.org/TR/SVG11/types.html#ColorKeywords),"
            " hexadecimal value, RGB value, or HSL value. The default value is"
            " rgb(0,79,144)."
        ),
        examples=["Black", "7fffd4", "rgb(0,79,144)", "hsl(270, 60%, 70%)"],
    )
    disable_external_link_icons: bool = pydantic.Field(
        default=False,
        title="Disable External Link Icons",
        description=(
            "If this option is set to true, then the external link icons will not be"
            " shown next to the links. The default value is false."
        ),
    )
    disable_page_numbering: bool = pydantic.Field(
        default=False,
        title="Disable Page Numbering",
        description=(
            "If this option is set to true, then the page numbering will not be shown."
            " The default value is false."
        ),
    )
    page_numbering_style: str = pydantic.Field(
        default="NAME - Page PAGE_NUMBER of TOTAL_PAGES",
        title="Page Numbering Style",
        description=(
            "The style of the page numbering. The following placeholders can be used:"
            "\n- NAME: The name of the person\n- PAGE_NUMBER: The current page number"
            "\n- TOTAL_PAGES: The total number of pages\nThe default value is"
            " NAME - Page PAGE_NUMBER of TOTAL_PAGES."
        ),
    )
    disable_last_updated_date: bool = pydantic.Field(
        default=False,
        title="Disable Last Updated Date",
        description=(
            "If this option is set to true, then the last updated date will not be"
            " shown in the header. The default value is false."
        ),
    )
    last_updated_date_style: str = pydantic.Field(
        default="Last updated in TODAY",
        title="Last Updated Date Style",
        description=(
            "The style of the last updated date. The following placeholder can be"
            " used:\n- TODAY: Today's month and year (April 2024)\nThe default value is"
            " Last updated in TODAY."
        ),
    )
    header_font_size: LaTeXDimension = pydantic.Field(
        default="30 pt",
        title="Header Font Size",
        description=(
            "The font size of the header (the name of the person). The default value is"
            " 30 pt."
        ),
    )
    text_alignment: Literal[
        "left-aligned", "justified", "justified-with-no-hyphenation"
    ] = pydantic.Field(
        default="justified",
        title="Text Alignment",
        description="The alignment of the text. The default value is justified.",
    )
    margins: Margins = pydantic.Field(
        default=Margins(),
        title="Margins",
        description="Page, section title, entry field, and highlights field margins.",
    )
