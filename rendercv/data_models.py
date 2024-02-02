"""
This module contains all the necessary classes to store CV data. The YAML input file is
transformed into instances of these classes (i.e., the input file is read) with the
[`read_input_file`](utilities.md#read_input_file) function. RenderCV utilizes these
instances to generate a CV. These classes are called data models.

The data models are initialized with data validation to prevent unexpected bugs. During
the initialization, we ensure that everything is in the correct place and that the user
has provided a valid RenderCV input. This is achieved through the use of
[Pydantic](https://pypi.org/project/pydantic/).
"""

from datetime import date as Date
from typing import Literal, Any
from typing_extensions import Annotated, Optional
from functools import cached_property
from urllib.request import urlopen, HTTPError
import os
import json
import re
import ssl
import time

import pydantic
import pydantic_extra_types.phone_numbers as pydantic_phone_numbers
import pydantic.functional_validators as pydantic_functional_validators
import strictyaml

from . import utilities
from .terminal_reporter import warning
from .themes.classic import ClassicThemeOptions
from .terminal_reporter import warning, error, information


# Create a custom type called PastDate that accepts a string in YYYY-MM-DD format and
# returns a Date object. It also checks if the date is in the past.
# See https://docs.pydantic.dev/2.5/concepts/types/#custom-types for more information
# about custom types.
RenderCVDate = Annotated[
    str,
    pydantic.Field(pattern=r"\d{4}-\d{2}(-\d{2})?"),
]


def get_date_object(date: str | int) -> Date:
    """Parse a date string in YYYY-MM-DD, YYYY-MM, or YYYY format and return a
    datetime.date object.

    Args:
        date_string (str): The date string to parse.
    Returns:
        datetime.date: The parsed date.
    """
    if isinstance(date, int):
        date_object = Date.fromisoformat(f"{date}-01-01")
    elif re.match(r"\d{4}-\d{2}-\d{2}", date):
        # Then it is in YYYY-MM-DD format
        date_object = Date.fromisoformat(date)
    elif re.match(r"\d{4}-\d{2}", date):
        # Then it is in YYYY-MM format
        # Assign a random day since days are not rendered in the CV
        date_object = Date.fromisoformat(f"{date}-01")
    elif date == "present":
        date_object = Date.today()
    else:
        raise ValueError(
            f'The date string "{date}" is not in YYYY-MM-DD, YYYY-MM, or YYYY format.'
        )

    return date_object


