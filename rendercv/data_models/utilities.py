"""
The `rendercv.data_models.utilities` module contains utility functions that are required
by data models.
"""

import io
import re
from datetime import date as Date
from typing import Any

import pydantic
import ruamel.yaml


def dictionary_to_yaml(dictionary: dict[str, Any]):
    """Converts a dictionary to a YAML string.

    Args:
        dictionary (dict[str, Any]): The dictionary to be converted to YAML.
    Returns:
        str: The YAML string.
    """
    yaml_object = ruamel.yaml.YAML()
    yaml_object.encoding = "utf-8"
    yaml_object.width = 60
    yaml_object.indent(mapping=2, sequence=4, offset=2)
    with io.StringIO() as string_stream:
        yaml_object.dump(dictionary, string_stream)
        yaml_string = string_stream.getvalue()
    return yaml_string


def get_date_object(date: str | int) -> Date:
    """Parse a date string in YYYY-MM-DD, YYYY-MM, or YYYY format and return a
    `datetime.date` object. This function is used throughout the validation process of
    the data models.

    Args:
        date (str | int): The date string to parse.
    Returns:
        Date: The parsed date.
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


def dictionary_key_to_proper_section_title(key: str) -> str:
    """Convert a dictionary key to a proper section title.

    Example:
        ```python
        dictionary_key_to_proper_section_title("section_title")
        ```
        returns
        `#!python "Section Title"`

    Args:
        key (str): The key to convert to a proper section title.
    Returns:
        str: The proper section title.
    """
    title = key.replace("_", " ")
    words = title.split(" ")

    # loop through the words and if the word doesn't contain any uppercase letters,
    # capitalize the first letter of the word. If the word contains uppercase letters,
    # don't change the word.
    proper_title = " ".join(
        word.capitalize() if word.islower() else word for word in words
    )

    return proper_title


def set_or_update_a_value(
    data_model: pydantic.BaseModel | dict | list,
    key: str,
    value: str,
    sub_model: pydantic.BaseModel | dict | list = None,
):
    """Set or update a value in a data model for a specific key. For example, a key can
    be `cv.sections.education.3.institution` and the value can be "Bogazici University".

    Args:
        data_model (pydantic.BaseModel | dict | list): The data model to set or update
            the value.
        key (str): The key to set or update the value.
        value (Any): The value to set or update.
        sub_model (pydantic.BaseModel | dict | list, optional): The sub model to set or
            update the value. This is used for recursive calls. When the value is set
            to a sub model, the original data model is validated. Defaults to None.
    """
    # Recursively call this function until the last key is reached:

    # Rename `sections` with `sections_input` since the key is `sections` is an alias:
    key = key.replace("sections.", "sections_input.")
    keys = key.split(".")

    if sub_model is not None:
        model = sub_model
    else:
        model = data_model

    if len(keys) == 1:
        # Set the value:
        if value.startswith("{") and value.endswith("}"):
            # Allow users to assign dictionaries:
            value = eval(value)
        elif value.startswith("[") and value.endswith("]"):
            # Allow users to assign lists:
            value = eval(value)

        if isinstance(model, pydantic.BaseModel):
            setattr(model, key, value)
        elif isinstance(model, dict):
            model[key] = value
        elif isinstance(model, list):
            model[int(key)] = value
        else:
            raise ValueError(
                "The data model should be either a Pydantic data model, dictionary, or"
                " list.",
            )

        data_model = type(data_model).model_validate(
            (data_model.model_dump(by_alias=True))
        )
        return data_model
    else:
        # get the first key and call the function with remaining keys:
        first_key = keys[0]
        key = ".".join(keys[1:])
        if isinstance(model, pydantic.BaseModel):
            sub_model = getattr(model, first_key)
        elif isinstance(model, dict):
            sub_model = model[first_key]
        elif isinstance(model, list):
            sub_model = model[int(first_key)]
        else:
            raise ValueError(
                "The data model should be either a Pydantic data model, dictionary, or"
                " list.",
            )

        set_or_update_a_value(data_model, key, value, sub_model)


def make_a_url_clean(url: str) -> str:
    """Make a URL clean by removing the protocol, www, and trailing slashes.

    Example:
        ```python
        make_a_url_clean("https://www.example.com/")
        ```
        returns
        `#!python "example.com"`

    Args:
        url (str): The URL to make clean.
    Returns:
        str: The clean URL.
    """
    url = url.replace("https://", "").replace("http://", "").replace("www.", "")
    if url.endswith("/"):
        url = url[:-1]

    return url
