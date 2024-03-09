import pathlib
import copy

import jinja2
import pytest

from rendercv import data_models as dm
import rendercv.renderer as r

update_auxiliary_files = False
folder_name_dictionary = {
    "rendercv_empty_curriculum_vitae_data_model": "empty",
    "rendercv_filled_curriculum_vitae_data_model": "filled",
}

# copy sample entries from docs/generate_entry_figures_and_examples.py:
education_entry_dictionary = {
    "institution": "Boğaziçi University",
    "location": "Istanbul, Turkey",
    "degree": "BS",
    "area": "Mechanical Engineering",
    "start_date": "2015-09",
    "end_date": "2020-06",
    "highlights": [
        "GPA: 3.24/4.00 ([Transcript](https://example.com))",
        "Awards: Dean's Honor List, Sportsperson of the Year",
    ],
}

experience_entry_dictionary = {
    "company": "Some Company",
    "location": "TX, USA",
    "position": "Software Engineer",
    "start_date": "2020-07",
    "end_date": "2021-08-12",
    "highlights": [
        (
            "Developed an [IOS application](https://example.com) that has received"
            " more than **100,000 downloads**."
        ),
        "Managed a team of **5** engineers.",
    ],
}

normal_entry_dictionary = {
    "name": "Some Project",
    "location": "Remote",
    "date": "2021-09",
    "highlights": [
        "Developed a web application with **React** and **Django**.",
        "Implemented a **RESTful API**",
    ],
}

publication_entry_dictionary = {
    "title": (
        "Magneto-Thermal Thin Shell Approximation for 3D Finite Element Analysis of"
        " No-Insulation Coils"
    ),
    "authors": ["J. Doe", "***H. Tom***", "S. Doe", "A. Andsurname"],
    "date": "2021-12-08",
    "journal": "IEEE Transactions on Applied Superconductivity",
    "doi": "10.1109/TASC.2023.3340648",
}

one_line_entry_dictionary = {
    "name": "Programming",
    "details": "Python, C++, JavaScript, MATLAB",
}


@pytest.fixture
def publication_entry() -> dict[str, str | list[str]]:
    return copy.deepcopy(publication_entry_dictionary)


@pytest.fixture
def experience_entry() -> dict[str, str]:
    return copy.deepcopy(experience_entry_dictionary)


@pytest.fixture
def education_entry() -> dict[str, str]:
    return copy.deepcopy(education_entry_dictionary)


@pytest.fixture
def normal_entry() -> dict[str, str]:
    return copy.deepcopy(normal_entry_dictionary)


@pytest.fixture
def one_line_entry() -> dict[str, str]:
    return copy.deepcopy(one_line_entry_dictionary)


@pytest.fixture
def text_entry() -> str:
    return "My Text Entry with some **markdown** and [links](https://example.com)!"


@pytest.fixture
def rendercv_data_model() -> dm.RenderCVDataModel:
    return dm.get_a_sample_data_model()


@pytest.fixture
def rendercv_empty_curriculum_vitae_data_model() -> dm.CurriculumVitae:
    return dm.CurriculumVitae(sections={"test": ["test"]})


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
