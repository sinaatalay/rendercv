"""
The `rendercv.models.rendercv_settings` module contains the data model of the
`rendercv_settings` field of the input file.
"""

import pathlib
from typing import Optional

import pydantic

from .base import RenderCVBaseModelWithoutExtraKeys
from .computers import convert_string_to_path, replace_placeholders

file_path_placeholder_description = (
    "The following placeholders can be used:\n- FULL_MONTH_NAME: Full name of the"
    " month\n- MONTH_ABBREVIATION: Abbreviation of the month\n- MONTH: Month as a"
    " number\n- MONTH_IN_TWO_DIGITS: Month as a number in two digits\n- YEAR: Year as a"
    " number\n- YEAR_IN_TWO_DIGITS: Year as a number in two digits\n- NAME: The name of"
    " the CV owner\n- NAME_IN_SNAKE_CASE: The name of the CV owner in snake case\n-"
    " NAME_IN_LOWER_SNAKE_CASE: The name of the CV owner in lower snake case\n-"
    " NAME_IN_UPPER_SNAKE_CASE: The name of the CV owner in upper snake case\n-"
    " NAME_IN_KEBAB_CASE: The name of the CV owner in kebab case\n-"
    " NAME_IN_LOWER_KEBAB_CASE: The name of the CV owner in lower kebab case\n-"
    " NAME_IN_UPPER_KEBAB_CASE: The name of the CV owner in upper kebab case\nThe"
    " default value is an empty string.\n- FULL_MONTH_NAME: Full name of the month\n-"
    " MONTH_ABBREVIATION: Abbreviation of the month\n- MONTH: Month as a number\n-"
    " MONTH_IN_TWO_DIGITS: Month as a number in two digits\n- YEAR: Year as a number\n-"
    " YEAR_IN_TWO_DIGITS: Year as a number in two digits\nThe default value is"
    ' "MONTH_ABBREVIATION YEAR".\nThe default value is null.'
)

file_path_placeholder_description_without_default = (
    file_path_placeholder_description.replace("\nThe default value is null.", "")
)


class RenderCommandSettings(RenderCVBaseModelWithoutExtraKeys):
    """This class is the data model of the `render` command's settings."""

    output_folder_name: str = pydantic.Field(
        default="rendercv_output",
        title="Output Folder Name",
        description=(
            "The name of the folder where the output files will be saved."
            f" {file_path_placeholder_description_without_default}\nThe default value"
            ' is "rendercv_output".'
        ),
    )

    use_local_latex_command: Optional[str] = pydantic.Field(
        default=None,
        title="Local LaTeX Command",
        description=(
            "The command to compile the LaTeX file to a PDF file. The default value is"
            ' "pdflatex".'
        ),
    )

    pdf_path: Optional[pathlib.Path] = pydantic.Field(
        default=None,
        title="PDF Path",
        description=(
            "The path of the PDF file. If it is not provided, the PDF file will not be"
            f" generated. {file_path_placeholder_description}"
        ),
    )

    latex_path: Optional[pathlib.Path] = pydantic.Field(
        default=None,
        title="LaTeX Path",
        description=(
            "The path of the LaTeX file. If it is not provided, the LaTeX file will not"
            f" be generated. {file_path_placeholder_description}"
        ),
    )

    html_path: Optional[pathlib.Path] = pydantic.Field(
        default=None,
        title="HTML Path",
        description=(
            "The path of the HTML file. If it is not provided, the HTML file will not"
            f" be generated. {file_path_placeholder_description}"
        ),
    )

    png_path: Optional[pathlib.Path] = pydantic.Field(
        default=None,
        title="PNG Path",
        description=(
            "The path of the PNG file. If it is not provided, the PNG file will not be"
            f" generated. {file_path_placeholder_description}"
        ),
    )

    markdown_path: Optional[pathlib.Path] = pydantic.Field(
        default=None,
        title="Markdown Path",
        description=(
            "The path of the Markdown file. If it is not provided, the Markdown file"
            f" will not be generated. {file_path_placeholder_description}"
        ),
    )

    dont_generate_html: bool = pydantic.Field(
        default=False,
        title="Generate HTML Flag",
        description=(
            "A boolean value to determine whether the HTML file will be generated. The"
            " default value is False."
        ),
    )

    dont_generate_markdown: bool = pydantic.Field(
        default=False,
        title="Generate Markdown Flag",
        description=(
            "A boolean value to determine whether the Markdown file will be generated."
            " The default value is False."
        ),
    )

    dont_generate_png: bool = pydantic.Field(
        default=False,
        title="Generate PNG Flag",
        description=(
            "A boolean value to determine whether the PNG file will be generated. The"
            " default value is False."
        ),
    )

    @pydantic.field_validator(
        "output_folder_name",
        mode="before",
    )
    @classmethod
    def replace_placeholders(cls, value: str) -> str:
        """Replaces the placeholders in a string with the corresponding values."""
        return replace_placeholders(value)

    @pydantic.field_validator(
        "pdf_path",
        "latex_path",
        "html_path",
        "png_path",
        "markdown_path",
        mode="before",
    )
    @classmethod
    def convert_string_to_path(cls, value: Optional[str]) -> Optional[pathlib.Path]:
        """Converts a string to a `pathlib.Path` object by replacing the placeholders
        with the corresponding values. If the path is not an absolute path, it is
        converted to an absolute path by prepending the current working directory.
        """
        if value is None:
            return None

        return convert_string_to_path(value)


class RenderCVSettings(RenderCVBaseModelWithoutExtraKeys):
    """This class is the data model of the RenderCV settings."""

    render_command: Optional[RenderCommandSettings] = pydantic.Field(
        default=None,
        title="Render Command Settings",
        description=(
            "RenderCV's `render` command settings. They are the same as the command"
            " line arguments. CLI arguments have higher priority than the settings in"
            " the input file."
        ),
    )
