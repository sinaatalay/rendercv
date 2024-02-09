"""
This module contains all the necessary classes to store CV data. These classes are called
data models. The YAML input file is transformed into instances of these classes (i.e.,
the input file is read) with the [`read_input_file`](#read_input_file) function.
RenderCV utilizes these instances to generate a LaTeX file which is then rendered into a
PDF file.

The data models are initialized with data validation to prevent unexpected bugs. During
the initialization, we ensure that everything is in the correct place and that the user
has provided a valid RenderCV input. This is achieved through the use of
[Pydantic](https://pypi.org/project/pydantic/).
"""

from datetime import date as Date
from typing import Literal, Any, Type
from typing_extensions import Annotated, Optional
from functools import cached_property
from urllib.request import urlopen, HTTPError
import json
import re
import ssl
import pathlib

import pydantic
import pydantic_extra_types.phone_numbers as pydantic_phone_numbers
import ruamel.yaml

from .themes.classic import ClassicThemeOptions

# Create a custom type called RenderCVDate that accepts only strings in YYYY-MM-DD or
# YYYY-MM format:
# This type is used to validate the date fields in the data.
# See https://docs.pydantic.dev/2.5/concepts/types/#custom-types for more information
# about custom types.
RenderCVDate = Annotated[
    str,
    pydantic.Field(pattern=r"\d{4}-\d{2}(-\d{2})?"),
]


def get_date_object(date: str | int) -> Date:
    """Parse a date string in YYYY-MM-DD, YYYY-MM, or YYYY format and return a
    datetime.date object. This function is used throughout the validation process of the
    data models.

    Args:
        date_string (str): The date string to parse.
    Returns:
        datetime.date: The parsed date.
    """
    if isinstance(date, int):
        date_object = Date.fromisoformat(f"{date}-01-01")
    elif re.fullmatch(r"\d{4}-\d{2}-\d{2}", date):
        # Then it is in YYYY-MM-DD format
        date_object = Date.fromisoformat(date)
    elif re.fullmatch(r"\d{4}-\d{2}", date):
        # Then it is in YYYY-MM format
        date_object = Date.fromisoformat(f"{date}-01")
    elif re.fullmatch(r"\d{4}", date):
        # Then it is in YYYY format
        date_object = Date.fromisoformat(f"{date}-01-01")
    elif date == "present":
        date_object = Date.today()
    else:
        raise ValueError(
            "This is not a valid date! Please use either YYYY-MM-DD, YYYY-MM, or"
            " YYYY format."
        )

    return date_object


