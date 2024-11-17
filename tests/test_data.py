import io
import json
import os
import shutil
from datetime import date as Date

import pydantic
import pytest
import ruamel.yaml
import time_machine

from rendercv import data as data
from rendercv.data import generator
from rendercv.data.models import (
    computers,
    curriculum_vitae,
    entry_types,
    locale_catalog,
)

from .conftest import update_testdata


@pytest.mark.parametrize(
    "date, expected_date_object, expected_error",
    [
        ("2020-01-01", Date(2020, 1, 1), None),
        ("2020-01", Date(2020, 1, 1), None),
        ("2020", Date(2020, 1, 1), None),
        (2020, Date(2020, 1, 1), None),
        ("present", Date(2024, 1, 1), None),
        ("invalid", None, ValueError),
        ("20222", None, ValueError),
        ("202222-20200", None, ValueError),
        ("202222-12-20", None, ValueError),
        ("2022-20-20", None, ValueError),
    ],
)
@time_machine.travel("2024-01-01")
def test_get_date_object(date, expected_date_object, expected_error):
    if expected_error:
        with pytest.raises(expected_error):
            computers.get_date_object(date)
    else:
        assert computers.get_date_object(date) == expected_date_object


@pytest.mark.parametrize(
    "date, expected_date_string",
    [
        (Date(2020, 1, 1), "Jan 2020"),
        (Date(2020, 2, 1), "Feb 2020"),
        (Date(2020, 3, 1), "Mar 2020"),
        (Date(2020, 4, 1), "Apr 2020"),
        (Date(2020, 5, 1), "May 2020"),
        (Date(2020, 6, 1), "June 2020"),
        (Date(2020, 7, 1), "July 2020"),
        (Date(2020, 8, 1), "Aug 2020"),
        (Date(2020, 9, 1), "Sept 2020"),
        (Date(2020, 10, 1), "Oct 2020"),
        (Date(2020, 11, 1), "Nov 2020"),
        (Date(2020, 12, 1), "Dec 2020"),
    ],
)
def test_format_date(date, expected_date_string):
    assert data.format_date(date) == expected_date_string


def test_read_input_file(input_file_path):
    # Update the auxiliary files if update_testdata is True
    if update_testdata:
        # create testdata directory if it doesn't exist
        if not input_file_path.parent.exists():
            input_file_path.parent.mkdir()

        input_dictionary = {
            "cv": {
                "name": "John Doe",
                "sections": {"test_section": ["this is a text entry."]},
            },
            "design": {
                "theme": "classic",
            },
        }

        # dump the dictionary to a yaml file
        yaml_object = ruamel.yaml.YAML()
        yaml_object.dump(input_dictionary, input_file_path)

    data_model = data.read_input_file(input_file_path)

    assert isinstance(data_model, data.RenderCVDataModel)


def test_read_input_file_directly_with_contents(input_file_path):
    input_dictionary = {
        "cv": {
            "name": "John Doe",
        },
        "design": {
            "theme": "classic",
        },
    }

    # dump the dictionary to a yaml file
    yaml_object = ruamel.yaml.YAML()
    yaml_object.width = 60
    yaml_object.indent(mapping=2, sequence=4, offset=2)
    with io.StringIO() as string_stream:
        yaml_object.dump(input_dictionary, string_stream)
        yaml_string = string_stream.getvalue()

    data_model = data.read_input_file(yaml_string)

    assert isinstance(data_model, data.RenderCVDataModel)


def test_read_input_file_invalid_file(tmp_path):
    invalid_file_path = tmp_path / "invalid.extension"
    invalid_file_path.write_text("dummy content", encoding="utf-8")
    with pytest.raises(ValueError):
        data.read_input_file(invalid_file_path)


def test_read_input_file_that_doesnt_exist(tmp_path):
    non_existent_file_path = tmp_path / "non_existent_file.yaml"
    with pytest.raises(FileNotFoundError):
        data.read_input_file(non_existent_file_path)


@pytest.mark.parametrize(
    "theme",
    data.available_themes,
)
def test_create_a_sample_data_model(theme):
    data_model = data.create_a_sample_data_model("John Doe", theme)
    assert isinstance(data_model, data.RenderCVDataModel)


