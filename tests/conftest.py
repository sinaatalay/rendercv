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
        "details": "My Details",
    }


@pytest.fixture
def text_entry() -> str:
    return "My Text Entry"


@pytest.fixture
def rendercv_data_model() -> dm.RenderCVDataModel:
    return dm.get_a_sample_data_model()


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
def reference_files_directory_path(tests_directory_path) -> pathlib.Path:
    return tests_directory_path / "reference_files"


@pytest.fixture
def input_file_path(reference_files_directory_path) -> pathlib.Path:
    return reference_files_directory_path / "John_Doe_CV.yaml"
