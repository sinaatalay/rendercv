"""
The `rendercv.data_models.validators` module contains all the functions used to validate
the data models of RenderCV, in addition to Pydantic inner validation.
"""

import re
from datetime import date as Date
from typing import Optional

import pydantic

from . import utilities as util


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
