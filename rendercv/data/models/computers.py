"""
The `rendercv.data.models.computers` module contains functions that compute some
properties based on the input data. For example, it includes functions that calculate
the time span between two dates, the date string, the URL of a social network, etc.
"""

import re
from datetime import date as Date
from typing import Optional

import phonenumbers

from .locale_catalog import locale_catalog


def format_phone_number(phone_number: str) -> str:
    """Format a phone number to the format specified in the `locale_catalog` dictionary.

    Example:
        ```python
        format_phone_number("+17034800500")
        ```
        returns
        ```python
        "(703) 480-0500"
        ```

    Args:
        phone_number (str): The phone number to format.

    Returns:
        str: The formatted phone number.
    """

    format = locale_catalog["phone_number_format"].upper()  # type: ignore

    parsed_number = phonenumbers.parse(phone_number, None)
    formatted_number = phonenumbers.format_number(
        parsed_number, getattr(phonenumbers.PhoneNumberFormat, format)
    )
    return formatted_number


def format_date(date: Date, date_style: Optional[str] = None) -> str:
    """Formats a `Date` object to a string in the following format: "Jan 2021". The
    month names are taken from the `locale_catalog` dictionary from the
    `rendercv.data_models.models` module.

    Example:
        ```python
        format_date(Date(2024, 5, 1))
        ```
        will return

        `#!python "May 2024"`

    Args:
        date (Date): The date to format.
        date_style (Optional[str]): The style of the date string. If not provided, the
            default date style from the `locale_catalog` dictionary will be used.

    Returns:
        str: The formatted date.
    """
    full_month_names = locale_catalog["full_names_of_months"]
    short_month_names = locale_catalog["abbreviations_for_months"]

    month = int(date.strftime("%m"))
    year = date.strftime(format="%Y")

    placeholders = {
        "FULL_MONTH_NAME": full_month_names[month - 1],
        "MONTH_ABBREVIATION": short_month_names[month - 1],
        "MONTH": str(month),
        "MONTH_IN_TWO_DIGITS": f"{month:02d}",
        "YEAR": str(year),
        "YEAR_IN_TWO_DIGITS": str(year[-2:]),
    }
    if date_style is None:
        date_style = locale_catalog["date_style"]  # type: ignore

    for placeholder, value in placeholders.items():
        date_style = date_style.replace(placeholder, value)  # type: ignore

    date_string = date_style

    return date_string  # type: ignore


def compute_time_span_string(
    start_date: Optional[str | int],
    end_date: Optional[str | int],
    date: Optional[str | int],
) -> str:
    """
    Return a time span string based on the provided dates.

    Example:
        ```python
        get_time_span_string("2020-01-01", "2020-05-01", None)
        ```

        returns

        `#!python "4 months"`

    Args:
        start_date (Optional[str]): A start date in YYYY-MM-DD, YYYY-MM, or YYYY format.
        end_date (Optional[str]): An end date in YYYY-MM-DD, YYYY-MM, or YYYY format or
            "present".
        date (Optional[str]): A date in YYYY-MM-DD, YYYY-MM, or YYYY format or a custom
            string. If provided, start_date and end_date will be ignored.

    Returns:
        str: The computed time span string.
    """
    date_is_provided = date is not None
    start_date_is_provided = start_date is not None
    end_date_is_provided = end_date is not None

    if date_is_provided:
        # If only the date is provided, the time span is irrelevant. So, return an
        # empty string.
        return ""

    elif not start_date_is_provided and not end_date_is_provided:
        # If neither start_date nor end_date is provided, return an empty string.
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
        # Then it means both start_date and end_date are in YYYY-MM-DD or YYYY-MM
        # format.
        end_date = get_date_object(end_date)  # type: ignore
        start_date = get_date_object(start_date)  # type: ignore

        # Calculate the number of days between start_date and end_date:
        timespan_in_days = (end_date - start_date).days  # type: ignore

        # Calculate the number of years between start_date and end_date:
        how_many_years = timespan_in_days // 365
        if how_many_years == 0:
            how_many_years_string = None
        elif how_many_years == 1:
            how_many_years_string = f"1 {locale_catalog['year']}"
        else:
            how_many_years_string = f"{how_many_years} {locale_catalog['years']}"

        # Calculate the number of months between start_date and end_date:
        how_many_months = round((timespan_in_days % 365) / 30)
        if how_many_months <= 1:
            how_many_months_string = f"1 {locale_catalog['month']}"
        else:
            how_many_months_string = f"{how_many_months} {locale_catalog['months']}"

        # Combine howManyYearsString and howManyMonthsString:
        if how_many_years_string is None:
            time_span_string = how_many_months_string
        else:
            time_span_string = f"{how_many_years_string} {how_many_months_string}"

        return time_span_string


