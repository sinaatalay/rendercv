import pytest
import time_machine

from rendercv import data_models as dm

import pydantic


@pytest.fixture
def publication_entry():
    return {
        "title": "My Title",
        "authors": ["John Doe", "Jane Doe"],
        "doi": "10.1109/TASC.2023.3340648",
        "date": "2023-12-08",
    }


@pytest.fixture
def experience_entry():
    return {
        "company": "CERN",
        "position": "Researcher",
    }


@pytest.fixture
def education_entry():
    return {
        "institution": "Boğaziçi University",
        "area": "Mechanical Engineering",
    }


@pytest.fixture
def normal_entry():
    return {
        "name": "My Entry",
    }


@pytest.fixture
def one_line_entry():
    return {
        "name": "My One Line Entry",
        "details": "My Details",
    }


@pytest.fixture
def text_entry():
    return "My Text Entry"


@pytest.mark.parametrize(
    "start_date, end_date, date, expected_date_string, expected_time_span",
    [
        ("2020-01-01", "2021-01-01", None, "Jan. 2020 to Jan. 2021", "1 year 1 month"),
        ("2020-01", "2021-01", None, "Jan. 2020 to Jan. 2021", "1 year 1 month"),
        ("2020-01", "2021-01-01", None, "Jan. 2020 to Jan. 2021", "1 year 1 month"),
        ("2020-01-01", "2021-01", None, "Jan. 2020 to Jan. 2021", "1 year 1 month"),
        ("2020-01-01", None, None, "Jan. 2020 to present", "4 years 1 month"),
        ("2020-02-01", "present", None, "Feb. 2020 to present", "3 years 11 months"),
        ("2020-01-01", "2021-01-01", "2023-02-01", "Feb. 2023", None),
        ("2020", "2021", None, "2020 to 2021", "1 year"),
        ("2020", None, None, "2020 to present", "4 years"),
        ("2020-10-10", "2022", None, "Oct. 2020 to 2022", "2 years"),
        ("2022", "2023-10-10", None, "2022 to Oct. 2023", "1 year"),
        ("2020-01-01", "present", "My Custom Date", "My Custom Date", None),
        ("2020-01-01", None, "My Custom Date", "My Custom Date", None),
        (None, None, "My Custom Date", "My Custom Date", None),
        (None, "2020-01-01", "My Custom Date", "My Custom Date", None),
        (None, None, None, None, None),
    ],
)
@time_machine.travel("2024-01-01")
def test_dates(start_date, end_date, date, expected_date_string, expected_time_span):
    entry_base = dm.EntryBase(start_date=start_date, end_date=end_date, date=date)

    assert entry_base.date_string == expected_date_string
    assert entry_base.time_span_string == expected_time_span


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
