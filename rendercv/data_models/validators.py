"""
The `rendercv.data_models.validators` module contains all the functions used to validate
the data models of RenderCV, in addition to Pydantic inner validation.
"""

import importlib
import importlib.machinery
import importlib.util
import pathlib
import re
from datetime import date as Date
from typing import Any, Optional

import pydantic

from . import models
# from .types import (
#     available_entry_types,
#     available_theme_options,
#     available_themes,
#     available_entry_type_names,
#     # RenderCVBuiltinDesign,
# )
from . import utilities as util

# Create a URL validator:
# url_validator = pydantic.TypeAdapter(pydantic.HttpUrl)

# Create a RenderCVDesign validator:
# rendercv_design_validator = pydantic.TypeAdapter(RenderCVBuiltinDesign)


def validate_url(url: str) -> str:
    """Validate a URL.

    Args:
        url (str): The URL to validate.
    Returns:
        str: The validated URL.
    """
    url_validator.validate_strings(url)
    return url


def validate_date_field(date: Optional[int | str]) -> Optional[int | str]:
    """Check if the `date` field is provided correctly.

    Args:
        date (Optional[int | str]): The date to validate.
    Returns:
        Optional[int | str]: The validated date.
    """
    date_is_provided = date is not None

    if date_is_provided:
        if isinstance(date, str):
            if re.fullmatch(r"\d{4}-\d{2}(-\d{2})?", date):
                # Then it is in YYYY-MM-DD or YYYY-MMY format
                # Check if it is a valid date:
                util.get_date_object(date)
            elif re.fullmatch(r"\d{4}", date):
                # Then it is in YYYY format, so, convert it to an integer:

                # This is not required for start_date and end_date because they
                # can't be casted into a general string. For date, this needs to
                # be done manually, because it can be a general string.
                date = int(date)

        elif isinstance(date, Date):
            # Pydantic parses YYYY-MM-DD dates as datetime.date objects. We need to
            # convert them to strings because that is how RenderCV uses them.
            date = date.isoformat()

    return date


def validate_start_and_end_date_fields(
    date: str | Date,
) -> str:
    """Check if the `start_date` and `end_date` fields are provided correctly.

    Args:
        date (Optional[Literal["present"] | int | RenderCVDate]): The date to validate.
    Returns:
        Optional[Literal["present"] | int | RenderCVDate]: The validated date.
    """
    date_is_provided = date is not None

    if date_is_provided:
        if isinstance(date, Date):
            # Pydantic parses YYYY-MM-DD dates as datetime.date objects. We need to
            # convert them to strings because that is how RenderCV uses them.
            date = date.isoformat()

        elif date != "present":
            # Validate the date:
            util.get_date_object(date)

    return date


def validate_and_adjust_dates_of_an_entry(entry: models.EntryBase):
    """Check if the dates are provided correctly and make the necessary adjustments.

    Args:
        entry (EntryBase): The entry to validate its dates.
    Returns:
        EntryBase: The validated entry.
    """
    date_is_provided = entry.date is not None
    start_date_is_provided = entry.start_date is not None
    end_date_is_provided = entry.end_date is not None

    if date_is_provided:
        # If only date is provided, ignore start_date and end_date:
        entry.start_date = None
        entry.end_date = None
    elif not start_date_is_provided and end_date_is_provided:
        # If only end_date is provided, assume it is a one-day event and act like
        # only the date is provided:
        entry.date = entry.end_date
        entry.start_date = None
        entry.end_date = None
    elif start_date_is_provided:
        start_date = util.get_date_object(entry.start_date)
        if not end_date_is_provided:
            # If only start_date is provided, assume it is an ongoing event, i.e.,
            # the end_date is present:
            entry.end_date = "present"

        if entry.end_date != "present":
            end_date = util.get_date_object(entry.end_date)

            if start_date > end_date:
                raise ValueError(
                    '"start_date" can not be after "end_date"!',
                    "start_date",  # This is the location of the error
                    str(start_date),  # This is value of the error
                )

    return entry


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


def validate_a_section(sections_input: list[Any]) -> list[Any]:
    """Validate a list of entries (a section).

    Sections input is a list of entries. Since there are multiple entry types, it is not
    possible to validate it directly. Firstly, the entry type is determined with the
    `get_entry_and_section_type` function. If the entry type cannot be determined, an
    error is raised. If the entry type is determined, the rest of the list is validated
    based on the determined entry type.

    Args:
        sections_input (list[Any]): The sections input to validate.
    Returns:
        list[Any]: The validated sections input.
    """
    if isinstance(sections_input, list):
        # Find the entry type based on the first identifiable entry:
        entry_type = None
        section_type = None
        for entry in sections_input:
            try:
                entry_type, section_type = (
                    validate_an_entry_type_and_get_entry_type_name(entry)
                )
                break
            except ValueError:
                pass

        if entry_type is None or section_type is None:
            raise ValueError(
                "RenderCV couldn't match this section with any entry types! Please"
                " check the entries and make sure they are provided correctly.",
                "",  # This is the location of the error
                "",  # This is value of the error
            )

        section = {
            "title": "Test Section",
            "entry_type": entry_type,
            "entries": sections_input,
        }

        try:
            section_type.model_validate(
                section,
            )
        except pydantic.ValidationError as e:
            new_error = ValueError(
                "There are problems with the entries. RenderCV detected the entry type"
                f" of this section to be {entry_type}! The problems are shown below.",
                "",  # This is the location of the error
                "",  # This is value of the error
            )
            raise new_error from e

    return sections_input