def compute_date_string(
    start_date: Optional[str | int],
    end_date: Optional[str | int],
    date: Optional[str | int],
    show_only_years: bool = False,
) -> str:
    """Return a date string based on the provided dates.

    Example:
        ```python
        get_date_string("2020-01-01", "2021-01-01", None)
        ```
        returns
        ```
        "Jan 2020 to Jan 2021"
        ```

    Args:
        start_date (Optional[str]): A start date in YYYY-MM-DD, YYYY-MM, or YYYY
            format.
        end_date (Optional[str]): An end date in YYYY-MM-DD, YYYY-MM, or YYYY format
            or "present".
        date (Optional[str]): A date in YYYY-MM-DD, YYYY-MM, or YYYY format or
            a custom string. If provided, start_date and end_date will be ignored.
        show_only_years (bool): If True, only the years will be shown in the date
            string.

    Returns:
        str: The computed date string.
    """
    date_is_provided = date is not None
    start_date_is_provided = start_date is not None
    end_date_is_provided = end_date is not None

    if date_is_provided:
        if isinstance(date, int):
            # Then it means only the year is provided
            date_string = str(date)
        else:
            try:
                date_object = get_date_object(date)
                if show_only_years:
                    date_string = str(date_object.year)
                else:
                    date_string = format_date(date_object)
            except ValueError:
                # Then it is a custom date string (e.g., "My Custom Date")
                date_string = str(date)
    elif start_date_is_provided and end_date_is_provided:
        if isinstance(start_date, int):
            # Then it means only the year is provided
            start_date = str(start_date)
        else:
            # Then it means start_date is either in YYYY-MM-DD or YYYY-MM format
            date_object = get_date_object(start_date)
            if show_only_years:
                start_date = date_object.year
            else:
                start_date = format_date(date_object)

        if end_date == "present":
            end_date = locale_catalog["present"]  #  type: ignore
        elif isinstance(end_date, int):
            # Then it means only the year is provided
            end_date = str(end_date)
        else:
            # Then it means end_date is either in YYYY-MM-DD or YYYY-MM format
            date_object = get_date_object(end_date)
            if show_only_years:
                end_date = date_object.year
            else:
                end_date = format_date(date_object)

        date_string = f"{start_date} {locale_catalog['to']} {end_date}"

    else:
        # Neither date, start_date, nor end_date are provided, so return an empty
        # string:
        date_string = ""

    return date_string


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
    url = url.replace("https://", "").replace("http://", "")
    if url.endswith("/"):
        url = url[:-1]

    return url


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

    words_not_capitalized_in_a_title = [
        "a",
        "and",
        "as",
        "at",
        "but",
        "by",
        "for",
        "from",
        "if",
        "in",
        "into",
        "like",
        "near",
        "nor",
        "of",
        "off",
        "on",
        "onto",
        "or",
        "over",
        "so",
        "than",
        "that",
        "to",
        "upon",
        "when",
        "with",
        "yet",
    ]

    # loop through the words and if the word doesn't contain any uppercase letters,
    # capitalize the first letter of the word. If the word contains uppercase letters,
    # don't change the word.
    proper_title = " ".join(
        (
            word.capitalize()
            if (word.islower() and word not in words_not_capitalized_in_a_title)
            else word
        )
        for word in words
    )

    return proper_title
