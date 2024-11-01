"""
The `rendercv.data.models.curriculum_vitae` module contains the data model of the `cv`
field of the input file.
"""

import functools
import re
from typing import Annotated, Any, Literal, Optional, Type, get_args

import pydantic
import pydantic_extra_types.phone_numbers as pydantic_phone_numbers

from . import computers, entry_types
from .base import RenderCVBaseModelWithExtraKeys, RenderCVBaseModelWithoutExtraKeys

# ======================================================================================
# Create validator functions: ==========================================================
# ======================================================================================


class SectionBase(RenderCVBaseModelWithoutExtraKeys):
    """This class is the parent class of all the section types. It is being used
    in RenderCV internally, and it is not meant to be used directly by the users.
    It is used by `rendercv.data_models.utilities.create_a_section_model` function to
    create a section model based on any entry type.
    """

    title: str
    entry_type: str
    entries: list[Any]


# Create a URL validator:
url_validator = pydantic.TypeAdapter(pydantic.HttpUrl)


def validate_url(url: str) -> str:
    """Validate a URL.

    Args:
        url: The URL to validate.

    Returns:
        The validated URL.
    """
    url_validator.validate_strings(url)
    return url


def create_a_section_validator(entry_type: Type) -> Type[SectionBase]:
    """Create a section model based on the entry type. See [Pydantic's documentation
    about dynamic model
    creation](https://pydantic-docs.helpmanual.io/usage/models/#dynamic-model-creation)
    for more information.

    The section model is used to validate a section.

    Args:
        entry_type: The entry type to create the section model. It's not an instance of
            the entry type, but the entry type itself.

    Returns:
        The section validator (a Pydantic model).
    """
    if entry_type is str:
        model_name = "SectionWithTextEntries"
        entry_type_name = "TextEntry"
    else:
        model_name = "SectionWith" + entry_type.__name__.replace("Entry", "Entries")
        entry_type_name = entry_type.__name__

    SectionModel = pydantic.create_model(
        model_name,
        entry_type=(Literal[entry_type_name], ...),  # type: ignore
        entries=(list[entry_type], ...),
        __base__=SectionBase,
    )

    return SectionModel


def get_characteristic_entry_attributes(
    entry_types: list[Type],
) -> dict[Type, set[str]]:
    """Get the characteristic attributes of the entry types.

    Args:
        entry_types: The entry types to get their characteristic attributes. These are
            not instances of the entry types, but the entry types themselves. `str` type
            should not be included in this list.

    Returns:
        The characteristic attributes of the entry types.
    """
    # Look at all the entry types, collect their attributes with
    # EntryType.model_fields.keys() and find the common ones.
    all_attributes = []
    for EntryType in entry_types:
        all_attributes.extend(EntryType.model_fields.keys())

    common_attributes = set(
        attribute for attribute in all_attributes if all_attributes.count(attribute) > 1
    )

    # Store each entry type's characteristic attributes in a dictionary:
    characteristic_entry_attributes = {}
    for EntryType in entry_types:
        characteristic_entry_attributes[EntryType] = (
            set(EntryType.model_fields.keys()) - common_attributes
        )

    return characteristic_entry_attributes


def get_entry_type_name_and_section_validator(
    entry: dict[str, str | list[str]] | str | Type, entry_types: list[Type]
) -> tuple[str, Type[SectionBase]]:
    """Get the entry type name and the section validator based on the entry.

    It takes an entry (as a dictionary or a string) and a list of entry types. Then
    it determines the entry type and creates a section validator based on the entry
    type.

    Args:
        entry: The entry to determine its type.
        entry_types: The entry types to determine the entry type. These are not
            instances of the entry types, but the entry types themselves. `str` type
            should not be included in this list.

    Returns:
        The entry type name and the section validator.
    """

    if isinstance(entry, dict):
        entry_type_name = None  # the entry type is not determined yet
        characteristic_entry_attributes = get_characteristic_entry_attributes(
            entry_types
        )

        for (
            EntryType,
            characteristic_attributes,
        ) in characteristic_entry_attributes.items():
            # If at least one of the characteristic_entry_attributes is in the entry,
            # then it means the entry is of this type:
            if characteristic_attributes & set(entry.keys()):
                entry_type_name = EntryType.__name__
                section_type = create_a_section_validator(EntryType)
                break

        if entry_type_name is None:
            raise ValueError("The entry is not provided correctly.")

    elif isinstance(entry, str):
        # Then it is a TextEntry
        entry_type_name = "TextEntry"
        section_type = create_a_section_validator(str)

    else:
        # Then the entry is already initialized with a data model:
        entry_type_name = entry.__class__.__name__
        section_type = create_a_section_validator(entry.__class__)

    return entry_type_name, section_type  # type: ignore


