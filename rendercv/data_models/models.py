"""
The `rendercv.data_models.models` module contains all the Pydantic data models used in
RenderCV. These data models define the data format and the usage of computed fields and
the validators.
"""

import functools
from typing import Annotated, Optional
import pathlib

import annotated_types as at
import pydantic
import pydantic_extra_types.phone_numbers as pydantic_phone_numbers

from ..themes.classic import ClassicThemeOptions
from . import computed_fields as cf
from . import types
from . import utilities as util
from . import validators as val

# Disable Pydantic warnings:
# warnings.filterwarnings("ignore")


class RenderCVBaseModel(pydantic.BaseModel):
    """This class is the parent class of all the data models in RenderCV. It has only
    one difference from the default `pydantic.BaseModel`: It raises an error if an
    unknown key is provided in the input file.
    """

    model_config = pydantic.ConfigDict(extra="forbid")


# ======================================================================================
# Entry models: ========================================================================
# ======================================================================================


class OneLineEntry(RenderCVBaseModel):
    """This class is the data model of `OneLineEntry`."""

    label: str = pydantic.Field(
        title="Name",
        description="The label of the OneLineEntry.",
    )
    details: str = pydantic.Field(
        title="Details",
        description="The details of the OneLineEntry.",
    )


class BulletEntry(RenderCVBaseModel):
    """This class is the data model of `BulletEntry`."""

    bullet: str = pydantic.Field(
        title="Bullet",
        description="The bullet of the BulletEntry.",
    )


class EntryWithDate(RenderCVBaseModel):
    """This class is the parent class of some of the entry types that have date
    fields.
    """

    date: types.ArbitraryDate = pydantic.Field(
        default=None,
        title="Date",
        description=(
            "The date field can be filled in YYYY-MM-DD, YYYY-MM, or YYYY formats or as"
            ' an arbitrary string like "Fall 2023".'
        ),
        examples=["2020-09-24", "Fall 2023"],
    )

    @functools.cached_property
    def date_string(self) -> str:
        """Return a date string based on the `date` field and cache `date_string` as
        an attribute of the instance.
        """
        return cf.compute_date_string(start_date=None, end_date=None, date=self.date)


class PublicationEntryBase(RenderCVBaseModel):
    title: str = pydantic.Field(
        title="Publication Title",
        description="The title of the publication.",
    )
    authors: list[str] = pydantic.Field(
        title="Authors",
        description="The authors of the publication in order as a list of strings.",
    )
    doi: Optional[str] = pydantic.Field(
        default=None,
        title="DOI",
        description="The DOI of the publication.",
        examples=["10.48550/arXiv.2310.03138"],
    )
    url: Optional[pydantic.HttpUrl] = pydantic.Field(
        default=None,
        title="URL",
        description=(
            "The URL of the publication. If DOI is provided, it will be ignored."
        ),
    )
    journal: Optional[str] = pydantic.Field(
        default=None,
        title="Journal",
        description="The journal or conference name.",
    )

    @pydantic.model_validator(mode="after")
    def ignore_url_if_doi_is_given(self) -> "PublicationEntryBase":
        """Check if DOI is provided and ignore the URL if it is provided."""
        doi_is_provided = self.doi is not None
        url_is_provided = self.url is not None
        if doi_is_provided and url_is_provided:
            self.url = None

        return self

    @functools.cached_property
    def doi_url(self) -> str:
        """Return the URL of the DOI and cache `doi_url` as an attribute of the
        instance.
        """
        doi_is_provided = self.doi is not None

        if doi_is_provided:
            return f"https://doi.org/{self.doi}"
        else:
            return ""

    @functools.cached_property
    def clean_url(self) -> str:
        """Return the clean URL of the publication and cache `clean_url` as an attribute
        of the instance.
        """
        url_is_provided = self.url is not None

        if url_is_provided:
            return util.make_a_url_clean(self.url)
        else:
            return ""


# The following class is to ensure PublicationEntryBase keys come first,
# then the keys of the EntryWithDate class. The only way to achieve this in Pydantic is
# to do this. The same thing is done for the other classes as well.
class PublicationEntry(EntryWithDate, PublicationEntryBase):
    """This class is the data model of `PublicationEntry`."""

    pass