def format_date(date: Date) -> str:
    """Formats a `Date` object to a string in the following format: "Jan. 2021".

    It uses month abbreviations, taken from
    [Yale University Library](https://web.library.yale.edu/cataloging/months).

    Example:
        ```python
        format_date(Date(2024, 5, 1))
        ```
        will return

        `#!python "May 2024"`

    Args:
        date (Date): The date to format.

    Returns:
        str: The formatted date.
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
    month_abbreviation = abbreviations_of_months[month - 1]
    year = date.strftime(format="%Y")
    date_string = f"{month_abbreviation} {year}"

    return date_string


class RenderCVBaseModel(pydantic.BaseModel):
    """This class is the parent class of all the data models in RenderCV. It has only
    one difference from the default `pydantic.BaseModel`: It raises an error if an
    unknown key is provided in the input file.
    """

    model_config = pydantic.ConfigDict(extra="forbid")


# ======================================================================================
# Entry models: ========================================================================
# ======================================================================================


class EntryBase(RenderCVBaseModel):
    """This class is the parent class of some of the entry types. It is being used
    because some of the entry types have common fields like dates, highlights, location,
    etc.
    """

    start_date: Optional[int | RenderCVDate] = pydantic.Field(
        default=None,
        title="Start Date",
        description=(
            "The start date of the event in YYYY-MM-DD, YYYY-MM, or YYYY format."
        ),
        examples=["2020-09-24"],
    )
    end_date: Optional[Literal["present"] | int | RenderCVDate] = pydantic.Field(
        default=None,
        title="End Date",
        description=(
            "The end date of the event in YYYY-MM-DD, YYYY-MM, or YYYY format. If the"
            ' event is still ongoing, then type "present" or provide only the start'
            " date."
        ),
        examples=["2020-09-24", "present"],
    )
    date: Optional[RenderCVDate | int | str] = pydantic.Field(
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
    highlights: Optional[list[str]] = pydantic.Field(
        default=None,
        title="Highlights",
        description="The highlights of the event as a list of strings.",
        examples=["Did this.", "Did that."],
    )
    location: Optional[str] = pydantic.Field(
        default=None,
        title="Location",
        description="The location of the event.",
        examples=["Istanbul, Turkey"],
    )
    url: Optional[pydantic.HttpUrl] = None
    url_text_input: Optional[str] = pydantic.Field(default=None, alias="url_text")

    @pydantic.model_validator(
        mode="after",
    )  # type: ignore
    @classmethod
    def check_dates(cls, model: "EntryBase") -> "EntryBase":
        """
        Check if the dates are provided correctly and do the necessary adjustments.
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

        if date_is_provided:
            try:
                date_object = get_date_object(model.date)  # type: ignore
            except ValueError:
                # Then it is a custom date string (e.g., "My Custom Date")
                pass
            else:
                today_object = Date.today()
                if date_object > today_object:
                    raise ValueError(
                        '"date" cannot be in the future.',
                        "date",  # this is the location of the error
                        model.date,  # this is value of the error
                    )

        elif start_date_is_provided and not end_date_is_provided:
            model.end_date = "present"

        elif not start_date_is_provided and end_date_is_provided:
            raise ValueError(
                '"end_date" is provided in of the entries, but "start_date" is not.'
                ' Either provide both "start_date" and "end_date" or provide "date".',
                "start_date",  # this is the location of the error
                "",  # this supposed to be the value of the error
            )

        if model.start_date is not None and model.end_date is not None:
            try:
                end_date = get_date_object(model.end_date)
            except ValueError as e:
                raise ValueError(str(e), "end_date", model.end_date)

            try:
                start_date = get_date_object(model.start_date)
            except ValueError as e:
                raise ValueError(str(e), "start_date", model.start_date)

            if start_date > end_date:
                raise ValueError(
                    '"start_date" can not be after "end_date"',
                    "start_date/end_date",  # this is the location of the error
                    "",  # this supposed to be the value of the error
                )
            elif end_date > Date.today():
                raise ValueError(
                    '"end_date" cannot be in the future.',
                    "end_date",  # this is the location of the error
                    model.end_date,  # this is value of the error
                )

        return model

    @cached_property
    def date_string(self) -> str:
        """
        Return a date string based on the `date`, `start_date`, and `end_date` fields.

        Example:
            ```python
            entry = dm.EntryBase(start_date=2020-10-11, end_date=2021-04-04).date_string
            ```
            will return:
            `#!python "2020-10-11 to 2021-04-04"`
        """
        if self.date is not None:
            try:
                date_object = get_date_object(self.date)
                date_string = format_date(date_object)
            except ValueError:
                # Then it is a custom date string (e.g., "My Custom Date")
                date_string = str(self.date)

        elif self.start_date is not None and self.end_date is not None:
            if isinstance(self.start_date, int):
                # Then it means only the year is provided
                start_date = str(self.start_date)
            else:
                # Then it means start_date is either in YYYY-MM-DD or YYYY-MM format
                date_object = get_date_object(self.start_date)
                start_date = format_date(date_object)

            if self.end_date == "present":
                end_date = "present"
            elif isinstance(self.end_date, int):
                # Then it means only the year is provided
                end_date = str(self.end_date)
            else:
                # Then it means end_date is either in YYYY-MM-DD or YYYY-MM format
                date_object = get_date_object(self.end_date)
                end_date = format_date(date_object)

            date_string = f"{start_date} to {end_date}"

        else:
            # Neither date, start_date, nor end_date is provided, so return an empty
            # string:
            date_string = ""

        return date_string

    @cached_property
    def time_span_string(self) -> str:
        """
        Return a time span string based on the `date`, `start_date`, and `end_date`
        fields.

        Example:
            ```python
            entry = dm.EntryBase(start_date=2020-01-01, end_date=2020-04-20).time_span
            ```
            will return:
            `#!python "4 months"`
        """
        start_date = self.start_date
        end_date = self.end_date
        date = self.date

        if date is not None or (start_date is None and end_date is None):
            # If only the date is provided, the time span is irrelevant. So, return an
            # empty string.
            return ""

        elif isinstance(start_date, int) or isinstance(end_date, int):
            # Then it means one of the dates is year, so time span cannot be more
            # specific than years.
            start_year = get_date_object(start_date).year  # type: ignore
            end_year = get_date_object(end_date).year  # type: ignore

            time_span_in_years = end_year - start_year

            if time_span_in_years < 2:
                time_span_string = "1 year"
            else:
                time_span_string = f"{time_span_in_years} years"

            return time_span_string

        else:
            # Then it means both start_date and end_date are in YYYY-MM-DD or YYYY-MM
            # format.
            end_date = get_date_object(end_date)  # type: ignore
            start_date = get_date_object(start_date)  # type: ignore

            # calculate the number of days between start_date and end_date:
            timespan_in_days = (end_date - start_date).days  # type: ignore

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
                time_span_string = how_many_months_string
            else:
                time_span_string = f"{how_many_years_string} {how_many_months_string}"

            return time_span_string

    @cached_property
    def url_text(self) -> Optional[str]:
        """
        Return a URL text based on the `url_text_input` and `url` fields.
        """
        url_text = None
        if self.url_text_input is not None:
            # If the user provides a custom URL text, then use it.
            url_text = self.url_text_input
        elif self.url is not None:
            url_text_dictionary = {
                "github": "view on GitHub",
                "linkedin": "view on LinkedIn",
                "instagram": "view on Instagram",
                "youtube": "view on YouTube",
            }
            url_text = "view on my website"
            for key in url_text_dictionary:
                if key in str(self.url):
                    url_text = url_text_dictionary[key]
                    break

        return url_text


