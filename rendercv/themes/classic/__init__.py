from typing import Literal

import pydantic


class ClassicThemeOptions(pydantic.BaseModel):
    theme: Literal["classic"]