def test_create_a_sample_data_model_invalid_theme():
    with pytest.raises(ValueError):
        data.create_a_sample_data_model("John Doe", "invalid")


def test_generate_json_schema():
    schema = data.generate_json_schema()
    assert isinstance(schema, dict)


def test_generate_json_schema_file(tmp_path):
    schema_file_path = tmp_path / "schema.json"
    data.generate_json_schema_file(schema_file_path)

    assert schema_file_path.exists()

    schema_text = schema_file_path.read_text(encoding="utf-8")
    schema = json.loads(schema_text)

    assert isinstance(schema, dict)


@pytest.mark.skip(
    reason="We should start using this when we start to use branches for each version."
)
def test_if_the_schema_is_the_latest(root_directory_path):
    original_schema_file_path = root_directory_path / "schema.json"
    original_schema_text = original_schema_file_path.read_text()
    original_schema = json.loads(original_schema_text)

    new_schema = data.generate_json_schema()

    assert original_schema == new_schema


@pytest.mark.parametrize(
    "start_date, end_date, date, expected_date_string, expected_date_string_only_years,"
    " expected_time_span",
    [
        (
            "2020-01-01",
            "2021-01-01",
            None,
            "Jan 2020 – Jan 2021",
            "2020 – 2021",
            "1 year 1 month",
        ),
        (
            "2020-01-01",
            "2022-01-01",
            None,
            "Jan 2020 – Jan 2022",
            "2020 – 2022",
            "2 years 1 month",
        ),
        (
            "2020-01-01",
            "2021-12-10",
            None,
            "Jan 2020 – Dec 2021",
            "2020 – 2021",
            "2 years",
        ),
        (
            Date(2020, 1, 1),
            Date(2021, 1, 1),
            None,
            "Jan 2020 – Jan 2021",
            "2020 – 2021",
            "1 year 1 month",
        ),
        (
            "2020-01",
            "2021-01",
            None,
            "Jan 2020 – Jan 2021",
            "2020 – 2021",
            "1 year 1 month",
        ),
        (
            "2020-01",
            "2021-01-01",
            None,
            "Jan 2020 – Jan 2021",
            "2020 – 2021",
            "1 year 1 month",
        ),
        (
            "2020-01-01",
            "2021-01",
            None,
            "Jan 2020 – Jan 2021",
            "2020 – 2021",
            "1 year 1 month",
        ),
        (
            "2020-01-01",
            None,
            None,
            "Jan 2020 – present",
            "2020 – present",
            "4 years 1 month",
        ),
        (
            "2020-02-01",
            "present",
            None,
            "Feb 2020 – present",
            "2020 – present",
            "4 years",
        ),
        ("2020-01-01", "2021-01-01", "2023-02-01", "Feb 2023", "2023", ""),
        ("2020", "2021", None, "2020 – 2021", "2020 – 2021", "1 year"),
        ("2020", None, None, "2020 – present", "2020 – present", "4 years"),
        ("2020-10-10", "2022", None, "Oct 2020 – 2022", "2020 – 2022", "2 years"),
        (
            "2020-10-10",
            "2020-11-05",
            None,
            "Oct 2020 – Nov 2020",
            "2020 – 2020",
            "1 month",
        ),
        ("2022", "2023-10-10", None, "2022 – Oct 2023", "2022 – 2023", "1 year"),
        (
            "2020-01-01",
            "present",
            "My Custom Date",
            "My Custom Date",
            "My Custom Date",
            "",
        ),
        (
            "2020-01-01",
            None,
            "My Custom Date",
            "My Custom Date",
            "My Custom Date",
            "",
        ),
        (
            None,
            None,
            "My Custom Date",
            "My Custom Date",
            "My Custom Date",
            "",
        ),
        (
            None,
            "2020-01-01",
            "My Custom Date",
            "My Custom Date",
            "My Custom Date",
            "",
        ),
        (None, None, "2020-01-01", "Jan 2020", "2020", ""),
        (None, None, "2020-09", "Sept 2020", "2020", ""),
        (None, None, Date(2020, 1, 1), "Jan 2020", "2020", ""),
        (None, None, None, "", "", ""),
        (None, "2020-01-01", None, "Jan 2020", "2020", ""),
        (None, "present", None, "Jan 2024", "2024", ""),
        ("2002", "2020", "2024", "2024", "2024", ""),
    ],
)
@time_machine.travel("2024-01-01")
def test_dates(
    start_date,
    end_date,
    date,
    expected_date_string,
    expected_date_string_only_years,
    expected_time_span,
):
    entry_base = entry_types.EntryBase(
        start_date=start_date, end_date=end_date, date=date
    )

    assert entry_base.date_string == expected_date_string
    assert entry_base.date_string_only_years == expected_date_string_only_years
    assert entry_base.time_span_string == expected_time_span


