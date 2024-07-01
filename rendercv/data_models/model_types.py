from typing import Annotated, Any

import pydantic

from ..themes.classic import ClassicThemeOptions
from ..themes.engineeringresumes import EngineeringresumesThemeOptions
from ..themes.moderncv import ModerncvThemeOptions
from ..themes.sb2nov import Sb2novThemeOptions
from .models import (
    OneLineEntry,
    NormalEntry,
    ExperienceEntry,
    EducationEntry,
    PublicationEntry,
    BulletEntry,
)
from . import model_validators

# See https://docs.pydantic.dev/2.7/concepts/types/#custom-types and
# https://docs.pydantic.dev/2.7/concepts/validators/#annotated-validators
# for more information about custom types.


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

# Entry.__args__[:-1] is a tuple of all the entry types except str:
available_entry_types = Entry.__args__[:-1]

available_entry_type_names = [
    entry_type.__name__ for entry_type in available_entry_types
] + ["TextEntry"]

# Create a custom type named ListOfEntries:
ListOfEntries = list[Entry]


# Create a custom type named SectionInput so that it can be validated with
# `validate_a_section` function.
SectionInput = Annotated[
    ListOfEntries,
    pydantic.PlainValidator(
        lambda entries: model_validators.validate_a_section(
            entries, entry_types=available_entry_types
        )
    ),
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

available_theme_options = {
    "classic": ClassicThemeOptions,
    "moderncv": ModerncvThemeOptions,
    "sb2nov": Sb2novThemeOptions,
    "engineeringresumes": EngineeringresumesThemeOptions,
}

available_themes = list(available_theme_options.keys())


# Create a custom type named RenderCVDesign:
# RenderCV supports custom themes as well. Therefore, `Any` type is used to allow custom
# themes. However, the JSON Schema generation is skipped, otherwise, the JSON Schema
# would accept any `design` field in the YAML input file.
RenderCVDesign = Annotated[
    RenderCVBuiltinDesign | pydantic.json_schema.SkipJsonSchema[Any],
    pydantic.PlainValidator(
        lambda design: model_validators.validate_design_options(
            design,
            available_theme_options=available_theme_options,
            available_entry_type_names=available_entry_type_names,
        )
    ),
]
