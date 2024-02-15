from typing import Literal, Annotated

import pydantic


LaTeXDimension = Annotated[
    str,
    pydantic.Field(
        pattern=r"\d+\.?\d* *(cm|in|pt|mm|ex|em)",
    ),
]


class Sb2novThemeOptions(pydantic.BaseModel):
    """ """

    model_config = pydantic.ConfigDict(extra="forbid")

    theme: Literal["sb2nov"]

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
    space_between_connection_objects: LaTeXDimension = pydantic.Field(
        default="0.5 cm",
        title="Space Between Connection Objects",
        description=(
            "The space between the connection objects (like phone, email, and website)."
        ),
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
