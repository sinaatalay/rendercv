"""
The `rendercv.models.rendercv_settings` module contains the data model of the
`rendercv_settings` field of the input file.
"""

from typing import Optional

import pydantic

from .base import RenderCVBaseModelWithExtraKeys
from .render import RenderOptions


class RenderCVSettings(RenderCVBaseModelWithExtraKeys):
    """This class is the data model of the rendercv settings. The values of each field
    updates the `rendercv_settings` dictionary.
    """

    render_options: Optional[RenderOptions] = pydantic.Field(
        default=None,
        title="Render Options",
        description="The options to render the output files.",
    )

    @pydantic.field_validator(
        "render_options",
    )
    @classmethod
    def update_settings(
        cls, value: Optional[str], info: pydantic.ValidationInfo
    ) -> Optional[str]:
        """Update the `rendercv_settings` dictionary with the provided values."""
        if value:
            rendercv_settings[info.field_name] = value  # type: ignore

        return value


# Initialize the rendercv settings with the default values
rendercv_settings: dict[str, str] = {}
RenderCVSettings()  # Initialize the rendercv settings with the default values
