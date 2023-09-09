from datetime import date as Date
from typing import Literal
from typing_extensions import Annotated
import re
import logging
import math
from functools import cached_property

from pydantic import BaseModel, HttpUrl, Field, model_validator, computed_field
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
    To be continued...
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


def compute_time_span_string(start_date: Date, end_date: Date) -> str:
    """
    To be continued...
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


class Skill(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    # 2) Optional user inputs:
    details: str = None


class Event(BaseModel):
    start_date: Date = None
    end_date: Date | Literal["present"] = None
    date: str | Date = None
    location: str = None
    highlights: list[SpellCheckedString] = None

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

            list_of_no_time_span_string_classes = [
                "Education",
            ]
            if not self.__class__.__name__ in list_of_no_time_span_string_classes:
                date_and_location_strings.append(f"{time_span_string}")

        return date_and_location_strings

    @computed_field
    @cached_property
    def highlight_strings(self) -> list[SpellCheckedString]:
        """
        To be continued...
        """
        highlight_strings = []

        highlight_strings.extend(self.highlights)

        return highlight_strings


class TestScore(Event):
    # 1) Mandotory user inputs:
    name: str
    score: str
    # 2) Optional user inputs:
    url: HttpUrl = None


class NormalEntry(Event):
    # 1) Mandotory user inputs:
    name: str
    # 2) Optional user inputs:
    url: HttpUrl = None

    @computed_field
    @cached_property
    def highlight_strings(self) -> list[SpellCheckedString]:
        """
        To be continued...
        """
        highlight_strings = []

        highlight_strings.extend(self.highlights)

        if self.url is not None:
            # remove "https://" from the url for a cleaner look
            textUrl = str(self.url).replace("https://", "")
            linkString = f"Course certificate: [{textUrl}]({self.transcript_url}))"
            highlight_strings.append(linkString)

        return highlight_strings


class ExperienceEntry(Event):
    # 1) Mandotory user inputs:
    company: str
    position: str
    # 2) Optional user inputs:


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
        """
        To be continued...
        """
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
    email: str = None
    phone: PhoneNumber = None
    website: HttpUrl = None
    location: str = None
    social_networks: list[SocialNetwork] = None
    education: list[EducationEntry] = None
    work_experience: list[ExperienceEntry] = None
    academic_projects: list[NormalEntry] = None
    certificates: list[NormalEntry] = None
    extracurricular_activities: list[ExperienceEntry] = None
    test_scores: list[TestScore] = None
    skills: list[Skill] = None

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
