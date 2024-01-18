import unittest
import os
import json

from rendercv import data_models

from datetime import date as Date
from pydantic import ValidationError


def test_sections():
    input = {
        "name": "John Doe",
        "sections": {
            "my_section": {
                "title": "test",
                "entry_type": "EducationEntry",
                "entries": [
                    {
                        "institution": "Boğaziçi University",
                        "area": "Mechanical Engineering",
                        "date": "My Date",
                    }
                ],
            }
        },
    }

    cv = data_models.CurriculumVitae(**input)
    assert cv is not None
    assert cv.sections[0].entry_type == "EducationEntry"
    assert len(cv.sections_input["my_section"].entries) == 1
    assert cv.sections[0].title == "My Section"
