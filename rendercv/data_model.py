"""
This module contains classes and functions to parse a specifically structured YAML or
JSON to generate meaningful data for Python.
"""

from datetime import date as Date
from typing import Literal
from typing_extensions import Annotated
import re
import logging
from functools import cached_property

from pydantic import (
    BaseModel,
    HttpUrl,
    Field,
    model_validator,
    computed_field,
    EmailStr,
    PastDate
)
from pydantic.functional_validators import AfterValidator
from pydantic_extra_types.phone_numbers import PhoneNumber
from pydantic_extra_types.color import Color

from spellchecker import SpellChecker

# ======================================================================================
# HELPERS ==============================================================================
# ======================================================================================

spell = SpellChecker()

# don't give spelling warnings for these words:
dictionary = [
    "aerostructures",
    "sportsperson",
    "cern",
    "mechatronics",
    "calculix",
    "microcontroller",
    "ansys",
    "nx",
    "aselsan",
    "hrjet",
    "simularge",
    "siemens",
    "dynamometer",
    "dc",
]


def check_spelling(sentence: str) -> str:
    """
    Check the spelling of a sentence and give warnings if there are any misspelled
    words.

    It uses pyspellchecker. It can also guess the correct version of the
    misspelled word, but it is not used because it is very slow.

    :param sentence: The sentence to be checked.
    :type sentence: str
    :return: The same sentence.
    """
    modifiedSentence = sentence.lower()  # convert to lower case
    modifiedSentence = re.sub(
        r"\-+", " ", modifiedSentence
    )  # replace hyphens with spaces
    modifiedSentence = re.sub(
        "[^a-z\s\-']", "", modifiedSentence
    )  # remove all the special characters
    words = modifiedSentence.split()  # split sentence into a list of words
    misspelled = spell.unknown(words)  # find misspelled words

    if len(misspelled) > 0:
        for word in misspelled:
            # for each misspelled word, check if it is in the dictionary and otherwise
            # give a warning
            if word in dictionary:
                continue

            logging.warning(
                f'The word "{word}" might be misspelled according to the'
                " pyspellchecker."
            )

    return sentence


SpellCheckedString = Annotated[str, AfterValidator(check_spelling)]


def compute_time_span_string(start_date: PastDate, end_date: PastDate) -> str:
    """
    Compute the time span between two dates and return a string that represents it. For,
    example, if the time span is 1 year and 3 months, it will return "1 year 3 months".

    :param start_date: The start date.
    :type start_date: PastDate
    :param end_date: The end date.
    :type end_date: PastDate
    :return: The time span string.
    :rtype: str
    """
    # calculate the number of days between start_date and end_date:
    timeSpanInDays = (end_date - start_date).days

    # calculate the number of years between start_date and end_date:
    howManyYears = timeSpanInDays // 365
    if howManyYears == 0:
        howManyYearsString = None
    elif howManyYears == 1:
        howManyYearsString = "1 year"
    else:
        howManyYearsString = f"{howManyYears} years"

    # calculate the number of months between start_date and end_date:
    howManyMonths = round((timeSpanInDays % 365) / 30)
    if howManyMonths == 0:
        howManyMonths = 1

    if howManyMonths == 0:
        howManyMonthsString = None
    elif howManyMonths == 1:
        howManyMonthsString = "1 month"
    else:
        howManyMonthsString = f"{howManyMonths} months"

    # combine howManyYearsString and howManyMonthsString:
    if howManyYearsString is None:
        timeSpanString = howManyMonthsString
    elif howManyMonthsString is None:
        timeSpanString = howManyYearsString
    else:
        timeSpanString = f"{howManyYearsString} {howManyMonthsString}"

    return timeSpanString


def format_date(date: Date) -> str:
    """
    To be continued...
    """
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


# ======================================================================================
# ======================================================================================
# ======================================================================================


# ======================================================================================
# DESIGN MODELS ========================================================================
# ======================================================================================


class ClassicThemeOptions(BaseModel):
    """
    In RenderCV, each theme has its own ThemeNameThemeOptions class so that new themes
    can be implemented easily.
    """

    primary_color: Color = Field(default="blue")

    page_top_margin: str = Field(default="1.35cm")
    page_bottom_margin: str = Field(default="1.35cm")
    page_left_margin: str = Field(default="1.35cm")
    page_right_margin: str = Field(default="1.35cm")

    section_title_top_margin: str = Field(default="0.13cm")
    section_title_bottom_margin: str = Field(default="0.13cm")

    vertical_margin_between_bullet_points: str = Field(default="0.07cm")
    bullet_point_left_margin: str = Field(default="0.7cm")

    vertical_margin_between_entries: str = Field(default="0.12cm")

    vertical_margin_between_entries_and_highlights: str = Field(default="0.12cm")

    date_and_location_width: str = Field(default="3.7cm")


