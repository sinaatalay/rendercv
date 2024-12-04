"""
The `rendercv.data.models` package contains all the Pydantic data models, validators,
and computed fields that are used in RenderCV. The package is divided into several
modules, each containing a different group of data models.

- `base.py`: Contains `RenderCVBaseModel`, which is the parent class of all the data
    models in RenderCV.
- `computers.py`: Contains all the functions that are used to compute some values of
    the fields in the data models. For example, converting ISO dates to human-readable
    dates.
- `entry_types.py`: Contains all the data models that are used to represent the entries
    in the CV.
- `curriculum_vitae.py`: Contains the `CurriculumVitae` data model, which is the main
    data model that contains all the content of the CV.
- `design.py`: Contains the data model that is used to represent the design options of
    the CV.
- `locale_catalog.py`: Contains the data model that is used to represent the locale
    catalog of the CV.
- `rendercv_settings.py`: Contains the data model that is used to represent the settings
    of the RenderCV.
- `rendercv_data_model.py`: Contains the `RenderCVDataModel` data model, which is the
    main data model that defines the whole input file structure.
"""

from .computers import format_date
from .curriculum_vitae import (
    CurriculumVitae,
    SectionContents,
    SocialNetwork,
    available_social_networks,
)
from .design import available_theme_options, available_themes
from .entry_types import (
    BulletEntry,
    EducationEntry,
    Entry,
    ExperienceEntry,
    ConsultingExperienceEntry,
    NormalEntry,
    OneLineEntry,
    PublicationEntry,
    available_entry_models,
    available_entry_type_names,
)
from .locale_catalog import LocaleCatalog
from .rendercv_data_model import RenderCVDataModel
from .rendercv_settings import RenderCommandSettings, RenderCVSettings

__all__ = [
    "OneLineEntry",
    "BulletEntry",
    "EducationEntry",
    "ConsultingExperienceEntry",
    "ExperienceEntry",
    "PublicationEntry",
    "NormalEntry",
    "SocialNetwork",
    "CurriculumVitae",
    "LocaleCatalog",
    "RenderCVDataModel",
    "available_theme_options",
    "format_date",
    "Entry",
    "available_social_networks",
    "SectionContents",
    "available_themes",
    "available_entry_type_names",
    "RenderCVSettings",
    "RenderCommandSettings",
    "available_entry_models",
]