class EntryBase(EntryWithDate):
    """This class is the parent class of some of the entry types. It is being used
    because some of the entry types have common fields like dates, highlights, location,
    etc.
    """

    location: Optional[str] = pydantic.Field(
        default=None,
        title="Location",
        description="The location of the event.",
        examples=["Istanbul, Türkiye"],
    )
    start_date: types.StartDate = pydantic.Field(
        default=None,
        title="Start Date",
        description=(
            "The start date of the event in YYYY-MM-DD, YYYY-MM, or YYYY format."
        ),
        examples=["2020-09-24"],
    )
    end_date: types.EndDate = pydantic.Field(
        default=None,
        title="End Date",
        description=(
            "The end date of the event in YYYY-MM-DD, YYYY-MM, or YYYY format. If the"
            ' event is still ongoing, then type "present" or provide only the'
            " start_date."
        ),
        examples=["2020-09-24", "present"],
    )
    highlights: Optional[list[str]] = pydantic.Field(
        default=None,
        title="Highlights",
        description="The highlights of the event as a list of strings.",
        examples=["Did this.", "Did that."],
    )

    @pydantic.model_validator(mode="after")
    def check_and_adjust_dates(self) -> "EntryBase":
        """Call the `validate_adjust_dates_of_an_entry` function to validate the
        dates.
        """
        return val.validate_and_adjust_dates_of_an_entry(self)

    @functools.cached_property
    def date_string(self) -> str:
        """Return a date string based on the `date`, `start_date`, and `end_date` fields
        and cache `date_string` as an attribute of the instance.

        Example:
            ```python
            entry = dm.EntryBase(start_date="2020-10-11", end_date="2021-04-04").date_string
            ```
            returns
            `#!python "Nov 2020 to Apr 2021"`
        """
        return cf.compute_date_string(
            start_date=self.start_date, end_date=self.end_date, date=self.date
        )

    @functools.cached_property
    def date_string_only_years(self) -> str:
        """Return a date string that only contains years based on the `date`,
        `start_date`, and `end_date` fields and cache `date_string_only_years` as an
        attribute of the instance.

        Example:
            ```python
            entry = dm.EntryBase(start_date="2020-10-11", end_date="2021-04-04").date_string_only_years
            ```
            returns
            `#!python "2020 to 2021"`
        """
        return cf.compute_date_string(
            start_date=self.start_date,
            end_date=self.end_date,
            date=self.date,
            show_only_years=True,
        )

    @functools.cached_property
    def time_span_string(self) -> str:
        """Return a time span string based on the `date`, `start_date`, and `end_date`
        fields and cache `time_span_string` as an attribute of the instance.
        """
        return cf.compute_time_span_string(
            start_date=self.start_date, end_date=self.end_date, date=self.date
        )


class NormalEntryBase(RenderCVBaseModel):
    name: str = pydantic.Field(
        title="Name",
        description="The name of the NormalEntry.",
    )


class NormalEntry(EntryBase, NormalEntryBase):
    """This class is the data model of `NormalEntry`."""

    pass


class ExperienceEntryBase(RenderCVBaseModel):
    company: str = pydantic.Field(
        title="Company",
        description="The company name.",
    )
    position: str = pydantic.Field(
        title="Position",
        description="The position.",
    )


class ExperienceEntry(EntryBase, ExperienceEntryBase):
    """This class is the data model of `ExperienceEntry`."""

    pass


class EducationEntryBase(RenderCVBaseModel):
    institution: str = pydantic.Field(
        title="Institution",
        description="The institution name.",
    )
    area: str = pydantic.Field(
        title="Area",
        description="The area of study.",
    )
    degree: Optional[str] = pydantic.Field(
        default=None,
        title="Degree",
        description="The type of the degree.",
        examples=["BS", "BA", "PhD", "MS"],
    )


class EducationEntry(EntryBase, EducationEntryBase):
    """This class is the data model of `EducationEntry`."""

    pass


# ======================================================================================
# Section models: ======================================================================
# ======================================================================================