class Design(BaseModel):
    theme: Literal["classic"] = "classic"
    options: ClassicThemeOptions


# ======================================================================================
# ======================================================================================
# ======================================================================================

# ======================================================================================
# CONTENT MODELS =======================================================================
# ======================================================================================


class Event(BaseModel):
    """s
    aa

    Attributes:
        test
    """

    start_date: PastDate = None
    end_date: PastDate | Literal["present"] = None
    date: str = None
    location: str = None
    highlights: list[SpellCheckedString] = None
    url: HttpUrl = None

    @model_validator(mode="after")
    @classmethod
    def check_dates(cls, model):
        """
        To be continued...
        """
        if (
            model.start_date is not None
            and model.end_date is not None
            and model.date is not None
        ):
            logging.warning(
                "start_date, end_date and date are all provided. Therefore, date will"
                " be ignored."
            )
            model.date = None
        elif model.date is not None and (
            model.start_date is not None or model.end_date is not None
        ):
            logging.warning(
                "date is provided. Therefore, start_date and end_date will be ignored."
            )
            model.start_date = None
            model.end_date = None

        return model

    @computed_field
    @cached_property
    def date_and_location_strings(self) -> list[str]:
        date_and_location_strings = []

        if self.location is not None:
            date_and_location_strings.append(self.location)

        if self.date is not None:
            # Then it means start_date and end_date are not provided.
            try:
                # If this runs, it means the date is an ISO format string, and it can be
                # parsed
                date = format_date(Date.fromisoformat(self.date))
                date_and_location_strings.append(date)
            except:
                date_and_location_strings.append(self.date)
        else:
            # Then it means start_date and end_date are provided.

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
    def date_and_location_strings_without_time_span(self) -> list[str]:
        strings_without_time_span = self.date_and_location_strings
        for string in strings_without_time_span:
            if (
                "years" in string
                or "months" in string
                or "year" in string
                or "month" in string
            ):
                strings_without_time_span.remove(string)

        return strings_without_time_span

    @computed_field
    @cached_property
    def highlight_strings(self) -> list[SpellCheckedString]:
        """
        To be continued...
        """
        highlight_strings = []

        highlight_strings.extend(self.highlights)

        return highlight_strings

    @computed_field
    @cached_property
    def markdown_url(self) -> str:
        """
        To be continued...
        """
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


class OneLineEntry(Event):
    # 1) Mandotory user inputs:
    name: str
    details: str


class NormalEntry(Event):
    # 1) Mandotory user inputs:
    name: str


class ExperienceEntry(Event):
    # 1) Mandotory user inputs:
    company: str
    position: str


class EducationEntry(Event):
    # 1) Mandotory user inputs:
    institution: str
    area: str
    # 2) Optional user inputs:
    study_type: str = None
    gpa: str = None
    transcript_url: HttpUrl = None

    @computed_field
    @cached_property
    def highlight_strings(self) -> list[SpellCheckedString]:
        highlight_strings = []

        if self.gpa is not None:
            gpaString = f"GPA: {self.gpa}"
            if self.transcript_url is not None:
                gpaString += f" ([Transcript]({self.transcript_url}))"
            highlight_strings.append(gpaString)

        highlight_strings.extend(self.highlights)

        return highlight_strings


class SocialNetwork(BaseModel):
    # 1) Mandotory user inputs:
    network: Literal["LinkedIn", "GitHub", "Instagram"]
    username: str


class Connection(BaseModel):
    # 3) Derived fields (not user inputs):
    name: Literal["LinkedIn", "GitHub", "Instagram", "phone", "email", "website"]
    value: str


class CurriculumVitae(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    # 2) Optional user inputs:
    email: EmailStr = None
    phone: PhoneNumber = None
    website: HttpUrl = None
    location: str = None
    social_networks: list[SocialNetwork] = None
    education: list[EducationEntry] = None
    work_experience: list[ExperienceEntry] = None
    academic_projects: list[NormalEntry] = None
    personal_projects: list[NormalEntry] = None
    certificates: list[NormalEntry] = None
    extracurricular_activities: list[ExperienceEntry] = None
    test_scores: list[OneLineEntry] = None
    skills: list[OneLineEntry] = None

    @computed_field
    @cached_property
    def connections(self) -> list[str]:
        connections = []
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


# ======================================================================================
# ======================================================================================
# ======================================================================================


class RenderCVDataModel(BaseModel):
    design: Design
    cv: CurriculumVitae
