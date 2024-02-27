import pathlib
import importlib
import importlib.machinery
import importlib.util

import jinja2
import pytest

from rendercv import data_models as dm
import rendercv.renderer as r

update_auxiliary_files = False

# import docs/generate_entry_figures_and_examples.py to get example entries (SSOT)
path = (
    pathlib.Path(__file__).parent.parent
    / "docs"
    / "generate_entry_figures_and_examples.py"
)
spec = importlib.util.spec_from_file_location(
    "generate_entry_figures_and_examples", path
)
generate_entry_figures_and_examples = importlib.util.module_from_spec(spec)  # type: ignore
spec.loader.exec_module(generate_entry_figures_and_examples)  # type: ignore

folder_name_dictionary = {
    "rendercv_empty_curriculum_vitae_data_model": "empty",
    "rendercv_filled_curriculum_vitae_data_model": "filled",
}


@pytest.fixture
def publication_entry() -> dict[str, str | list[str]]:
    return generate_entry_figures_and_examples.publication_entry


@pytest.fixture
def experience_entry() -> dict[str, str]:
    return generate_entry_figures_and_examples.experience_entry


@pytest.fixture
def education_entry() -> dict[str, str]:
    return generate_entry_figures_and_examples.education_entry


@pytest.fixture
def normal_entry() -> dict[str, str]:
    return generate_entry_figures_and_examples.normal_entry


@pytest.fixture
def one_line_entry() -> dict[str, str]:
    return generate_entry_figures_and_examples.one_line_entry


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