def validate_an_entry_type_and_get_entry_type_name(
    entry: dict[str, Any] | str,
) -> str:
    """Determine the entry type based on an entry.

    Args:
        entry: The entry to determine the type.
    Returns:
        str: The name of the entry type.
    """
    # Get the class attributes of EntryBase class:
    common_attributes = set(models.EntryBase.model_fields.keys())

    if isinstance(entry, dict):
        entry_type_name = None  # the entry type is not determined yet

        for EntryType in available_entry_types:
            characteristic_entry_attributes = (
                set(EntryType.model_fields.keys()) - common_attributes
            )

            # If at least one of the characteristic_entry_attributes is in the entry,
            # then it means the entry is of this type:
            if characteristic_entry_attributes & set(entry.keys()):
                entry_type_name = EntryType.__name__
                break

        if entry_type_name is None:
            raise ValueError("The entry is not provided correctly.")

    elif isinstance(entry, str):
        # Then it is a TextEntry
        entry_type_name = "TextEntry"

    return entry_type_name


def validate_a_custom_theme(
    design: Any,
) -> Any:
    """Validate a custom theme.

    Args:
        design (Any | RenderCVBuiltinDesign): The design to validate.
    Returns:
        RenderCVBuiltinDesign | Any: The validated design.
    """
    if (
        isinstance(design, available_theme_options)
        or design["theme"] in available_themes
    ):
        # Then it means it is a built-in theme. Return it as it is:
        return design

    theme_name: str = str(design["theme"])

    # Check if the theme name is valid:
    if not theme_name.isalpha():
        raise ValueError(
            "The custom theme name should contain only letters.",
            "theme",  # this is the location of the error
            theme_name,  # this is value of the error
        )

    custom_theme_folder = pathlib.Path(theme_name)

    # Check if the custom theme folder exists:
    if not custom_theme_folder.exists():
        raise ValueError(
            f"The custom theme folder `{custom_theme_folder}` does not exist."
            " It should be in the working directory as the input file.",
            "",  # this is the location of the error
            theme_name,  # this is value of the error
        )

    # check if all the necessary files are provided in the custom theme folder:
    required_entry_files = [
        entry_type_name + ".j2.tex" for entry_type_name in available_entry_type_names
    ]
    required_files = [
        "SectionBeginning.j2.tex",  # section beginning template
        "SectionEnding.j2.tex",  # section ending template
        "Preamble.j2.tex",  # preamble template
        "Header.j2.tex",  # header template
    ] + required_entry_files

    for file in required_files:
        file_path = custom_theme_folder / file
        if not file_path.exists():
            raise ValueError(
                f"You provided a custom theme, but the file `{file}` is not"
                f" found in the folder `{custom_theme_folder}`.",
                "",  # This is the location of the error
                theme_name,  # This is value of the error
            )

    # Import __init__.py file from the custom theme folder if it exists:
    path_to_init_file = pathlib.Path(f"{theme_name}/__init__.py")

    if path_to_init_file.exists():
        spec = importlib.util.spec_from_file_location(
            "theme",
            path_to_init_file,
        )

        theme_module = importlib.util.module_from_spec(spec)
        try:
            spec.loader.exec_module(theme_module)  # type: ignore
        except SyntaxError:
            raise ValueError(
                f"The custom theme {theme_name}'s __init__.py file has a syntax"
                " error. Please fix it.",
            )
        except ImportError:
            raise ValueError(
                f"The custom theme {theme_name}'s __init__.py file has an"
                " import error. If you have copy-pasted RenderCV's built-in"
                " themes, make sure tto update the import statements (e.g.,"
                ' "from . import" to "from rendercv.themes import").',
            )

        ThemeDataModel = getattr(
            theme_module, f"{theme_name.capitalize()}ThemeOptions"  # type: ignore
        )

        # Initialize and validate the custom theme data model:
        theme_data_model = ThemeDataModel(**design)
    else:
        # Then it means there is no __init__.py file in the custom theme folder.
        # Create a dummy data model and use that instead.
        class ThemeOptionsAreNotProvided(models.RenderCVBaseModel):
            theme: str = theme_name

        theme_data_model = ThemeOptionsAreNotProvided(theme=theme_name)

    return theme_data_model