def validate_a_section(
    sections_input: list[Any], entry_types: list[Type]
) -> list[entry_types.Entry]:
    """Validate a list of entries (a section) based on the entry types.

    Sections input is a list of entries. Since there are multiple entry types, it is not
    possible to validate it directly. Firstly, the entry type is determined with the
    `get_entry_type_name_and_section_validator` function. If the entry type cannot be
    determined, an error is raised. If the entry type is determined, the rest of the
    list is validated with the section validator.

    Args:
        sections_input: The sections input to validate.
        entry_types: The entry types to determine the entry type. These are not
            instances of the entry types, but the entry types themselves. `str` type
            should not be included in this list.

    Returns:
        The validated sections input.
    """
    if isinstance(sections_input, list):
        # Find the entry type based on the first identifiable entry:
        entry_type_name = None
        section_type = None
        for entry in sections_input:
            try:
                entry_type_name, section_type = (
                    get_entry_type_name_and_section_validator(entry, entry_types)
                )
                break
            except ValueError:
                # If the entry type cannot be determined, try the next entry:
                pass

        if entry_type_name is None or section_type is None:
            raise ValueError(
                "RenderCV couldn't match this section with any entry types! Please"
                " check the entries and make sure they are provided correctly.",
                "",  # This is the location of the error
                "",  # This is value of the error
            )

        section = {
            "title": "Test Section",
            "entry_type": entry_type_name,
            "entries": sections_input,
        }

        try:
            section_object = section_type.model_validate(
                section,
            )
            sections_input = section_object.entries
        except pydantic.ValidationError as e:
            new_error = ValueError(
                "There are problems with the entries. RenderCV detected the entry type"
                f" of this section to be {entry_type_name}! The problems are shown"
                " below.",
                "",  # This is the location of the error
                "",  # This is value of the error
            )
            raise new_error from e

    else:
        raise ValueError(
            "Each section should be a list of entries! Please see the documentation for"
            " more information about the sections.",
        )
    return sections_input


def validate_a_social_network_username(username: str, network: str) -> str:
    """Check if the `username` field in the `SocialNetwork` model is provided correctly.

    Args:
        username: The username to validate.

    Returns:
        The validated username.
    """
    if network == "Mastodon":
        mastodon_username_pattern = r"@[^@]+@[^@]+"
        if not re.fullmatch(mastodon_username_pattern, username):
            raise ValueError(
                'Mastodon username should be in the format "@username@domain"!'
            )
    if network == "StackOverflow":
        stackoverflow_username_pattern = r"\d+\/[^\/]+"
        if not re.fullmatch(stackoverflow_username_pattern, username):
            raise ValueError(
                'StackOverflow username should be in the format "user_id/username"!'
            )
    if network == "YouTube":
        if username.startswith("@"):
            raise ValueError(
                'YouTube username should not start with "@"! Remove "@" from the'
                " beginning of the username."
            )

    return username


# ======================================================================================
# Create custom types: =================================================================
# ======================================================================================

# Create a custom type named SectionContents, which is a list of entries. The entries
# can be any of the available entry types. The section is validated with the
# `validate_a_section` function.
SectionContents = Annotated[
    pydantic.json_schema.SkipJsonSchema[Any] | entry_types.ListOfEntries,
    pydantic.BeforeValidator(
        lambda entries: validate_a_section(
            entries, entry_types=entry_types.available_entry_models
        )
    ),
]

# Create a custom type named SectionInput, which is a dictionary where the keys are the
# section titles and the values are the list of entries in that section.
Sections = Optional[dict[str, SectionContents]]

# Create a custom type named SocialNetworkName, which is a literal type of the available
# social networks.
SocialNetworkName = Literal[
    "LinkedIn",
    "GitHub",
    "GitLab",
    "Instagram",
    "ORCID",
    "Mastodon",
    "StackOverflow",
    "ResearchGate",
    "YouTube",
    "Google Scholar",
    "Telegram",
]

available_social_networks = get_args(SocialNetworkName)

# ======================================================================================
# Create the models: ===================================================================
# ======================================================================================


