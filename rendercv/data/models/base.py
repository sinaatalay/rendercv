"""
The `rendercv.data.models.base` module contains the parent classes of all the data
models in RenderCV.
"""

from pathlib import Path
from typing import Optional

import pydantic


class RenderCVBaseModelWithoutExtraKeys(pydantic.BaseModel):
    """This class is the parent class of the data models that do not allow extra keys.
    It has only one difference from the default `pydantic.BaseModel`: It raises an error
    if an unknown key is provided in the input file.
    """

    model_config = pydantic.ConfigDict(extra="forbid", validate_default=True)


class RenderCVBaseModelWithExtraKeys(pydantic.BaseModel):
    """This class is the parent class of the data models that allow extra keys. It has
    only one difference from the default `pydantic.BaseModel`: It allows extra keys in
    the input file.
    """

    model_config = pydantic.ConfigDict(extra="allow", validate_default=True)


class RenderCVContextModel(pydantic.BaseModel):
    """This class describe the context data structure that will be passed during model validation."""

    input_file_path: Optional[Path]
