import pathlib
from typing import Type

import jinja2
import pytest

from rendercv import data_models as dm
import rendercv.renderer as r


@pytest.fixture
def publication_entry() -> dict[str, str | list[str]]:
    return {
        "title": "My Title",
        "authors": ["John Doe", "Jane Doe"],
        "doi": "10.1109/TASC.2023.3340648",
        "date": "2023-12-08",
    }


@pytest.fixture
def experience_entry() -> dict[str, str]:
    return {
        "company": "CERN",
        "position": "Researcher",
    }


@pytest.fixture
def education_entry() -> dict[str, str]:
    return {
        "institution": "Boğaziçi University",
        "area": "Mechanical Engineering",
        "degree": "BS",
    }


@pytest.fixture
def normal_entry() -> dict[str, str]:
    return {
        "name": "My Entry",
    }


@pytest.fixture
def one_line_entry() -> dict[str, str]:
    return {
        "name": "My One Line Entry",
        "details": "My Details and some math $a=6^4 \\frac{3}{5}$",
    }


@pytest.fixture
def text_entry() -> str:
    return "My Text Entry"


@pytest.fixture
def rendercv_data_model() -> dm.RenderCVDataModel:
    return dm.get_a_sample_data_model()


@pytest.fixture
def rendercv_empty_curriculum_vitae_data_model() -> dm.CurriculumVitae:
    return dm.CurriculumVitae(name="John Doe")


@pytest.fixture
def rendercv_filled_curriculum_vitae_data_model(
    text_entry,
    publication_entry,
    experience_entry,
    education_entry,
    normal_entry,
    one_line_entry,
) -> dm.CurriculumVitae:
    return dm.CurriculumVitae(
        name="John Doe",
        label="Mechanical Engineer",
        location="Istanbul, Turkey",
        email="johndoe@example.com",
        phone="+905419999999",  # type: ignore
        website="https://example.com",  # type: ignore
        social_networks=[
            dm.SocialNetwork(network="LinkedIn", username="johndoe"),
            dm.SocialNetwork(network="GitHub", username="johndoe"),
            dm.SocialNetwork(network="Instagram", username="johndoe"),
            dm.SocialNetwork(network="Orcid", username="0000-0000-0000-0000"),
            dm.SocialNetwork(network="Mastodon", username="@johndoe@example"),
            dm.SocialNetwork(network="Twitter", username="johndoe"),
        ],
        sections={
            "section1": [
                text_entry,
                text_entry,
            ],
            "section2": [
                publication_entry,
                publication_entry,
            ],
            "section3": [
                experience_entry,
                experience_entry,
            ],
            "section4": [
                education_entry,
                education_entry,
            ],
            "section5": [
                normal_entry,
                normal_entry,
            ],
            "section6": [
                one_line_entry,
                one_line_entry,
            ],
        },
    )


@pytest.fixture
def jinja2_environment() -> jinja2.Environment:
    return r.setup_jinja2_environment()


@pytest.fixture
def tests_directory_path() -> pathlib.Path:
    return pathlib.Path(__file__).parent


@pytest.fixture
def root_directory_path(tests_directory_path) -> pathlib.Path:
    return tests_directory_path.parent


@pytest.fixture
def auxiliary_files_directory_path(tests_directory_path) -> pathlib.Path:
    return tests_directory_path / "auxiliary_files"


@pytest.fixture
def input_file_path(auxiliary_files_directory_path) -> pathlib.Path:
    return auxiliary_files_directory_path / "John_Doe_CV.yaml"
