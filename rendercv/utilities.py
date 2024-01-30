import re
from datetime import date as Date
import time
import os

from ruamel.yaml import YAML

from .terminal_reporter import warning, error, information


def escape_latex_characters(sentence: str) -> str:
    """Escape some of the speacial LaTeX characters (e.g. #, %, &, ~) in a string.

    Example:
        ```python
        escape_latex_characters("This is a # sentence.")
        ```
        will return:
        `#!python "This is a \\# sentence."`
    """

    # Dictionary of escape characters:
    escape_characters = {
        "#": r"\#",
        # "$": r"\$", # Don't escape $ as it is used for math mode
        "%": r"\%",
        "&": r"\&",
        "~": r"\textasciitilde{}",
        # "_": r"\_", # Don't escape _ as it is used for math mode
        # "^": r"\textasciicircum{}", # Don't escape ^ as it is used for math mode
    }

    # Don't escape links as hyperref will do it automatically:

    # Find all the links in the sentence:
    links = re.findall(r"\[.*?\]\(.*?\)", sentence)

    # Replace the links with a placeholder:
    for link in links:
        sentence = sentence.replace(link, "!!-link-!!")

    # Handle backslash and curly braces separately because the other characters are
    # escaped with backslash and curly braces:
    # --don't escape curly braces as they are used heavily in LaTeX--:
    # sentence = sentence.replace("{", ">>{")
    # sentence = sentence.replace("}", ">>}")
    # --don't escape backslash as it is used heavily in LaTeX--:
    # sentence = sentence.replace("\\", "\\textbackslash{}")
    # sentence = sentence.replace(">>{", "\\{")
    # sentence = sentence.replace(">>}", "\\}")

    # Loop through the letters of the sentence and if you find an escape character,
    # replace it with its LaTeX equivalent:
    copy_of_the_sentence = sentence
    for character in copy_of_the_sentence:
        if character in escape_characters:
            sentence = sentence.replace(character, escape_characters[character])

    # Replace the links with the original links:
    for link in links:
        sentence = sentence.replace("!!-link-!!", link)

    return sentence


def parse_date_string(date_string: str) -> Date:
    """Parse a date string in YYYY-MM-DD, YYYY-MM, or YYYY format and return a
    datetime.date object.

    Args:
        date_string (str): The date string to parse.
    Returns:
        datetime.date: The parsed date.
    """
    if re.match(r"\d{4}-\d{2}-\d{2}", date_string):
        # Then it is in YYYY-MM-DD format
        date = Date.fromisoformat(date_string)
    elif re.match(r"\d{4}-\d{2}", date_string):
        # Then it is in YYYY-MM format
        # Assign a random day since days are not rendered in the CV
        date = Date.fromisoformat(f"{date_string}-01")
    else:
        raise ValueError(
            f'The date string "{date_string}" is not in YYYY-MM-DD, YYYY-MM, or YYYY'
            " format."
        )

    return date


def format_date(date: Date) -> str:
    """Formats a `Date` object to a string in the following format: "Jan. 2021".

    It uses month abbreviations, taken from
    [Yale University Library](https://web.library.yale.edu/cataloging/months).

    Example:
        ```python
        format_date(Date(2024, 5, 1))
        ```
        will return

        `#!python "May 2024"`

    Args:
        date (Date): The date to format.

    Returns:
        str: The formatted date.
    """
    # Month abbreviations,
    # taken from: https://web.library.yale.edu/cataloging/months
    abbreviations_of_months = [
        "Jan.",
        "Feb.",
        "Mar.",
        "Apr.",
        "May",
        "June",
        "July",
        "Aug.",
        "Sept.",
        "Oct.",
        "Nov.",
        "Dec.",
    ]

    month = int(date.strftime("%m"))
    month_abbreviation = abbreviations_of_months[month - 1]
    year = date.strftime(format="%Y")
    date_string = f"{month_abbreviation} {year}"

    return date_string