class OneLineEntry(RenderCVBaseModel):
    """This class is the data model of `OneLineEntry`."""

    name: str = pydantic.Field(
        title="Name",
        description="The name of the entry. It will be shown as bold text.",
    )
    details: str = pydantic.Field(
        title="Details",
        description="The details of the entry. It will be shown as normal text.",
    )


class NormalEntry(EntryBase):
    """This class is the data model of `NormalEntry`."""

    name: str = pydantic.Field(
        title="Name",
        description="The name of the entry. It will be shown as bold text.",
    )


class ExperienceEntry(EntryBase):
    """This class is the data model of `ExperienceEntry`."""

    company: str = pydantic.Field(
        title="Company",
        description="The company name. It will be shown as bold text.",
    )
    position: str = pydantic.Field(
        title="Position",
        description="The position. It will be shown as normal text.",
    )


class EducationEntry(EntryBase):
    """This class is the data model of `EducationEntry`."""

    institution: str = pydantic.Field(
        title="Institution",
        description="The institution name. It will be shown as bold text.",
        examples=["Bogazici University"],
    )
    area: str = pydantic.Field(
        title="Area",
        description="The area of study. It will be shown as normal text.",
    )
    degree: Optional[str] = pydantic.Field(
        default=None,
        title="Degree",
        description="The type of the degree.",
        examples=["BS", "BA", "PhD", "MS"],
    )


class PublicationEntry(RenderCVBaseModel):
    """This class is the data model of `PublicationEntry`."""

    title: str = pydantic.Field(
        title="Title of the Publication",
        description="The title of the publication. It will be shown as bold text.",
    )
    authors: list[str] = pydantic.Field(
        title="Authors",
        description="The authors of the publication in order as a list of strings.",
    )
    doi: str = pydantic.Field(
        title="DOI",
        description="The DOI of the publication.",
        examples=["10.48550/arXiv.2310.03138"],
    )
    date: int | RenderCVDate = pydantic.Field(
        title="Publication Date",
        description=(
            "The date of the publication in YYYY-MM-DD, YYYY-MM, or YYYY format."
        ),
        examples=["2021-10-31", "2010"],
    )
    journal: Optional[str] = pydantic.Field(
        default=None,
        title="Journal",
        description="The journal or the conference name.",
    )

    @pydantic.field_validator("date")
    @classmethod
    def check_date(cls, date: int | RenderCVDate) -> int | RenderCVDate:
        """Check if the date is in the past."""
        date_object = get_date_object(date)
        if date_object > Date.today():
            raise ValueError("The publication date cannot be in the future!")

        return date

    @pydantic.field_validator("doi")
    @classmethod
    def check_doi(cls, doi: str) -> str:
        """Check if the DOI exists in the DOI System."""
        # see https://stackoverflow.com/a/60671292/18840665 for the explanation of the
        # next line:
        ssl._create_default_https_context = ssl._create_unverified_context

        doi_url = f"http://doi.org/{doi}"

        try:
            urlopen(doi_url)
        except HTTPError as err:
            if err.code == 404:
                raise ValueError("DOI cannot be found in the DOI System!")

        return doi

    @cached_property
    def doi_url(self) -> str:
        """Return the URL of the DOI."""
        return f"https://doi.org/{self.doi}"

    @cached_property
    def date_string(self) -> str:
        """Return the date string of the publication."""
        if isinstance(self.date, int):
            date_string = str(self.date)
        elif isinstance(self.date, str):
            date_object = get_date_object(self.date)
            date_string = format_date(date_object)

        return date_string


# ======================================================================================
# Section models: ======================================================================
# ======================================================================================
# Each section data model has a field called `entry_type` and a field called `entries`.
# Since the same pydantic.Field object is used in all of the section models, it is
# defined as a separate variable and used in all of the section models:
entry_type_field_of_section_model = pydantic.Field(
    title="Entry Type",
    description="The type of the entries in the section.",
)
entries_field_of_section_model = pydantic.Field(
    title="Entries",
    description="The entries of the section. The format depends on the entry type.",
)


