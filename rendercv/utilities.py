import re
from datetime import date as Date


def escape_latex_characters(sentence: str) -> str:
    """Escape LaTeX characters in a sentence.

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

    return date


def compute_time_span_string(start_date: Date | int, end_date: Date | int) -> str:
    """Compute the time span between two dates and return a string that represents it.

    Example:
        ```python
        compute_time_span_string(Date(2022, 9, 24), Date(2025, 2, 12))
        ```

        will return:

        `#!python "2 years 5 months"`

    Args:
        start_date (Date | int): The start date.
        end_date (Date | int): The end date.

    Returns:
        str: The time span string.
    """
    # check if the types of start_date and end_date are correct:
    if not isinstance(start_date, (Date, int)):
        raise TypeError("start_date is not a Date object or an integer!")
    if not isinstance(end_date, (Date, int)):
        raise TypeError("end_date is not a Date object or an integer!")

    # calculate the number of days between start_date and end_date:
    if isinstance(start_date, Date) and isinstance(end_date, Date):
        timespan_in_days = (end_date - start_date).days  # type: ignore
    elif isinstance(start_date, Date) and isinstance(end_date, int):
        timespan_in_days = (Date(end_date, 1, 1) - start_date).days
    elif isinstance(start_date, int) and isinstance(end_date, Date):
        timespan_in_days = (end_date - Date(start_date, 1, 1)).days  # type: ignore
    elif isinstance(start_date, int) and isinstance(end_date, int):
        timespan_in_days = (end_date - start_date) * 365
    else:
        raise TypeError(
            f"start_date ({start_date}) and end_date ({end_date}) are not valid to"
            " compute the time span."
        )

    if timespan_in_days < 0:
        raise ValueError(
            '"start_date" can not be after "end_date". Please check the dates.'
        )

    # calculate the number of years between start_date and end_date:
    how_many_years = timespan_in_days // 365
    if how_many_years == 0:
        how_many_years_string = None
    elif how_many_years == 1:
        how_many_years_string = "1 year"
    else:
        how_many_years_string = f"{how_many_years} years"

    # calculate the number of months between start_date and end_date:
    how_many_months = round((timespan_in_days % 365) / 30)
    if how_many_months <= 1:
        how_many_months_string = "1 month"
    else:
        how_many_months_string = f"{how_many_months} months"

    # combine howManyYearsString and howManyMonthsString:
    if how_many_years_string is None:
        timespan_string = how_many_months_string
    else:
        timespan_string = f"{how_many_years_string} {how_many_months_string}"

    return timespan_string


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
