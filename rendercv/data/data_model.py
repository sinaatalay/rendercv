from pydantic import BaseModel
from .content import CurriculumVitae
from .design import Design

class RenderCVDataModel(BaseModel):
    design: Design
    cv: CurriculumVitae