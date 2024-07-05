"""
The `rendercv.models.locale_catalog` module contains the data model of the
`locale_catalog` field of the input file.
"""

from typing import Annotated, Optional

import annotated_types as at
import pydantic

from .base import RenderCVBaseModel


class LocaleCatalog(RenderCVBaseModel):
    """This class is the data model of the locale catalog. The values of each field
    updates the `locale_catalog` dictionary.
    """

    month: Optional[str] = pydantic.Field(
        default="month",
        title='Translation of "Month"',
        description='Translation of the word "month" in the locale.',
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    months: Optional[str] = pydantic.Field(
        default="months",
        title='Translation of "Months"',
        description='Translation of the word "months" in the locale.',
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    year: Optional[str] = pydantic.Field(
        default="year",
        title='Translation of "Year"',
        description='Translation of the word "year" in the locale.',
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    years: Optional[str] = pydantic.Field(
        default="years",
        title='Translation of "Years"',
        description='Translation of the word "years" in the locale.',
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    present: Optional[str] = pydantic.Field(
        default="present",
        title='Translation of "Present"',
        description='Translation of the word "present" in the locale.',
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    to: Optional[str] = pydantic.Field(
        default="–",  # en dash
        title='Translation of "To"',
        description=(
            "The word or character used to indicate a range in the locale (e.g.,"
            ' "2020 - 2021").'
        ),
        validate_default=True,  # To initialize the locale catalog with the default values
    )
    abbreviations_for_months: Optional[
        Annotated[list[str], at.Len(min_length=12, max_length=12)]
    ] = pydantic.Field(
        # Month abbreviations are taken from
        # https://web.library.yale.edu/cataloging/months:
        default=[
            "Jan",
            "Feb",
            "Mar",
            "Apr",
            "May",
            "June",
            "July",
            "Aug",
            "Sept",
            "Oct",
            "Nov",
            "Dec",
        ],
        title="Abbreviations of Months",
        description="Abbreviations of the months in the locale.",
        validate_default=True,  # to initialize the locale catalog with the default values
    )
    full_names_of_months: Optional[
        Annotated[list[str], at.Len(min_length=12, max_length=12)]
    ] = pydantic.Field(
        default=[
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December",
        ],
        title="Full Names of Months",
        description="Full names of the months in the locale.",
        validate_default=True,  # to initialize the locale catalog with the default values
    )

    @pydantic.field_validator(
        "month",
        "months",
        "year",
        "years",
        "present",
        "abbreviations_for_months",
        "to",
        "full_names_of_months",
    )
    @classmethod
    def update_translations(cls, value: str, info: pydantic.ValidationInfo) -> str:
        """Update the `locale_catalog` dictionary with the provided translations."""
        if value:
            locale_catalog[info.field_name] = value  # type: ignore

        return value


# The dictionary below will be overwritten by LocaleCatalog class, which will contain
# month names, month abbreviations, and other locale-specific strings.
locale_catalog: dict[str, str | list[str]] = {}
LocaleCatalog()  # Initialize the locale catalog with the default values
