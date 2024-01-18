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
