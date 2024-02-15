from typing import Literal, Annotated

import pydantic


LaTeXDimension = Annotated[
    str,
    pydantic.Field(
        pattern=r"\d+\.?\d* *(cm|in|pt|mm|ex|em)",
    ),
]


class Sb2novThemeOptions(pydantic.BaseModel):
    """ """

    model_config = pydantic.ConfigDict(extra="forbid")

    theme: Literal["sb2nov"]
    font_size: Literal["10pt", "11pt", "12pt"] = pydantic.Field(
        default="10pt",
        title="Font Size",
        description='The font size of the CV. The default value is "10pt".',
        examples=["10pt", "11pt", "12pt"],
    )
    page_size: Literal["a4paper", "letterpaper"] = pydantic.Field(
        default="a4paper",
        title="Page Size",
        description='The page size of the CV. The default value is "a4paper".',
        examples=["a4paper", "letterpaper"],
    )
    color: (
        Literal["blue"]
        | Literal["black"]
        | Literal["burgundy"]
        | Literal["green"]
        | Literal["grey"]
        | Literal["orange"]
        | Literal["purple"]
        | Literal["red"]
    ) = pydantic.Field(
        default="blue",
        validate_default=True,
        title="Primary Color",
        description='The primary color of the CV. The default value is "blue".',
        examples=[
            "blue",
            "black",
            "burgundy",
            "green",
            "grey",
            "orange",
            "purple",
            "red",
        ],
    )
    date_width: LaTeXDimension = pydantic.Field(
        default="3.8 cm",
        validate_default=True,
        title="Date and Location Column Width",
        description='The width of the date column. The default value is "3.8 cm".',
    )
    content_scale: float = pydantic.Field(
        default=0.75,
        title="Content Scale",
        description=(
            "The scale of the content with respect to the page size. The default value"
            ' is "0.75".'
        ),
    )
    show_only_years: bool = pydantic.Field(
        default=False,
        title="Show Only Years",
        description=(
            'If "True", only the years will be shown in the date column. The default'
            ' value is "False".'
        ),
    )
    disable_page_numbers: bool = pydantic.Field(
        default=False,
        title="Disable Page Numbers",
        description=(
            'If "True", the page numbers will be disabled. The default value is'
            ' "False".'
        ),
    )
