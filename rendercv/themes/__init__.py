from typing import Annotated

import pydantic

LaTeXDimension = Annotated[
    str,
    pydantic.Field(
        pattern=r"\d+\.?\d* *(cm|in|pt|mm|ex|em)",
    ),
]


class PageMargins(pydantic.BaseModel):
    top: LaTeXDimension = pydantic.Field(
        default="2 cm",
        title="Top Margin",
        description="The top margin of the page with units.",
    )
    bottom: LaTeXDimension = pydantic.Field(
        default="2 cm",
        title="Bottom Margin",
        description="The bottom margin of the page with units.",
    )
    left: LaTeXDimension = pydantic.Field(
        default="1.24 cm",
        title="Left Margin",
        description="The left margin of the page with units.",
    )
    right: LaTeXDimension = pydantic.Field(
        default="1.24 cm",
        title="Right Margin",
        description="The right margin of the page with units.",
    )