def test_dates_style():
    assert "TEST" == data.format_date(Date(2020, 1, 1), "TEST")


@pytest.mark.parametrize(
    "date, expected_date_string",
    [
        ("2020-01-01", "Jan 2020"),
        ("2020-01", "Jan 2020"),
        ("2020", "2020"),
    ],
)
def test_publication_dates(publication_entry, date, expected_date_string):
    publication_entry["date"] = date
    publication_entry = data.PublicationEntry(**publication_entry)
    assert publication_entry.date_string == expected_date_string


@pytest.mark.parametrize("date", ["2025-23-23"])
def test_invalid_publication_dates(publication_entry, date):
    with pytest.raises(pydantic.ValidationError):
        publication_entry["date"] = date
        data.PublicationEntry(**publication_entry)


@pytest.mark.parametrize(
    "start_date, end_date, date",
    [
        ("aaa", "2021-01-01", None),
        ("2020-01-01", "aaa", None),
        ("2023-01-01", "2021-01-01", None),
        ("2022", "2021", None),
        ("2025", "2021", None),
        ("2020-01-01", "invalid_end_date", None),
        ("invalid_start_date", "2021-01-01", None),
        ("2020-99-99", "2021-01-01", None),
        ("2020-10-12", "2020-99-99", None),
        (None, None, "2020-20-20"),
    ],
)
def test_invalid_dates(start_date, end_date, date):
    with pytest.raises(pydantic.ValidationError):
        entry_types.EntryBase(start_date=start_date, end_date=end_date, date=date)


@pytest.mark.parametrize(
    "doi, expected_doi_url",
    [
        ("10.1109/TASC.2023.3340648", "https://doi.org/10.1109/TASC.2023.3340648"),
    ],
)
def test_doi_url(publication_entry, doi, expected_doi_url):
    publication_entry["doi"] = doi
    publication_entry = data.PublicationEntry(**publication_entry)
    assert publication_entry.doi_url == expected_doi_url


@pytest.mark.parametrize(
    "network, username",
    [
        ("Mastodon", "invalidmastodon"),
        ("Mastodon", "@inva@l@id"),
        ("Mastodon", "@invalid@ne<>twork.com"),
        ("StackOverflow", "invalidusername"),
        ("StackOverflow", "invalidusername//"),
        ("StackOverflow", "invalidusername/invalid"),
        ("YouTube", "@invalidusername"),
    ],
)
def test_invalid_social_networks(network, username):
    with pytest.raises(pydantic.ValidationError):
        data.SocialNetwork(network=network, username=username)


@pytest.mark.parametrize(
    "network, username, expected_url",
    [
        ("LinkedIn", "myusername", "https://linkedin.com/in/myusername"),
        ("GitHub", "myusername", "https://github.com/myusername"),
        ("Instagram", "myusername", "https://instagram.com/myusername"),
        ("ORCID", "myusername", "https://orcid.org/myusername"),
        ("Mastodon", "@myusername@test.org", "https://test.org/@myusername"),
        (
            "StackOverflow",
            "4567/myusername",
            "https://stackoverflow.com/users/4567/myusername",
        ),
        (
            "GitLab",
            "myusername",
            "https://gitlab.com/myusername",
        ),
        (
            "ResearchGate",
            "myusername",
            "https://researchgate.net/profile/myusername",
        ),
        (
            "YouTube",
            "myusername",
            "https://youtube.com/@myusername",
        ),
        (
            "Google Scholar",
            "myusername",
            "https://scholar.google.com/citations?user=myusername",
        ),
        (
            "Telegram",
            "myusername",
            "https://t.me/myusername",
        ),
    ],
)
def test_social_network_url(network, username, expected_url):
    social_network = data.SocialNetwork(network=network, username=username)
    assert str(social_network.url) == expected_url


