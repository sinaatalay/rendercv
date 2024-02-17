from typing import Literal

import pydantic

from .. import ThemeOptions


class ClassicThemeOptions(ThemeOptions):
    """ """

    theme: Literal["classic"]

    text_alignment: Literal["left-aligned", "justified"] = pydantic.Field(
        default="justified",
        title="Text Alignment",
        description="The alignment of the text. The default value is justified.",
    )
    show_timespan_in: list[str] = pydantic.Field(
        default=[],
        title="Show Time Span in These Sections",
        description=(
            "The time span will be shown in the date and location column in these"
            " sections. The input should be a list of section titles as strings"
            " (case-sensitive)."
        ),
    )
