import pytest

from rendercv import data_models as dm


@pytest.fixture(scope="module")
def dummy_input():
    return {
        "name": "John Doe",
        "sections": None,
    }


# abi burda baya bi senaryo test etmen lazim:
# mesela section icinde title field verilmisse, title o olamli, herseyo overwrite etmeli
# sonra siralama listede verildigi gibi olmali kesinlikle bunu da check et
# sonra default listler alisiyo mu kesinlikle onu check etmek lazim
# bide validation errorleri check etmek lazim
# REPLACEWITHTODAY olayini monkeypatch ile duzelticeksin, hep statik bir tarih return etsin


def test_sections(dummy_input):
    dummy_input["sections"] = {
        "My Section 1": {
            "entry_type": "EducationEntry",
            "entries": [
                {
                    "institution": "Boğaziçi University",
                    "area": "Mechanical Engineering",
                }
            ],
        },
        "My Section 2": {
            "entry_type": "ExperienceEntry",
            "entries": [
                {
                    "company": "Apple",
                    "position": "Researcher",
                }
            ],
        },
        "My Section 3": {
            "entry_type": "PublicationEntry",
            "entries": [
                {
                    "title": "My Title",
                    "authors": ["John Doe", "Jane Doe"],
                    "doi": "10.1109/TASC.2023.3340648",
                    "date": "2023-12-08",
                }
            ],
        },
        "my_section_4": {
            "entry_type": "NormalEntry",
            "entries": [
                {
                    "name": "My Entry",
                }
            ],
        },
        "my_section_5": {
            "entry_type": "OneLineEntry",
            "entries": [
                {
                    "name": "My One Line Entry",
                    "details": "My Details",
                }
            ],
        },
        "my_section_6": {
            "entry_type": "TextEntry",
            "entries": ["My Text Entry"],
        },
        "Education": [
            {
                "institution": "Boğaziçi University",
                "area": "Mechanical Engineering",
            }
        ],
        "Experience": [
            {
                "company": "Apple",
                "position": "Researcher",
            }
        ],
        "Work Experience": [
            {
                "company": "Apple",
                "position": "Researcher",
            }
        ],
        "Research Experience": [
            {
                "company": "Apple",
                "position": "Researcher",
            }
        ],
        "Publications": [
            {
                "title": "My Title",
                "authors": ["John Doe", "Jane Doe"],
                "doi": "10.1109/TASC.2023.3340648",
                "date": "2023-12-08",
            }
        ],
        "Papers": [
            {
                "title": "My Title",
                "authors": ["John Doe", "Jane Doe"],
                "doi": "10.1109/TASC.2023.3340648",
                "date": "2023-12-08",
            }
        ],
        "Projects": [
            {
                "name": "My Entry",
            }
        ],
        "Academic Projects": [
            {
                "name": "My Entry",
            }
        ],
        "University Projects": [
            {
                "name": "My Entry",
            }
        ],
        "Personal Projects": [
            {
                "name": "My Entry",
            }
        ],
        "Certificates": [
            {
                "name": "My Entry",
            }
        ],
        "Extracurricular Activities": [
            {
                "company": "Apple",
                "position": "Researcher",
            }
        ],
        "Test Scores": [
            {
                "name": "My One Line Entry",
                "details": "My Details",
            }
        ],
        "Skills": [
            {
                "name": "My One Line Entry",
                "details": "My Details",
            }
        ],
        "Programming Skills": [
            {
                "name": "My Entry",
            }
        ],
        "Other Skills": [
            {
                "name": "My One Line Entry",
                "details": "My Details",
            }
        ],
        "Awards": [
            {
                "name": "My One Line Entry",
                "details": "My Details",
            }
        ],
        "Interests": [
            {
                "name": "My One Line Entry",
                "details": "My Details",
            }
        ],
        "Summary": ["My Text Entry"],
    }

    cv = dm.CurriculumVitae(**dummy_input)
    assert len(cv.sections) == 22

    titles = [section.title for section in cv.sections]
    for key in dummy_input["sections"]:
        assert key in titles


def test_education_entry(dummy_input):
    dummy_input["sections"] = {
        "My Section": [
            {
                "entry_type": "EducationEntry",
                "entries": [
                    {
                        "institution": "Boğaziçi University",
                        "start_date": "2019-01-01",
                        "end_date": "2020-01-01",
                        "area": "Mechanical Engineering",
                    }
                ],
            }
        ]
    }
    cv = dm.CurriculumVitae(**dummy_input)
    assert cv.sections[0].title == "My Section"
    assert len(cv.sections[0].entries) == 1


def test_experience_entry(dummy_input):
    dummy_input["sections"] = {
        "My Section": [
            {
                "entry_type": "ExperienceEntry",
                "entries": [
                    {
                        "company": "CERN",
                        "start_date": "2019-01-01",
                        "end_date": "2020-01-01",
                        "position": "Researcher",
                    }
                ],
            }
        ]
    }
    cv = dm.CurriculumVitae(**dummy_input)
    assert cv.sections[0].title == "My Section"
    assert len(cv.sections[0].entries) == 1
