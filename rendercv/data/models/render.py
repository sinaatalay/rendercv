"""
The `rendercv.models.render` module contains the data model of the
`rendercv_settings.render` field of the input file.
"""

from typing import Optional

import pydantic

from .base import RenderCVBaseModelWithExtraKeys


class RenderOptions(RenderCVBaseModelWithExtraKeys):
    """This class is the data model of the render options. The values of each field
    updates the `rendercv_settings.render` dictionary.
    """

    output_folder_name: Optional[str] = pydantic.Field(
        default="rendercv_output",
        title="Output Folder Name",
        description=(
            "The name of the folder where the output files will be saved. The default"
            ' value is "rendercv_output".'
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

    pdf_path: Optional[str] = pydantic.Field(
        default=None,
        title="PDF Path",
        description=(
            "The path of the PDF file. If it is not provided, the PDF file will not be"
            " generated. The default value is an empty string."
        ),
    )

    latex_path: Optional[str] = pydantic.Field(
        default=None,
        title="LaTeX Path",
        description=(
            "The path of the LaTeX file. If it is not provided, the LaTeX file will not"
            " be generated. The default value is an empty string."
        ),
    )

    html_path: Optional[str] = pydantic.Field(
        default=None,
        title="HTML Path",
        description=(
            "The path of the HTML file. If it is not provided, the HTML file will not"
            " be generated. The default value is an empty string."
        ),
    )

    png_path: Optional[str] = pydantic.Field(
        default=None,
        title="PNG Path",
        description=(
            "The path of the PNG file. If it is not provided, the PNG file will not be"
            " generated. The default value is an empty string."
        ),
    )

    markdown_path: Optional[str] = pydantic.Field(
        default=None,
        title="Markdown Path",
        description=(
            "The path of the Markdown file. If it is not provided, the Markdown file"
            " will not be generated. The default value is an empty string."
        ),
    )

    no_html: Optional[bool] = pydantic.Field(
        default=False,
        title="Generate HTML Flag",
        description=(
            "A boolean value to determine whether the HTML file will be generated. The"
            " default value is False."
        ),
    )

    no_markdown: Optional[bool] = pydantic.Field(
        default=False,
        title="Generate Markdown Flag",
        description=(
            "A boolean value to determine whether the Markdown file will be generated."
            " The default value is False."
        ),
    )

    no_png: Optional[bool] = pydantic.Field(
        default=False,
        title="Generate PNG Flag",
        description=(
            "A boolean value to determine whether the PNG file will be generated. The"
            " default value is False."
        ),
    )

    @pydantic.field_validator(
        "output_folder_name",
        "pdf_path",
        "latex_path",
        "html_path",
        "png_path",
        "no_html",
        "no_markdown",
        "no_png",
    )
    @classmethod
    def update_settings(
        cls, value: Optional[str], info: pydantic.ValidationInfo
    ) -> Optional[str]:
        """Update the `rendercv_settings` dictionary with the provided values."""
        if value:
            render_options[info.field_name] = value  # type: ignore

        return value


# Initialize the `rendercv_settings.render` dictionary with the default values
render_options: dict[str, str] = {}
RenderOptions()  # Initialize the render options with the default values
