"""
The `rendercv.models.data.entry_types` module contains the data models of all the available
entry types in RenderCV.
"""

import functools
import re
from datetime import date as Date
from typing import Annotated, Literal, Optional

import pydantic

from . import computers
from .base import RenderCVBaseModelWithExtraKeys

# ======================================================================================
# Create validator functions: ==========================================================
# ======================================================================================


def validate_date_field(date: Optional[int | str]) -> Optional[int | str]:
    """Check if the `date` field is provided correctly.

    Args:
        date: The date to validate.

    Returns:
        The validated date.
    """
    date_is_provided = date is not None

    if date_is_provided:
        if isinstance(date, str):
            if re.fullmatch(r"\d{4}-\d{2}(-\d{2})?", date):
                # Then it is in YYYY-MM-DD or YYYY-MMY format
                # Check if it is a valid date:
                computers.get_date_object(date)
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
        date: The date to validate.

    Returns:
        The validated date.
    """
    date_is_provided = date is not None

    if date_is_provided:
        if isinstance(date, Date):
            # Pydantic parses YYYY-MM-DD dates as datetime.date objects. We need to
            # convert them to strings because that is how RenderCV uses them.
            date = date.isoformat()

        elif date != "present":
            # Validate the date:
            computers.get_date_object(date)

    return date


# See https://peps.python.org/pep-0484/#forward-references for more information about
# the quotes around the type hints.
def validate_and_adjust_dates_for_an_entry(
    start_date: "StartDate",
    end_date: "EndDate",
    date: "ArbitraryDate",
) -> tuple["StartDate", "EndDate", "ArbitraryDate"]:
    """Check if the dates are provided correctly and make the necessary adjustments.

    Args:
        start_date: The start date of the event.
        end_date: The end date of the event.
        date: The date of the event.

    Returns:
        The validated and adjusted `start_date`, `end_date`, and `date`.
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
        start_date_object = computers.get_date_object(start_date)
        if not end_date_is_provided:
            # If only start_date is provided, assume it is an ongoing event, i.e.,
            # the end_date is present:
            end_date = "present"

        if end_date != "present":
            end_date_object = computers.get_date_object(end_date)

            if start_date_object > end_date_object:
                raise ValueError(
                    '"start_date" can not be after "end_date"!',
                    "start_date",  # This is the location of the error
                    str(start_date),  # This is value of the error
                )

    return start_date, end_date, date


# ======================================================================================
# Create custom types: =================================================================
# ======================================================================================


# See https://docs.pydantic.dev/2.7/concepts/types/#custom-types and
# https://docs.pydantic.dev/2.7/concepts/validators/#annotated-validators
# for more information about custom types.

# ExactDate that accepts only strings in YYYY-MM-DD or YYYY-MM format:
ExactDate = Annotated[
    str,
    pydantic.Field(
        pattern=r"\d{4}-\d{2}(-\d{2})?",
    ),
]

# ArbitraryDate that accepts either an integer or a string, but it is validated with
# `validate_date_field` function:
ArbitraryDate = Annotated[
    Optional[int | str],
    pydantic.BeforeValidator(validate_date_field),
]

# StartDate that accepts either an integer or an ExactDate, but it is validated with
# `validate_start_and_end_date_fields` function:
StartDate = Annotated[
    Optional[int | ExactDate],
    pydantic.BeforeValidator(validate_start_and_end_date_fields),
]

# EndDate that accepts either an integer, the string "present", or an ExactDate, but it
# is validated with `validate_start_and_end_date_fields` function:
EndDate = Annotated[
    Optional[Literal["present"] | int | ExactDate],
    pydantic.BeforeValidator(validate_start_and_end_date_fields),
]

# ======================================================================================
# Create the entry models: =============================================================
# ======================================================================================


class OneLineEntry(RenderCVBaseModelWithExtraKeys):
    """This class is the data model of `OneLineEntry`."""

    label: str = pydantic.Field(
        title="Name",
        description="The label of the OneLineEntry.",
    )
    details: str = pydantic.Field(
        title="Details",
        description="The details of the OneLineEntry.",
    )


class BulletEntry(RenderCVBaseModelWithExtraKeys):
    """This class is the data model of `BulletEntry`."""

    bullet: str = pydantic.Field(
        title="Bullet",
        description="The bullet of the BulletEntry.",
    )


