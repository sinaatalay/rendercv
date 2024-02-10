from typing import Literal, Annotated

import pydantic

LaTeXDimension = Annotated[
    str,
    pydantic.Field(
        pattern=r"\d+\.?\d* *(cm|in|pt|mm|ex|em)",
    ),
]


class McdowellThemeOptions(pydantic.BaseModel):
    """ """

    theme: Literal["mcdowell"]
