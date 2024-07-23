from typing import Literal

import pydantic


class DummythemeThemeOptions(pydantic.BaseModel):
    theme: Literal["dummytheme"]