class EntryWithDate(RenderCVBaseModelWithExtraKeys):
    """This class is the parent class of some of the entry types that have date
    fields.
    """

    date: ArbitraryDate = pydantic.Field(
        default=None,
        title="Date",
        description=(
            "The date field can be filled in YYYY-MM-DD, YYYY-MM, or YYYY formats or as"
            ' an arbitrary string like "Fall 2023".'
        ),
        examples=["2020-09-24", "Fall 2023"],
    )

    @functools.cached_property
    def date_string(self) -> str:
        """Return a date string based on the `date` field and cache `date_string` as
        an attribute of the instance.
        """
        return computers.compute_date_string(
            start_date=None, end_date=None, date=self.date
        )


class PublicationEntryBase(RenderCVBaseModelWithExtraKeys):
    """This class is the parent class of the `PublicationEntry` class."""

    title: str = pydantic.Field(
        title="Publication Title",
        description="The title of the publication.",
    )
    authors: list[str] = pydantic.Field(
        title="Authors",
        description="The authors of the publication in order as a list of strings.",
    )
    doi: Optional[Annotated[str, pydantic.Field(pattern=r"\b10\..*")]] = pydantic.Field(
        default=None,
        title="DOI",
        description="The DOI of the publication.",
        examples=["10.48550/arXiv.2310.03138"],
    )
    url: Optional[pydantic.HttpUrl] = pydantic.Field(
        default=None,
        title="URL",
        description=(
            "The URL of the publication. If DOI is provided, it will be ignored."
        ),
    )
    journal: Optional[str] = pydantic.Field(
        default=None,
        title="Journal",
        description="The journal or conference name.",
    )

    @pydantic.model_validator(mode="after")  # type: ignore
    def ignore_url_if_doi_is_given(self) -> "PublicationEntryBase":
        """Check if DOI is provided and ignore the URL if it is provided."""
        doi_is_provided = self.doi is not None

        if doi_is_provided:
            self.url = None

        return self

    @functools.cached_property
    def doi_url(self) -> str:
        """Return the URL of the DOI and cache `doi_url` as an attribute of the
        instance.
        """
        doi_is_provided = self.doi is not None

        if doi_is_provided:
            return f"https://doi.org/{self.doi}"
        else:
            return ""

    @functools.cached_property
    def clean_url(self) -> str:
        """Return the clean URL of the publication and cache `clean_url` as an attribute
        of the instance.
        """
        url_is_provided = self.url is not None

        if url_is_provided:
            return computers.make_a_url_clean(str(self.url))  # type: ignore
        else:
            return ""


# The following class is to ensure PublicationEntryBase keys come first,
# then the keys of the EntryWithDate class. The only way to achieve this in Pydantic is
# to do this. The same thing is done for the other classes as well.
class PublicationEntry(EntryWithDate, PublicationEntryBase):
    """This class is the data model of `PublicationEntry`. `PublicationEntry` class is
    created by combining the `EntryWithDate` and `PublicationEntryBase` classes to have
    the fields in the correct order.
    """

    pass


