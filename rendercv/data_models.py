"""
in the end: document the whole code!
"""

from datetime import date as Date
from typing import Literal
from typing_extensions import Annotated, Optional
from functools import cached_property
from urllib.request import urlopen, HTTPError
import os
import json

import pydantic
import pydantic_extra_types.phone_numbers as pydantic_phone_numbers
import pydantic.functional_validators as pydantic_functional_validators

from . import utilities
from .terminal_reporter import warning

# To understand how to create custom data types, see:
# https://docs.pydantic.dev/latest/usage/types/custom/ # use links with pydantic version tags!


# LaTeXDimension = Annotated[
#     str,
#     pydantic.Field(
#         pattern=r"\d+\.?\d* *(cm|in|pt|mm|ex|em)",
#     ),
# ]
LaTeXString = Annotated[
    str,
    pydantic_functional_validators.AfterValidator(utilities.escape_latex_characters),
]
PastDate = Annotated[
    str,
    pydantic.Field(pattern=r"\d{4}-?(\d{2})?-?(\d{2})?"),
    pydantic_functional_validators.AfterValidator(utilities.parse_date_string),
]

PastDateAdapter = pydantic.TypeAdapter(PastDate)

# ======================================================================================
# Entry models: ========================================================================
# ======================================================================================


class EntryBase(pydantic.BaseModel):
    """This class is the parent class for classes like `#!python EducationEntry`,
    `#!python ExperienceEntry`, `#!python NormalEntry`, and `#!python OneLineEntry`.

    It stores the common fields between these classes like dates, location, highlights,
    and URL.
    """

    start_date: Optional[PastDate] = pydantic.Field(
        default=None,
        title="Start Date",
        description="The start date of the event in YYYY-MM-DD format.",
        examples=["2020-09-24"],
    )
    end_date: Optional[Literal["present"] | PastDate] = pydantic.Field(
        default=None,
        title="End Date",
        description=(
            "The end date of the event in YYYY-MM-DD format. If the event is still"
            ' ongoing, then the value should be "present".'
        ),
        examples=["2020-09-24", "present"],
    )
    date: Optional[PastDate | int | LaTeXString] = pydantic.Field(
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
    highlights: Optional[list[LaTeXString]] = pydantic.Field(
        default=[],
        title="Highlights",
        description=(
            "The highlights of the event. It will be rendered as bullet points."
        ),
        examples=["Did this.", "Did that."],
    )
    location: Optional[LaTeXString] = pydantic.Field(
        default=None,
        title="Location",
        description=(
            "The location of the event. It will be shown with the date in the"
            " same column."
        ),
        examples=["Istanbul, Turkey"],
    )
    url: Optional[pydantic.HttpUrl] = None

    @pydantic.field_validator("date")
    @classmethod
    def check_date(
        cls, date: PastDate | LaTeXString
    ) -> Optional[PastDate | int | LaTeXString]:
        """Check if the date is a string or a Date object and return accordingly."""
        if date is None:
            new_date = None
        elif isinstance(date, Date):
            new_date = date
        else:
            raise TypeError(f"{date} is an invalid date.")

        return new_date

    @pydantic.model_validator(mode="after")
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
            warning(
                '"start_date", "end_date" and "date" are all provided in of the'
                " entries. Therefore, date will be ignored."
            )
            model.date = None

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

    @pydantic.computed_field
    @cached_property
    def date_string(self) -> Optional[LaTeXString]:
        if self.date is not None:
            if isinstance(self.date, str):
                date_string = self.date
            elif isinstance(self.date, Date):
                date_string = utilities.format_date(self.date)
            else:
                raise RuntimeError("Date is neither a string nor a Date object.")

        elif self.start_date is not None and self.end_date is not None:
            if isinstance(self.start_date, (int, Date)):
                start_date = utilities.format_date(self.start_date)
            else:
                raise RuntimeError(
                    "This error shouldn't have been raised. Please open an issue on"
                    " GitHub."
                )
            if self.end_date == "present":
                end_date = "present"
            elif isinstance(self.end_date, (int, Date)):
                end_date = utilities.format_date(self.end_date)
            else:
                raise RuntimeError(
                    "This error shouldn't have been raised. Please open an issue on"
                    " GitHub."
                )

            date_string = f"{start_date} to {end_date}"

        else:
            date_string = None

        return date_string

    @pydantic.computed_field
    @cached_property
    def time_span(self) -> Optional[LaTeXString]:
        if self.date is not None:
            time_span = ""
        elif self.start_date is not None and self.end_date is not None:
            if self.end_date == "present" and isinstance(self.start_date, Date):
                time_span = utilities.compute_time_span_string(
                    self.start_date, Date.today()
                )
            elif isinstance(self.start_date, (int, Date)) and isinstance(
                self.end_date, (int, Date)
            ):
                time_span = utilities.compute_time_span_string(
                    self.start_date, self.end_date
                )
            else:
                raise RuntimeError(
                    "This error shouldn't have been raised. Please open an issue on"
                    " GitHub."
                )
        else:
            time_span = None

        return time_span

    @pydantic.computed_field
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

    @pydantic.computed_field
    @cached_property
    def month_and_year(self) -> Optional[LaTeXString]:
        if self.date is not None:
            # Then it means start_date and end_date are not provided.
            try:
                # If this runs, it means the date is an ISO format string, and it can be
                # parsed
                month_and_year = utilities.format_date(self.date)  # type: ignore
            except TypeError:
                month_and_year = str(self.date)
        else:
            # Then it means start_date and end_date are provided and month_and_year
            # doesn't make sense.
            month_and_year = None

        return month_and_year


class OneLineEntry(pydantic.BaseModel):
    """This class stores [OneLineEntry](../user_guide.md#onelineentry) information."""

    name: LaTeXString = pydantic.Field(
        title="Name",
        description="The name of the entry. It will be shown as bold text.",
    )
    details: LaTeXString = pydantic.Field(
        title="Details",
        description="The details of the entry. It will be shown as normal text.",
    )


class NormalEntry(EntryBase):
    """This class stores [NormalEntry](../user_guide.md#normalentry) information."""

    name: LaTeXString = pydantic.Field(
        title="Name",
        description="The name of the entry. It will be shown as bold text.",
    )


class ExperienceEntry(EntryBase):
    """This class stores [ExperienceEntry](../user_guide.md#experienceentry)
    information.
    """

    company: LaTeXString = pydantic.Field(
        title="Company",
        description="The company name. It will be shown as bold text.",
    )
    position: LaTeXString = pydantic.Field(
        title="Position",
        description="The position. It will be shown as normal text.",
    )


class EducationEntry(EntryBase):
    """This class stores [EducationEntry](../user_guide.md#educationentry) information."""

    institution: LaTeXString = pydantic.Field(
        title="Institution",
        description="The institution name. It will be shown as bold text.",
        examples=["Bogazici University"],
    )
    area: LaTeXString = pydantic.Field(
        title="Area",
        description="The area of study. It will be shown as normal text.",
    )
    study_type: Optional[LaTeXString] = pydantic.Field(
        default=None,
        title="Study Type",
        description="The type of the degree.",
        examples=["BS", "BA", "PhD", "MS"],
    )


class PublicationEntry(pydantic.BaseModel):
    """This class stores [PublicationEntry](../user_guide.md#publicationentry)
    information.
    """

    title: LaTeXString = pydantic.Field(
        title="Title of the Publication",
        description="The title of the publication. It will be shown as bold text.",
    )
    authors: list[LaTeXString] = pydantic.Field(
        title="Authors",
        description="The authors of the publication in order as a list of strings.",
    )
    doi: str = pydantic.Field(
        title="DOI",
        description="The DOI of the publication.",
        examples=["10.48550/arXiv.2310.03138"],
    )
    date: LaTeXString = pydantic.Field(
        title="Publication Date",
        description="The date of the publication.",
        examples=["2021-10-31"],
    )
    journal: Optional[LaTeXString] = pydantic.Field(
        default=None,
        title="Journal",
        description="The journal or the conference name.",
    )

    @pydantic.field_validator("doi")
    @classmethod
    def check_doi(cls, doi: str) -> str:
        """Check if the DOI exists in the DOI System."""
        doi_url = f"https://doi.org/{doi}"

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


class SectionBase(pydantic.BaseModel):
    """This class stores a section information.

    It is the parent class of all the section classes like
    `#!python SectionWithEducationEntries`, `#!python SectionWithExperienceEntries`,
    `#!python SectionWithNormalEntries`, `#!python SectionWithOneLineEntries`, and
    `#!python SectionWithPublicationEntries`.
    """

    title: Optional[LaTeXString] = pydantic.Field(default=None)
    link_text: Optional[LaTeXString] = pydantic.Field(
        default=None,
        title="Link Text",
        description=(
            "If the section has a link, then what should be the text of the link? If"
            " this field is not provided, then the link text will be generated"
            " automatically based on the URL."
        ),
        examples=["view on GitHub", "view on LinkedIn"],
    )


class SectionWithEducationEntries(SectionBase):
    """This class stores a section with
    [EducationEntry](../user_guide.md#educationentry)s.
    """

    entry_type: Literal["EducationEntry"] = entry_type_field_of_section_model
    entries: list[EducationEntry] = entries_field_of_section_model


class SectionWithExperienceEntries(SectionBase):
    """This class stores a section with
    [ExperienceEntry](../user_guide.md#experienceentry)s.
    """

    entry_type: Literal["ExperienceEntry"] = entry_type_field_of_section_model
    entries: list[ExperienceEntry] = entries_field_of_section_model


class SectionWithNormalEntries(SectionBase):
    """This class stores a section with
    [NormalEntry](../user_guide.md#normalentry)s.
    """

    entry_type: Literal["NormalEntry"] = entry_type_field_of_section_model
    entries: list[NormalEntry] = entries_field_of_section_model


class SectionWithOneLineEntries(SectionBase):
    """This class stores a section with
    [OneLineEntry](../user_guide.md#onelineentry)s.
    """

    entry_type: Literal["OneLineEntry"] = entry_type_field_of_section_model
    entries: list[OneLineEntry] = entries_field_of_section_model


class SectionWithPublicationEntries(SectionBase):
    """This class stores a section with
    [PublicationEntry](../user_guide.md#publicationentry)s.
    """

    entry_type: Literal["PublicationEntry"] = entry_type_field_of_section_model
    entries: list[PublicationEntry] = entries_field_of_section_model


class SectionWithTextEntries(SectionBase):
    """This class stores a section with
    [TextEntry](../user_guide.md#textentry)s.
    """

    entry_type: Literal["TextEntry"] = entry_type_field_of_section_model
    entries: list[LaTeXString] = entries_field_of_section_model


class SocialNetwork(pydantic.BaseModel):
    """This class stores a social network information.

    Currently, only LinkedIn, Github, and Instagram are supported.
    """

    network: Literal["LinkedIn", "GitHub", "Instagram", "Orcid"] = pydantic.Field(
        title="Social Network",
        description="The social network name.",
    )
    username: str = pydantic.Field(
        title="Username",
        description="The username of the social network. The link will be generated.",
    )


# Section type
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

# Default entry types for a given section title
default_entry_types_for_a_given_title: dict[
    str,
    tuple[type[EducationEntry], type[SectionWithEducationEntries]]
    | tuple[type[ExperienceEntry], type[SectionWithExperienceEntries]]
    | tuple[type[PublicationEntry], type[SectionWithPublicationEntries]]
    | tuple[type[NormalEntry], type[SectionWithNormalEntries]]
    | tuple[type[OneLineEntry], type[SectionWithOneLineEntries]]
    | tuple[type[LaTeXString], type[SectionWithTextEntries]],
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
    "Summary": (LaTeXString, SectionWithTextEntries),
}


class Connection(pydantic.BaseModel):
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

    @pydantic.computed_field
    @cached_property
    def url(self) -> Optional[pydantic.HttpUrl | str]:
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


class CurriculumVitae(pydantic.BaseModel):
    """This class binds all the information of a CV together."""

    name: LaTeXString = pydantic.Field(
        title="Name",
        description="The name of the person.",
    )
    label: Optional[LaTeXString] = pydantic.Field(
        default=None,
        title="Label",
        description="The label of the person.",
    )
    location: Optional[LaTeXString] = pydantic.Field(
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
    sections_input: dict[
        str,
        Section
        | list[EducationEntry]
        | list[NormalEntry]
        | list[OneLineEntry]
        | list[PublicationEntry]
        | list[ExperienceEntry]
        | list[LaTeXString],
    ] = pydantic.Field(
        default=None,
        title="Sections",
        description="The sections of the CV.",
        alias="sections",
    )

    @pydantic.field_validator("sections_input", mode="before")
    @classmethod
    def parse_and_validate_sections(
        cls,
        sections_input: dict[
            str,
            Section
            | list[EducationEntry]
            | list[NormalEntry]
            | list[OneLineEntry]
            | list[PublicationEntry]
            | list[ExperienceEntry]
            | list[LaTeXString],
        ],
    ) -> dict[
        str,
        Section
        | list[EducationEntry]
        | list[NormalEntry]
        | list[OneLineEntry]
        | list[PublicationEntry]
        | list[ExperienceEntry]
        | list[LaTeXString],
    ]:
        """"""

        if sections_input is not None:
            # check if the section names are unique, get the keys of the sections:
            keys = list(sections_input.keys())
            unique_keys = list(set(keys))
            if len(keys) != len(unique_keys):
                duplicate_keys = list(set([key for key in keys if keys.count(key) > 1]))
                raise ValueError(
                    "The section names should be unique. The following section names"
                    f" are duplicated: {duplicate_keys}"
                )

            for title, section_or_entries in sections_input.items():
                if isinstance(section_or_entries, list):
                    # Then it means the user provided entries directly. Then it means
                    # the section title should have a default entry type.
                    if title in default_entry_types_for_a_given_title:
                        (
                            entry_type,
                            section_type,
                        ) = default_entry_types_for_a_given_title[title]

                        # try if the entries are of the correct type by casting them
                        # to the entry type one by one
                        for entry in section_or_entries:
                            if entry_type is LaTeXString:
                                if not isinstance(entry, str):
                                    raise pydantic.ValidationError(
                                        f'"{entry}" is not a valid string.'
                                    )
                            else:
                                try:
                                    entry = entry_type(**entry)  # type: ignore
                                except pydantic.ValidationError as err:
                                    raise pydantic.ValidationError(
                                        f'"{entry}" is not a valid'
                                        f" {entry_type.__name__}."
                                    ) from err

                    else:
                        raise ValueError(
                            f'"{title}" is a custom section and it doesn\'t have'
                            " a default entry type. Please provide the entry type."
                        )

        return sections_input

    @pydantic.computed_field
    @cached_property
    def sections(self) -> list[Section]:
        """Compute the sections of the CV.

        Returns:
            list[Section]: The sections of the CV.
        """
        sections = []
        if self.sections_input is not None:
            for title, section_or_entries in self.sections_input.items():
                if isinstance(
                    section_or_entries,
                    (
                        SectionWithEducationEntries,
                        SectionWithExperienceEntries,
                        SectionWithNormalEntries,
                        SectionWithOneLineEntries,
                        SectionWithPublicationEntries,
                        SectionWithTextEntries,
                    ),
                ):
                    if section_or_entries.title is None:
                        section_or_entries.title = title
                    sections.append(section_or_entries)
                elif isinstance(section_or_entries, list):
                    if title in default_entry_types_for_a_given_title:
                        (
                            entry_type,
                            section_type,
                        ) = default_entry_types_for_a_given_title[title]
                        section = section_type(
                            title=title,
                            entry_type=entry_type.__name__,  # type: ignore
                            entries=section_or_entries,  # type: ignore
                        )
                        sections.append(section)
                    else:
                        raise RuntimeError(
                            "This error shouldn't have been raised. Please open an"
                            " issue on GitHub."
                        )
                else:
                    raise RuntimeError(
                        "This error shouldn't have been raised. Please open an"
                        " issue on GitHub."
                    )

        return sections

    @pydantic.computed_field
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


# ======================================================================================
# ======================================================================================
# ======================================================================================


class RenderCVDataModel(pydantic.BaseModel):
    """This class binds both the CV and the design information together."""

    cv: CurriculumVitae = pydantic.Field(
        default=CurriculumVitae(name="John Doe"),
        title="Curriculum Vitae",
        description="The data of the CV.",
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