@pytest.mark.parametrize(
    "entry, expected_entry_type, expected_section_type",
    [
        (
            "publication_entry",
            "PublicationEntry",
            "SectionWithPublicationEntries",
        ),
        (
            "experience_entry",
            "ExperienceEntry",
            "SectionWithExperienceEntries",
        ),
        (
            "education_entry",
            "EducationEntry",
            "SectionWithEducationEntries",
        ),
        (
            "normal_entry",
            "NormalEntry",
            "SectionWithNormalEntries",
        ),
        ("one_line_entry", "OneLineEntry", "SectionWithOneLineEntries"),
        ("text_entry", "TextEntry", "SectionWithTextEntries"),
        ("bullet_entry", "BulletEntry", "SectionWithBulletEntries"),
    ],
)
def test_get_entry_type_name_and_section_validator(
    entry, expected_entry_type, expected_section_type, request: pytest.FixtureRequest
):
    entry = request.getfixturevalue(entry)
    entry_type, section_type = (
        curriculum_vitae.get_entry_type_name_and_section_validator(
            entry, entry_types.available_entry_models
        )
    )
    assert entry_type == expected_entry_type
    assert section_type.__name__ == expected_section_type

    # initialize the entry with the entry type
    if entry_type != "TextEntry":
        entry = eval(f"data.{entry_type}(**entry)")
        entry_type, section_type = (
            curriculum_vitae.get_entry_type_name_and_section_validator(
                entry, entry_types.available_entry_models
            )
        )
        assert entry_type == expected_entry_type
        assert section_type.__name__ == expected_section_type


@pytest.mark.parametrize(
    "EntryType",
    data.available_entry_models,
)
def test_entries_with_extra_attributes(EntryType, request: pytest.FixtureRequest):
    # Get the name of the class:
    entry_type_name: str = EntryType.__name__

    # Convert from camel case to snake case
    entry_type_name = "".join(
        ["_" + c.lower() if c.isupper() else c for c in entry_type_name]
    ).lstrip("_")

    # Get entry contents from fixture:
    entry_contents = request.getfixturevalue(entry_type_name)

    entry_contents["extra_attribute"] = "extra value"

    entry = EntryType(**entry_contents)

    assert entry.extra_attribute == "extra value"


def test_sections(
    education_entry,
    experience_entry,
    publication_entry,
    normal_entry,
    one_line_entry,
    text_entry,
):
    input = {
        "name": "John Doe",
        "sections": {
            "arbitrary_title": [
                education_entry,
                education_entry,
            ],
            "arbitrary_title_2": [
                experience_entry,
                experience_entry,
            ],
            "arbitrary_title_3": [
                publication_entry,
                publication_entry,
            ],
            "arbitrary_title_4": [
                normal_entry,
                normal_entry,
            ],
            "arbitrary_title_5": [
                one_line_entry,
                one_line_entry,
            ],
            "arbitrary_title_6": [
                text_entry,
                text_entry,
            ],
        },
    }

    cv = data.CurriculumVitae(**input)
    assert len(cv.sections) == 6
    for section in cv.sections:
        assert len(section.entries) == 2


def test_sections_with_invalid_entries():
    input = {"name": "John Doe", "sections": dict()}
    input["sections"]["section_title"] = [
        {
            "this": "is",
            "an": "invalid",
            "entry": 10,
        }
    ]
    with pytest.raises(pydantic.ValidationError):
        data.CurriculumVitae(**input)


def test_sections_without_list():
    input = {"name": "John Doe", "sections": dict()}
    input["sections"]["section_title"] = {
        "this section": "does not have a list of entries but a single entry."
    }
    with pytest.raises(pydantic.ValidationError):
        data.CurriculumVitae(**input)


