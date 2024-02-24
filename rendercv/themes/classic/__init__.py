from typing import Literal

import pydantic

from .. import ThemeOptions


class ClassicThemeOptions(ThemeOptions):
    """This class is the data model of the theme options for the classic theme."""

    theme: Literal["classic"]
    show_timespan_in: list[str] = pydantic.Field(
        default=[],
        title="Show Time Span in These Sections",
        description=(
            "The time span will be shown in the date and location column in these"
            " sections. The input should be a list of section titles as strings"
            " (case-sensitive). The default value is an empty list, which means the"
            " time span will not be shown in any section."
        ),
    )
