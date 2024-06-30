"""
The `rendercv.data_models.computed_fields` module contains functions that compute
some properties based on the input data. For example, it includes functions that
calculate the time span between two dates, the date string, the URL of a social network,
etc.
"""

from typing import Optional

from . import models
from . import utilities as util
from . import validators as val


def compute_time_span_string(
    start_date: Optional[str],
    end_date: Optional[str],
    date: Optional[str],
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
        start_year = util.get_date_object(start_date).year  # type: ignore
        end_year = util.get_date_object(end_date).year  # type: ignore

        time_span_in_years = end_year - start_year

        if time_span_in_years < 2:
            time_span_string = "1 year"
        else:
            time_span_string = f"{time_span_in_years} years"

        return time_span_string

    else:
        # Then it means both start_date and end_date are in YYYY-MM-DD or YYYY-MM
        # format.
        end_date = util.get_date_object(end_date)  # type: ignore
        start_date = util.get_date_object(start_date)  # type: ignore

        # Calculate the number of days between start_date and end_date:
        timespan_in_days = (end_date - start_date).days  # type: ignore

        # Calculate the number of years between start_date and end_date:
        how_many_years = timespan_in_days // 365
        if how_many_years == 0:
            how_many_years_string = None
        elif how_many_years == 1:
            how_many_years_string = f"1 {models.locale_catalog['year']}"
        else:
            how_many_years_string = f"{how_many_years} {models.locale_catalog['years']}"

        # Calculate the number of months between start_date and end_date:
        how_many_months = round((timespan_in_days % 365) / 30)
        if how_many_months <= 1:
            how_many_months_string = f"1 {models.locale_catalog['month']}"
        else:
            how_many_months_string = (
                f"{how_many_months} {models.locale_catalog['months']}"
            )

        # Combine howManyYearsString and howManyMonthsString:
        if how_many_years_string is None:
            time_span_string = how_many_months_string
        else:
            time_span_string = f"{how_many_years_string} {how_many_months_string}"

        return time_span_string


def compute_date_string(
    start_date: Optional[str],
    end_date: Optional[str],
    date: Optional[str],
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
                date_object = util.get_date_object(date)
                if show_only_years:
                    date_string = str(date_object.year)
                else:
                    date_string = util.format_date(date_object)
            except ValueError:
                # Then it is a custom date string (e.g., "My Custom Date")
                date_string = str(date)
    elif start_date_is_provided and end_date_is_provided:
        if isinstance(start_date, int):
            # Then it means only the year is provided
            start_date = str(start_date)
        else:
            # Then it means start_date is either in YYYY-MM-DD or YYYY-MM format
            date_object = util.get_date_object(start_date)
            if show_only_years:
                start_date = date_object.year
            else:
                start_date = util.format_date(date_object)

        if end_date == "present":
            end_date = models.locale_catalog["present"]
        elif isinstance(end_date, int):
            # Then it means only the year is provided
            end_date = str(end_date)
        else:
            # Then it means end_date is either in YYYY-MM-DD or YYYY-MM format
            date_object = util.get_date_object(end_date)
            if show_only_years:
                end_date = date_object.year
            else:
                end_date = util.format_date(date_object)

        date_string = f"{start_date} {models.locale_catalog['to']} {end_date}"

    else:
        # Neither date, start_date, nor end_date are provided, so return an empty
        # string:
        date_string = ""

    return date_string


def compute_social_network_url(network: str, username: str):
    """Return the URL of a social network based on the network name and the username.

    Args:
        network (str): The name of the social network.
        username (str): The username of the user in the social network.
    Returns:
        str: The URL of the social network.
    """
    if network == "Mastodon":
        # Split domain and username
        dummy, username, domain = username.split("@")
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
        }
        url = url_dictionary[network] + username

    return url


def compute_connections(cv: models.CurriculumVitae) -> list[dict[str, str]]:
    """Bring together all the connections in the CV, such as social networks, phone
    number, email, etc and return them as a list of dictionaries. Each dictionary
    contains the following keys: "latex_icon", "url", "clean_url", and "placeholder."

    The connections are used in the header of the CV.

    Args:
        cv (CurriculumVitae): The CV to compute the connections.

    Returns:
        list[dict[str, str]]: The computed connections.
    """
    connections: list[dict[str, str]] = []

    if cv.location is not None:
        connections.append(
            {
                "latex_icon": "\\faMapMarker*",
                "url": None,
                "clean_url": None,
                "placeholder": cv.location,
            }
        )

    if cv.email is not None:
        connections.append(
            {
                "latex_icon": "\\faEnvelope[regular]",
                "url": f"mailto:{cv.email}",
                "clean_url": cv.email,
                "placeholder": cv.email,
            }
        )

    if cv.phone is not None:
        phone_placeholder = cv.phone.replace("tel:", "").replace("-", " ")
        connections.append(
            {
                "latex_icon": "\\faPhone*",
                "url": f"{cv.phone}",
                "clean_url": phone_placeholder,
                "placeholder": phone_placeholder,
            }
        )

    if cv.website is not None:
        website_placeholder = util.make_a_url_clean(cv.website)
        connections.append(
            {
                "latex_icon": "\\faLink",
                "url": cv.website,
                "clean_url": website_placeholder,
                "placeholder": website_placeholder,
            }
        )

    if cv.social_networks is not None:
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
        }
        for social_network in cv.social_networks:
            clean_url = util.make_a_url_clean(social_network.url)
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

            connections.append(connection)

    return connections


def compute_sections(
    sections_input: Optional[dict[str, models.SectionInput]],
) -> list[models.SectionBase]:
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
    sections: list[models.SectionBase] = []

    if sections_input is not None:
        for title, section_or_entries in sections_input.items():
            title = util.dictionary_key_to_proper_section_title(title)

            entry_type_name = val.validate_an_entry_type_and_get_entry_type_name(
                section_or_entries[0]
            )

            section = models.SectionBase(
                title=title,
                entry_type=entry_type_name,
                entries=section_or_entries,
            )
            sections.append(section)

    return sections