@pytest.mark.parametrize(
    "invalid_custom_theme_name",
    [
        "pathdoesntexist",
        "invalid_theme_name",
    ],
)
def test_invalid_custom_theme(invalid_custom_theme_name):
    with pytest.raises(pydantic.ValidationError):
        data.RenderCVDataModel(
            **{
                "cv": {"name": "John Doe"},
                "design": {"theme": invalid_custom_theme_name},
            }
        )


def test_custom_theme_with_missing_files(tmp_path):
    custom_theme_path = tmp_path / "customtheme"
    custom_theme_path.mkdir()
    with pytest.raises(pydantic.ValidationError):
        os.chdir(tmp_path)
        data.RenderCVDataModel(
            **{  # type: ignore
                "cv": {"name": "John Doe"},
                "design": {"theme": "customtheme"},
            }
        )


def test_custom_theme(testdata_directory_path):
    os.chdir(
        testdata_directory_path
        / "test_copy_theme_files_to_output_directory_custom_theme"
    )
    data_model = data.RenderCVDataModel(
        **{  # type: ignore
            "cv": {"name": "John Doe"},
            "design": {"theme": "dummytheme"},
        }
    )

    assert data_model.design.theme == "dummytheme"


def test_custom_theme_without_init_file(tmp_path, testdata_directory_path):
    reference_custom_theme_path = (
        testdata_directory_path
        / "test_copy_theme_files_to_output_directory_custom_theme"
        / "dummytheme"
    )

    # copy the directory to tmp_path:
    custom_theme_path = tmp_path / "dummytheme"
    shutil.copytree(reference_custom_theme_path, custom_theme_path, dirs_exist_ok=True)

    # remove the __init__.py file:
    init_file = custom_theme_path / "__init__.py"
    init_file.unlink()

    os.chdir(tmp_path)
    data_model = data.RenderCVDataModel(
        **{  # type: ignore
            "cv": {"name": "John Doe"},
            "design": {"theme": "dummytheme"},
        }
    )

    assert data_model.design.theme == "dummytheme"


def test_custom_theme_with_broken_init_file(tmp_path, testdata_directory_path):
    reference_custom_theme_path = (
        testdata_directory_path
        / "test_copy_theme_files_to_output_directory_custom_theme"
        / "dummytheme"
    )

    # copy the directory to tmp_path:
    custom_theme_path = tmp_path / "dummytheme"
    shutil.copytree(reference_custom_theme_path, custom_theme_path, dirs_exist_ok=True)

    # overwrite the __init__.py file (syntax error)
    init_file = custom_theme_path / "__init__.py"
    init_file.write_text("invalid python code", encoding="utf-8")

    os.chdir(tmp_path)
    with pytest.raises(pydantic.ValidationError):
        data.RenderCVDataModel(
            **{  # type: ignore
                "cv": {"name": "John Doe"},
                "design": {"theme": "dummytheme"},
            }
        )

    # overwrite the __init__.py file (import error)
    init_file = custom_theme_path / "__init__.py"
    init_file.write_text("from ... import test", encoding="utf-8")

    os.chdir(tmp_path)
    with pytest.raises(pydantic.ValidationError):
        data.RenderCVDataModel(
            **{  # type: ignore
                "cv": {"name": "John Doe"},
                "design": {"theme": "dummytheme"},
            }
        )


def test_locale_catalog():
    data_model = data.create_a_sample_data_model("John Doe")
    data_model.locale_catalog = data.LocaleCatalog(
        month="a",
        months="b",
        year="c",
        years="d",
        present="e",
        to="f",
        abbreviations_for_months=[
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
            "12",
        ],
        full_names_of_months=[
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
            "12",
        ],
        phone_number_format="international",
    )

    assert locale_catalog.LOCALE_CATALOG == data_model.locale_catalog.model_dump()


def test_if_local_catalog_resets():
    data_model = data.create_a_sample_data_model("John Doe")

    data_model.locale_catalog = data.LocaleCatalog(
        month="a",
    )

    assert locale_catalog.LOCALE_CATALOG["month"] == "a"

    data_model = data.create_a_sample_data_model("John Doe")

    assert locale_catalog.LOCALE_CATALOG["month"] == "month"


def test_curriculum_vitae():
    data.CurriculumVitae(name="Test Doe")

    assert curriculum_vitae.curriculum_vitae == {"name": "Test Doe"}


