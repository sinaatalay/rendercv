"""
The `rendercv.data_models.types` module contains all the custom types created for
RenderCV, and it contains important information about the package, such as
`available_themes`, `available_social_networks`, etc.
"""

from typing import Annotated, Any, Literal, Optional, get_args

import pydantic

from ..themes.classic import ClassicThemeOptions
from ..themes.engineeringresumes import EngineeringresumesThemeOptions
from ..themes.moderncv import ModerncvThemeOptions
from ..themes.sb2nov import Sb2novThemeOptions
from . import models
from . import validators as val

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
    pydantic.BeforeValidator(val.validate_date_field),
]

# StartDate that accepts either an integer or an ExactDate, but it is validated with
# `validate_start_and_end_date_fields` function:
StartDate = Annotated[
    Optional[int | ExactDate],
    pydantic.BeforeValidator(val.validate_start_and_end_date_fields),
]

# EndDate that accepts either an integer, the string "present", or an ExactDate, but it
# is validated with `validate_start_and_end_date_fields` function:
EndDate = Annotated[
    Optional[Literal["present"] | int | ExactDate],
    pydantic.BeforeValidator(val.validate_start_and_end_date_fields),
]

# Create a custom type named RenderCVBuiltinDesign:
# It is a union of all the design options and the correct design option is determined by
# the theme field, thanks to Pydantic's discriminator feature.
# See https://docs.pydantic.dev/2.7/concepts/fields/#discriminator for more information
RenderCVBuiltinDesign = Annotated[
    ClassicThemeOptions
    | ModerncvThemeOptions
    | Sb2novThemeOptions
    | EngineeringresumesThemeOptions,
    pydantic.Field(discriminator="theme"),
]

# Create a custom type named RenderCVDesign:
# RenderCV supports custom themes as well. Therefore, `Any` type is used to allow custom
# themes. However, the JSON Schema generation is skipped, otherwise, the JSON Schema
# would accept any `design` field in the YAML input file.
RenderCVDesign = Annotated[
    pydantic.json_schema.SkipJsonSchema[Any] | RenderCVBuiltinDesign,
    pydantic.BeforeValidator(val.validate_a_custom_theme),
]

# Create a custom type named Entry:
Entry = (
    models.OneLineEntry
    | models.NormalEntry
    | models.ExperienceEntry
    | models.EducationEntry
    | models.PublicationEntry
    | models.BulletEntry
    | str
)

# Create a custom type named ListOfEntries:
ListOfEntries = list[Entry]

# Create a custom type named SectionInput so that it can be validated with
# `validate_section_input` function.
SectionInput = Annotated[
    ListOfEntries,
    pydantic.BeforeValidator(val.validate_a_section),
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

# Entry.__args__[:-1] is a tuple of all the entry types except str:
available_entry_types = Entry.__args__[:-1]

available_entry_type_names = [
    entry_type.__name__ for entry_type in available_entry_types
] + ["TextEntry"]

available_theme_options = get_args(RenderCVBuiltinDesign)[0]

available_themes = ["classic", "moderncv", "sb2nov", "engineeringresumes"]
