from datetime import date as Date
import pathlib
import json

import pydantic
import pytest
import time_machine

from rendercv import data_models as dm


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
def tests_directory_path() -> pathlib.Path:
    return pathlib.Path(__file__).parent


@pytest.fixture
def root_directory_path(tests_directory_path) -> pathlib.Path:
    return tests_directory_path.parent


@pytest.fixture
def input_file_path(tests_directory_path) -> pathlib.Path:
    return tests_directory_path / "input_files" / "John_Doe_CV.yaml"


@pytest.mark.parametrize(
    "date, expected_date_object, expected_error",
    [
        ("2020-01-01", Date(2020, 1, 1), None),
        ("2020-01", Date(2020, 1, 1), None),
        ("2020", Date(2020, 1, 1), None),
        (2020, Date(2020, 1, 1), None),
        ("present", Date(2024, 1, 1), None),
        ("invalid", None, ValueError),
    ],
)
@time_machine.travel("2024-01-01")
def test_get_date_object(date, expected_date_object, expected_error):
    if expected_error:
        with pytest.raises(expected_error):
            dm.get_date_object(date)
    else:
        assert dm.get_date_object(date) == expected_date_object


@pytest.mark.parametrize(
    "date, expected_date_string",
    [
        (Date(2020, 1, 1), "Jan. 2020"),
        (Date(2020, 2, 1), "Feb. 2020"),
        (Date(2020, 3, 1), "Mar. 2020"),
        (Date(2020, 4, 1), "Apr. 2020"),
        (Date(2020, 5, 1), "May 2020"),
        (Date(2020, 6, 1), "June 2020"),
        (Date(2020, 7, 1), "July 2020"),
        (Date(2020, 8, 1), "Aug. 2020"),
        (Date(2020, 9, 1), "Sept. 2020"),
        (Date(2020, 10, 1), "Oct. 2020"),
        (Date(2020, 11, 1), "Nov. 2020"),
        (Date(2020, 12, 1), "Dec. 2020"),
    ],
)
def test_format_date(date, expected_date_string):
    assert dm.format_date(date) == expected_date_string


@pytest.mark.parametrize(
    "string, expected_string",
    [
        ("My Text", "My Text"),
        ("My # Text", "My \\# Text"),
        ("My % Text", "My \\% Text"),
        ("My & Text", "My \\& Text"),
        ("My ~ Text", "My \\textasciitilde{} Text"),
        ("##%%&&~~", "\\#\\#\\%\\%\\&\\&\\textasciitilde{}\\textasciitilde{}"),
    ],
)
def test_escape_latex_characters(string, expected_string):
    assert dm.escape_latex_characters(string) == expected_string


@pytest.mark.parametrize(
    "markdown_string, expected_latex_string",
    [
        ("My Text", "My Text"),
        ("**My** Text", "\\textbf{My} Text"),
        ("*My* Text", "\\textit{My} Text"),
        ("***My*** Text", "\\textit{\\textbf{My}} Text"),
        ("[My](https://myurl.com) Text", "\\href{https://myurl.com}{My} Text"),
        ("`My` Text", "\\texttt{My} Text"),
        (
            "[**My** *Text* ***Is*** `Here`](https://myurl.com)",
            (
                "\\href{https://myurl.com}{\\textbf{My} \\textit{Text}"
                " \\textit{\\textbf{Is}} \\texttt{Here}}"
            ),
        ),
    ],
)
def test_markdown_to_latex(markdown_string, expected_latex_string):
    assert dm.markdown_to_latex(markdown_string) == expected_latex_string


def test_read_input_file(input_file_path):
    data_model = dm.read_input_file(input_file_path)
    assert isinstance(data_model, dm.RenderCVDataModel)


def test_get_a_sample_data_model():
    data_model = dm.get_a_sample_data_model("John Doe")
    assert isinstance(data_model, dm.RenderCVDataModel)


def test_generate_json_schema():
    schema = dm.generate_json_schema()
    assert isinstance(schema, dict)


def test_generate_json_schema_file(tmp_path):
    schema_file_path = tmp_path / "schema.json"
    dm.generate_json_schema_file(schema_file_path)

    assert schema_file_path.exists()

    schema_text = schema_file_path.read_text()
    schema = json.loads(schema_text)

    assert isinstance(schema, dict)


def test_if_the_schema_is_the_latest(root_directory_path):
    original_schema_file_path = root_directory_path / "schema.json"
    original_schema_text = original_schema_file_path.read_text()
    original_schema = json.loads(original_schema_text)

    new_schema = dm.generate_json_schema()

    assert original_schema == new_schema