def test_if_curriculum_vitae_resets():
    data.CurriculumVitae(name="Test Doe")

    assert curriculum_vitae.curriculum_vitae["name"] == "Test Doe"

    data.create_a_sample_data_model("John Doe")

    assert curriculum_vitae.curriculum_vitae["name"] == "John Doe"


def test_dictionary_to_yaml():
    input_dictionary = {
        "test_list": [
            "a",
            "b",
            "c",
        ],
        "test_dict": {
            "a": 1,
            "b": 2,
        },
    }
    yaml_string = generator.dictionary_to_yaml(input_dictionary)

    # load the yaml string
    yaml_object = ruamel.yaml.YAML()
    output_dictionary = yaml_object.load(yaml_string)

    assert input_dictionary == output_dictionary


def test_create_a_sample_yaml_input_file(tmp_path):
    input_file_path = tmp_path / "input.yaml"
    yaml_contents = data.create_a_sample_yaml_input_file(input_file_path)

    assert input_file_path.exists()
    assert yaml_contents == input_file_path.read_text(encoding="utf-8")


def test_default_input_file_doesnt_have_local_catalog():
    yaml_contents = data.create_a_sample_yaml_input_file()
    assert "locale_catalog" not in yaml_contents


@pytest.mark.parametrize(
    "key, expected_section_title",
    [
        ("this_is_a_test", "This Is a Test"),
        ("welcome_to_RenderCV!", "Welcome to RenderCV!"),
        ("\\faGraduationCap_education", "\\faGraduationCap Education"),
        ("Hello_World", "Hello World"),
        ("Hello World", "Hello World"),
    ],
)
def test_dictionary_key_to_proper_section_title(key, expected_section_title):
    assert (
        computers.dictionary_key_to_proper_section_title(key) == expected_section_title
    )


# def test_if_available_themes_and_avaialble_theme_options_has_the_same_length():


@pytest.mark.parametrize(
    "url, expected_clean_url",
    [
        ("https://example.com", "example.com"),
        ("https://example.com/", "example.com"),
        ("https://example.com/test", "example.com/test"),
        ("https://example.com/test/", "example.com/test"),
        ("https://www.example.com/test/", "www.example.com/test"),
    ],
)
def test_make_a_url_clean(url, expected_clean_url):
    assert computers.make_a_url_clean(url) == expected_clean_url
    assert (
        data.PublicationEntry(title="Test", authors=["test"], url=url).clean_url
        == expected_clean_url
    )


@pytest.mark.parametrize(
    "path_name, expected_value",
    [
        ("NAME_IN_SNAKE_CASE", "John_Doe"),
        ("NAME_IN_LOWER_SNAKE_CASE", "john_doe"),
        ("NAME_IN_UPPER_SNAKE_CASE", "JOHN_DOE"),
        ("NAME_IN_KEBAB_CASE", "John-Doe"),
        ("NAME_IN_LOWER_KEBAB_CASE", "john-doe"),
        ("NAME_IN_UPPER_KEBAB_CASE", "JOHN-DOE"),
        ("NAME", "John Doe"),
        ("FULL_MONTH_NAME", "January"),
        ("MONTH_ABBREVIATION", "Jan"),
        ("MONTH", "1"),
        ("MONTH_IN_TWO_DIGITS", "01"),
        ("YEAR", "2024"),
        ("YEAR_IN_TWO_DIGITS", "24"),
    ],
)
@time_machine.travel("2024-01-01")
def test_render_command_settings_placeholders(path_name, expected_value):
    data.CurriculumVitae(name="John Doe")

    render_command_settings = data.RenderCommandSettings(
        pdf_path=path_name,
        latex_path=path_name,
        html_path=path_name,
        markdown_path=path_name,
        output_folder_name=path_name,
    )

    assert render_command_settings.pdf_path.name == expected_value  # type: ignore
    assert render_command_settings.latex_path.name == expected_value  # type: ignore
    assert render_command_settings.html_path.name == expected_value  # type: ignore
    assert render_command_settings.markdown_path.name == expected_value  # type: ignore
    assert render_command_settings.output_folder_name == expected_value
