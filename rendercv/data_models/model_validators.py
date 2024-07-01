from typing import Optional, Any, Type, Literal

import pathlib
import pydantic
import importlib
import importlib.util


# from .types import (
#     available_entry_types,
#     available_theme_options,
#     available_themes,
#     available_entry_type_names,
#     # RenderCVBuiltinDesign,
# )

from . import utilities as util
from . import field_types
from .models import RenderCVBaseModel


class SectionBase(RenderCVBaseModel):
    """This class is the parent class of all the section types. It is being used
    in RenderCV internally, and it is not meant to be used directly by the users.
    It is used by `rendercv.data_models.utilities.create_a_section_model` function to
    create a section model based on any entry type.
    """

    title: str
    entry_type: str
    entries: list[Any]


def create_a_section_validator(entry_type: Type) -> Type[SectionBase]:
    """Create a section model based on the entry type. See [Pydantic's documentation
    about dynamic model
    creation](https://pydantic-docs.helpmanual.io/usage/models/#dynamic-model-creation)
    for more information.

    The section model is used to validate a section.

    Args:
        entry_type (Type[Entry]): The entry type to create the section model. It's not
            an instance of the entry type, but the entry type itself.
    Returns:
        Type[SectionBase]: The section model.
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


def validate_and_adjust_dates(
    start_date: field_types.StartDate,
    end_date: field_types.EndDate,
    date: Optional[field_types.ArbitraryDate],
) -> tuple[field_types.StartDate, field_types.EndDate, field_types.ArbitraryDate]:
    """Check if the dates are provided correctly and make the necessary adjustments.

    Args:
        entry (EntryBase): The entry to validate its dates.
    Returns:
        EntryBase: The validated
    """
    date_is_provided = date is not None
    start_date_is_provided = start_date is not None
    end_date_is_provided = end_date is not None

    if date_is_provided:
        # If only date is provided, ignore start_date and end_date:
        start_date = None
        end_date = None
    elif not start_date_is_provided and end_date_is_provided:
        # If only end_date is provided, assume it is a one-day event and act like
        # only the date is provided:
        date = end_date
        start_date = None
        end_date = None
    elif start_date_is_provided:
        start_date = util.get_date_object(start_date)
        if not end_date_is_provided:
            # If only start_date is provided, assume it is an ongoing event, i.e.,
            # the end_date is present:
            end_date = "present"

        if end_date != "present":
            end_date = util.get_date_object(end_date)

            if start_date > end_date:
                raise ValueError(
                    '"start_date" can not be after "end_date"!',
                    "start_date",  # This is the location of the error
                    str(start_date),  # This is value of the error
                )

    return start_date, end_date, date


def get_characteristic_entry_attributes(
    entry_types: list[Type],
) -> dict[Type, set[str]]:
    """Get the characteristic attributes of the entry types.

    Args:
        entry_types (list[Type]): The entry types to get their characteristic
            attributes.
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


def validate_design_options(
    design: Any,
    available_theme_options: dict[str, Type],
    available_entry_type_names: list[str],
) -> Any:
    """Chech if the design options are for a built-in theme or a custom theme. If it is
    a built-in theme, validate it with the corresponding data model. If it is a custom
    theme, check if the necessary files are provided and validate it with the custom
    theme data model, found in the `__init__.py` file of the custom theme folder.

    Args:
        design (Any | RenderCVBuiltinDesign): The design options to validate.
        available_theme_options (dict[str, Type]): The available theme options. The keys
            are the theme names and the values are the corresponding data models.
        available_entry_type_names (list[str]): The available entry type names. These
            are used to validate if all the templates are provided in the custom theme
            folder.
    Returns:
        Any: The validated design as a Pydantic data model.
    """
    if isinstance(design, available_theme_options):
        # Then it means it is an already validated built-in theme. Return it as it is:
        return design
    elif design["theme"] in available_theme_options:
        # Then it is a built-in theme, but it is not validated yet. Validate it and
        # return it:
        ThemeDataModel = available_theme_options[design["theme"]]
        return ThemeDataModel(**design)
    else:
        # It is a custom theme. Validate it:
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
            entry_type_name + ".j2.tex"
            for entry_type_name in available_entry_type_names
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
                    " themes, make sure to update the import statements (e.g.,"
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
            class ThemeOptionsAreNotProvided(RenderCVBaseModel):
                theme: str = theme_name

            theme_data_model = ThemeOptionsAreNotProvided(theme=theme_name)

        return theme_data_model
