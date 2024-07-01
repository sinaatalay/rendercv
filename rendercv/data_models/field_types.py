"""
The `rendercv.data_models.types` module contains all the custom types created for
RenderCV, and it contains important information about the package, such as
`available_themes`, `available_social_networks`, etc.
"""

from typing import Annotated, Literal, Optional, get_args

import pydantic

from . import field_validators as field_val

# See https://docs.pydantic.dev/2.7/concepts/types/#custom-types and
# https://docs.pydantic.dev/2.7/concepts/validators/#annotated-validators
# for more information about custom types.

# Create custom types for dates:
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
    pydantic.BeforeValidator(field_val.validate_date_field),
]

# StartDate that accepts either an integer or an ExactDate, but it is validated with
# `validate_start_and_end_date_fields` function:
StartDate = Annotated[
    Optional[int | ExactDate],
    pydantic.BeforeValidator(field_val.validate_start_and_end_date_fields),
]

# EndDate that accepts either an integer, the string "present", or an ExactDate, but it
# is validated with `validate_start_and_end_date_fields` function:
EndDate = Annotated[
    Optional[Literal["present"] | int | ExactDate],
    pydantic.BeforeValidator(field_val.validate_start_and_end_date_fields),
]

# Create a custom type named SocialNetworkName:
SocialNetworkName = Literal[
    "LinkedIn",
    "GitHub",
    "GitLab",
    "Instagram",
    "ORCID",
    "Mastodon",
    "StackOverflow",
    "ResearchGate",
    "YouTube",
    "Google Scholar",
]

# ======================================================================================
# Create variables that show the available stuff: ======================================
# ======================================================================================
available_social_networks = get_args(SocialNetworkName)