class RenderCVBaseModel(pydantic.BaseModel):
    """
    This class is the parent class of all the data models in RenderCV. It has only one
    difference from the default `pydantic.BaseModel`: It raises an error if an unknown
    key is provided in the input file.
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
        description="The start date of the event in YYYY-MM-DD format.",
        examples=["2020-09-24"],
    )
    end_date: Optional[Literal["present"] | int | RenderCVDate] = pydantic.Field(
        default=None,
        title="End Date",
        description=(
            "The end date of the event in YYYY-MM-DD format. If the event is still"
            ' ongoing, then the value should be "present".'
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
        default=[],
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

    @pydantic.model_validator(mode="after")
    @classmethod
    def check_dates(cls, model):
        """
        Check if the dates are provided correctly and convert them to `Date` objects if
        they are provided in YYYY-MM-DD format.
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
            warning(
                '"start_date", "end_date" and "date" are all provided in of the'
                " entries. start_date and end_date will be ignored."
            )
            model.start_date = None
            model.end_date = None

        elif date_is_provided and start_date_is_provided and not end_date_is_provided:
            warning(
                'Both "date" and "start_date" is provided in of the entries.'
                ' "start_date" will be ignored.'
            )
            model.start_date = None
            model.end_date = None

        elif date_is_provided and end_date_is_provided and not start_date_is_provided:
            warning(
                'Both "date" and "end_date" is provided in of the entries. "end_date"'
                " will be ignored."
            )
            model.start_date = None
            model.end_date = None

        elif start_date_is_provided and not end_date_is_provided:
            warning(
                '"start_date" is provided in of the entries, but "end_date" is not.'
                ' "end_date" will be set to "present".'
            )
            model.end_date = "present"

        elif not start_date_is_provided and end_date_is_provided:
            raise ValueError(
                '"end_date" is provided in of the entries, but "start_date" is not.'
                ' "start_date" is required.'
            )

        if model.start_date is not None and model.end_date is not None:
            end_date = get_date_object(model.end_date)
            start_date = get_date_object(model.start_date)

            if start_date > end_date:
                raise ValueError(
                    '"start_date" can not be after "end_date". The start date is'
                    f" {start_date} and the end date is {end_date}."
                )
            elif end_date > Date.today():
                raise ValueError(
                    f'"end_date" cannot be in the future. The end date is {end_date}.'
                )
            elif start_date > Date.today():
                raise ValueError(
                    '"start_date" cannot be in the future. The start date is'
                    f" {start_date}."
                )

        return model

    @pydantic.computed_field
    @cached_property
    def date_string(self) -> str:
        """
        Return a date string based on the `date`, `start_date`, and `end_date` fields.

        Example:
            ```python
            entry = dm.EntryBase(start_date=2020-10-11, end_date=2021-04-04)
            entry.date_string
            ```
            will return:
            `#!python "2020-10-11 to 2021-04-04"`
        """
        if self.date is not None:
            try:
                date_object = get_date_object(self.date)
                date_string = utilities.format_date(date_object)
            except ValueError:
                date_string = str(self.date)

        elif self.start_date is not None and self.end_date is not None:
            if isinstance(self.start_date, int):
                start_date = str(self.start_date)
            else:
                date_object = get_date_object(self.start_date)
                start_date = utilities.format_date(date_object)

            if self.end_date == "present":
                end_date = "present"
            elif isinstance(self.end_date, int):
                end_date = str(self.end_date)
            else:
                date_object = get_date_object(self.end_date)
                end_date = utilities.format_date(date_object)

            date_string = f"{start_date} to {end_date}"

        else:
            date_string = ""

        return date_string

    @pydantic.computed_field
    @cached_property
    def time_span_string(self) -> str:
        """
        Return a time span string based on the `date`, `start_date`, and `end_date`
        fields.

        Example:
            ```python
            entry = dm.EntryBase(start_date=2020-01-01, end_date=2020-04-20)
            entry.time_span
            ```
            will return:
            `#!python "4 months"`
        """
        start_date = self.start_date
        end_date = self.end_date
        date = self.date

        if date is not None or (start_date is None and end_date is None):
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

    @pydantic.computed_field
    @cached_property
    def url_text(self) -> Optional[str]:
        """
        Return a URL text based on the `url_text_input` and `url` fields.
        """
        url_text = None
        if self.url_text_input is not None:
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
    study_type: Optional[str] = pydantic.Field(
        default=None,
        title="Study Type",
        description="The type of the degree.",
        examples=["BS", "BA", "PhD", "MS"],
    )


class PublicationEntry(RenderCVBaseModel):
    """THis class is the data model of `PublicationEntry`."""

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
        description="The date of the publication.",
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
            raise ValueError(
                f"The publication date {date} cannot be in the future. The publication"
                " date should be in the past."
            )

        return date

    @pydantic.field_validator("doi")
    @classmethod
    def check_doi(cls, doi: str) -> str:
        """Check if the DOI exists in the DOI System."""
        # see https://stackoverflow.com/a/60671292/18840665
        ssl._create_default_https_context = ssl._create_unverified_context

        doi_url = f"http://doi.org/{doi}"

        try:
            urlopen(doi_url)
        except HTTPError as err:
            if err.code == 404:
                raise ValueError(f"{doi} cannot be found in the DOI System.")

        return doi

    @pydantic.computed_field
    @cached_property
    def doi_url(self) -> str:
        return f"https://doi.org/{self.doi}"

    @pydantic.computed_field
    @cached_property
    def date_string(self) -> str:
        if isinstance(self.date, int):
            date_string = str(self.date)
        elif isinstance(self.date, str):
            date_object = get_date_object(self.date)
            date_string = utilities.format_date(date_object)
        else:
            date_string = ""

        return date_string


# ======================================================================================
# Section models: ======================================================================
# ======================================================================================

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

    # title is excluded from the JSON schema because this will be written by RenderCV
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


# A custom type Section. It is a union of all the section types and the correct section
# type is determined by the entry_type field.
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

# ======================================================================================
# Full RenderCV data models: ===========================================================
# ======================================================================================

