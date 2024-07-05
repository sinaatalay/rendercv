"""
The `rendercv.data.models.base` module contains the `RenderCVBaseModel` class, which is
the parent class of all the data models in RenderCV.
"""

import pydantic


class RenderCVBaseModel(pydantic.BaseModel):
    """This class is the parent class of all the data models in RenderCV. It has only
    one difference from the default `pydantic.BaseModel`: It raises an error if an
    unknown key is provided in the input file.
    """

    model_config = pydantic.ConfigDict(extra="forbid")