class SocialNetwork(RenderCVBaseModelWithoutExtraKeys):
    """This class is the data model of a social network."""

    network: SocialNetworkName = pydantic.Field(
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

        username = validate_a_social_network_username(username, network)

        return username

    @pydantic.model_validator(mode="after")  # type: ignore
    def check_url(self) -> "SocialNetwork":
        """Validate the URL of the social network."""
        if self.network == "Mastodon":
            # All the other social networks have valid URLs. Mastodon URLs contain both
            # the username and the domain. So, we need to validate if the url is valid.
            validate_url(self.url)

        return self

    @functools.cached_property
    def url(self) -> str:
        """Return the URL of the social network and cache `url` as an attribute of the
        instance.
        """
        if self.network == "Mastodon":
            # Split domain and username
            _, username, domain = self.username.split("@")
            url = f"https://{domain}/@{username}"
        else:
            url_dictionary = {
                "LinkedIn": "https://linkedin.com/in/",
                "GitHub": "https://github.com/",
                "GitLab": "https://gitlab.com/",
                "Instagram": "https://instagram.com/",
                "ORCID": "https://orcid.org/",
                "StackOverflow": "https://stackoverflow.com/users/",
                "ResearchGate": "https://researchgate.net/profile/",
                "YouTube": "https://youtube.com/@",
                "Google Scholar": "https://scholar.google.com/citations?user=",
                "Telegram": "https://t.me/",
            }
            url = url_dictionary[self.network] + self.username

        return url


class CurriculumVitae(RenderCVBaseModelWithExtraKeys):
    """This class is the data model of the `cv` field."""

    name: Optional[str] = pydantic.Field(
        default=None,
        title="Name",
        description="The name of the person.",
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
        description="The phone number of the person, including the country code.",
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
    sections_input: Sections = pydantic.Field(
        default=None,
        title="Sections",
        description="The sections of the CV.",
        # This is an alias to allow users to use `sections` in the YAML file:
        # `sections` key is preserved for RenderCV's internal use.
        alias="sections",
    )

    @pydantic.field_validator("name")
    @classmethod
    def update_curriculum_vitae(cls, value: str, info: pydantic.ValidationInfo) -> str:
        """Update the `curriculum_vitae` dictionary."""
        if value:
            curriculum_vitae[info.field_name] = value  # type: ignore

        return value

    @functools.cached_property
    def connections(self) -> list[dict[str, Optional[str]]]:
        """Return all the connections of the person as a list of dictionaries and cache
        `connections` as an attribute of the instance. The connections are used in the
        header of the CV.

        Returns:
            The connections of the person.
        """

        connections: list[dict[str, Optional[str]]] = []

        if self.location is not None:
            connections.append(
                {
                    "latex_icon": "\\faMapMarker*",
                    "url": None,
                    "clean_url": None,
                    "placeholder": self.location,
                }
            )

        if self.email is not None:
            connections.append(
                {
                    "latex_icon": "\\faEnvelope[regular]",
                    "url": f"mailto:{self.email}",
                    "clean_url": self.email,
                    "placeholder": self.email,
                }
            )

        if self.phone is not None:
            phone_placeholder = computers.format_phone_number(self.phone)
            connections.append(
                {
                    "latex_icon": "\\faPhone*",
                    "url": self.phone,
                    "clean_url": phone_placeholder,
                    "placeholder": phone_placeholder,
                }
            )

        if self.website is not None:
            website_placeholder = computers.make_a_url_clean(str(self.website))
            connections.append(
                {
                    "latex_icon": "\\faLink",
                    "url": str(self.website),
                    "clean_url": website_placeholder,
                    "placeholder": website_placeholder,
                }
            )

        if self.social_networks is not None:
            icon_dictionary = {
                "LinkedIn": "\\faLinkedinIn",
                "GitHub": "\\faGithub",
                "GitLab": "\\faGitlab",
                "Instagram": "\\faInstagram",
                "Mastodon": "\\faMastodon",
                "ORCID": "\\faOrcid",
                "StackOverflow": "\\faStackOverflow",
                "ResearchGate": "\\faResearchgate",
                "YouTube": "\\faYoutube",
                "Google Scholar": "\\faGraduationCap",
                "Telegram": "\\faTelegram",
            }
            for social_network in self.social_networks:
                clean_url = computers.make_a_url_clean(social_network.url)
                connection = {
                    "latex_icon": icon_dictionary[social_network.network],
                    "url": social_network.url,
                    "clean_url": clean_url,
                    "placeholder": social_network.username,
                }

                if social_network.network == "StackOverflow":
                    username = social_network.username.split("/")[1]
                    connection["placeholder"] = username
                if social_network.network == "Google Scholar":
                    connection["placeholder"] = "Google Scholar"

                connections.append(connection)  # type: ignore

        return connections

    @functools.cached_property
    def sections(self) -> list[SectionBase]:
        """Compute the sections of the CV based on the input sections.

        The original `sections` input is a dictionary where the keys are the section titles
        and the values are the list of entries in that section. This function converts the
        input sections to a list of `SectionBase` objects. This makes it easier to work with
        the sections in the rest of the code.

        Returns:
            The computed sections.
        """
        sections: list[SectionBase] = []

        if self.sections_input is not None:
            for title, entries in self.sections_input.items():
                title = computers.dictionary_key_to_proper_section_title(title)

                # The first entry can be used because all the entries in the section are
                # already validated with the `validate_a_section` function:
                entry_type_name, _ = get_entry_type_name_and_section_validator(
                    entries[0],  # type: ignore
                    entry_types=entry_types.available_entry_models,
                )

                # SectionBase is used so that entries are not validated again:
                section = SectionBase(
                    title=title,
                    entry_type=entry_type_name,
                    entries=entries,
                )
                sections.append(section)

        return sections


# The dictionary below will be overwritten by CurriculumVitae class, which will contain
# some important data for the CV.
curriculum_vitae: dict[str, str] = dict()