# RenderCV requires users to specify the entry type for each section in their CV in
# order to render the correct thing in the CV. However, for certain sections, specifying
# the entry type can be redundant. To simplify this process for users, default entry
# types are stored in a dictionary for certain section titles so that users do not have
# to specify them.
default_entry_types_for_a_given_title: dict[
    str,
    tuple[type[EducationEntry], type[SectionWithEducationEntries]]
    | tuple[type[ExperienceEntry], type[SectionWithExperienceEntries]]
    | tuple[type[PublicationEntry], type[SectionWithPublicationEntries]]
    | tuple[type[NormalEntry], type[SectionWithNormalEntries]]
    | tuple[type[OneLineEntry], type[SectionWithOneLineEntries]]
    | tuple[type[str], type[SectionWithTextEntries]],
] = {
    "Education": (EducationEntry, SectionWithEducationEntries),
    "Experience": (ExperienceEntry, SectionWithExperienceEntries),
    "Work Experience": (ExperienceEntry, SectionWithExperienceEntries),
    "Research Experience": (ExperienceEntry, SectionWithExperienceEntries),
    "Publications": (PublicationEntry, SectionWithPublicationEntries),
    "Papers": (PublicationEntry, SectionWithPublicationEntries),
    "Projects": (NormalEntry, SectionWithNormalEntries),
    "Academic Projects": (NormalEntry, SectionWithNormalEntries),
    "University Projects": (NormalEntry, SectionWithNormalEntries),
    "Personal Projects": (NormalEntry, SectionWithNormalEntries),
    "Certificates": (NormalEntry, SectionWithNormalEntries),
    "Extracurricular Activities": (ExperienceEntry, SectionWithExperienceEntries),
    "Test Scores": (OneLineEntry, SectionWithOneLineEntries),
    "Skills": (OneLineEntry, SectionWithOneLineEntries),
    "Programming Skills": (NormalEntry, SectionWithNormalEntries),
    "Other Skills": (OneLineEntry, SectionWithOneLineEntries),
    "Awards": (OneLineEntry, SectionWithOneLineEntries),
    "Interests": (OneLineEntry, SectionWithOneLineEntries),
    "Summary": (str, SectionWithTextEntries),
}


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

    @pydantic.model_validator(mode="after")
    @classmethod
    def check_networks(cls, model):
        if model.network == "Mastodon":
            if not model.username.startswith("@"):
                raise ValueError(
                    "Mastodon username should start with '@'. The username is"
                    f" {model.username}."
                )
            if model.username.count("@") > 2:
                raise ValueError(
                    "Mastodon username should contain only two '@'. The username is"
                    f" {model.username}."
                )

        return model

    @pydantic.computed_field
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
    section_order: Optional[list[str]] = pydantic.Field(
        default=None,
        title="Section Order",
        description=(
            "The order of sections in the CV. The section title should be used."
        ),
    )
    sections_input: dict[str, Section | list[Any]] = pydantic.Field(
        default=None,
        title="Sections",
        description="The sections of the CV.",
        alias="sections",
    )

    @pydantic.field_validator("sections_input")
    @classmethod
    def validate_sections(
        cls,
        sections_input: dict[str, Section | list[Any]],
    ) -> dict[str, Section | list[Any]]:
        """
        Parse and validate the sections of the CV.
        """
        if sections_input is not None:
            for title, section_or_entries in sections_input.items():
                if isinstance(section_or_entries, list):
                    title = title.replace("_", " ").title()
                    if title in default_entry_types_for_a_given_title:
                        (
                            entry_type,
                            section_type,
                        ) = default_entry_types_for_a_given_title[title]

                        if entry_type is str:
                            entry_type = "TextEntry"
                        else:
                            entry_type = entry_type.__name__

                        test_section = {
                            "title": title,
                            "entry_type": entry_type,
                            "entries": section_or_entries,
                        }

                        section_type.model_validate(test_section)

                    else:
                        raise ValueError(
                            f'The entry type for the section "{title}" is not provided!'
                            " Please provide an entry type."
                        )

        return sections_input

    @pydantic.computed_field
    @cached_property
    def sections(self) -> list[Section]:
        """Return all the sections of the CV with their titles."""
        sections = []
        if self.sections_input is not None:
            for title, section_or_entries in self.sections_input.items():
                title = title.replace("_", " ").title()
                if isinstance(section_or_entries, list):
                    if title in default_entry_types_for_a_given_title:
                        (
                            entry_type,
                            section_type,
                        ) = default_entry_types_for_a_given_title[title]

                        if entry_type is str:
                            entry_type = "TextEntry"
                        else:
                            entry_type = entry_type.__name__

                        section = section_type(
                            title=title,
                            entry_type=entry_type,  # type: ignore
                            entries=section_or_entries,  # type: ignore
                        )
                        sections.append(section)
                    else:
                        raise RuntimeError(
                            "This error shouldn't have been raised. Please open an"
                            " issue on GitHub."
                        )
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

