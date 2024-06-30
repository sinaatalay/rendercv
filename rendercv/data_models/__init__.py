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
    OneLineEntry,
    BulletEntry,
    EducationEntry,
    ExperienceEntry,
    PublicationEntry,
    NormalEntry,
    SocialNetwork,
    CurriculumVitae,
    LocaleCatalog,
    RenderCVDataModel,
    locale_catalog,
    read_input_file,
)

from .generators import (
    generate_json_schema_file,
    generate_json_schema,
    create_a_sample_yaml_input_file,
    get_a_sample_data_model,
)

from .types import (
    available_entry_type_names,
    available_themes,
    available_social_networks,
)

from .utilities import set_or_update_a_value, dictionary_to_yaml

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
    "locale_catalog",
    "generate_json_schema_file",
    "generate_json_schema",
    "create_a_sample_yaml_input_file",
    "get_a_sample_data_model",
    "available_entry_type_names",
    "available_themes",
    "available_social_networks",
    "read_input_file",
    "set_or_update_a_value",
    "dictionary_to_yaml",
]
