import pathlib
import copy
import typing
import itertools

import jinja2
import pytest
import pydantic
import pydantic_extra_types.phone_numbers as pydantic_phone_numbers

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
    "label": "Programming",
    "details": "Python, C++, JavaScript, MATLAB",
}

bullet_entry_dictionary = {
    "bullet": "This is a bullet entry.",
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
def bullet_entry() -> dict[str, str]:
    return copy.deepcopy(bullet_entry_dictionary)


@pytest.fixture
def text_entry() -> str:
    return "My Text Entry with some **markdown** and [links](https://example.com)!"


def return_a_value_for_a_field_type(
    field: str,
    field_type: typing.Any,
) -> str:
    """Return a value for a field type.

    Args:
        field_type (typing.Any): _description_

    Returns:
        str: _description_
    """
    field_dictionary = {
        "institution": "Boğaziçi University",
        "location": "Istanbul, Turkey",
        "degree": "BS",
        "area": "Mechanical Engineering",
        "start_date": "2015-09",
        "end_date": "2020-06",
        "date": "2021-09",
        "highlights": [
            "Did this.",
            "Did that.",
        ],
        "company": "Some Company",
        "position": "Software Engineer",
        "name": "My Project",
        "label": "Programming",
        "details": "Python, C++, JavaScript, MATLAB",
        "authors": ["J. Doe", "**H. Tom**", "S. Doe", "A. Andsurname"],
        "title": (
            "Magneto-Thermal Thin Shell Approximation for 3D Finite Element Analysis of"
            " No-Insulation Coils"
        ),
        "journal": "IEEE Transactions on Applied Superconductivity",
        "doi": "10.1109/TASC.2023.3340648",
    }

    field_type_dictionary = {
        pydantic.HttpUrl: "https://example.com",
        pydantic_phone_numbers.PhoneNumber: "+905419999999",
        str: "A string",
        list[str]: ["A string", "Another string"],
        int: 1,
        float: 1.0,
        bool: True,
    }

    if type(None) in typing.get_args(field_type):
        return return_a_value_for_a_field_type(field, field_type.__args__[0])
    elif typing.get_origin(field_type) == typing.Literal:
        return field_type.__args__[0]
    elif typing.get_origin(field_type) == typing.Union:
        return return_a_value_for_a_field_type(field, field_type.__args__[0])
    elif field in field_dictionary:
        return field_dictionary[field]
    elif field_type in field_type_dictionary:
        return field_type_dictionary[field_type]

    return "A string"


def create_combinations_of_a_model(
    model: pydantic.BaseModel,
) -> list[pydantic.BaseModel]:
    """Look at the required fields and optional fields of a model and create all
    possible combinations of them.

    Args:
        model (pydantic.BaseModel): The data model class to create combinations of.

    Returns:
        list[pydantic.BaseModel]: All possible instances of the model.
    """
    fields = typing.get_type_hints(model)

    required_fields = dict()
    optional_fields = dict()

    for field, field_type in fields.items():
        value = return_a_value_for_a_field_type(field, field_type)
        if type(None) in typing.get_args(field_type):  # check if a field is optional
            optional_fields[field] = value
        else:
            required_fields[field] = value

    model_with_only_required_fields = model(**required_fields)

    # create all possible combinations of optional fields
    all_combinations = [model_with_only_required_fields]
    for i in range(1, len(optional_fields) + 1):
        for combination in itertools.combinations(optional_fields, i):
            kwargs = {k: optional_fields[k] for k in combination}
            model = copy.deepcopy(model_with_only_required_fields)
            model.__dict__.update(kwargs)
            all_combinations.append(model)

    return all_combinations


@pytest.fixture
def all_combinations_of_text_entries() -> list[str]:
    return [
        "My Text Entry with some **markdown** and [links](https://example.com)!",
        "My Text Entry with some **markdown** and [links](https://example.com)!",
        "Some other *** tests, which should be tricky* to parse!**",
    ]


@pytest.fixture
def all_combinations_of_bullet_entries() -> list[dict[str, str]]:
    return [
        {"bullet": "This is a bullet entry."},
        {
            "bullet": (
                "My Text Entry with some **markdown** and [links](https://example.com)!"
            )
        },
        {"bullet": "Some other *** tests, which should be tricky* to parse!**"},
    ]


@pytest.fixture
def all_combinations_of_one_line_entries() -> list[dict[str, str]]:
    return create_combinations_of_a_model(dm.OneLineEntry)


@pytest.fixture
def all_combinations_of_normal_entries() -> list[dict[str, str]]:
    return create_combinations_of_a_model(dm.NormalEntry)


@pytest.fixture
def all_combinations_of_education_entries() -> list[dict[str, str]]:
    return create_combinations_of_a_model(dm.EducationEntry)


@pytest.fixture
def all_combinations_of_experience_entries() -> list[dict[str, str]]:
    return create_combinations_of_a_model(dm.ExperienceEntry)


@pytest.fixture
def all_combinations_of_publication_entries() -> list[dict[str, str | list[str]]]:
    return create_combinations_of_a_model(dm.PublicationEntry)


@pytest.fixture
def rendercv_data_model() -> dm.RenderCVDataModel:
    return dm.get_a_sample_data_model()


@pytest.fixture
def rendercv_empty_curriculum_vitae_data_model() -> dm.CurriculumVitae:
    return dm.CurriculumVitae(sections={"test": ["test"]})


@pytest.fixture
def rendercv_filled_curriculum_vitae_data_model(
    text_entry,
    all_combinations_of_publication_entries,
    all_combinations_of_experience_entries,
    all_combinations_of_education_entries,
    all_combinations_of_normal_entries,
    all_combinations_of_one_line_entries,
    all_combinations_of_bullet_entries,
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
            "Text Entries": [
                text_entry,
                text_entry,
                "Some other *** tests, which should be tricky* to parse!**",
            ],
            "Bullet Entries": all_combinations_of_bullet_entries,
            "Publication Entries": all_combinations_of_publication_entries,
            "Experience Entries": all_combinations_of_experience_entries,
            "Education Entries": all_combinations_of_education_entries,
            "Normal Entries": all_combinations_of_normal_entries,
            "One Line Entries": all_combinations_of_one_line_entries,
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
