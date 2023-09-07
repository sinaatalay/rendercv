from datetime import date as Date
from typing import Literal, Union
from typing_extensions import Annotated
import re
import logging
import math
from functools import cached_property

from pydantic import BaseModel, HttpUrl, model_validator, computed_field
from pydantic.functional_validators import AfterValidator
from pydantic_extra_types.phone_numbers import PhoneNumber

from spellchecker import SpellChecker

spell = SpellChecker()
# don't give spelling warnings for these words:
dictionary = [
    "aerostructures",
    "sportsperson",
    "cern",
    "calculix",
    "ansys",
    "nx",
    "aselsan",
    "hrjet",
    "simularge",
    "siemens",
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
    )  # remove unwanted characters
    words = modifiedSentence.split()  # split sentence into a list of words
    misspelled = spell.unknown(words)  # find misspelled words

    if len(misspelled) > 0:
        for word in misspelled:
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
    timeSpan = (end_date - start_date).days

    howManyYears = timeSpan // 365
    if howManyYears == 0:
        howManyYearsString = None
    elif howManyYears == 1:
        howManyYearsString = "1 year"
    else:
        howManyYearsString = f"{howManyYears} years"

    howManyMonths = math.ceil((timeSpan % 365) / 30)
    if howManyMonths == 0:
        howManyMonths = 1
        
    if howManyMonths == 0:
        howManyMonthsString = None
    elif howManyMonths == 1:
        howManyMonthsString = "1 month"
    else:
        howManyMonthsString = f"{howManyMonths} months"

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

    month = abbreviations_of_months[int(date.strftime("%m")) - 1]
    year = date.strftime("%Y")
    date_string = f"{month} {year}"

    return date_string


class Skill(BaseModel):
    # 1) Mandotory user inputs:
    name: str
    # 2) Optional user inputs:
    details: str = None


class Event(BaseModel):
    start_date: Date = None
    end_date: Date | Literal["present"] = None
    date: str = None
    location: str

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

        date_and_location_strings.append(self.location)

        if self.date is not None:
            # Then it means start_date and end_date are not provided.
            date_and_location_strings.append(str(self.start_date))
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


class TestScore(Event):
    # 1) Mandotory user inputs:
    name: str
    score: str
    # 2) Optional user inputs:
    url: HttpUrl = None


class Project(Event):
    # 1) Mandotory user inputs:
    name: str
    # 2) Optional user inputs:
    url: HttpUrl = None
    highlights: list[SpellCheckedString] = None


class Experience(Event):
    # 1) Mandotory user inputs:
    company: str
    position: str
    # 2) Optional user inputs:
    highlights: list[SpellCheckedString] = None


class Education(Event):
    # 1) Mandotory user inputs:
    institution: str
    area: str
    # 2) Optional user inputs:
    study_type: str = None
    gpa: str = None
    transcript_url: HttpUrl = None
    highlights: list[SpellCheckedString] = None

    @computed_field
    @cached_property
    def highlight_strings(self) -> list[str]:
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
    education: list[Education] = None
    work_experience: list[Experience] = None
    academic_projects: list[Project] = None
    extracurricular_activities: list[Experience] = None
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
