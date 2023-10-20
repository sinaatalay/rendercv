import unittest
import os
import json

from rendercv import data_model

from datetime import date as Date
from pydantic import ValidationError


class TestDataModel(unittest.TestCase):
    def test_check_spelling(self):
        sentences = [
            "This is a sentence.",
            "This is a sentance with special characters &@#&^@*#&)((!@#_)()).",
            r"12312309 Thisdf sdfsd is a sentence *safds\{\}[[[]]]",
        ]

        for sentence in sentences:
            with self.subTest(sentence=sentence):
                data_model.check_spelling(sentence)

    def test_compute_time_span_string(self):
        start_date = Date(year=2020, month=1, day=1)
        end_date = Date(year=2021, month=1, day=1)
        expected = "1 year 1 month"
        result = data_model.compute_time_span_string(start_date, end_date)
        with self.subTest(expected=expected):
            self.assertEqual(result, expected)

        start_date = Date(year=2020, month=1, day=1)
        end_date = Date(year=2020, month=2, day=1)
        expected = "1 month"
        result = data_model.compute_time_span_string(start_date, end_date)
        with self.subTest(expected=expected):
            self.assertEqual(result, expected)

        start_date = Date(year=2020, month=1, day=1)
        end_date = Date(year=2023, month=3, day=2)
        expected = "3 years 2 months"
        result = data_model.compute_time_span_string(start_date, end_date)
        with self.subTest(expected=expected):
            self.assertEqual(result, expected)

        start_date = Date(year=2020, month=1, day=1)
        end_date = Date(year=1982, month=1, day=1)
        with self.subTest(msg="start_date > end_date"):
            with self.assertRaises(ValueError):
                data_model.compute_time_span_string(start_date, end_date)

        # invalid inputs:
        start_date = None
        end_date = Date(year=2023, month=3, day=2)
        with self.subTest(msg="start_date is None"):
            with self.assertRaises(TypeError):
                data_model.compute_time_span_string(start_date, end_date)  # type: ignore

        start_date = Date(year=2020, month=1, day=1)
        end_date = None
        with self.subTest(msg="end_date is None"):
            with self.assertRaises(TypeError):
                data_model.compute_time_span_string(start_date, end_date)  # type: ignore

        start_date = 324
        end_date = "test"
        with self.subTest(msg="start_date and end_date are not dates"):
            with self.assertRaises(TypeError):
                data_model.compute_time_span_string(start_date, end_date)  # type: ignore

    def test_format_date(self):
        date = Date(year=2020, month=1, day=1)
        expected = "Jan. 2020"
        result = data_model.format_date(date)
        with self.subTest(expected=expected):
            self.assertEqual(result, expected)

        date = Date(year=1983, month=12, day=1)
        expected = "Dec. 1983"
        result = data_model.format_date(date)
        with self.subTest(expected=expected):
            self.assertEqual(result, expected)

        date = Date(year=2045, month=6, day=1)
        expected = "June 2045"
        result = data_model.format_date(date)
        with self.subTest(expected=expected):
            self.assertEqual(result, expected)

    def test_data_design_font(self):
        # Valid font:
        input = {
            "font": "SourceSans3",
        }
        with self.subTest(msg="valid font"):
            design = data_model.Design(**input)  # type: ignore
            self.assertEqual(design.font, input["font"])

        # Invalid font:
        input = {
            "font": "InvalidFont",
        }
        with self.subTest(msg="invalid font"):
            with self.assertRaises(ValidationError):
                data_model.Design(**input)  # type: ignore

    def test_data_design_theme(self):
        # Valid theme:
        input = {
            "theme": "classic",
        }
        with self.subTest(msg="valid theme"):
            design = data_model.Design(**input)  # type: ignore
            self.assertEqual(design.theme, input["theme"])

        # Nonexistent theme:
        input = {
            "theme": "nonexistent",
        }
        with self.subTest(msg="nonexistent theme"):
            with self.assertRaises(ValidationError):
                data_model.Design(**input)  # type: ignore

    def test_data_design_show_timespan_in(self):
        # Valid show_timespan_in:
        input = {
            "design": {
                "options": {
                    "show_timespan_in": ["Work Experience"],
                }
            },
            "cv": {
                "name": "John Doe",
                "work_experience": [
                    {
                        "company": "My Company",
                        "position": "My Position",
                        "start_date": "2020-01-01",
                        "end_date": "2021-01-01",
                    }
                ],
            },
        }
        with self.subTest(msg="valid show_timespan_in"):
            data_model.RenderCVDataModel(**input)

        # Nonexistent show_timespan_in:
        del input["cv"]["work_experience"]
        with self.subTest(msg="nonexistent show_timespan_in"):
            with self.assertRaises(ValidationError):
                data_model.RenderCVDataModel(**input)

    def test_data_event_check_dates(self):
        # Inputs with valid dates:
        input = {
            "start_date": "2020-01-01",
            "end_date": "2021-01-01",
            "date": None,
        }
        with self.subTest(msg="valid date with start_date and end_date"):
            event = data_model.Event(**input)
            self.assertEqual(event.start_date, Date.fromisoformat(input["start_date"]))
            self.assertEqual(event.end_date, Date.fromisoformat(input["end_date"]))
            self.assertEqual(event.date, None)

        input = {
            "start_date": "2020-01-01",
            "end_date": None,
            "date": None,
        }
        with self.subTest(msg="valid date with start_date"):
            event = data_model.Event(**input)
            self.assertEqual(
                event.start_date,
                Date.fromisoformat(input["start_date"]),
                msg="Start date is not correct.",
            )
            self.assertEqual(event.end_date, "present", msg="End date is not correct.")
            self.assertEqual(event.date, None, msg="Date is not correct.")

        input = {
            "start_date": "2020-01-01",
            "end_date": "present",
            "date": None,
        }
        with self.subTest(msg="valid date with start_date and end_date=present"):
            event = data_model.Event(**input)
            self.assertEqual(
                event.start_date,
                Date.fromisoformat(input["start_date"]),
                msg="Start date is not correct.",
            )
            self.assertEqual(event.end_date, "present", msg="End date is not correct.")
            self.assertEqual(event.date, None, msg="Date is not correct.")

        input = {
            "start_date": None,
            "end_date": None,
            "date": "My Birthday",
        }
        with self.subTest(msg="valid date with custom date"):
            event = data_model.Event(**input)
            self.assertEqual(event.start_date, None, msg="Start date is not correct.")
            self.assertEqual(event.end_date, None, msg="End date is not correct.")
            self.assertEqual(event.date, input["date"], msg="Date is not correct.")

        input = {
            "start_date": None,
            "end_date": None,
            "date": "2020-01-01",
        }
        with self.subTest(msg="valid date with ISO date"):
            event = data_model.Event(**input)
            self.assertEqual(event.start_date, None, msg="Start date is not correct.")
            self.assertEqual(event.end_date, None, msg="End date is not correct.")
            self.assertEqual(
                event.date,
                Date.fromisoformat(input["date"]),
                msg="Date is not correct.",
            )

        input = {
            "start_date": "2020-01-01",
            "end_date": "present",
            "date": "My Birthday",
        }
        event = data_model.Event(**input)  # type: ignore
        with self.subTest(msg="start_date, end_date, and date are all provided"):
            self.assertEqual(event.date, None, msg="Date is not correct.")
            self.assertEqual(
                event.start_date,
                Date.fromisoformat(input["start_date"]),
                msg="Start date is not correct.",
            )
            self.assertEqual(
                event.end_date, input["end_date"], msg="End date is not correct."
            )

        input = {
            "start_date": "2020-01-01",
            "end_date": None,
            "date": "My Birthday",
        }
        event = data_model.Event(**input)
        with self.subTest(msg="start_date and date are provided"):
            self.assertEqual(event.start_date, None, msg="Start date is not correct.")
            self.assertEqual(event.end_date, None, msg="End date is not correct.")
            self.assertEqual(event.date, input["date"], msg="Date is not correct.")

        input = {
            "start_date": None,
            "end_date": "2020-01-01",
            "date": "My Birthday",
        }
        event = data_model.Event(**input)
        with self.subTest(msg="end_date and date are provided"):
            self.assertEqual(event.start_date, None, msg="Start date is not correct.")
            self.assertEqual(event.end_date, None, msg="End date is not correct.")
            self.assertEqual(event.date, input["date"], msg="Date is not correct.")

        input = {
            "start_date": None,
            "end_date": None,
            "date": "2020-01-01",
        }
        event = data_model.Event(**input)
        with self.subTest(msg="only date is provided"):
            self.assertEqual(event.start_date, None, msg="Start date is not correct.")
            self.assertEqual(event.end_date, None, msg="End date is not correct.")
            self.assertEqual(
                event.date,
                Date.fromisoformat(input["date"]),
                msg="Date is not correct.",
            )

        # Inputs without dates:
        with self.subTest(msg="no dates"):
            event = data_model.Event(**{})
            self.assertEqual(event.start_date, None, msg="Start date is not correct.")
            self.assertEqual(event.end_date, None, msg="End date is not correct.")
            self.assertEqual(event.date, None, msg="Date is not correct.")

        # Inputs with invalid dates:
        input = {
            "start_date": "2020-01-01",
            "end_date": "2019-01-01",
        }
        with self.subTest(msg="start_date > end_date"):
            with self.assertRaises(ValidationError):
                data_model.Event(**input)  # type: ignore

        input = {
            "start_date": "2020-01-01",
            "end_date": "2900-01-01",
        }
        with self.subTest(msg="end_date > present"):
            with self.assertRaises(ValidationError):
                data_model.Event(**input)  # type: ignore

    def test_data_event_date_and_location_strings_with_timespan(self):
        input = {
            "start_date": "2020-01-01",
            "end_date": "2021-01-16",
            "location": "My Location",
        }
        expected = [
            "My Location",
            "Jan. 2020 to Jan. 2021",
            "1 year 1 month",
        ]
        event = data_model.Event(**input)  # type: ignore
        result = event.date_and_location_strings_with_timespan
        with self.subTest(msg="start_date, end_date, and location are provided"):
            self.assertEqual(result, expected)

        input = {
            "date": "My Birthday",
            "location": "My Location",
        }
        expected = [
            "My Location",
            "My Birthday",
        ]
        event = data_model.Event(**input)  # type: ignore
        result = event.date_and_location_strings_with_timespan
        with self.subTest(msg="date and location are provided"):
            self.assertEqual(result, expected)

        input = {
            "date": "2020-01-01",
        }
        expected = [
            "Jan. 2020",
        ]
        event = data_model.Event(**input)  # type: ignore
        result = event.date_and_location_strings_with_timespan
        with self.subTest(msg="date is provided"):
            self.assertEqual(result, expected)

        input = {
            "start_date": "2020-01-01",
            "end_date": "2021-01-16",
        }
        expected = [
            "Jan. 2020 to Jan. 2021",
            "1 year 1 month",
        ]
        event = data_model.Event(**input)  # type: ignore
        result = event.date_and_location_strings_with_timespan
        with self.subTest(msg="start_date and end_date are provided"):
            self.assertEqual(result, expected)

        input = {
            "location": "My Location",
        }
        expected = [
            "My Location",
        ]
        event = data_model.Event(**input)  # type: ignore
        result = event.date_and_location_strings_with_timespan
        with self.subTest(msg="location is provided"):
            self.assertEqual(result, expected)

    def test_data_event_date_and_location_strings_without_timespan(self):
        input = {
            "start_date": "2020-01-01",
            "end_date": "2021-01-16",
            "location": "My Location",
        }
        expected = [
            "My Location",
            "Jan. 2020 to Jan. 2021",
        ]
        event = data_model.Event(**input)  # type: ignore
        result = event.date_and_location_strings_without_timespan
        with self.subTest(expected=expected):
            self.assertEqual(result, expected)

        input = {
            "date": "My Birthday",
            "location": "My Location",
        }
        expected = [
            "My Location",
            "My Birthday",
        ]
        event = data_model.Event(**input)  # type: ignore
        result = event.date_and_location_strings_without_timespan
        with self.subTest(expected=expected):
            self.assertEqual(result, expected)

    def test_data_event_highlight_strings(self):
        input = {
            "highlights": [
                "My Highlight 1",
                "My Highlight 2",
            ],
        }
        expected = [
            "My Highlight 1",
            "My Highlight 2",
        ]
        event = data_model.Event(**input)  # type: ignore
        result = event.highlight_strings
        with self.subTest(msg="highlights are provided"):
            self.assertEqual(result, expected)

        input = {}
        expected = []
        event = data_model.Event(**input)
        result = event.highlight_strings
        with self.subTest(msg="no highlights"):
            self.assertEqual(result, expected)

    def test_data_event_markdown_url(self):
        # Github link:
        input = {"url": "https://github.com/sinaatalay"}
        expected = "[view on GitHub](https://github.com/sinaatalay)"
        event = data_model.Event(**input)  # type: ignore
        result = event.markdown_url
        with self.subTest(msg="Github link"):
            self.assertEqual(result, expected)

        # LinkedIn link:
        input = {"url": "https://www.linkedin.com/"}
        expected = "[view on LinkedIn](https://www.linkedin.com/)"
        event = data_model.Event(**input)  # type: ignore
        result = event.markdown_url
        with self.subTest(msg="LinkedIn link"):
            self.assertEqual(result, expected)

        # Instagram link:
        input = {"url": "https://www.instagram.com/"}
        expected = "[view on Instagram](https://www.instagram.com/)"
        event = data_model.Event(**input)  # type: ignore
        result = event.markdown_url
        with self.subTest(msg="Instagram link"):
            self.assertEqual(result, expected)

        # Youtube link:
        input = {"url": "https://www.youtube.com/"}
        expected = "[view on YouTube](https://www.youtube.com/)"
        event = data_model.Event(**input)  # type: ignore
        result = event.markdown_url
        with self.subTest(msg="Youtube link"):
            self.assertEqual(result, expected)

        # Other links:
        input = {"url": "https://www.google.com/"}
        expected = "[view on my website](https://www.google.com/)"
        event = data_model.Event(**input)  # type: ignore
        result = event.markdown_url
        with self.subTest(msg="Other links"):
            self.assertEqual(result, expected)

    def test_data_event_month_and_year(self):
        input = {
            "start_date": "2020-01-01",
            "end_date": "2021-01-16",
        }
        expected = None
        event = data_model.Event(**input)  # type: ignore
        result = event.month_and_year
        with self.subTest(msg="start_date and end_date are provided"):
            self.assertEqual(result, expected)

        input = {
            "date": "My Birthday",
        }
        expected = "My Birthday"
        event = data_model.Event(**input)  # type: ignore
        result = event.month_and_year
        with self.subTest(msg="custom date is provided"):
            self.assertEqual(result, expected)

        input = {
            "date": "2020-01-01",
        }
        expected = "Jan. 2020"
        event = data_model.Event(**input)  # type: ignore
        result = event.month_and_year
        with self.subTest(msg="date is provided"):
            self.assertEqual(result, expected)

    def test_data_education_entry_highlight_strings(self):
        input = {
            "institution": "My Institution",
            "area": "My Area",
            "gpa": 3.5,
            "highlights": [
                "My Highlight 1",
                "My Highlight 2",
            ],
        }
        expected = [
            "GPA: 3.5",
            "My Highlight 1",
            "My Highlight 2",
        ]
        education = data_model.EducationEntry(**input)
        result = education.highlight_strings
        with self.subTest(msg="gpa and highlights are provided"):
            self.assertEqual(result, expected)

        input = {
            "institution": "My Institution",
            "area": "My Area",
            "gpa": None,
            "highlights": [
                "My Highlight 1",
                "My Highlight 2",
            ],
        }
        expected = [
            "My Highlight 1",
            "My Highlight 2",
        ]
        education = data_model.EducationEntry(**input)
        result = education.highlight_strings
        with self.subTest(msg="gpa is not provided, but highlights are"):
            self.assertEqual(result, expected)

        input = {
            "institution": "My Institution",
            "area": "My Area",
            "gpa": 3.5,
            "highlights": [],
        }
        expected = [
            "GPA: 3.5",
        ]
        education = data_model.EducationEntry(**input)
        result = education.highlight_strings
        with self.subTest(msg="gpa is provided, but highlights are not"):
            self.assertEqual(result, expected)

        input = {
            "institution": "My Institution",
            "area": "My Area",
            "gpa": None,
            "highlights": [],
        }
        expected = []
        education = data_model.EducationEntry(**input)
        result = education.highlight_strings
        with self.subTest(msg="neither gpa nor highlights are provided"):
            self.assertEqual(result, expected)

        input = {
            "institution": "My Institution",
            "area": "My Area",
            "gpa": 3.5,
            "transcript_url": "https://www.example.com/",
            "highlights": None,
        }
        expected = [
            "GPA: 3.5 ([Transcript](https://www.example.com/))",
        ]
        education = data_model.EducationEntry(**input)
        result = education.highlight_strings
        with self.subTest(
            msg="gpa and transcript_url are provided, but highlights are not"
        ):
            self.assertEqual(result, expected)

        input = {
            "institution": "My Institution",
            "area": "My Area",
            "gpa": "3.5",
            "transcript_url": "https://www.example.com/",
            "highlights": [
                "My Highlight 1",
                "My Highlight 2",
            ],
        }
        expected = [
            "GPA: 3.5 ([Transcript](https://www.example.com/))",
            "My Highlight 1",
            "My Highlight 2",
        ]
        education = data_model.EducationEntry(**input)
        result = education.highlight_strings
        with self.subTest(msg="gpa, transcript_url, and highlights are provided"):
            self.assertEqual(result, expected)

    def test_data_publication_entry_check_doi(self):
        # Invalid DOI:
        input = {
            "title": "My Publication",
            "authors": [
                "Author 1",
                "Author 2",
            ],
            "doi": "invalidDoi",
            "date": "2020-01-01",
        }
        with self.subTest(msg="invalid doi"):
            with self.assertRaises(ValidationError):
                data_model.PublicationEntry(**input)

        # Valid DOI:
        input = {
            "title": "My Publication",
            "authors": [
                "Author 1",
                "Author 2",
            ],
            "doi": "10.1103/PhysRevB.76.054309",
            "date": "2007-08-01",
        }
        with self.subTest(msg="valid doi"):
            publication_entry = data_model.PublicationEntry(**input)
            self.assertEqual(publication_entry.doi, input["doi"])

    def test_data_publication_entry_doi_url(self):
        input = {
            "title": "My Publication",
            "authors": [
                "Author 1",
                "Author 2",
            ],
            "doi": "10.1103/PhysRevB.76.054309",
            "date": "2007-08-01",
        }
        expected = "https://doi.org/10.1103/PhysRevB.76.054309"
        publication = data_model.PublicationEntry(**input)
        result = publication.doi_url
        self.assertEqual(result, expected, msg="DOI URL is not correct.")

    def test_data_connection_url(self):
        # Github link:
        inputs = [
            {"name": "LinkedIn", "value": "username"},
            {"name": "GitHub", "value": "sinaatalay"},
            {"name": "Instagram", "value": "username"},
            {"name": "phone", "value": "+909999999999"},
            {"name": "email", "value": "example@example.com"},
            {"name": "website", "value": "https://www.example.com/"},
            {"name": "location", "value": "My Location"},
        ]
        expected_results = [
            "https://www.linkedin.com/in/username",
            "https://www.github.com/sinaatalay",
            "https://www.instagram.com/username",
            "tel:+909999999999",
            "mailto:example@example.com",
            "https://www.example.com/",
            None,
        ]
        for input, expected in zip(inputs, expected_results):
            with self.subTest(type=input["name"]):
                connection = data_model.Connection(**input)  # type: ignore
                result = connection.url
                self.assertEqual(result, expected)

    def test_data_curriculum_vitae_connections(self):
        input = {
            "name": "John Doe",
            "location": "My Location",
            "phone": "+905559876543",
            "email": "john@doe.com",
            "website": "https://www.example.com/",
        }
        exptected_length = 4
        cv = data_model.CurriculumVitae(**input)  # type: ignore
        result = len(cv.connections)
        with self.subTest(msg="without social networks"):
            self.assertEqual(result, exptected_length)

        input = {
            "name": "John Doe",
            "location": "My Location",
            "phone": "+905559876543",
            "email": "john@doe.com",
            "website": "https://www.example.com/",
            "social_networks": [
                {"network": "LinkedIn", "username": "username"},
                {"network": "GitHub", "username": "sinaatalay"},
                {"network": "Instagram", "username": "username"},
            ],
        }
        exptected_length = 7
        cv = data_model.CurriculumVitae(**input)
        result = len(cv.connections)
        with self.subTest(msg="with social networks"):
            self.assertEqual(result, exptected_length)

    def test_data_curriculum_vitae_custom_sections(self):
        # Valid custom sections:
        input = {
            "name": "John Doe",
            "custom_sections": [
                {
                    "title": "My Custom Section 1",
                    "entry_type": "OneLineEntry",
                    "entries": [
                        {
                            "name": "My Custom Entry Name",
                            "details": "My Custom Entry Value",
                        },
                        {
                            "name": "My Custom Entry Name",
                            "details": "My Custom Entry Value",
                        },
                    ],
                },
                {
                    "title": "My Custom Section 2",
                    "entry_type": "NormalEntry",
                    "entries": [
                        {"name": "My Custom Entry Name"},
                        {"name": "My Custom Entry Name"},
                    ],
                },
                {
                    "title": "My Custom Section 3",
                    "entry_type": "ExperienceEntry",
                    "entries": [
                        {
                            "company": "My Custom Entry Name",
                            "position": "My Custom Entry Value",
                        },
                        {
                            "company": "My Custom Entry Name",
                            "position": "My Custom Entry Value",
                        },
                    ],
                },
                {
                    "title": "My Custom Section 4",
                    "entry_type": "EducationEntry",
                    "entries": [
                        {
                            "institution": "My Custom Entry Name",
                            "area": "My Custom Entry Value",
                        },
                        {
                            "institution": "My Custom Entry Name",
                            "area": "My Custom Entry Value",
                        },
                    ],
                },
                {
                    "title": "My Custom Section 5",
                    "entry_type": "PublicationEntry",
                    "entries": [
                        {
                            "title": "My Publication",
                            "authors": [
                                "Author 1",
                                "Author 2",
                            ],
                            "doi": "10.1103/PhysRevB.76.054309",
                            "date": "2020-01-01",
                        },
                        {
                            "title": "My Publication",
                            "authors": [
                                "Author 1",
                                "Author 2",
                            ],
                            "doi": "10.1103/PhysRevB.76.054309",
                            "date": "2020-01-01",
                        },
                    ],
                },
            ],
        }

        with self.subTest(msg="valid custom sections"):
            cv = data_model.CurriculumVitae(**input)
            self.assertEqual(len(cv.sections), 5)

        # Invalid section_order:
        input["section_order"] = ["invalid section"]
        with self.subTest(msg="invalid section_order"):
            data = data_model.CurriculumVitae(**input)
            with self.assertRaises(ValueError):
                data.sections
        del input["section_order"]

        # Custom sections with duplicate titles:
        input["custom_sections"][1]["title"] = "My Custom Section 1"
        with self.subTest(msg="custom sections with duplicate titles"):
            with self.assertRaises(ValidationError):
                data_model.CurriculumVitae(**input)

    def test_if_json_schema_is_the_latest(self):
        tests_directory = os.path.dirname(__file__)
        path_to_generated_schema = data_model.generate_json_schema(tests_directory)

        # Read the generated JSON schema:
        with open(path_to_generated_schema, "r") as f:
            generated_json_schema = json.load(f)

        # Remove the generated JSON schema:
        os.remove(path_to_generated_schema)

        # Read the repository's current JSON schema:
        path_to_schema = os.path.join(os.path.dirname(tests_directory), "schema.json")
        with open(path_to_schema, "r") as f:
            current_json_schema = json.load(f)

        # Compare the two JSON schemas:
        self.assertEqual(generated_json_schema, current_json_schema)
