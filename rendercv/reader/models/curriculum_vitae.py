from typing import Annotated, Any, Optional, get_args

import pydantic
import functools

from . import entry_types
from . import computers as cf

from typing import Type, Literal
import re

import pydantic_extra_types.phone_numbers as pydantic_phone_numbers

from . import utilities as util
from . import entry_validators

# ======================================================================================
# Create validator functions: ==========================================================
# ======================================================================================


class SectionBase(entry_types.RenderCVBaseModel):
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
        url (str): The URL to validate.
    Returns:
        str: The validated URL.
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
        entry_type (Type): The entry type to create the section model. It's not an
            instance of the entry type, but the entry type itself.
    Returns:
        Type[SectionBase]: The section validator (a Pydantic model).
    """
    if entry_type == str:
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
        entry_types (list[Type]): The entry types to get their characteristic
            attributes. These are not instances of the entry types, but the entry
            types themselves. `str` type should not be included in this list.
    Returns:
        dict[Type, list[str]]: The characteristic attributes of the entry types.
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
    entry: dict[str, Any] | str, entry_types: list[Type]
) -> tuple[str, Type[SectionBase]]:
    """Get the entry type name and the section validator based on the entry.

    It takes an entry (as a dictionary or a string) and a list of entry types. Then
    it determines the entry type and creates a section validator based on the entry
    type.

    Args:
        entry (dict[str, Any] | str): The entry to determine its type.
        entry_types (list[Type]): The entry types to determine the entry type. These
            are not instances of the entry types, but the entry types themselves. `str`
            type should not be included in this list.
    Returns:
        tuple[str, Type[SectionBase]]: The entry type name and the section validator.
    """
    characteristic_entry_attributes = get_characteristic_entry_attributes(entry_types)

    if isinstance(entry, dict):
        entry_type_name = None  # the entry type is not determined yet

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

    return entry_type_name, section_type


def validate_a_section(sections_input: list[Any], entry_types: list[Type]) -> list[Any]:
    """Validate a list of entries (a section) based on the entry types.

    Sections input is a list of entries. Since there are multiple entry types, it is not
    possible to validate it directly. Firstly, the entry type is determined with the
    `get_entry_type_name_and_section_validator` function. If the entry type cannot be
    determined, an error is raised. If the entry type is determined, the rest of the
    list is validated with the section validator.

    Args:
        sections_input (list[Any]): The sections input to validate.
        entry_types (list[Type]): The entry types to determine the entry type. These
            are not instances of the entry types, but the entry types themselves. `str`
            type should not be included in this list.
    Returns:
        list[Any]: The validated sections input.
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
            section_type.model_validate(
                section,
            )
        except pydantic.ValidationError as e:
            new_error = ValueError(
                "There are problems with the entries. RenderCV detected the entry type"
                f" of this section to be {entry_type_name}! The problems are shown"
                " below.",
                "",  # This is the location of the error
                "",  # This is value of the error
            )
            raise new_error from e

    return sections_input


def validate_a_social_network_username(username: str, network: str) -> str:
    """Check if the `username` field in the `SocialNetwork` model is provided correctly.

    Args:
        username (str): The username to validate.
    Returns:
        str: The validated username.
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

# Create a custom type named ListOfEntries:
ListOfEntries = list[entry_types.Entry]

# Create a custom type named SectionContents, which is a list of entries. The entries
# can be any of the available entry types. The section is validated with the
# `validate_a_section` function.
SectionContents = Annotated[
    ListOfEntries,
    pydantic.PlainValidator(
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
]

available_social_networks = get_args(SocialNetworkName)

# ======================================================================================
# Create the models: ===================================================================
# ======================================================================================


class SocialNetwork(entry_types.RenderCVBaseModel):
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
        return cf.compute_social_network_url(self.network, self.username)


class CurriculumVitae(entry_validators.RenderCVBaseModel):
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
    sections_input: Sections = pydantic.Field(
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
        """Compute the sections of the CV based on the input sections.

        The original `sections` input is a dictionary where the keys are the section titles
        and the values are the list of entries in that section. This function converts the
        input sections to a list of `SectionBase` objects. This makes it easier to work with
        the sections in the rest of the code.

        Args:
            sections_input (Optional[dict[str, SectionInput]]): The input sections.
        Returns:
            list[SectionBase]: The computed sections.
        """
        sections: list[SectionBase] = []

        if self.sections_input is not None:
            for title, entries in self.sections_input.items():
                title = util.dictionary_key_to_proper_section_title(title)

                # The first entry can be used because all the entries in the section are
                # already validated with the `validate_a_section` function:
                entry_type_name, _ = get_entry_type_name_and_section_validator(
                    entries[0]
                )

                # SectionBase is used so that entries are not validated again:
                section = SectionBase(
                    title=title,
                    entry_type=entry_type_name,
                    entries=entries,
                )
                sections.append(section)

        return sections
