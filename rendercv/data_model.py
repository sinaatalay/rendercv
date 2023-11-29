"""
This module contains classes and functions to parse and validate YAML or JSON input
files. It uses [Pydantic](https://github.com/pydantic/pydantic) to achieve this goal.
All the data classes have `BaseModel` from Pydantic as a base class, and some data
fields have advanced types like `HttpUrl`, `EmailStr`, or `PastDate` from the Pydantic
library for validation.
"""

from datetime import date as Date
from typing import Literal
from typing_extensions import Annotated, Optional
import re
import logging
from functools import cached_property
import urllib.request
import os
from importlib.resources import files
import json
import time

from pydantic import (
    BaseModel,
    HttpUrl,
    Field,
    field_validator,
    model_validator,
    computed_field,
    EmailStr,
)
from pydantic.json_schema import GenerateJsonSchema
from pydantic.functional_validators import AfterValidator
from pydantic_extra_types.phone_numbers import PhoneNumber
from pydantic_extra_types.color import Color
from ruamel.yaml import YAML

logger = logging.getLogger(__name__)


def escape_latex_characters(sentence: str) -> str:
    """Escape LaTeX characters in a sentence.

    Example:
        ```python
        escape_latex_characters("This is a # sentence.")
        ```
        will return:
        `#!python "This is a \\# sentence."`
    """

    # Dictionary of escape characters:
    escape_characters = {
        "#": r"\#",
        # "$": r"\$", # Don't escape $ as it is used for math mode
        "%": r"\%",
        "&": r"\&",
        "~": r"\textasciitilde{}",
        # "_": r"\_", # Don't escape _ as it is used for math mode
        # "^": r"\textasciicircum{}", # Don't escape ^ as it is used for math mode
    }

    # Don't escape links as hyperref will do it automatically:

    # Find all the links in the sentence:
    links = re.findall(r"\[.*?\]\(.*?\)", sentence)

    # Replace the links with a placeholder:
    for link in links:
        sentence = sentence.replace(link, "!!-link-!!")

    # Handle backslash and curly braces separately because the other characters are
    # escaped with backslash and curly braces:
    # --don't escape curly braces as they are used heavily in LaTeX--:
    # sentence = sentence.replace("{", ">>{")
    # sentence = sentence.replace("}", ">>}")
    # --don't escape backslash as it is used heavily in LaTeX--:
    # sentence = sentence.replace("\\", "\\textbackslash{}")
    # sentence = sentence.replace(">>{", "\\{")
    # sentence = sentence.replace(">>}", "\\}")

    # Loop through the letters of the sentence and if you find an escape character,
    # replace it with its LaTeX equivalent:
    copy_of_the_sentence = sentence
    for character in copy_of_the_sentence:
        if character in escape_characters:
            sentence = sentence.replace(character, escape_characters[character])

    # Replace the links with the original links:
    for link in links:
        sentence = sentence.replace("!!-link-!!", link)

    return sentence


def parse_date_string(date_string: str) -> Date | int:
    """Parse a date string in YYYY-MM-DD, YYYY-MM, or YYYY format and return a
    datetime.date object.

    Args:
        date_string (str): The date string to parse.
    Returns:
        datetime.date: The parsed date.
    """
    if re.match(r"\d{4}-\d{2}-\d{2}", date_string):
        # Then it is in YYYY-MM-DD format
        date = Date.fromisoformat(date_string)
    elif re.match(r"\d{4}-\d{2}", date_string):
        # Then it is in YYYY-MM format
        # Assign a random day since days are not rendered in the CV
        date = Date.fromisoformat(f"{date_string}-01")
    elif re.match(r"\d{4}", date_string):
        # Then it is in YYYY format
        # Then keep it as an integer
        date = int(date_string)
    else:
        raise ValueError(
            f'The date string "{date_string}" is not in YYYY-MM-DD, YYYY-MM, or YYYY'
            " format."
        )

    if isinstance(date, Date):
        # Then it means the date is a Date object, so check if it is a past date:
        if date > Date.today():
            raise ValueError(
                f'The date "{date_string}" is in the future. Please check the dates.'
            )

    return date


def compute_time_span_string(start_date: Date | int, end_date: Date | int) -> str:
    """Compute the time span between two dates and return a string that represents it.

    Example:
        ```python
        compute_time_span_string(Date(2022,9,24), Date(2025,2,12))
        ```

        will return:

        `#!python "2 years 5 months"`

    Args:
        start_date (Date | int): The start date.
        end_date (Date | int): The end date.

    Returns:
        str: The time span string.
    """
    # check if the types of start_date and end_date are correct:
    if not isinstance(start_date, (Date, int)):
        raise TypeError("start_date is not a Date object or an integer!")
    if not isinstance(end_date, (Date, int)):
        raise TypeError("end_date is not a Date object or an integer!")

    # calculate the number of days between start_date and end_date:
    if isinstance(start_date, Date) and isinstance(end_date, Date):
        timespan_in_days = (end_date - start_date).days
    elif isinstance(start_date, Date) and isinstance(end_date, int):
        timespan_in_days = (Date(end_date, 1, 1) - start_date).days
    elif isinstance(start_date, int) and isinstance(end_date, Date):
        timespan_in_days = (end_date - Date(start_date, 1, 1)).days
    elif isinstance(start_date, int) and isinstance(end_date, int):
        timespan_in_days = (end_date - start_date) * 365

    if timespan_in_days < 0:
        raise ValueError(
            '"start_date" can not be after "end_date". Please check the dates.'
        )

    # calculate the number of years between start_date and end_date:
    how_many_years = timespan_in_days // 365
    if how_many_years == 0:
        how_many_years_string = None
    elif how_many_years == 1:
        how_many_years_string = "1 year"
    else:
        how_many_years_string = f"{how_many_years} years"

    # calculate the number of months between start_date and end_date:
    how_many_months = round((timespan_in_days % 365) / 30)
    if how_many_months <= 1:
        how_many_months_string = "1 month"
    else:
        how_many_months_string = f"{how_many_months} months"

    # combine howManyYearsString and howManyMonthsString:
    if how_many_years_string is None:
        timespan_string = how_many_months_string
    else:
        timespan_string = f"{how_many_years_string} {how_many_months_string}"

    return timespan_string