class SectionBase(RenderCVBaseModel):
    """This class is the parent class of all the section types. It is being used
    in RenderCV internally, and it is not meant to be used directly by the users.
    It is used by `rendercv.data_models.utilities.create_a_section_model` function to
    create a section model based on any entry type.
    """

    title: str
    entry_type: str
    entries: types.ListOfEntries


# ======================================================================================
# Full RenderCV data models: ===========================================================
# ======================================================================================


class SocialNetwork(RenderCVBaseModel):
    """This class is the data model of a social network."""

    network: types.SocialNetworkName = pydantic.Field(
        title="Social Network",
        description="Name of the social network.",
    )
    username: str = pydantic.Field(
        title="Username",
        description="The username of the social network. The link will be generated.",
    )

    @pydantic.field_validator("username")
    @classmethod
    def check_username(cls, username: str, info: pydantic.ValidationInfo) -> str:
        """Check if the username is provided correctly."""
        if "network" not in info.data:
            # the network is either not provided or not one of the available social
            # networks. In this case, don't check the username, since Pydantic will
            # raise an error for the network.
            return username

        network = info.data["network"]

        username = val.validate_a_social_network_username(username, network)

        return username

    @pydantic.model_validator(mode="after")  # type: ignore
    def check_url(self) -> "SocialNetwork":
        """Validate the URL of the social network."""
        if self.network == "Mastodon":
            # All the other social networks have valid URLs. Mastodon URLs contain both
            # the username and the domain. So, we need to validate if the url is valid.
            val.validate_url(self.url)

        return self

    @functools.cached_property
    def url(self) -> str:
        """Return the URL of the social network and cache `url` as an attribute of the
        instance.
        """
        return cf.compute_social_network_url(self.network, self.username)


class CurriculumVitae(RenderCVBaseModel):
    """This class is the data model of the `cv` field."""

    name: Optional[str] = pydantic.Field(
        default=None,
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
        description="The location of the person.",
    )
    email: Optional[pydantic.EmailStr] = pydantic.Field(
        default=None,
        title="Email",
        description="The email address of the person.",
    )
    phone: Optional[pydantic_phone_numbers.PhoneNumber] = pydantic.Field(
        default=None,
        title="Phone",
        description="The phone number of the person.",
    )
    website: Optional[pydantic.HttpUrl] = pydantic.Field(
        default=None,
        title="Website",
        description="The website of the person.",
    )
    social_networks: Optional[list[SocialNetwork]] = pydantic.Field(
        default=None,
        title="Social Networks",
        description="The social networks of the person.",
    )
    sections_input: Optional[dict[str, types.SectionInput]] = pydantic.Field(
        default=None,
        title="Sections",
        description="The sections of the CV.",
        # This is an alias to allow users to use `sections` in the YAML file:
        # `sections` key is preserved for RenderCV's internal use.
        alias="sections",
    )

    @functools.cached_property
    def connections(self) -> list[dict[str, str]]:
        """Return all the connections of the person as a list of dictionaries and cache
        `connections` as an attribute of the instance.
        """
        connections = cf.compute_connections(self)

        return connections

    @functools.cached_property
    def sections(self) -> list[SectionBase]:
        """Return all the sections of the CV with their titles as a list of
        `SectionBase` instances and cache `sections` as an attribute of the instance.
        """
        sections = cf.compute_sections(self.sections_input)

        return sections