class SectionBase(RenderCVBaseModel):
    """This class is the parent class of all the section types. It is being used
    because all of the section types have a common field called `title`.
    """

    # Title is excluded from the JSON schema because this will be written by RenderCV
    # depending on the key in the input file.
    title: Optional[str] = pydantic.Field(default=None, exclude=True)


class SectionWithEducationEntries(SectionBase):
    """This class is the data model of the section with `EducationEntry`s."""

    entry_type: Literal["EducationEntry"] = entry_type_field_of_section_model
    entries: list[EducationEntry] = entries_field_of_section_model


class SectionWithExperienceEntries(SectionBase):
    """This class is the data model of the section with `ExperienceEntry`s."""

    entry_type: Literal["ExperienceEntry"] = entry_type_field_of_section_model
    entries: list[ExperienceEntry] = entries_field_of_section_model


class SectionWithNormalEntries(SectionBase):
    """This class is the data model of the section with `NormalEntry`s."""

    entry_type: Literal["NormalEntry"] = entry_type_field_of_section_model
    entries: list[NormalEntry] = entries_field_of_section_model


class SectionWithOneLineEntries(SectionBase):
    """This class is the data model of the section with `OneLineEntry`s."""

    entry_type: Literal["OneLineEntry"] = entry_type_field_of_section_model
    entries: list[OneLineEntry] = entries_field_of_section_model


class SectionWithPublicationEntries(SectionBase):
    """This class is the data model of the section with `PublicationEntry`s."""

    entry_type: Literal["PublicationEntry"] = entry_type_field_of_section_model
    entries: list[PublicationEntry] = entries_field_of_section_model


class SectionWithTextEntries(SectionBase):
    """This class is the data model of the section with `TextEntry`s."""

    entry_type: Literal["TextEntry"] = entry_type_field_of_section_model
    entries: list[str] = entries_field_of_section_model


# Create a custom type called Section:
# It is a union of all the section types and the correct section type is determined by
# the entry_type field, thanks Pydantic's discriminator feature.
# See https://docs.pydantic.dev/2.5/concepts/fields/#discriminator for more information
# about discriminators.
Section = Annotated[
    SectionWithEducationEntries
    | SectionWithExperienceEntries
    | SectionWithNormalEntries
    | SectionWithOneLineEntries
    | SectionWithPublicationEntries
    | SectionWithTextEntries,
    pydantic.Field(
        discriminator="entry_type",
    ),
]


def get_entry_and_section_type(
    entry: (
        dict[str, Any]
        | EducationEntry
        | ExperienceEntry
        | PublicationEntry
        | NormalEntry
        | OneLineEntry
        | str
    ),
) -> tuple[
    str,
    Type[
        SectionWithTextEntries
        | SectionWithOneLineEntries
        | SectionWithExperienceEntries
        | SectionWithEducationEntries
        | SectionWithPublicationEntries
        | SectionWithNormalEntries
    ],
]:
    """Determine the entry and section type based on the entry.

    Args:
        entry (dict[str, Any] | EducationEntry | ExperienceEntry | PublicationEntry |
        NormalEntry | OneLineEntry | str): The entry to determine the type.
    Returns:
        tuple[str, Type[SectionWithTextEntries | SectionWithOneLineEntries |
        SectionWithExperienceEntries | SectionWithEducationEntries |
        SectionWithPublicationEntries | SectionWithNormalEntries]]: The entry type and the
        section type.
    """
    if isinstance(entry, dict):
        if "details" in entry:
            entry_type = "OneLineEntry"
            section_type = SectionWithOneLineEntries
        elif "company" in entry:
            entry_type = "ExperienceEntry"
            section_type = SectionWithExperienceEntries
        elif "institution" in entry:
            entry_type = "EducationEntry"
            section_type = SectionWithEducationEntries
        elif "title" in entry:
            entry_type = "PublicationEntry"
            section_type = SectionWithPublicationEntries
        elif "name" in entry:
            entry_type = "NormalEntry"
            section_type = SectionWithNormalEntries
        else:
            raise ValueError("The entry is not provided correctly.")
    else:
        if isinstance(entry, str):
            entry_type = "TextEntry"
            section_type = SectionWithTextEntries
        elif isinstance(entry, OneLineEntry):
            entry_type = "OneLineEntry"
            section_type = SectionWithOneLineEntries
        elif isinstance(entry, ExperienceEntry):
            entry_type = "ExperienceEntry"
            section_type = SectionWithExperienceEntries
        elif isinstance(entry, EducationEntry):
            entry_type = "EducationEntry"
            section_type = SectionWithEducationEntries
        elif isinstance(entry, PublicationEntry):
            entry_type = "PublicationEntry"
            section_type = SectionWithPublicationEntries
        elif isinstance(entry, NormalEntry):
            entry_type = "NormalEntry"
            section_type = SectionWithNormalEntries
        else:
            raise RuntimeError(
                "This error shouldn't have been raised. Please open an issue on GitHub."
            )

    return entry_type, section_type