def format_date(date: Date) -> str:
    """Formats a date to a string in the following format: "Jan. 2021".

    It uses month abbreviations, taken from
    [Yale University Library](https://web.library.yale.edu/cataloging/months).

    Example:
        ```python
        format_date(Date(2024,5,1))
        ```
        will return

        `#!python "May 2024"`

    Args:
        date (Date): The date to format.

    Returns:
        str: The formatted date.
    """
    if not isinstance(date, (Date, int)):
        raise TypeError("date is not a Date object or an integer!")

    if isinstance(date, int):
        # Then it means the user only provided the year, so just return the year
        return str(date)

    # Month abbreviations,
    # taken from: https://web.library.yale.edu/cataloging/months
    abbreviations_of_months = [
        "Jan.",
        "Feb.",
        "Mar.",
        "Apr.",
        "May",
        "June",
        "July",
        "Aug.",
        "Sept.",
        "Oct.",
        "Nov.",
        "Dec.",
    ]

    month = int(date.strftime("%m"))
    monthAbbreviation = abbreviations_of_months[month - 1]
    year = date.strftime("%Y")
    date_string = f"{monthAbbreviation} {year}"

    return date_string


def generate_json_schema(output_directory: str) -> str:
    """Generate the JSON schema of the data model and save it to a file.

    Args:
        output_directory (str): The output directory to save the schema.
    """

    class RenderCVSchemaGenerator(GenerateJsonSchema):
        def generate(self, schema, mode="validation"):
            json_schema = super().generate(schema, mode=mode)
            json_schema["title"] = "RenderCV Input"

            # remove the description of the class (RenderCVDataModel)
            del json_schema["description"]

            # add $id
            json_schema[
                "$id"
            ] = "https://raw.githubusercontent.com/sinaatalay/rendercv/main/schema.json"

            # add $schema
            json_schema["$schema"] = "http://json-schema.org/draft-07/schema#"

            # Loop through $defs and remove docstring descriptions and fix optional
            # fields
            for key, value in json_schema["$defs"].items():
                # Don't allow additional properties
                value["additionalProperties"] = False

                # I don't want the docstrings in the schema, so remove them:
                if "This class" in value["description"]:
                    del value["description"]

                # If a type is optional, then Pydantic sets the type to a list of two
                # types, one of which is null. The null type can be removed since we
                # already have the required field. Moreover, we would like to warn
                # users if they provide null values. They can remove the fields if they
                # don't want to provide them.
                null_type_dict = {}
                null_type_dict["type"] = "null"
                for field in value["properties"].values():
                    if "anyOf" in field:
                        if (
                            len(field["anyOf"]) == 2
                            and null_type_dict in field["anyOf"]
                        ):
                            field["allOf"] = [field["anyOf"][0]]
                            del field["anyOf"]

                # In date field, we both accept normal strings and Date objects. They
                # are both strings, therefore, if user provides a Date object, then
                # JSON schema will complain that it matches two different types.
                # Remember that all of the anyOfs are changed to oneOfs. Only one of
                # the types can be matched. Therefore, we remove the first type, which
                # is the string with the YYYY-MM-DD format.
                if (
                    "date" in value["properties"]
                    and "anyOf" in value["properties"]["date"]
                ):
                    del value["properties"]["date"]["anyOf"][0]

            return json_schema

    schema = RenderCVDataModel.model_json_schema(
        schema_generator=RenderCVSchemaGenerator
    )
    schema = json.dumps(schema, indent=2)

    # Change all anyOf to oneOf
    schema = schema.replace('"anyOf"', '"oneOf"')

    path_to_schema = os.path.join(output_directory, "schema.json")
    with open(path_to_schema, "w") as f:
        f.write(schema)

    return path_to_schema


# ======================================================================================
# DESIGN MODELS ========================================================================
# ======================================================================================

# To understand how to create custom data types, see:
# https://docs.pydantic.dev/latest/usage/types/custom/
LaTeXDimension = Annotated[
    str,
    Field(
        pattern=r"\d+\.?\d* *(cm|in|pt|mm|ex|em)",
    ),
]


class ClassicThemePageMargins(BaseModel):
    """This class stores the margins of pages for the classic theme."""

    top: LaTeXDimension = Field(
        default="2 cm",
        title="Top Margin",
        description="The top margin of the page with units.",
    )
    bottom: LaTeXDimension = Field(
        default="2 cm",
        title="Bottom Margin",
        description="The bottom margin of the page with units.",
    )
    left: LaTeXDimension = Field(
        default="1.24 cm",
        title="Left Margin",
        description="The left margin of the page with units.",
    )
    right: LaTeXDimension = Field(
        default="1.24 cm",
        title="Right Margin",
        description="The right margin of the page with units.",
    )


class ClassicThemeSectionTitleMargins(BaseModel):
    """This class stores the margins of section titles for the classic theme."""

    top: LaTeXDimension = Field(
        default="0.2 cm",
        title="Top Margin",
        description="The top margin of section titles.",
    )
    bottom: LaTeXDimension = Field(
        default="0.2 cm",
        title="Bottom Margin",
        description="The bottom margin of section titles.",
    )