class LocaleCatalog(RenderCVBaseModel):
    """This class is the data model of the locale catalog. The values of each field
    updates the `locale_catalog` dictionary.
    """

    month: Optional[str] = pydantic.Field(
        default="month",
        title='Translation of "Month"',
        description='Translation of the word "month" in the locale.',
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    months: Optional[str] = pydantic.Field(
        default="months",
        title='Translation of "Months"',
        description='Translation of the word "months" in the locale.',
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    year: Optional[str] = pydantic.Field(
        default="year",
        title='Translation of "Year"',
        description='Translation of the word "year" in the locale.',
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    years: Optional[str] = pydantic.Field(
        default="years",
        title='Translation of "Years"',
        description='Translation of the word "years" in the locale.',
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    present: Optional[str] = pydantic.Field(
        default="present",
        title='Translation of "Present"',
        description='Translation of the word "present" in the locale.',
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    to: Optional[str] = pydantic.Field(
        default="–",  # en dash
        title='Translation of "To"',
        description=(
            "The word or character used to indicate a range in the locale (e.g.,"
            ' "2020 - 2021").'
        ),
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    abbreviations_for_months: Optional[
        Annotated[list[str], at.Len(min_length=12, max_length=12)]
    ] = pydantic.Field(
        # Month abbreviations are taken from
        # https://web.library.yale.edu/cataloging/months:
        default=[
            "Jan",
            "Feb",
            "Mar",
            "Apr",
            "May",
            "June",
            "July",
            "Aug",
            "Sept",
            "Oct",
            "Nov",
            "Dec",
        ],
        title="Abbreviations of Months",
        description="Abbreviations of the months in the locale.",
        validate_default=True,  # to initialize the locale catalog with the default values
    )
    full_names_of_months: Optional[
        Annotated[list[str], at.Len(min_length=12, max_length=12)]
    ] = pydantic.Field(
        default=[
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December",
        ],
        title="Full Names of Months",
        description="Full names of the months in the locale.",
        validate_default=True,  # to initialize the locale catalog with the default values
    )

    @pydantic.field_validator(
        "month",
        "months",
        "year",
        "years",
        "present",
        "abbreviations_for_months",
        "to",
        "full_names_of_months",
    )
    @classmethod
    def update_translations(cls, value: str, info: pydantic.ValidationInfo) -> str:
        """Update the `locale_catalog` dictionary with the provided translations."""
        if value:
            locale_catalog[info.field_name] = value

        return value


# The dictionary below will be overwritten by LocaleCatalog class, which will contain
# month names, month abbreviations, and other locale-specific strings.
locale_catalog: dict[str, str | list[str]] = {}
LocaleCatalog()  # Initialize the locale catalog with the default values


class RenderCVDataModel(RenderCVBaseModel):
    """This class binds both the CV and the design information together."""

    cv: CurriculumVitae = pydantic.Field(
        title="Curriculum Vitae",
        description="The data of the CV.",
    )
    design: types.RenderCVDesign = pydantic.Field(
        default=ClassicThemeOptions(theme="classic"),
        title="Design",
        description=(
            "The design information of the CV. The default is the classic theme."
        ),
    )
    locale_catalog: Optional[LocaleCatalog] = pydantic.Field(
        default=None,
        title="Locale Catalog",
        description=(
            "The locale catalog of the CV to allow the support of multiple languages."
        ),
    )


def read_input_file(
    file_path_or_contents: pathlib.Path | str,
) -> RenderCVDataModel:
    """Read the input file (YAML or JSON) and return them as an instance of
    `RenderCVDataModel`, which is a Pydantic data model of RenderCV's data format.

    Args:
        file_path_or_contents (str): The path to the input file or the contents of the
            input file as a string.

    Returns:
        RenderCVDataModel: The data models with $\\LaTeX$ and Markdown strings.
    """
    if isinstance(file_path_or_contents, pathlib.Path):
        # Check if the file exists:
        if not file_path_or_contents.exists():
            raise FileNotFoundError(
                f"The input file [magenta]{file_path_or_contents}[/magenta] doesn't"
                " exist!"
            )

        # Check the file extension:
        accepted_extensions = [".yaml", ".yml", ".json", ".json5"]
        if file_path_or_contents.suffix not in accepted_extensions:
            user_friendly_accepted_extensions = [
                f"[green]{ext}[/green]" for ext in accepted_extensions
            ]
            user_friendly_accepted_extensions = ", ".join(
                user_friendly_accepted_extensions
            )
            raise ValueError(
                "The input file should have one of the following extensions:"
                f" {user_friendly_accepted_extensions}. The input file is"
                f" [magenta]{file_path_or_contents}[/magenta]."
            )

        file_content = file_path_or_contents.read_text(encoding="utf-8")
    else:
        file_content = file_path_or_contents

    input_as_dictionary: dict[str, Any] = ruamel.yaml.YAML().load(file_content)  # type: ignore

    # Validate the parsed dictionary by creating an instance of RenderCVDataModel:
    rendercv_data_model = RenderCVDataModel(**input_as_dictionary)

    return rendercv_data_model
