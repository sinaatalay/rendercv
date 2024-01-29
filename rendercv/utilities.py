import re
from datetime import date as Date
import time
import os

from ruamel.yaml import YAML

from . import data_models as dm
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


def parse_date_string(date_string: str) -> Date | int:
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
    elif re.match(r"\d{4}", date_string):
        # Then it is in YYYY format
        # Then keep it as an integer
        date = int(date_string)
    else:
        raise ValueError(
            f'The date string "{date_string}" is not in YYYY-MM-DD, YYYY-MM, or YYYY'
            " format."
        )

    if isinstance(date, Date):
        # Then it means the date is a Date object, so check if it is a past date:
        if date > Date.today():
            raise ValueError(
                f'The date "{date_string}" is in the future. Please check the dates.'
            )
    elif isinstance(date, int):
        # Then it means the date is an integer, so check if it is a past date:
        if date > Date.today().year:
            raise ValueError(
                f'The date "{date_string}" is in the future. Please check the dates.'
            )
    elif not isinstance(date, str):
        raise RuntimeError(
            "This error shouldn't have been raised. Please open an issue on GitHub."
        )

    return date


def format_date(date: Date | int) -> str:
    """Formats a date to a string in the following format: "Jan. 2021".

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
    if not isinstance(date, (Date, int)):
        raise TypeError("date is not a Date object or an integer!")

    if isinstance(date, int):
        # Then it means the user only provided the year, so just return the year
        return str(date)

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
    monthAbbreviation = abbreviations_of_months[month - 1]
    year = date.strftime("%Y")
    date_string = f"{monthAbbreviation} {year}"

    return date_string


def read_input_file(file_path: str) -> dm.RenderCVDataModel:
    """Read the input file and return an instance of RenderCVDataModel.

    Args:
        file_path (str): The path to the input file.

    Returns:
        str: The input file as a string.
    """
    start_time = time.time()
    information(f"Reading and validating the input file {file_path} has started.")

    # check if the file exists:
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"The input file {file_path} doesn't exist.")

    # check the file extension:
    accepted_extensions = [".yaml", ".yml", ".json", ".json5"]
    if not any(file_path.endswith(extension) for extension in accepted_extensions):
        raise ValueError(
            f"The file {file_path} doesn't have an accepted extension!"
            f" Accepted extensions are: {accepted_extensions}"
        )

    with open(file_path) as file:
        yaml = YAML()
        raw_json = yaml.load(file)

    data = RenderCVDataModel(**raw_json)

    end_time = time.time()
    time_taken = end_time - start_time
    information(
        f"Reading and validating the input file {file_path} has finished in"
        f" {time_taken:.2f} s."
    )
    return data