class EntryBase(EntryWithDate):
    """This class is the parent class of some of the entry types. It is being used
    because some of the entry types have common fields like dates, highlights, location,
    etc.
    """

    location: Optional[str] = pydantic.Field(
        default=None,
        title="Location",
        description="The location of the event.",
        examples=["Istanbul, Türkiye"],
    )
    start_date: StartDate = pydantic.Field(
        default=None,
        title="Start Date",
        description=(
            "The start date of the event in YYYY-MM-DD, YYYY-MM, or YYYY format."
        ),
        examples=["2020-09-24"],
    )
    end_date: EndDate = pydantic.Field(
        default=None,
        title="End Date",
        description=(
            "The end date of the event in YYYY-MM-DD, YYYY-MM, or YYYY format. If the"
            ' event is still ongoing, then type "present" or provide only the'
            " start_date."
        ),
        examples=["2020-09-24", "present"],
    )
    highlights: Optional[list[str]] = pydantic.Field(
        default=None,
        title="Highlights",
        description="The highlights of the event as a list of strings.",
        examples=["Did this.", "Did that."],
    )

    @pydantic.model_validator(mode="after")  # type: ignore
    def check_and_adjust_dates(self) -> "EntryBase":
        """Call the `validate_adjust_dates_of_an_entry` function to validate the
        dates.
        """
        self.start_date, self.end_date, self.date = (
            validate_and_adjust_dates_for_an_entry(
                start_date=self.start_date, end_date=self.end_date, date=self.date
            )
        )
        return self

    @functools.cached_property
    def date_string(self) -> str:
        """Return a date string based on the `date`, `start_date`, and `end_date` fields
        and cache `date_string` as an attribute of the instance.

        Example:
            ```python
            entry = dm.EntryBase(start_date="2020-10-11", end_date="2021-04-04").date_string
            ```
            returns
            `"Nov 2020 to Apr 2021"`
        """
        return computers.compute_date_string(
            start_date=self.start_date, end_date=self.end_date, date=self.date
        )

    @functools.cached_property
    def date_string_only_years(self) -> str:
        """Return a date string that only contains years based on the `date`,
        `start_date`, and `end_date` fields and cache `date_string_only_years` as an
        attribute of the instance.

        Example:
            ```python
            entry = dm.EntryBase(start_date="2020-10-11", end_date="2021-04-04").date_string_only_years
            ```
            returns
            `"2020 to 2021"`
        """
        return computers.compute_date_string(
            start_date=self.start_date,
            end_date=self.end_date,
            date=self.date,
            show_only_years=True,
        )

    @functools.cached_property
    def time_span_string(self) -> str:
        """Return a time span string based on the `date`, `start_date`, and `end_date`
        fields and cache `time_span_string` as an attribute of the instance.
        """
        return computers.compute_time_span_string(
            start_date=self.start_date, end_date=self.end_date, date=self.date
        )


class NormalEntryBase(RenderCVBaseModelWithExtraKeys):
    """This class is the parent class of the `NormalEntry` class."""

    name: str = pydantic.Field(
        title="Name",
        description="The name of the NormalEntry.",
    )


class NormalEntry(EntryBase, NormalEntryBase):
    """This class is the data model of `NormalEntry`. `NormalEntry` class is created by
    combining the `EntryBase` and `NormalEntryBase` classes to have the fields in the
    correct order.
    """

    pass


class ExperienceEntryBase(RenderCVBaseModelWithExtraKeys):
    """This class is the parent class of the `ExperienceEntry` class."""

    company: str = pydantic.Field(
        title="Company",
        description="The company name.",
    )
    position: str = pydantic.Field(
        title="Position",
        description="The position.",
    )


class ExperienceEntry(EntryBase, ExperienceEntryBase):
    """This class is the data model of `ExperienceEntry`. `ExperienceEntry` class is
    created by combining the `EntryBase` and `ExperienceEntryBase` classes to have the
    fields in the correct order.
    """

    pass


class EducationEntryBase(RenderCVBaseModelWithExtraKeys):
    """This class is the parent class of the `EducationEntry` class."""

    institution: str = pydantic.Field(
        title="Institution",
        description="The institution name.",
    )
    area: str = pydantic.Field(
        title="Area",
        description="The area of study.",
    )
    degree: Optional[str] = pydantic.Field(
        default=None,
        title="Degree",
        description="The type of the degree.",
        examples=["BS", "BA", "PhD", "MS"],
    )


class EducationEntry(EntryBase, EducationEntryBase):
    """This class is the data model of `EducationEntry`. `EducationEntry` class is
    created by combining the `EntryBase` and `EducationEntryBase` classes to have the
    fields in the correct order.
    """

    pass


# ======================================================================================
# Create custom types based on the entry models: =======================================
# ======================================================================================
# Create a custom type named Entry:
Entry = (
    OneLineEntry
    | NormalEntry
    | ExperienceEntry
    | EducationEntry
    | PublicationEntry
    | BulletEntry
    | str
)

# Create a custom type named ListOfEntries:
ListOfEntries = (
    list[OneLineEntry]
    | list[NormalEntry]
    | list[ExperienceEntry]
    | list[EducationEntry]
    | list[PublicationEntry]
    | list[BulletEntry]
    | list[str]
)

# ======================================================================================
# Store the available entry types: =====================================================
# ======================================================================================
# Entry.__args__[:-1] is a tuple of all the entry types except `str``:
# `str` (TextEntry) is not included because it's validation handled differently. It is
# not a Pydantic model, but a string.
available_entry_models = list(Entry.__args__[:-1])

available_entry_type_names = [
    entry_type.__name__ for entry_type in available_entry_models
] + ["TextEntry"]
