from typing import Literal

import pydantic

from .. import ThemeOptions, EntryAreaMargins, Margins, LaTeXDimension


class EntryAreaMarginsForClassic(EntryAreaMargins):
    """This class is a data model for the entry area margins."""

    education_degree_width: LaTeXDimension = pydantic.Field(
        default="1 cm",
        title="Date and Location Column Width",
        description=(
            "The width of the degree column in EducationEntry. The default value is"
            " 1 cm."
        ),
    )


class MarginsForClassic(Margins):
    """This class is a data model for the margins."""

    entry_area: EntryAreaMarginsForClassic = pydantic.Field(
        default=EntryAreaMarginsForClassic(),
        title="Entry Area Margins",
        description="Entry area margins.",
    )


class ClassicThemeOptions(ThemeOptions):
    """This class is the data model of the theme options for the `classic` theme."""

    theme: Literal["classic"]
    font: Literal[
        "Latin Modern Serif",
        "Latin Modern Sans Serif",
        "Latin Modern Mono",
        "Source Sans 3",
        "Charter",
    ] = pydantic.Field(
        default="Source Sans 3",
        title="Font",
        description="The font family of the CV. The default value is Source Sans 3.",
    )
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
    margins: MarginsForClassic = pydantic.Field(
        default=MarginsForClassic(),
        title="Margins",
        description="Page, section title, entry field, and highlights field margins.",
    )