Design = ClassicThemeOptions


class RenderCVDataModel(RenderCVBaseModel):
    """This class binds both the CV and the design information together."""

    cv: CurriculumVitae = pydantic.Field(
        title="Curriculum Vitae",
        description="The data of the CV.",
    )
    design: Design = pydantic.Field(
        title="Design",
        description="The design information.",
        discriminator="theme",
    )


def generate_json_schema(output_directory: str) -> str:
    """Generate the JSON schema of the data model and save it to a file.

    Args:
        output_directory (str): The output directory to save the schema.
    """

    class RenderCVSchemaGenerator(pydantic.json_schema.GenerateJsonSchema):
        def generate(self, schema, mode="validation"):
            json_schema = super().generate(schema, mode=mode)
            json_schema["title"] = "RenderCV Input"

            # remove the description of the class (RenderCVDataModel)
            del json_schema["description"]

            # add $id
            json_schema["$id"] = (
                "https://raw.githubusercontent.com/sinaatalay/rendercv/main/schema.json"
            )

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


def escape_latex_characters(sentence: str) -> str:
    """Escape LaTeX characters in a string.

    Example:
        ```python
        escape_latex_characters("This is a # string.")
        ```
        will return:
        `#!python "This is a \\# string."`
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

    # Don't escape links as hyperref package will do it automatically:

    # Find all the links in the sentence:
    links = re.findall(r"\[.*?\]\(.*?\)", sentence)

    # Replace the links with a placeholder:
    for link in links:
        sentence = sentence.replace(link, "!!-link-!!")

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


def markdown_to_latex(markdown_string: str) -> str:
    """Convert a markdown string to LaTeX.

    This function is used as a Jinja2 filter.

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


def read_input_file(file_path: str) -> RenderCVDataModel:
    """Read the input file and return an instance of RenderCVDataModel.

    Args:
        file_path (str): The path to the input file.

    Returns:
        str: The input file as a string.
    """
    start_time = time.time()

    information(f"Reading and validating the input file {file_path} has started.")

    # check if the file exists:
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"The input file {file_path} doesn't exist.")

    # check the file extension:
    accepted_extensions = [".yaml", ".yml", ".json", ".json5"]
    if not any(file_path.endswith(extension) for extension in accepted_extensions):
        raise ValueError(
            f"The file {file_path} doesn't have an accepted extension!"
            f" Accepted extensions are: {accepted_extensions}"
        )

    with open(file_path) as file:
        file_content = file.read()
        parsed_dictionary: dict[str, Any] = strictyaml.load(file_content).data  # type: ignore

    def loop_through_dictionary(dictionary: dict[str, Any]) -> dict[str, Any]:
        """Recursively loop through a dictionary and apply markdown_to_latex and
        escape_latex_characters to all the fields.

        Args:
            dictionary (dict[str, Any]): The dictionary to loop through.

        Returns:
            dict[str, Any]: The dictionary with markdown_to_latex and
                escape_latex_characters applied to all the fields.
        """
        for key, value in dictionary.items():
            if isinstance(value, str):
                result = escape_latex_characters(value)
                dictionary[key] = markdown_to_latex(result)
            elif isinstance(value, list):
                for index, item in enumerate(value):
                    if isinstance(item, str):
                        result = escape_latex_characters(item)
                        dictionary[key][index] = markdown_to_latex(result)
                    elif isinstance(item, dict):
                        dictionary[key][index] = loop_through_dictionary(item)
            elif isinstance(value, dict):
                dictionary[key] = loop_through_dictionary(value)

        return dictionary

    parsed_dictionary = loop_through_dictionary(parsed_dictionary)

    data = RenderCVDataModel(**parsed_dictionary)  ## type: ignore

    end_time = time.time()
    time_taken = end_time - start_time
    information(
        f"Reading and validating the input file {file_path} has finished in"
        f" {time_taken:.2f} s."
    )
    return data