def validate_section_input(
    sections_input: Section | list[Any],
) -> Section | list[Any]:
    """Validate a SectionInput object and raise an error if it is not valid.

    Sections input is very complex. It is either a `Section` object or a list of
    entries. Since there are multiple entry types, it is not possible to validate it
    directly. This function looks at the entry list's first element and determines the
    section's entry type based on the first element. Then, it validates the rest of the
    list based on the determined entry type. If it is a `Section` object, then it
    validates it directly.

    Args:
        sections_input (Section | list[Any]): The sections input to validate.
    Returns:
        Section | list[Any]: The validated sections input.
    """
    if isinstance(sections_input, list):
        # find the entry type based on the first element of the list:
        try:
            entry_type, section_type = get_entry_and_section_type(sections_input[0])
        except ValueError:
            raise ValueError("The entries are not provided correctly.")

        test_section = {
            "title": "Test Section",
            "entry_type": entry_type,
            "entries": sections_input,
        }

        section_type.model_validate(test_section)

    return sections_input


# Create a custom type called SectionInput so that it can be validated with
# `validate_section_input` function.
SectionInput = Annotated[
    Section
    | list[
        EducationEntry
        | ExperienceEntry
        | PublicationEntry
        | NormalEntry
        | OneLineEntry
        | str
    ],
    pydantic.BeforeValidator(validate_section_input),
]


# ======================================================================================
# Full RenderCV data models: ===========================================================
# ======================================================================================


class SocialNetwork(RenderCVBaseModel):
    """This class is the data model of a social network."""

    network: Literal[
        "LinkedIn", "GitHub", "Instagram", "Orcid", "Mastodon", "Twitter"
    ] = pydantic.Field(
        title="Social Network",
        description="The social network name.",
    )
    username: str = pydantic.Field(
        title="Username",
        description="The username of the social network. The link will be generated.",
    )

    @pydantic.model_validator(mode="after")  # type: ignore
    @classmethod
    def check_networks(cls, model: "SocialNetwork") -> "SocialNetwork":
        """Check if the `SocialNetwork` is provided correctly."""
        if model.network == "Mastodon":
            if not model.username.startswith("@"):
                raise ValueError("Mastodon username should start with '@'!", "username")
            if model.username.count("@") > 2:
                raise ValueError(
                    "Mastodon username should contain only two '@'!", "username"
                )

        return model

    @cached_property
    def url(self) -> pydantic.HttpUrl:
        """Return the URL of the social network."""
        url_dictionary = {
            "LinkedIn": "https://linkedin.com/in/",
            "GitHub": "https://github.com/",
            "Instagram": "https://instagram.com/",
            "Orcid": "https://orcid.org/",
            "Mastodon": "https://mastodon.social/",
            "Twitter": "https://twitter.com/",
        }
        url = url_dictionary[self.network] + self.username

        HttpUrlAdapter = pydantic.TypeAdapter(pydantic.HttpUrl)
        url = HttpUrlAdapter.validate_python(url)

        return url


class CurriculumVitae(RenderCVBaseModel):
    """This class is the data model of the CV."""

    name: str = pydantic.Field(
        title="Name",
        description="The name of the person.",
    )
    label: Optional[str] = pydantic.Field(
        default=None,
        title="Label",
        description="The label of the person.",
    )
    location: Optional[str] = pydantic.Field(
        default=None,
        title="Location",
        description="The location of the person. This is not rendered currently.",
    )
    email: Optional[pydantic.EmailStr] = pydantic.Field(
        default=None,
        title="Email",
        description="The email of the person. It will be rendered in the heading.",
    )
    phone: Optional[pydantic_phone_numbers.PhoneNumber] = None
    website: Optional[pydantic.HttpUrl] = None
    social_networks: Optional[list[SocialNetwork]] = pydantic.Field(
        default=None,
        title="Social Networks",
        description=(
            "The social networks of the person. They will be rendered in the heading."
        ),
    )
    sections_input: dict[str, SectionInput] = pydantic.Field(
        default=None,
        title="Sections",
        description="The sections of the CV.",
        alias="sections",
    )

    @cached_property
    def sections(self) -> list[Section]:
        """Return all the sections of the CV with their titles."""
        sections = []
        if self.sections_input is not None:
            for title, section_or_entries in self.sections_input.items():
                title = title.replace("_", " ").title()
                if isinstance(section_or_entries, list):
                    entry_type, section_type = get_entry_and_section_type(
                        section_or_entries[0]
                    )

                    section = section_type(
                        title=title,
                        entry_type=entry_type,  # type: ignore
                        entries=section_or_entries,  # type: ignore
                    )
                    sections.append(section)

                elif hasattr(section_or_entries, "entry_type"):
                    if section_or_entries.title is None:
                        section_or_entries.title = title

                    sections.append(section_or_entries)

                else:
                    raise RuntimeError(
                        "This error shouldn't have been raised. Please open an"
                        " issue on GitHub."
                    )

        return sections