class ClassicThemeEntryAreaMargins(BaseModel):
    """This class stores the margins of entry areas for the classic theme.

    For the classic theme, entry areas are [OneLineEntry](../user_guide.md#onelineentry),
    [NormalEntry](../user_guide.md#normalentry), and
    [ExperienceEntry](../user_guide.md#experienceentry).
    """

    left_and_right: LaTeXDimension = Field(
        default="0.2 cm",
        title="Left Margin",
        description="The left margin of entry areas.",
    )

    vertical_between: LaTeXDimension = Field(
        default="0.12 cm",
        title="Vertical Margin Between Entry Areas",
        description="The vertical margin between entry areas.",
    )


class ClassicThemeHighlightsAreaMargins(BaseModel):
    """This class stores the margins of highlights areas for the classic theme."""

    top: LaTeXDimension = Field(
        default="0.10 cm",
        title="Top Margin",
        description="The top margin of highlights areas.",
    )
    left: LaTeXDimension = Field(
        default="0.4 cm",
        title="Left Margin",
        description="The left margin of highlights areas.",
    )
    vertical_between_bullet_points: LaTeXDimension = Field(
        default="0.10 cm",
        title="Vertical Margin Between Bullet Points",
        description="The vertical margin between bullet points.",
    )


class ClassicThemeHeaderMargins(BaseModel):
    """This class stores the margins of the header for the classic theme."""

    vertical_between_name_and_connections: LaTeXDimension = Field(
        default="0.2 cm",
        title="Vertical Margin Between the Name and Connections",
        description=(
            "The vertical margin between the name of the person and the connections."
        ),
    )
    bottom: LaTeXDimension = Field(
        default="0.2 cm",
        title="Bottom Margin",
        description=(
            "The bottom margin of the header, i.e., the vertical margin between the"
            " connections and the first section title."
        ),
    )


class ClassicThemeMargins(BaseModel):
    """This class stores the margins for the classic theme."""

    page: ClassicThemePageMargins = Field(
        default=ClassicThemePageMargins(),
        title="Page Margins",
        description="Page margins for the classic theme.",
    )
    section_title: ClassicThemeSectionTitleMargins = Field(
        default=ClassicThemeSectionTitleMargins(),
        title="Section Title Margins",
        description="Section title margins for the classic theme.",
    )
    entry_area: ClassicThemeEntryAreaMargins = Field(
        default=ClassicThemeEntryAreaMargins(),
        title="Entry Area Margins",
        description="Entry area margins for the classic theme.",
    )
    highlights_area: ClassicThemeHighlightsAreaMargins = Field(
        default=ClassicThemeHighlightsAreaMargins(),
        title="Highlights Area Margins",
        description="Highlights area margins for the classic theme.",
    )
    header: ClassicThemeHeaderMargins = Field(
        default=ClassicThemeHeaderMargins(),
        title="Header Margins",
        description="Header margins for the classic theme.",
    )


