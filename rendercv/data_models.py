"""
finally document the whole code!
"""

from datetime import date as Date
from typing import Literal
from typing_extensions import Annotated, Optional, Union
import logging
from functools import cached_property
import urllib.request
import os
import json

from pydantic import (
    BaseModel,
    RootModel,
    HttpUrl,
    Field,
    field_validator,
    model_validator,
    computed_field,
    EmailStr,
    TypeAdapter,
)
from pydantic.json_schema import GenerateJsonSchema
from pydantic.functional_validators import AfterValidator
from pydantic_extra_types.phone_numbers import PhoneNumber

from . import parser

logger = logging.getLogger(__name__)


# To understand how to create custom data types, see:
# https://docs.pydantic.dev/latest/usage/types/custom/


LaTeXDimension = Annotated[
    str,
    Field(
        pattern=r"\d+\.?\d* *(cm|in|pt|mm|ex|em)",
    ),
]

LaTeXString = Annotated[str, AfterValidator(parser.escape_latex_characters)]
PastDate = Annotated[
    str,
    Field(pattern=r"\d{4}-?(\d{2})?-?(\d{2})?"),
    AfterValidator(parser.parse_date_string),
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
    date: Optional[PastDate | int | LaTeXString] = Field(
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
    def check_date(
        cls, date: PastDate | LaTeXString
    ) -> Optional[PastDate | int | LaTeXString]:
        """Check if the date is a string or a Date object and return accordingly."""
        if isinstance(date, str):
            try:
                # If this runs, it means the date is an ISO format string, and it can be
                # parsed
                new_date = parser.parse_date_string(date)
            except ValueError:
                # Then it means it is a custom string like "Fall 2023"
                new_date = date
        elif date is None:
            new_date = None
        else:
            raise TypeError(f"Date ({date}) is neither a string nor a Date object.")

        return new_date

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
    def date_string(self) -> Optional[LaTeXString]:
        if self.date is not None:
            if isinstance(self.date, str):
                date_string = self.date
            elif isinstance(self.date, Date):
                date_string = parser.format_date(self.date)
            else:
                raise RuntimeError("Date is neither a string nor a Date object.")

        elif self.start_date is not None and self.end_date is not None:
            start_date = parser.format_date(self.start_date)

            if self.end_date == "present":
                end_date = "present"
            else:
                end_date = parser.format_date(self.end_date)

            date_string = f"{start_date} to {end_date}"

        else:
            date_string = None

        return date_string

    @computed_field
    @cached_property
    def time_span(self) -> Optional[LaTeXString]:
        if self.date is not None:
            time_span = ""
        elif self.start_date is not None and self.end_date is not None:
            if self.end_date == "present":
                time_span = parser.compute_time_span_string(
                    self.start_date, PastDate(Date.today())
                )
            else:
                time_span = parser.compute_time_span_string(
                    self.start_date, self.end_date
                )
        else:
            time_span = None

        return time_span

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
                month_and_year = parser.format_date(self.date)
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
    """This class stores [ExperienceEntry](../user_guide.md#experienceentry)
    information.
    """

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


class PublicationEntry(Event):
    """This class stores [PublicationEntry](../user_guide.md#publicationentry)
    information.
    """

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


default_entry_types = {
    "Education": EducationEntry,
    "Experience": ExperienceEntry,
    "Work Experience": ExperienceEntry,
    "Research Experience": ExperienceEntry,
    "Publications": PublicationEntry,
    "Papers": PublicationEntry,
    "Projects": NormalEntry,
    "Academic Projects": NormalEntry,
    "University Projects": NormalEntry,
    "Personal Projects": NormalEntry,
    "Certificates": NormalEntry,
    "Extracurricular Activities": ExperienceEntry,
    "Test Scores": OneLineEntry,
    "Skills": OneLineEntry,
    "Programming Skills": OneLineEntry,
    "Other Skills": OneLineEntry,
    "Awards": OneLineEntry,
    "Interests": OneLineEntry,
}


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

    title: Optional[LaTeXString]
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


class SectionWithTextEntries(SectionBase):
    """This class stores a section with
    [TextEntry](../user_guide.md#textentry)s.
    """

    entry_type: Literal["TextEntry"] = entry_type_field
    entries: list[LaTeXString] = entries_field


section_types = (
    SectionWithEducationEntries,
    SectionWithExperienceEntries,
    SectionWithNormalEntries,
    SectionWithOneLineEntries,
    SectionWithPublicationEntries,
    SectionWithTextEntries,
)

Section = Annotated[
    Union[section_types],
    Field(
        discriminator="entry_type",
    ),
]


class CurriculumVitae(BaseModel):
    """This class binds all the information of a CV together."""

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
    section_order: Optional[list[str]] = Field(
        default=None,
        title="Section Order",
        description=(
            "The order of sections in the CV. The section title should be used."
        ),
    )
    sections_input: dict[str, Section] = Field(
        default=None,
        title="Sections",
        description="The sections of the CV.",
        alias="sections",
    )

    @field_validator("sections_input")
    @classmethod
    def parse_and_check_sections(
        cls, sections_input: dict[str, Section]
    ) -> dict[str, Section]:
        """Check if the sections are provided."""

        if sections_input is not None:
            # check if the section names are unique, get the keys of the sections:
            keys = list(sections_input.keys())
            unique_keys = list(set(keys))
            duplicate_keys = list(set([key for key in keys if keys.count(key) > 1]))
            if len(keys) != len(unique_keys):
                raise ValueError(
                    "The section names should be unique. The following section names"
                    f" are duplicated: {duplicate_keys}"
                )

            for title, section in sections_input.items():
                parsed_title = title.replace("_", " ").title()
                if isinstance(section, section_types):
                    section.title = parsed_title
                elif isinstance(section, list):
                    if parsed_title not in default_entry_types:
                        raise ValueError(
                            f'"{parsed_title}" is a custom section and it doesn\'t have'
                            " a default entry type. Please provide the entry type."
                        )
                else:
                    raise TypeError(f'"{section}" is not a valid section.')

        return sections_input

    @computed_field
    @cached_property
    def sections(self) -> list[Section]:
        """Compute the sections of the CV.

        Returns:
            list[Section]: The sections of the CV.
        """
        sections = []
        if self.sections_input is not None:
            for title, section in self.sections_input.items():
                if isinstance(section, section_types):
                    sections.append(section)
                elif isinstance(section, list):
                    if title in default_entry_types:
                        entry_type = default_entry_types[title]
                        section = entry_type(
                            title=title, entry_type=entry_type.__name__, entries=section
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


# ======================================================================================
# ======================================================================================
# ======================================================================================


class RenderCVDataModel(BaseModel):
    """This class binds both the CV and the design information together."""

    cv: CurriculumVitae = Field(
        default=CurriculumVitae(name="John Doe"),
        title="Curriculum Vitae",
        description="The data of the CV.",
    )


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