# ======================================================================================
# ======================================================================================
# ======================================================================================

# Create a custom type called Design:
# It is a union of all the design options and the correct design option is determined by
# the theme field, thanks Pydantic's discriminator feature.
# See https://docs.pydantic.dev/2.5/concepts/fields/#discriminator for more information
# about discriminators.
Design = ClassicThemeOptions


class RenderCVDataModel(RenderCVBaseModel):
    """This class binds both the CV and the design information together."""

    cv: CurriculumVitae = pydantic.Field(
        title="Curriculum Vitae",
        description="The data of the CV.",
    )
    design: Design = pydantic.Field(
        default=ClassicThemeOptions(theme="classic"),
        title="Design",
        description="The design information of the CV.",
        discriminator="theme",
    )


def escape_latex_characters(string: str) -> str:
    """Escape $\\LaTeX$ characters in a string.

    This function is called during the reading of the input file. Before the validation
    process, each input field's special $\\LaTeX$ characters are escaped.

    Example:
        ```python
        escape_latex_characters("This is a # string.")
        ```
        will return:
        `#!python "This is a \\# string."`
    """

    # Dictionary of escape characters:
    escape_characters = {
        "#": "\\#",
        # "$": "\\$", # Don't escape $ as it is used for math mode
        "%": "\\%",
        "&": "\\&",
        "~": "\\textasciitilde{}",
        # "_": "\\_", # Don't escape _ as it is used for math mode
        # "^": "\\textasciicircum{}", # Don't escape ^ as it is used for math mode
    }

    # Don't escape links as hyperref package will do it automatically:

    # Find all the links in the sentence:
    links = re.findall(r"\[.*?\]\(.*?\)", string)

    # Replace the links with a placeholder:
    for link in links:
        string = string.replace(link, "!!-link-!!")

    # Loop through the letters of the sentence and if you find an escape character,
    # replace it with its LaTeX equivalent:
    copy_of_the_string = list(string)
    for i, character in enumerate(copy_of_the_string):
        if character in escape_characters:
            new_character = escape_characters[character]
            copy_of_the_string[i] = new_character

    string = "".join(copy_of_the_string)
    # Replace the links with the original links:
    for link in links:
        string = string.replace("!!-link-!!", link)

    return string


def markdown_to_latex(markdown_string: str) -> str:
    """Convert a markdown string to LaTeX.

    This function is called during the reading of the input file. Before the validation
    process, each input field is converted from markdown to LaTeX.

    Example:
        ```python
        markdown_to_latex("This is a **bold** text with an [*italic link*](https://google.com).")
        ```

        will return:

        `#!pytjon "This is a \\textbf{bold} text with a \\href{https://google.com}{\\textit{link}}."`

    Args:
        markdown_string (str): The markdown string to convert.

    Returns:
        str: The LaTeX string.
    """
    # convert links
    links = re.findall(r"\[([^\]\[]*)\]\((.*?)\)", markdown_string)
    if links is not None:
        for link in links:
            link_text = link[0]
            link_url = link[1]

            old_link_string = f"[{link_text}]({link_url})"
            new_link_string = "\\href{" + link_url + "}{" + link_text + "}"

            markdown_string = markdown_string.replace(old_link_string, new_link_string)

    # convert bold
    bolds = re.findall(r"\*\*([^\*]*)\*\*", markdown_string)
    if bolds is not None:
        for bold_text in bolds:
            old_bold_text = f"**{bold_text}**"
            new_bold_text = "\\textbf{" + bold_text + "}"

            markdown_string = markdown_string.replace(old_bold_text, new_bold_text)

    # convert italic
    italics = re.findall(r"\*([^\*]*)\*", markdown_string)
    if italics is not None:
        for italic_text in italics:
            old_italic_text = f"*{italic_text}*"
            new_italic_text = "\\textit{" + italic_text + "}"

            markdown_string = markdown_string.replace(old_italic_text, new_italic_text)

    # convert code
    codes = re.findall(r"`([^`]*)`", markdown_string)
    if codes is not None:
        for code_text in codes:
            old_code_text = f"`{code_text}`"
            new_code_text = "\\texttt{" + code_text + "}"

            markdown_string = markdown_string.replace(old_code_text, new_code_text)

    latex_string = markdown_string

    return latex_string