class ClassicThemeOptions(BaseModel):
    """This class stores the options for the classic theme.

    In RenderCV, each theme has its own Pydantic class so that new themes
    can be implemented easily in future.
    """

    primary_color: Color = Field(
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

    date_and_location_width: LaTeXDimension = Field(
        default="4.1 cm",
        title="Date and Location Column Width",
        description="The width of the date and location column.",
    )

    text_alignment: Literal["left-aligned", "justified"] = Field(
        default="left-aligned",
        title="Text Alignment",
        description="The alignment of the text.",
    )

    show_timespan_in: list[str] = Field(
        default=[],
        title="Show Time Span in These Sections",
        description=(
            "The time span will be shown in the date and location column in these"
            " sections. The input should be a list of strings."
        ),
    )

    show_last_updated_date: bool = Field(
        default=True,
        title="Show Last Updated Date",
        description=(
            "If this option is set to true, then the last updated date will be shown"
            " in the header."
        ),
    )

    header_font_size: LaTeXDimension = Field(
        default="30 pt",
        title="Header Font Size",
        description="The font size of the header (the name of the person).",
    )

    margins: ClassicThemeMargins = Field(
        default=ClassicThemeMargins(),
        title="Margins",
        description="Page, section title, entry field, and highlights field margins.",
    )


class Design(BaseModel):
    """This class stores the theme name of the CV and the theme's options."""

    theme: Literal["classic"] = Field(
        default="classic",
        title="Theme name",
        description='The only option is "Classic" for now.',
    )
    font: Literal["SourceSans3", "Roboto", "EBGaramond"] = Field(
        default="SourceSans3",
        title="Font",
        description="The font of the CV.",
    )
    font_size: Literal["10pt", "11pt", "12pt"] = Field(
        default="10pt",
        title="Font Size",
        description="The font size of the CV. It can be 10pt, 11pt, or 12pt.",
    )
    page_size: Literal["a4paper", "letterpaper"] = Field(
        default="a4paper",
        title="Page Size",
        description="The page size of the CV. It can be a4paper or letterpaper.",
    )
    options: Optional[ClassicThemeOptions] = Field(
        default=None,
        title="Theme Options",
        description="The options of the theme.",
    )

    @model_validator(mode="after")
    @classmethod
    def check_theme_options(cls, model):
        """Check if the correct options are provided for the theme. If the theme
        options are not provided, then set the default options for the theme.
        """
        if model.options is None:
            if model.theme == "classic":
                model.options = ClassicThemeOptions()
            else:
                raise RuntimeError(f'The theme "{model.theme}" does not exist.')
        else:
            if model.theme == "classic":
                if not isinstance(model.options, ClassicThemeOptions):
                    raise ValueError(
                        "Theme is classic but options is not classic theme options."
                    )
            else:
                raise RuntimeError(f'The theme "{model.theme}"" does not exist.')

        return model

    @field_validator("font")
    @classmethod
    def check_font(cls, font: str) -> str:
        """Go to the fonts directory and check if the font exists. If it exists, then
        check if all the required files are there.
        """
        fonts_directory = str(files("rendercv").joinpath("templates", "fonts"))
        if font not in os.listdir(fonts_directory):
            raise ValueError(
                f'The font "{font}" is not found in the "fonts" directory.'
            )
        else:
            font_directory = os.path.join(fonts_directory, font)
            required_files = [
                f"{font}-Bold.ttf",
                f"{font}-BoldItalic.ttf",
                f"{font}-Italic.ttf",
                f"{font}-Regular.ttf",
            ]
            for file in required_files:
                if file not in os.listdir(font_directory):
                    raise ValueError(f"{file} is not found in the {font} directory.")

        return font

    @field_validator("theme")
    @classmethod
    def check_if_theme_exists(cls, theme: str) -> str:
        """Check if the theme exists in the templates directory."""
        template_directory = str(files("rendercv").joinpath("templates", theme))
        if f"{theme}.tex.j2" not in os.listdir(template_directory):
            raise ValueError(
                f'The theme "{theme}" is not found in the "templates" directory.'
            )

        return theme


# ======================================================================================
# ======================================================================================
# ======================================================================================

# ======================================================================================
# CONTENT MODELS =======================================================================
# ======================================================================================

LaTeXString = Annotated[str, AfterValidator(escape_latex_characters)]
PastDate = Annotated[
    str, Field(pattern=r"\d{4}-?(\d{2})?-?(\d{2})?"), AfterValidator(parse_date_string)
]


class Event(BaseModel):
    """This class is the parent class for classes like `#!python EducationEntry`,
    `#!python ExperienceEntry`, `#!python NormalEntry`, and `#!python OneLineEntry`.

    It stores the common fields between these classes like dates, location, highlights,
    and URL.
    """

    start_date: Optional[PastDate] = Field(
        default=None,
        title="Start Date",
        description="The start date of the event in YYYY-MM-DD format.",
        examples=["2020-09-24"],
    )
    end_date: Optional[Literal["present"] | PastDate] = Field(
        default=None,
        title="End Date",
        description=(
            "The end date of the event in YYYY-MM-DD format. If the event is still"
            ' ongoing, then the value should be "present".'
        ),
        examples=["2020-09-24", "present"],
    )
    date: Optional[PastDate | LaTeXString] = Field(
        default=None,
        title="Date",
        description=(
            "If the event is a one-day event, then this field should be filled in"
            " YYYY-MM-DD format. If the event is a multi-day event, then the start date"
            " and end date should be provided instead. All of them can't be provided at"
            " the same time."
        ),
        examples=["2020-09-24", "My Custom Date"],
    )
    highlights: Optional[list[LaTeXString]] = Field(
        default=[],
        title="Highlights",
        description=(
            "The highlights of the event. It will be rendered as bullet points."
        ),
        examples=["Did this.", "Did that."],
    )
    location: Optional[LaTeXString] = Field(
        default=None,
        title="Location",
        description=(
            "The location of the event. It will be shown with the date in the"
            " same column."
        ),
        examples=["Istanbul, Turkey"],
    )
    url: Optional[HttpUrl] = None

    @field_validator("date")
    @classmethod
    def check_date(cls, date: PastDate | LaTeXString) -> PastDate | LaTeXString:
        """Check if the date is a string or a Date object and return accordingly."""
        if isinstance(date, str):
            try:
                # If this runs, it means the date is an ISO format string, and it can be
                # parsed
                date = parse_date_string(date)
            except ValueError:
                # Then it means it is a custom string like "Fall 2023"
                date = date

        return date

    @model_validator(mode="after")
    @classmethod
    def check_dates(cls, model):
        """Make sure that either `#!python start_date` and `#!python end_date` or only
        `#!python date` is provided.
        """
        date_is_provided = False
        start_date_is_provided = False
        end_date_is_provided = False
        if model.date is not None:
            date_is_provided = True
        if model.start_date is not None:
            start_date_is_provided = True
        if model.end_date is not None:
            end_date_is_provided = True

        if date_is_provided and start_date_is_provided and end_date_is_provided:
            logger.warning(
                '"start_date", "end_date" and "date" are all provided in of the'
                " entries. Therefore, date will be ignored."
            )
            model.date = None

        elif date_is_provided and start_date_is_provided and not end_date_is_provided:
            logger.warning(
                'Both "date" and "start_date" is provided in of the entries.'
                ' "start_date" will be ignored.'
            )
            model.start_date = None
            model.end_date = None

        elif date_is_provided and end_date_is_provided and not start_date_is_provided:
            logger.warning(
                'Both "date" and "end_date" is provided in of the entries. "end_date"'
                " will be ignored."
            )
            model.start_date = None
            model.end_date = None

        elif start_date_is_provided and not end_date_is_provided:
            logger.warning(
                '"start_date" is provided in of the entries, but "end_date" is not.'
                ' "end_date" will be set to "present".'
            )
            model.end_date = "present"

        if model.start_date is not None and model.end_date is not None:
            if model.end_date == "present":
                end_date = Date.today()
            elif isinstance(model.end_date, int):
                # Then it means user only provided the year, so convert it to a Date
                # object with the first day of the year (just for the date comparison)
                end_date = Date(model.end_date, 1, 1)
            elif isinstance(model.end_date, Date):
                # Then it means user provided either YYYY-MM-DD or YYYY-MM
                end_date = model.end_date
            else:
                raise RuntimeError("end_date is neither an integer nor a Date object.")

            if isinstance(model.start_date, int):
                # Then it means user only provided the year, so convert it to a Date
                # object with the first day of the year (just for the date comparison)
                start_date = Date(model.start_date, 1, 1)
            elif isinstance(model.start_date, Date):
                # Then it means user provided either YYYY-MM-DD or YYYY-MM
                start_date = model.start_date
            else:
                raise RuntimeError(
                    "start_date is neither an integer nor a Date object."
                )

            if start_date > end_date:
                raise ValueError(
                    '"start_date" can not be after "end_date". Please check the dates.'
                )

        return model

    @computed_field
    @cached_property
    def date_and_location_strings_with_timespan(self) -> list[LaTeXString]:
        date_and_location_strings = []

        if self.location is not None:
            date_and_location_strings.append(self.location)

        if self.date is not None:
            if isinstance(self.date, str):
                date_and_location_strings.append(self.date)
            elif isinstance(self.date, Date):
                date_and_location_strings.append(format_date(self.date))
            else:
                raise RuntimeError("Date is neither a string nor a Date object.")
        elif self.start_date is not None and self.end_date is not None:
            start_date = format_date(self.start_date)

            if self.end_date == "present":
                end_date = "present"

                time_span_string = compute_time_span_string(
                    self.start_date, Date.today()
                )
            else:
                end_date = format_date(self.end_date)

                time_span_string = compute_time_span_string(
                    self.start_date, self.end_date
                )

            date_and_location_strings.append(f"{start_date} to {end_date}")

            date_and_location_strings.append(f"{time_span_string}")

        return date_and_location_strings

    @computed_field
    @cached_property
    def date_and_location_strings_without_timespan(self) -> list[LaTeXString]:
        # use copy() to avoid modifying the original list
        date_and_location_strings = self.date_and_location_strings_with_timespan.copy()
        for string in date_and_location_strings:
            if (
                "years" in string
                or "months" in string
                or "year" in string
                or "month" in string
            ):
                date_and_location_strings.remove(string)

        return date_and_location_strings

    @computed_field
    @cached_property
    def highlight_strings(self) -> list[LaTeXString]:
        highlight_strings = []
        if self.highlights is not None:
            highlight_strings.extend(self.highlights)

        return highlight_strings

    @computed_field
    @cached_property
    def markdown_url(self) -> Optional[str]:
        if self.url is None:
            return None
        else:
            url = str(self.url)

            if "github" in url:
                link_text = "view on GitHub"
            elif "linkedin" in url:
                link_text = "view on LinkedIn"
            elif "instagram" in url:
                link_text = "view on Instagram"
            elif "youtube" in url:
                link_text = "view on YouTube"
            else:
                link_text = "view on my website"

            markdown_url = f"[{link_text}]({url})"

            return markdown_url

    @computed_field
    @cached_property
    def month_and_year(self) -> Optional[LaTeXString]:
        if self.date is not None:
            # Then it means start_date and end_date are not provided.
            try:
                # If this runs, it means the date is an ISO format string, and it can be
                # parsed
                month_and_year = format_date(self.date)  # type: ignore
            except TypeError:
                month_and_year = str(self.date)
        else:
            # Then it means start_date and end_date are provided and month_and_year
            # doesn't make sense.
            month_and_year = None

        return month_and_year


class OneLineEntry(Event):
    """This class stores [OneLineEntry](../user_guide.md#onelineentry) information."""

    name: LaTeXString = Field(
        title="Name",
        description="The name of the entry. It will be shown as bold text.",
    )
    details: LaTeXString = Field(
        title="Details",
        description="The details of the entry. It will be shown as normal text.",
    )


class NormalEntry(Event):
    """This class stores [NormalEntry](../user_guide.md#normalentry) information."""

    name: LaTeXString = Field(
        title="Name",
        description="The name of the entry. It will be shown as bold text.",
    )


class ExperienceEntry(Event):
    """This class stores [ExperienceEntry](../user_guide.md#experienceentry) information."""

    company: LaTeXString = Field(
        title="Company",
        description="The company name. It will be shown as bold text.",
    )
    position: LaTeXString = Field(
        title="Position",
        description="The position. It will be shown as normal text.",
    )


class EducationEntry(Event):
    """This class stores [EducationEntry](../user_guide.md#educationentry) information."""

    institution: LaTeXString = Field(
        title="Institution",
        description="The institution name. It will be shown as bold text.",
        examples=["Bogazici University"],
    )
    area: LaTeXString = Field(
        title="Area",
        description="The area of study. It will be shown as normal text.",
    )
    study_type: Optional[LaTeXString] = Field(
        default=None,
        title="Study Type",
        description="The type of the degree.",
        examples=["BS", "BA", "PhD", "MS"],
    )
    gpa: Optional[LaTeXString | float] = Field(
        default=None,
        title="GPA",
        description="The GPA of the degree.",
    )
    transcript_url: Optional[HttpUrl] = Field(
        default=None,
        title="Transcript URL",
        description=(
            "The URL of the transcript. It will be shown as a link next to the GPA."
        ),
        examples=["https://example.com/transcript.pdf"],
    )

    @computed_field
    @cached_property
    def highlight_strings(self) -> list[LaTeXString]:
        highlight_strings = []

        if self.gpa is not None:
            gpaString = f"GPA: {self.gpa}"
            if self.transcript_url is not None:
                gpaString += f" ([Transcript]({self.transcript_url}))"
            highlight_strings.append(gpaString)

        if self.highlights is not None:
            highlight_strings.extend(self.highlights)

        return highlight_strings


class PublicationEntry(Event):
    """This class stores [PublicationEntry](../user_guide.md#publicationentry) information."""

    title: LaTeXString = Field(
        title="Title of the Publication",
        description="The title of the publication. It will be shown as bold text.",
    )
    authors: list[LaTeXString] = Field(
        title="Authors",
        description="The authors of the publication in order as a list of strings.",
    )
    doi: str = Field(
        title="DOI",
        description="The DOI of the publication.",
        examples=["10.48550/arXiv.2310.03138"],
    )
    date: LaTeXString = Field(
        title="Publication Date",
        description="The date of the publication.",
        examples=["2021-10-31"],
    )
    cited_by: Optional[int] = Field(
        default=None,
        title="Cited By",
        description="The number of citations of the publication.",
    )
    journal: Optional[LaTeXString] = Field(
        default=None,
        title="Journal",
        description="The journal or the conference name.",
    )

    @field_validator("doi")
    @classmethod
    def check_doi(cls, doi: str) -> str:
        """Check if the DOI exists in the DOI System."""
        doi_url = f"https://doi.org/{doi}"

        try:
            urllib.request.urlopen(doi_url)
        except urllib.request.HTTPError as err:
            if err.code == 404:
                raise ValueError(f"{doi} cannot be found in the DOI System.")

        return doi

    @computed_field
    @cached_property
    def doi_url(self) -> str:
        return f"https://doi.org/{self.doi}"


class SocialNetwork(BaseModel):
    """This class stores a social network information.

    Currently, only LinkedIn, Github, and Instagram are supported.
    """

    network: Literal["LinkedIn", "GitHub", "Instagram", "Orcid"] = Field(
        title="Social Network",
        description="The social network name.",
    )
    username: str = Field(
        title="Username",
        description="The username of the social network. The link will be generated.",
    )


class Connection(BaseModel):
    """This class stores a connection/communication information.

    Warning:
        This class isn't designed for users to use, but it is used by RenderCV to make
        the $\\LaTeX$ templating easier.
    """

    name: Literal[
        "LinkedIn",
        "GitHub",
        "Instagram",
        "Orcid",
        "phone",
        "email",
        "website",
        "location",
    ]
    value: str

    @computed_field
    @cached_property
    def url(self) -> Optional[HttpUrl | str]:
        if self.name == "LinkedIn":
            url = f"https://www.linkedin.com/in/{self.value}"
        elif self.name == "GitHub":
            url = f"https://www.github.com/{self.value}"
        elif self.name == "Instagram":
            url = f"https://www.instagram.com/{self.value}"
        elif self.name == "Orcid":
            url = f"https://orcid.org/{self.value}"
        elif self.name == "email":
            url = f"mailto:{self.value}"
        elif self.name == "website":
            url = self.value
        elif self.name == "phone":
            url = self.value
        elif self.name == "location":
            url = None
        else:
            raise RuntimeError(f'"{self.name}" is not a valid connection.')

        return url


class SectionBase(BaseModel):
    """This class stores a section information.

    It is the parent class of all the section classes like
    `#!python SectionWithEducationEntries`, `#!python SectionWithExperienceEntries`,
    `#!python SectionWithNormalEntries`, `#!python SectionWithOneLineEntries`, and
    `#!python SectionWithPublicationEntries`.
    """

    title: LaTeXString = Field(
        title="Section Title",
        description="The title of the section.",
        examples=["My Custom Section"],
    )
    link_text: Optional[LaTeXString] = Field(
        default=None,
        title="Link Text",
        description=(
            "If the section has a link, then what should be the text of the link? If"
            " this field is not provided, then the link text will be generated"
            " automatically based on the URL."
        ),
        examples=["view on GitHub", "view on LinkedIn"],
    )

    @field_validator("title")
    @classmethod
    def make_first_letters_uppercase(cls, title: LaTeXString) -> LaTeXString:
        """Capitalize the first letters of the words in the title."""
        return title.title()


entry_type_field = Field(
    title="Entry Type",
    description="The type of the entries in the section.",
)
entries_field = Field(
    title="Entries",
    description="The entries of the section. The format depends on the entry type.",
)


class SectionWithEducationEntries(SectionBase):
    """This class stores a section with
    [EducationEntry](../user_guide.md#educationentry)s.
    """

    entry_type: Literal["EducationEntry"] = entry_type_field
    entries: list[EducationEntry] = entries_field


class SectionWithExperienceEntries(SectionBase):
    """This class stores a section with
    [ExperienceEntry](../user_guide.md#experienceentry)s.
    """

    entry_type: Literal["ExperienceEntry"] = entry_type_field
    entries: list[ExperienceEntry] = entries_field


class SectionWithNormalEntries(SectionBase):
    """This class stores a section with
    [NormalEntry](../user_guide.md#normalentry)s.
    """

    entry_type: Literal["NormalEntry"] = entry_type_field
    entries: list[NormalEntry] = entries_field


class SectionWithOneLineEntries(SectionBase):
    """This class stores a section with
    [OneLineEntry](../user_guide.md#onelineentry)s.
    """

    entry_type: Literal["OneLineEntry"] = entry_type_field
    entries: list[OneLineEntry] = entries_field


class SectionWithPublicationEntries(SectionBase):
    """This class stores a section with
    [PublicationEntry](../user_guide.md#publicationentry)s.
    """

    entry_type: Literal["PublicationEntry"] = entry_type_field
    entries: list[PublicationEntry] = entries_field


Section = Annotated[
    SectionWithEducationEntries
    | SectionWithExperienceEntries
    | SectionWithNormalEntries
    | SectionWithOneLineEntries
    | SectionWithPublicationEntries,
    Field(
        discriminator="entry_type",
    ),
]


class CurriculumVitae(BaseModel):
    """This class bindes all the information of a CV together."""

    name: LaTeXString = Field(
        title="Name",
        description="The name of the person.",
    )
    label: Optional[LaTeXString] = Field(
        default=None,
        title="Label",
        description="The label of the person.",
    )
    location: Optional[LaTeXString] = Field(
        default=None,
        title="Location",
        description="The location of the person. This is not rendered currently.",
    )
    email: Optional[EmailStr] = Field(
        default=None,
        title="Email",
        description="The email of the person. It will be rendered in the heading.",
    )
    phone: Optional[PhoneNumber] = None
    website: Optional[HttpUrl] = None
    social_networks: Optional[list[SocialNetwork]] = Field(
        default=None,
        title="Social Networks",
        description=(
            "The social networks of the person. They will be rendered in the heading."
        ),
    )
    summary: Optional[LaTeXString] = Field(
        default=None,
        title="Summary",
        description="The summary of the person.",
    )
    # Sections:
    section_order: Optional[list[str]] = Field(
        default=None,
        title="Section Order",
        description=(
            "The order of sections in the CV. The section title should be used."
        ),
    )
    education: Optional[list[EducationEntry]] = Field(
        default=None,
        title="Education",
        description="The education entries of the person.",
    )
    experience: Optional[list[ExperienceEntry]] = Field(
        default=None,
        title="Experience",
        description="The experience entries of the person.",
    )
    work_experience: Optional[list[ExperienceEntry]] = Field(
        default=None,
        title="Work Experience",
        description="The work experience entries of the person.",
    )
    projects: Optional[list[NormalEntry]] = Field(
        default=None,
        title="Projects",
        description="The project entries of the person.",
    )
    academic_projects: Optional[list[NormalEntry]] = Field(
        default=None,
        title="Academic Projects",
        description="The academic project entries of the person.",
    )
    university_projects: Optional[list[NormalEntry]] = Field(
        default=None,
        title="University Projects",
        description="The university project entries of the person.",
    )
    personal_projects: Optional[list[NormalEntry]] = Field(
        default=None,
        title="Personal Projects",
        description="The personal project entries of the person.",
    )
    publications: Optional[list[PublicationEntry]] = Field(
        default=None,
        title="Publications",
        description="The publication entries of the person.",
    )
    certificates: Optional[list[NormalEntry]] = Field(
        default=None,
        title="Certificates",
        description="The certificate entries of the person.",
    )
    extracurricular_activities: Optional[list[ExperienceEntry]] = Field(
        default=None,
        title="Extracurricular Activities",
        description="The extracurricular activity entries of the person.",
    )
    test_scores: Optional[list[OneLineEntry]] = Field(
        default=None,
        title="Test Scores",
        description="The test score entries of the person.",
    )
    programming_skills: Optional[list[NormalEntry]] = Field(
        default=None,
        title="Programming Skills",
        description="The programming skill entries of the person.",
    )
    skills: Optional[list[OneLineEntry]] = Field(
        default=None,
        title="Skills",
        description="The skill entries of the person.",
    )
    other_skills: Optional[list[OneLineEntry]] = Field(
        default=None,
        title="Skills",
        description="The skill entries of the person.",
    )
    awards: Optional[list[OneLineEntry]] = Field(
        default=None,
        title="Awards",
        description="The award entries of the person.",
    )
    interests: Optional[list[OneLineEntry]] = Field(
        default=None,
        title="Interests",
        description="The interest entries of the person.",
    )
    custom_sections: Optional[list[Section]] = Field(
        default=None,
        title="Custom Sections",
        description=(
            "Custom sections with custom section titles can be rendered as well."
        ),
    )

    @model_validator(mode="after")
    @classmethod
    def check_if_the_section_names_are_unique(cls, model):
        """Check if the section names are unique."""
        pre_defined_section_names = [
            "Education",
            "Work Experience",
            "Academic Projects",
            "Personal Projects",
            "Certificates",
            "Extracurricular Activities",
            "Test Scores",
            "Skills",
            "Publications",
        ]
        if model.custom_sections is not None:
            custom_section_names = []
            for custom_section in model.custom_sections:
                custom_section_names.append(custom_section.title)

            section_names = pre_defined_section_names + custom_section_names
        else:
            section_names = pre_defined_section_names

        seen = set()
        duplicates = {val for val in section_names if (val in seen or seen.add(val))}
        if len(duplicates) > 0:
            raise ValueError(
                "The section names should be unique. The following section names are"
                f" duplicated: {duplicates}"
            )

        return model

    @computed_field
    @cached_property
    def connections(self) -> list[Connection]:
        connections = []
        if self.location is not None:
            connections.append(Connection(name="location", value=self.location))
        if self.phone is not None:
            connections.append(Connection(name="phone", value=self.phone))
        if self.email is not None:
            connections.append(Connection(name="email", value=self.email))
        if self.website is not None:
            connections.append(Connection(name="website", value=str(self.website)))
        if self.social_networks is not None:
            for social_network in self.social_networks:
                connections.append(
                    Connection(
                        name=social_network.network, value=social_network.username
                    )
                )

        return connections

    @computed_field
    @cached_property
    def sections(self) -> list[SectionBase]:
        sections = []

        # Pre-defined sections (i.e. sections that are not custom)):
        pre_defined_sections = {
            "Education": self.education,
            "Experience": self.experience,
            "Work Experience": self.work_experience,
            "Publications": self.publications,
            "Projects": self.projects,
            "Academic Projects": self.academic_projects,
            "University Projects": self.university_projects,
            "Personal Projects": self.personal_projects,
            "Certificates": self.certificates,
            "Extracurricular Activities": self.extracurricular_activities,
            "Test Scores": self.test_scores,
            "Skills": self.skills,
            "Programming Skills": self.programming_skills,
            "Other Skills": self.other_skills,
            "Awards": self.awards,
            "Interests": self.interests,
            "Programming Skills": self.programming_skills,
        }

        section_order_is_given = True
        if self.section_order is None:
            section_order_is_given = False
            # If the user didn't specify the section order, then use the default order:
            self.section_order = list(pre_defined_sections.keys())
            if self.custom_sections is not None:
                # If the user specified custom sections, then add them to the end of the
                # section order with the same order as they are in the input file:
                self.section_order.extend(
                    [section.title for section in self.custom_sections]
                )

        link_text = None
        entry_type = None
        entries = None
        for section_name in self.section_order:
            # Create a section for each section name in the section order:
            if section_name in pre_defined_sections:
                if pre_defined_sections[section_name] is None:
                    if section_order_is_given:
                        raise ValueError(
                            f'The section "{section_name}" is not found in the CV.'
                            " Please create the section or delete it from the section"
                            " order."
                        )
                    else:
                        continue

                entry_type = pre_defined_sections[section_name][0].__class__.__name__
                entries = pre_defined_sections[section_name]
                if section_name == "Test Scores":
                    link_text = "Score Report"
                elif section_name == "Certificates":
                    link_text = "Certificate"
                else:
                    link_text = None
            else:
                # If the section is not pre-defined, then it is a custom section.
                # Find the corresponding custom section and get its entries:
                for custom_section in self.custom_sections:  # type: ignore
                    if custom_section.title == section_name:
                        entry_type = custom_section.entries[0].__class__.__name__
                        link_text = custom_section.link_text
                        entries = custom_section.entries
                        break
                    else:
                        entry_type = None
                        link_text = None
                        entries = None

                if entry_type is None or entries is None:
                    raise ValueError(
                        f'"{section_name}" is not a valid section name. Please create a'
                        " custom section with this name or delete it from the section"
                        " order."
                    )

            object_map = {
                "EducationEntry": SectionWithEducationEntries,
                "ExperienceEntry": SectionWithExperienceEntries,
                "NormalEntry": SectionWithNormalEntries,
                "OneLineEntry": SectionWithOneLineEntries,
                "PublicationEntry": SectionWithPublicationEntries,
            }

            section = object_map[entry_type](
                title=section_name,
                entry_type=entry_type,  # type: ignore
                entries=entries,
                link_text=link_text,
            )
            sections.append(section)

        # Check if any of the pre-defined sections are missing from the section order:
        for section_name in pre_defined_sections:
            if pre_defined_sections[section_name] is not None:
                if section_name not in self.section_order:
                    logger.warning(
                        f'The section "{section_name}" is not found in the section'
                        " order! It will not be rendered."
                    )

        # Check if any of the custom sections are missing from the section order:
        if self.custom_sections is not None:
            for custom_section in self.custom_sections:
                if custom_section.title not in self.section_order:
                    logger.warning(
                        f'The custom section "{custom_section.title}" is not found in'
                        " the section order! It will not be rendered."
                    )

        return sections


# ======================================================================================
# ======================================================================================
# ======================================================================================


class RenderCVDataModel(BaseModel):
    """This class binds both the CV and the design information together."""

    design: Design = Field(
        default=Design(),
        title="Design",
        description="The design of the CV.",
    )
    cv: CurriculumVitae = Field(
        default=CurriculumVitae(name="John Doe"),
        title="Curriculum Vitae",
        description="The data of the CV.",
    )

    @model_validator(mode="after")
    @classmethod
    def check_classical_theme_show_timespan_in(cls, model):
        """Check if the sections that are specified in the "show_timespan_in" option
        exist in the CV.
        """
        if model.design.theme == "classic":
            design: Design = model.design
            cv: CurriculumVitae = model.cv
            section_titles = [section.title for section in cv.sections]
            for title in design.options.show_timespan_in:  # type: ignore
                if title not in section_titles:
                    not_used_section_titles = list(
                        set(section_titles) - set(design.options.show_timespan_in)
                    )
                    not_used_section_titles = ", ".join(not_used_section_titles)
                    raise ValueError(
                        f'The section "{title}" that is specified in the'
                        ' "show_timespan_in" option is not found in the CV. You'
                        " might have wanted to use one of these:"
                        f" {not_used_section_titles}."
                    )

        return model


def read_input_file(file_path: str) -> RenderCVDataModel:
    """Read the input file.

    Args:
        file_path (str): The path to the input file.

    Returns:
        str: The input file as a string.
    """
    start_time = time.time()
    logger.info(f"Reading and validating the input file {file_path} has started.")

    # check if the file exists:
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"The file {file_path} doesn't exist.")

    # check the file extension:
    accepted_extensions = [".yaml", ".yml", ".json", ".json5"]
    if not any(file_path.endswith(extension) for extension in accepted_extensions):
        raise ValueError(
            f"The file {file_path} doesn't have an accepted extension!"
            f" Accepted extensions are: {accepted_extensions}"
        )

    with open(file_path) as file:
        yaml = YAML()
        raw_json = yaml.load(file)

    data = RenderCVDataModel(**raw_json)

    end_time = time.time()
    time_taken = end_time - start_time
    logger.info(
        f"Reading and validating the input file {file_path} has finished in"
        f" {time_taken:.2f} s."
    )
    return data