@pytest.mark.parametrize(
    "start_date, end_date, date, expected_date_string, expected_time_span",
    [
        ("2020-01-01", "2021-01-01", None, "Jan. 2020 to Jan. 2021", "1 year 1 month"),
        ("2020-01", "2021-01", None, "Jan. 2020 to Jan. 2021", "1 year 1 month"),
        ("2020-01", "2021-01-01", None, "Jan. 2020 to Jan. 2021", "1 year 1 month"),
        ("2020-01-01", "2021-01", None, "Jan. 2020 to Jan. 2021", "1 year 1 month"),
        ("2020-01-01", None, None, "Jan. 2020 to present", "4 years 1 month"),
        ("2020-02-01", "present", None, "Feb. 2020 to present", "3 years 11 months"),
        ("2020-01-01", "2021-01-01", "2023-02-01", "Feb. 2023", ""),
        ("2020", "2021", None, "2020 to 2021", "1 year"),
        ("2020", None, None, "2020 to present", "4 years"),
        ("2020-10-10", "2022", None, "Oct. 2020 to 2022", "2 years"),
        ("2022", "2023-10-10", None, "2022 to Oct. 2023", "1 year"),
        ("2020-01-01", "present", "My Custom Date", "My Custom Date", ""),
        ("2020-01-01", None, "My Custom Date", "My Custom Date", ""),
        (None, None, "My Custom Date", "My Custom Date", ""),
        (None, "2020-01-01", "My Custom Date", "My Custom Date", ""),
        (None, None, "2020-01-01", "Jan. 2020", ""),
        (None, None, None, "", ""),
    ],
)
@time_machine.travel("2024-01-01")
def test_dates(start_date, end_date, date, expected_date_string, expected_time_span):
    entry_base = dm.EntryBase(start_date=start_date, end_date=end_date, date=date)

    assert entry_base.date_string == expected_date_string
    assert entry_base.time_span_string == expected_time_span


@pytest.mark.parametrize(
    "date, expected_date_string",
    [
        ("2020-01-01", "Jan. 2020"),
        ("2020-01", "Jan. 2020"),
        ("2020", "2020"),
    ],
)
def test_publication_dates(publication_entry, date, expected_date_string):
    publication_entry["date"] = date
    publication_entry = dm.PublicationEntry(**publication_entry)
    assert publication_entry.date_string == expected_date_string


@pytest.mark.parametrize("date", ["aaa", None, "2025"])
def test_invalid_publication_dates(publication_entry, date):
    with pytest.raises(pydantic.ValidationError):
        publication_entry["date"] = date
        dm.PublicationEntry(**publication_entry)


@pytest.mark.parametrize(
    "start_date, end_date, date",
    [
        ("aaa", "2021-01-01", None),
        ("2020-01-01", "aaa", None),
        (None, "2020-01-01", None),
        ("2023-01-01", "2021-01-01", None),
        ("2999-01-01", None, None),
        ("2020-01-01", "2999-01-01", None),
        ("2022", "2021", None),
        ("2021", "2060", None),
    ],
)
def test_invalid_dates(start_date, end_date, date):
    with pytest.raises(pydantic.ValidationError):
        dm.EntryBase(start_date=start_date, end_date=end_date, date=date)


@pytest.mark.parametrize(
    "url, url_text, expected_url_text",
    [
        ("https://linkedin.com", None, "view on LinkedIn"),
        ("https://github.com", None, "view on GitHub"),
        ("https://instagram.com", None, "view on Instagram"),
        ("https://youtube.com", None, "view on YouTube"),
        ("https://twitter.com", "My URL Text", "My URL Text"),
        ("https://google.com", None, "view on my website"),
    ],
)
def test_url_text(url, url_text, expected_url_text):
    entry_base = dm.EntryBase(url=url, url_text=url_text)
    assert entry_base.url_text == expected_url_text


@pytest.mark.parametrize(
    "doi, expected_doi_url",
    [
        ("10.1109/TASC.2023.3340648", "https://doi.org/10.1109/TASC.2023.3340648"),
    ],
)
def test_doi_url(publication_entry, doi, expected_doi_url):
    publication_entry["doi"] = doi
    publication_entry = dm.PublicationEntry(**publication_entry)
    assert publication_entry.doi_url == expected_doi_url


@pytest.mark.parametrize(
    "doi",
    ["aaa10.1109/TASC.2023.3340648", "aaa"],
)
def test_invalid_doi(publication_entry, doi):
    with pytest.raises(pydantic.ValidationError):
        publication_entry["doi"] = doi
        dm.PublicationEntry(**publication_entry)


