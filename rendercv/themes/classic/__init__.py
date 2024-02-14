from typing import Literal, Annotated

import pydantic
import pydantic_extra_types.color as pydantic_color

LaTeXDimension = Annotated[
    str,
    pydantic.Field(
        pattern=r"\d+\.?\d* *(cm|in|pt|mm|ex|em)",
    ),
]


class ClassicThemePageMargins(pydantic.BaseModel):
    top: LaTeXDimension = pydantic.Field(
        default="2 cm",
        title="Top Margin",
        description="The top margin of the page with units.",
    )
    bottom: LaTeXDimension = pydantic.Field(
        default="2 cm",
        title="Bottom Margin",
        description="The bottom margin of the page with units.",
    )
    left: LaTeXDimension = pydantic.Field(
        default="1.24 cm",
        title="Left Margin",
        description="The left margin of the page with units.",
    )
    right: LaTeXDimension = pydantic.Field(
        default="1.24 cm",
        title="Right Margin",
        description="The right margin of the page with units.",
    )


class ClassicThemeSectionTitleMargins(pydantic.BaseModel):
    top: LaTeXDimension = pydantic.Field(
        default="0.2 cm",
        title="Top Margin",
        description="The top margin of section titles.",
    )
    bottom: LaTeXDimension = pydantic.Field(
        default="0.2 cm",
        title="Bottom Margin",
        description="The bottom margin of section titles.",
    )


class ClassicThemeEntryAreaMargins(pydantic.BaseModel):
    left_and_right: LaTeXDimension = pydantic.Field(
        default="0.2 cm",
        title="Left Margin",
        description="The left margin of entry areas.",
    )

    vertical_between: LaTeXDimension = pydantic.Field(
        default="0.12 cm",
        title="Vertical Margin Between Entry Areas",
        description="The vertical margin between entry areas.",
    )


class ClassicThemeHighlightsAreaMargins(pydantic.BaseModel):
    top: LaTeXDimension = pydantic.Field(
        default="0.10 cm",
        title="Top Margin",
        description="The top margin of highlights areas.",
    )
    left: LaTeXDimension = pydantic.Field(
        default="0.4 cm",
        title="Left Margin",
        description="The left margin of highlights areas.",
    )
    vertical_between_bullet_points: LaTeXDimension = pydantic.Field(
        default="0.10 cm",
        title="Vertical Margin Between Bullet Points",
        description="The vertical margin between bullet points.",
    )


class ClassicThemeHeaderMargins(pydantic.BaseModel):
    vertical_between_name_and_connections: LaTeXDimension = pydantic.Field(
        default="0.2 cm",
        title="Vertical Margin Between the Name and Connections",
        description=(
            "The vertical margin between the name of the person and the connections."
        ),
    )
    bottom: LaTeXDimension = pydantic.Field(
        default="0.2 cm",
        title="Bottom Margin",
        description=(
            "The bottom margin of the header, i.e., the vertical margin between the"
            " connections and the first section title."
        ),
    )


class ClassicThemeMargins(pydantic.BaseModel):
    page: ClassicThemePageMargins = pydantic.Field(
        default=ClassicThemePageMargins(),
        title="Page Margins",
        description="Page margins for the classic theme.",
    )
    section_title: ClassicThemeSectionTitleMargins = pydantic.Field(
        default=ClassicThemeSectionTitleMargins(),
        title="Section Title Margins",
        description="Section title margins for the classic theme.",
    )
    entry_area: ClassicThemeEntryAreaMargins = pydantic.Field(
        default=ClassicThemeEntryAreaMargins(),
        title="Entry Area Margins",
        description="Entry area margins for the classic theme.",
    )
    highlights_area: ClassicThemeHighlightsAreaMargins = pydantic.Field(
        default=ClassicThemeHighlightsAreaMargins(),
        title="Highlights Area Margins",
        description="Highlights area margins for the classic theme.",
    )
    header: ClassicThemeHeaderMargins = pydantic.Field(
        default=ClassicThemeHeaderMargins(),
        title="Header Margins",
        description="Header margins for the classic theme.",
    )


class ClassicThemeOptions(pydantic.BaseModel):
    """ """

    model_config = pydantic.ConfigDict(extra="forbid")

    theme: Literal["classic"]

    font_size: Literal["10pt", "11pt", "12pt"] = pydantic.Field(
        default="10pt",
        title="Font Size",
        description="The font size of the CV. It can be 10pt, 11pt, or 12pt.",
    )
    page_size: Literal["a4paper", "letterpaper"] = pydantic.Field(
        default="a4paper",
        title="Page Size",
        description="The page size of the CV. It can be a4paper or letterpaper.",
    )
    color: pydantic_color.Color = pydantic.Field(
        default="rgb(0,79,144)",
        validate_default=True,
        title="Primary Color",
        description=(
            "The primary color of Classic Theme. It is used for the section titles,"
            " heading, and the links.\nThe color can be specified either with their"
            " [name](https://www.w3.org/TR/SVG11/types.html#ColorKeywords), hexadecimal"
            " value, RGB value, or HSL value."
        ),
        examples=["Black", "7fffd4", "rgb(0,79,144)", "hsl(270, 60%, 70%)"],
    )
    disable_page_numbering: bool = pydantic.Field(
        default=False,
        title="Disable Page Numbering",
        description=(
            "If this option is set to true, then the page numbering will be disabled."
        ),
    )
    date_and_location_width: LaTeXDimension = pydantic.Field(
        default="4.1 cm",
        title="Date and Location Column Width",
        description="The width of the date and location column.",
    )
    text_alignment: Literal["left-aligned", "justified"] = pydantic.Field(
        default="left-aligned",
        title="Text Alignment",
        description="The alignment of the text.",
    )
    show_timespan_in: list[str] = pydantic.Field(
        default=[],
        title="Show Time Span in These Sections",
        description=(
            "The time span will be shown in the date and location column in these"
            " sections. The input should be a list of strings."
        ),
    )
    show_last_updated_date: bool = pydantic.Field(
        default=True,
        title="Show Last Updated Date",
        description=(
            "If this option is set to true, then the last updated date will be shown"
            " in the header."
        ),
    )
    header_font_size: LaTeXDimension = pydantic.Field(
        default="30 pt",
        title="Header Font Size",
        description="The font size of the header (the name of the person).",
    )
    margins: ClassicThemeMargins = pydantic.Field(
        default=ClassicThemeMargins(),
        title="Margins",
        description="Page, section title, entry field, and highlights field margins.",
    )
