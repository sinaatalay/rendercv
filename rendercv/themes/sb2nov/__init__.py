from typing import Literal

import pydantic

from .. import LaTeXDimension, PageMargins


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

    link_color: (
        Literal["black"]
        | Literal["red"]
        | Literal["green"]
        | Literal["blue"]
        | Literal["cyan"]
        | Literal["magenta"]
        | Literal["yellow"]
    ) = pydantic.Field(
        default="cyan",
        validate_default=True,
        title="Link Color",
        description="The color of the links in the CV.",
        examples=[
            "black",
            "red",
            "green",
            "blue",
            "cyan",
            "magenta",
            "yellow",
        ],
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
    margins: PageMargins = pydantic.Field(
        default=PageMargins(),
        title="Margins",
        description="The page margins of the CV.",
    )
