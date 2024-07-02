"""
The `rendercv.data_models` package contains the necessary classes and functions for

-   Parsing and validating a YAML input file
-   Computing some properties based on a YAML input file (like converting ISO dates to
    plain English, URLs of social networks, etc.)
-   Generating a JSON Schema for RenderCV's data format
-   Generating a sample YAML input file

The validators and data format of RenderCV are written using
[Pydantic](https://github.com/pydantic/pydantic).
"""

from .models import (
    CurriculumVitae,
    SocialNetwork,
    available_theme_options,
    BulletEntry,
    EducationEntry,
    ExperienceEntry,
    NormalEntry,
    OneLineEntry,
    PublicationEntry,
    LocaleCatalog,
    RenderCVDataModel,
    format_date,
)

from .reader import (
    create_a_sample_data_model,
    create_a_sample_yaml_input_file,
    generate_json_schema_file,
    generate_json_schema,
    set_or_update_a_value,
    read_input_file,
)


__all__ = [
    "OneLineEntry",
    "BulletEntry",
    "EducationEntry",
    "ExperienceEntry",
    "PublicationEntry",
    "NormalEntry",
    "SocialNetwork",
    "CurriculumVitae",
    "LocaleCatalog",
    "RenderCVDataModel",
    "available_theme_options",
    "available_themes",
    "create_a_sample_data_model",
    "create_a_sample_yaml_input_file",
    "generate_json_schema_file",
    "generate_json_schema",
    "set_or_update_a_value",
    "read_input_file",
    "format_date",
]