@pytest.mark.parametrize(
    "network, username, expected_url",
    [
        ("LinkedIn", "myusername", "https://linkedin.com/in/myusername"),
        ("GitHub", "myusername", "https://github.com/myusername"),
        ("Instagram", "myusername", "https://instagram.com/myusername"),
        ("Orcid", "myusername", "https://orcid.org/myusername"),
        ("Twitter", "myusername", "https://twitter.com/myusername"),
        ("Mastodon", "@myusername", "https://mastodon.social/@myusername"),
    ],
)
def test_social_network_url(network, username, expected_url):
    social_network = dm.SocialNetwork(network=network, username=username)
    assert str(social_network.url) == expected_url


@pytest.mark.parametrize(
    "title, default_entry",
    [
        ("Education", "education_entry"),
        ("Experience", "experience_entry"),
        ("Work Experience", "experience_entry"),
        ("Research Experience", "experience_entry"),
        ("Publications", "publication_entry"),
        ("Papers", "publication_entry"),
        ("Projects", "normal_entry"),
        ("Academic Projects", "normal_entry"),
        ("University Projects", "normal_entry"),
        ("Personal Projects", "normal_entry"),
        ("Certificates", "normal_entry"),
        ("Extracurricular Activities", "experience_entry"),
        ("Test Scores", "one_line_entry"),
        ("Skills", "one_line_entry"),
        ("programming_skills", "normal_entry"),
        ("other_skills", "one_line_entry"),
        ("Awards", "one_line_entry"),
        ("Interests", "one_line_entry"),
        ("Summary", "text_entry"),
    ],
)
def test_sections_with_default_types(
    education_entry,
    experience_entry,
    publication_entry,
    normal_entry,
    one_line_entry,
    text_entry,
    title,
    default_entry,
):
    input = {
        "name": "John Doe",
        "sections": {
            title: [
                eval(default_entry),
                eval(default_entry),
            ],
        },
    }

    cv = dm.CurriculumVitae(**input)
    assert len(cv.sections) == 1
    assert len(cv.sections[0].entries) == 2

    # test with other entry types:
    entries = [
        (education_entry, "EducationEntry"),
        (experience_entry, "ExperienceEntry"),
        (publication_entry, "PublicationEntry"),
        (normal_entry, "NormalEntry"),
        (one_line_entry, "OneLineEntry"),
        (text_entry, "TextEntry"),
    ]
    for entry, entry_type in entries:
        input["sections"][title] = {
            "entry_type": entry_type,
            "entries": [entry, entry],
        }
        cv = dm.CurriculumVitae(**input)
        assert len(cv.sections) == 1
        assert len(cv.sections[0].entries) == 2


def test_sections_without_default_types(
    education_entry,
    experience_entry,
    publication_entry,
    normal_entry,
    one_line_entry,
    text_entry,
):
    input = {"name": "John Doe", "sections": dict()}
    entries = [
        (education_entry, "EducationEntry"),
        (experience_entry, "ExperienceEntry"),
        (publication_entry, "PublicationEntry"),
        (normal_entry, "NormalEntry"),
        (one_line_entry, "OneLineEntry"),
        (text_entry, "TextEntry"),
    ]
    for i, (entry, entry_type) in enumerate(entries):
        input["sections"][f"My Section {i}"] = {
            "entry_type": entry_type,
            "entries": [entry, entry],
        }

    cv = dm.CurriculumVitae(**input)
    assert len(cv.sections) == len(entries)
    for i, entry in enumerate(entries):
        assert len(cv.sections[i].entries) == 2


def test_section_with_invalid_entry_type():
    input = {"name": "John Doe", "sections": dict()}
    input["sections"]["My Section"] = {
        "entry_type": "InvalidEntryType",
        "entries": [],
    }
    with pytest.raises(pydantic.ValidationError):
        dm.CurriculumVitae(**input)


@pytest.mark.parametrize(
    "section_title",
    [
        "Education",
        "Experience",
        "Work Experience",
        "Research Experience",
        "Publications",
        "Papers",
        "Projects",
        "Academic Projects",
        "University Projects",
        "Personal Projects",
        "Certificates",
        "Extracurricular Activities",
        "Test Scores",
        "Skills",
        "Programming Skills",
        "Other Skills",
        "Awards",
        "Interests",
        "Summary",
        "My Custom Section",
    ],
)
def test_sections_with_invalid_entries(section_title):
    input = {"name": "John Doe", "sections": dict()}
    input["sections"][section_title] = [{
        "this": "is",
        "an": "invalid",
        "entry": 10,
    }]
    with pytest.raises(pydantic.ValidationError):
        dm.CurriculumVitae(**input)