def convert_a_markdown_dictionary_to_a_latex_dictionary(
    dictionary: dict[str, Any],
) -> dict[str, Any]:
    """
    Recursively loop through a dictionary and convert all the markdown strings (keys and
    values) to LaTeX. Also, escape special LaTeX characters in the keys and values.

    Example:
        ```python
        convert_a_markdown_dictionary_to_a_latex_dictionary(
            {
                "key1": "This is a **bold** text with an [*italic link*](https://google.com).",
                "key2": "This is a **bold** text with an [*italic link*](https://google.com).",
                "**key3**": {
                    "key4": "This is a **bold** text with an [*italic link*](https://google.com).",
                    "key5": "This is a **bold** text with an [*italic link*](https://google.com).",
                },
            }
        )
        ```

        will return:

        ```python
        {
            "key1": "This is a \\textbf{bold} text with a \\href{https://google.com}{\\textit{link}}.",
            "key2": "This is a \\textbf{bold} text with a \\href{https://google.com}{\\textit{link}}.",
            "\\textbf{key3}": {
                "key4": "This is a \\textbf{bold} text with a \\href{https://google.com}{\\textit{link}}.",
                "key5": "This is a \\textbf{bold} text with a \\href{https://google.com}{\\textit{link}}.",
            },
        }
        ```

    Args:
        dictionary (dict): The dictionary to convert.
    Returns:
        dict: The LaTeX dictionary.
    """
    for key, value in dictionary.copy().items():
        if isinstance(value, str):
            # if the value is a string, then apply markdown_to_latex and
            # escape_latex_characters to it:
            result = escape_latex_characters(value)
            dictionary[key] = markdown_to_latex(result)
        elif isinstance(value, list):
            # if the value is a list, then loop through the list and apply
            # markdown_to_latex and escape_latex_characters to each item:
            for index, item in enumerate(value):
                if isinstance(item, str):
                    result = escape_latex_characters(item)
                    dictionary[key][index] = markdown_to_latex(result)
                elif isinstance(item, dict):
                    # if the item is a dictionary, then call loop_through_dictionary
                    # again:
                    dictionary[key][index] = (
                        convert_a_markdown_dictionary_to_a_latex_dictionary(item)
                    )
        elif isinstance(value, dict):
            # if the value is a dictionary, then call loop_through_dictionary again:
            dictionary[key] = convert_a_markdown_dictionary_to_a_latex_dictionary(value)

        # do the same for the key:
        result = escape_latex_characters(key)
        dictionary[markdown_to_latex(result)] = dictionary.pop(key)

    return dictionary


def read_input_file(file_path: pathlib.Path) -> RenderCVDataModel:
    """Read the input file and return an instance of RenderCVDataModel.

    This function reads the input file, converts the markdown strings to $\\LaTeX$, and
    validates the input file with the data models.

    Args:
        file_path (str): The path to the input file.

    Returns:
        str: The input file as a string.
    """
    # check if the file exists:
    if not file_path.exists():
        raise FileNotFoundError(f"The input file {file_path} doesn't exist.")

    # check the file extension:
    accepted_extensions = [".yaml", ".yml", ".json", ".json5"]
    if file_path.suffix not in accepted_extensions:
        raise ValueError(
            "The input file should have one of the following extensions:"
            f" {accepted_extensions}. The input file is {file_path}."
        )

    file_content = file_path.read_text()
    parsed_dictionary: dict[str, Any] = ruamel.yaml.YAML().load(file_content)
    parsed_dictionary = convert_a_markdown_dictionary_to_a_latex_dictionary(
        parsed_dictionary
    )

    # validate the parsed dictionary by creating an instance of RenderCVDataModel:
    data = RenderCVDataModel(**parsed_dictionary)  ## type: ignore

    return data


