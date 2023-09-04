from pydantic import BaseModel, Field, HttpUrl, model_validator
from pydantic_extra_types.color import Color
from typing import Literal
from datetime import date as Date

class ClassicTheme(BaseModel):
    # 1) Mandotory user inputs:
    # 2) Optional user inputs:
    primary_color: Color = Field(default="blue")
    
    page_top_margin: str = Field(default="1.35cm")
    page_bottom_margin: str = Field(default="1.35cm")
    page_left_margin: str = Field(default="1.35cm")
    page_right_margin: str = Field(default="1.35cm")

    section_title_top_margin: str = Field(default="0.13cm")
    section_title_bottom_margin: str = Field(default="0.13cm")

    vertical_margin_between_sections: str = Field(default="0.13cm")

    vertical_margin_between_bullet_points: str = Field(default="0.07cm")
    bullet_point_left_margin: str = Field(default="0.7cm")

    vertical_margin_between_entries: str = Field(default="0.12cm")

    vertical_margin_between_entries_and_highlights: str = Field(default="0.12cm")

    date_and_location_width: str = Field(default="3.7cm")

class Design(BaseModel):
    theme: Literal['classic'] = 'classic'
    options: ClassicTheme