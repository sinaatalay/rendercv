"""
The `rendercv.data` package contains the necessary classes and functions for

-   Parsing and validating a YAML input file
-   Computing some properties based on a YAML input file (like converting ISO dates to
    plain English, URLs of social networks, etc.)
-   Generating a JSON Schema for RenderCV's data format
-   Generating a sample YAML input file

The validators and data format of RenderCV are written using
[Pydantic](https://github.com/pydantic/pydantic).
"""

from .generator import (
    create_a_sample_data_model,
    create_a_sample_yaml_input_file,
    generate_json_schema,
    generate_json_schema_file,
)
from .models import (
    BulletEntry,
    CurriculumVitae,
    DetailedPosition,
    EducationEntry,
    Entry,
    ExperienceEntry,
    LocaleCatalog,
    NormalEntry,
    OneLineEntry,
    PublicationEntry,
    RenderCommandSettings,
    RenderCVDataModel,
    RenderCVSettings,
    SectionContents,
    SocialNetwork,
    available_entry_models,
    available_entry_type_names,
    available_social_networks,
    available_theme_options,
    available_themes,
    format_date,
    rendercv_data_model_fields,
)
from .reader import (
    read_a_yaml_file,
    read_input_file,
    validate_input_dictionary_and_return_the_data_model,
)

__all__ = [
    "BulletEntry",
    "CurriculumVitae",
    "DetailedPosition",
    "EducationEntry",
    "Entry",
    "ExperienceEntry",
    "LocaleCatalog",
    "NormalEntry",
    "OneLineEntry",
    "PublicationEntry",
    "RenderCVDataModel",
    "RenderCVSettings",
    "RenderCommandSettings",
    "SectionContents",
    "SocialNetwork",
    "available_entry_models",
    "available_entry_type_names",
    "available_social_networks",
    "available_theme_options",
    "available_themes",
    "create_a_sample_data_model",
    "create_a_sample_yaml_input_file",
    "format_date",
    "generate_json_schema",
    "generate_json_schema_file",
    "read_a_yaml_file",
    "read_input_file",
    "rendercv_data_model_fields",
    "validate_input_dictionary_and_return_the_data_model",
]