def get_a_sample_data_model(name: str) -> RenderCVDataModel:
    """Return a sample data model for new users to start with."""
    sections = {
        "summary": [
            (
                "I am a mechanical engineer with a [passion](https://example.com) for"
                " software development."
            ),
            "I am a **quick learner** and ***I love*** to learn new things.",
        ],
        "education": [
            EducationEntry(
                institution="Your University",
                area="Mechanical Engineering",
                degree="MS",
                start_date="2019-12",
                end_date="2021-12-22",
                highlights=[
                    "Did something great.",
                    "Did something else great.",
                ],
            ),
            EducationEntry(
                institution="Your University",
                area="Mechanical Engineering",
                location="Istanbul, Turkey",
                degree="BS",
                start_date=2015,
                end_date=2019,
            ),
        ],
        "experience": [
            ExperienceEntry(
                company="Your Company",
                position="Your Position",
                date="My Whole Life",
                location="USA",
                url="https://yourcompany.com",  # type: ignore
                url_text="view company website",
                highlights=[
                    "Did something great.",
                    "Did something else great.",
                ],
            ),
            ExperienceEntry(
                company="Your Company",
                position="Your Position",
            ),
        ],
        "publications": [
            PublicationEntry(
                title="My first publication",
                authors=["John Doe", name, "Jane Doe"],
                date="2015-01",
                doi="10.1109/TASC.2023.3340648",
            )
        ],
        "projects": [
            NormalEntry(
                name="Your Project",
                highlights=[
                    "Did [something](https://example.com) great.",
                    "Did something else great.",
                ],
            ),
            NormalEntry(
                name="Your Project",
                location="Istanbul, Turkey",
                date="2015-01",
                url="https://yourproject.com",  # type: ignore
                url_text="view details",
                highlights=[
                    "Did something **great**.",
                    "Did *something* else great.",
                ],
            ),
        ],
        "skills": [
            OneLineEntry(
                name="Programming Languages",
                details="Python, C++, JavaScript",
            ),
            OneLineEntry(
                name="Languages",
                details=(
                    "English ([TOEFL: 120/120](https://example.com)), Turkish (Native)"
                ),
            ),
        ],
        "my_custom_section": SectionWithExperienceEntries(
            entry_type="ExperienceEntry",
            entries=[
                ExperienceEntry(
                    company="Your Company",
                    position="Your Position",
                    date="My Whole Life",
                    location="USA",
                    url="https://yourcompany.com",  # type: ignore
                    url_text="view company website",
                    highlights=[
                        "Did something great.",
                        "Did something else great.",
                    ],
                ),
                ExperienceEntry(
                    company="Your Company",
                    position="Your Position",
                ),
            ],
        ),
        "This Format Is Also Accepted": SectionWithOneLineEntries(
            entry_type="OneLineEntry",
            entries=[
                OneLineEntry(
                    name="Your Entry",
                    details="Your details.",
                ),
                OneLineEntry(
                    name="Your *Entry*",
                    details="Your details.",
                ),
            ],
        ),
    }

    cv = CurriculumVitae(
        name=name,
        location="Your Location",
        email="youremail@yourdomain.com",
        phone="+905419999999",  # type: ignore
        website="https://yourwebsite.com",  # type: ignore
        social_networks=[
            SocialNetwork(network="LinkedIn", username="yourusername"),
            SocialNetwork(network="GitHub", username="yourusername"),
        ],
        sections=sections,
    )

    desgin = ClassicThemeOptions(theme="classic", show_timespan_in=["Experience"])

    return RenderCVDataModel(cv=cv, design=desgin)


def generate_json_schema() -> dict:
    """Generate the JSON schema of RenderCV.

    JSON schema is generated for the users to make it easier for them to write the input
    file. The JSON Schema of RenderCV is saved in the `docs` directory of the repository
    and distributed to the users with the
    [JSON Schema Store](https://www.schemastore.org/).

    Returns:
        dict: The JSON schema of RenderCV.
    """

    class RenderCVSchemaGenerator(pydantic.json_schema.GenerateJsonSchema):
        def generate(self, schema, mode="validation"):
            json_schema = super().generate(schema, mode=mode)

            # Basic information about the schema:
            json_schema["title"] = "RenderCV"
            json_schema["description"] = "RenderCV data model."
            json_schema["$id"] = (
                "https://raw.githubusercontent.com/sinaatalay/rendercv/main/schema.json"
            )
            json_schema["$schema"] = "http://json-schema.org/draft-07/schema#"

            # Loop through $defs and remove docstring descriptions and fix optional
            # fields
            for key, value in json_schema["$defs"].items():
                # Don't allow additional properties
                value["additionalProperties"] = False

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
                        else:
                            field["oneOf"] = field["anyOf"]
                            del field["anyOf"]

                # In date field, we both accept normal strings and Date objects. They
                # are both strings, therefore, if user provides a Date object, then
                # JSON schema will complain that it matches two different types.
                # Remember that all of the anyOfs are changed to oneOfs. Only one of
                # the types can be matched. Therefore, we remove the first type, which
                # is the string with the YYYY-MM-DD format.
                if (
                    "date" in value["properties"]
                    and "oneOf" in value["properties"]["date"]
                ):
                    del value["properties"]["date"]["oneOf"][0]

            return json_schema

    schema = RenderCVDataModel.model_json_schema(
        schema_generator=RenderCVSchemaGenerator
    )

    return schema


def generate_json_schema_file(json_schema_path: pathlib.Path):
    """Generate the JSON schema of RenderCV and save it to a file in the `docs`"""
    schema = generate_json_schema()
    schema_json = json.dumps(schema, indent=2)
    json_schema_path.write_text(schema_json)
