import unittest
import os
import json

from rendercv import data_model

from datetime import date as Date
from pydantic import ValidationError


class TestDataModel(unittest.TestCase):
    def test_escape_latex_characters(self):
        tests = [
            {
                "input": "This is a string without LaTeX characters.",
                "expected": "This is a string without LaTeX characters.",
                "msg": "string without LaTeX characters",
            },
            {
                "input": r"asdf#asdf$asdf%asdf& ~ fd_ \ ^aa aa{ bb}",
                "expected": (
                    r"asdf\#asdf$asdf\%asdf\& \textasciitilde{} fd_ \ ^aa aa{ bb}"
                ),
                "msg": "string with LaTeX characters",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                result = data_model.escape_latex_characters(test["input"])
                self.assertEqual(result, test["expected"])

    def test_compute_time_span_string(self):
        # Valid inputs:
        tests = [
            {
                "start_date": Date(year=2020, month=1, day=1),
                "end_date": Date(year=2021, month=1, day=1),
                "expected": "1 year 1 month",
                "msg": "1 year 1 month",
            },
            {
                "start_date": Date(year=2020, month=1, day=1),
                "end_date": Date(year=2020, month=2, day=1),
                "expected": "1 month",
                "msg": "1 month",
            },
            {
                "start_date": Date(year=2020, month=1, day=1),
                "end_date": Date(year=2023, month=3, day=2),
                "expected": "3 years 2 months",
                "msg": "3 years 2 months",
            },
            {
                "start_date": Date(year=2020, month=1, day=1),
                "end_date": 2021,
                "expected": "1 year 1 month",
                "msg": "start_date and YYYY end_date",
            },
            {
                "start_date": 2020,
                "end_date": Date(year=2021, month=1, day=1),
                "expected": "1 year 1 month",
                "msg": "YYYY start_date and end_date",
            },
            {
                "start_date": 2020,
                "end_date": 2021,
                "expected": "1 year 1 month",
                "msg": "YYYY start_date and YYYY end_date",
            },
            {
                "start_date": None,
                "end_date": Date(year=2023, month=3, day=2),
                "expected": TypeError,
                "msg": "start_date is None",
            },
            {
                "start_date": Date(year=2020, month=1, day=1),
                "end_date": None,
                "expected": TypeError,
                "msg": "end_date is None",
            },
            {
                "start_date": 324,
                "end_date": "test",
                "expected": TypeError,
                "msg": "start_date and end_date are not dates",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                if isinstance(test["expected"], type):
                    if issubclass(test["expected"], Exception):
                        with self.assertRaises(test["expected"]):
                            data_model.compute_time_span_string(
                                test["start_date"], test["end_date"]
                            )
                else:
                    result = data_model.compute_time_span_string(
                        test["start_date"], test["end_date"]
                    )
                    self.assertEqual(result, test["expected"])

    def test_format_date(self):
        tests = [
            {
                "date": Date(year=2020, month=1, day=1),
                "expected": "Jan. 2020",
                "msg": "Jan. 2020",
            },
            {
                "date": Date(year=1983, month=12, day=1),
                "expected": "Dec. 1983",
                "msg": "Dec. 1983",
            },
            {
                "date": Date(year=2045, month=6, day=1),
                "expected": "June 2045",
                "msg": "June 2045",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                result = data_model.format_date(test["date"])
                self.assertEqual(result, test["expected"])

    def test_data_design_font(self):
        tests = [
            {"input": "SourceSans3", "expected": "SourceSans3", "msg": "valid font"},
            {
                "input": "InvalidFont",
                "expected": ValidationError,
                "msg": "invalid font",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                if isinstance(test["expected"], type):
                    if issubclass(test["expected"], Exception):
                        with self.assertRaises(test["expected"]):
                            data_model.Design(font=test["input"])
                else:
                    design = data_model.Design(font=test["input"])
                    self.assertEqual(design.font, test["expected"])

    def test_data_design_theme(self):
        tests = [
            {"input": "classic", "expected": "classic", "msg": "valid theme"},
            {
                "input": "InvalidTheme",
                "expected": ValidationError,
                "msg": "invalid theme",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                if isinstance(test["expected"], type):
                    if issubclass(test["expected"], Exception):
                        with self.assertRaises(test["expected"]):
                            data_model.Design(theme=test["input"])
                else:
                    design = data_model.Design(theme=test["input"])
                    self.assertEqual(design.theme, test["expected"])

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
        # All the combinations are tried. In valid dates:
        # Start dates can be 4 different things: YYYY-MM-DD, YYYY-MM, YYYY.
        # End dates can be 5 different things: YYYY-MM-DD, YYYY-MM, YYYY, or "present" or None.
        start_dates = [
            {
                "input": "2020-01-01",
                "expected": Date.fromisoformat("2020-01-01"),
            },
            {
                "input": "2020-01",
                "expected": Date.fromisoformat("2020-01-01"),
            },
            {
                "input": "2020",
                "expected": 2020,
            },
        ]

        end_dates = [
            {
                "input": "2021-01-01",
                "expected": Date.fromisoformat("2021-01-01"),
            },
            {
                "input": "2021-01",
                "expected": Date.fromisoformat("2021-01-01"),
            },
            {
                "input": "2021",
                "expected": 2021,
            },
            {
                "input": "present",
                "expected": "present",
            },
            {
                "input": None,
                "expected": "present",
            },
        ]

        combinations = [
            (start_date, end_date)
            for start_date in start_dates
            for end_date in end_dates
        ]
        for start_date, end_date in combinations:
            with self.subTest(
                msg=f"valid: {start_date['expected']} to {end_date['expected']}"
            ):
                event = data_model.Event(
                    start_date=start_date["input"], end_date=end_date["input"]
                )
                self.assertEqual(event.start_date, start_date["expected"])
                self.assertEqual(event.end_date, end_date["expected"])

        # Valid dates but edge cases:
        tests = [
            {
                "input": {
                    "start_date": None,
                    "end_date": None,
                    "date": "My Birthday",
                },
                "expected": {
                    "start_date": None,
                    "end_date": None,
                    "date": "My Birthday",
                },
                "msg": "valid: custom date only",
            },
            {
                "input": {
                    "start_date": None,
                    "end_date": None,
                    "date": "2020-01-01",
                },
                "expected": {
                    "start_date": None,
                    "end_date": None,
                    "date": Date.fromisoformat("2020-01-01"),
                },
                "msg": "valid: YYYY-MM-DD date only",
            },
            {
                "input": {
                    "start_date": "2020-01-01",
                    "end_date": "present",
                    "date": "My Birthday",
                },
                "expected": {
                    "start_date": Date.fromisoformat("2020-01-01"),
                    "end_date": "present",
                    "date": None,
                },
                "msg": "valid: start_date, end_date, and date",
            },
            {
                "input": {
                    "start_date": "2020-01-01",
                    "end_date": None,
                    "date": "My Birthday",
                },
                "expected": {
                    "start_date": None,
                    "end_date": None,
                    "date": "My Birthday",
                },
                "msg": "valid: start_date and date",
            },
            {
                "input": {
                    "start_date": None,
                    "end_date": "2020-01-01",
                    "date": "My Birthday",
                },
                "expected": {
                    "start_date": None,
                    "end_date": None,
                    "date": "My Birthday",
                },
                "msg": "valid: end_date and date",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                event = data_model.Event(**test["input"])
                self.assertEqual(event.start_date, test["expected"]["start_date"])
                self.assertEqual(event.end_date, test["expected"]["end_date"])
                self.assertEqual(event.date, test["expected"]["date"])

        # Inputs without dates:
        with self.subTest(msg="no dates"):
            event = data_model.Event(**{})
            self.assertEqual(event.start_date, None, msg="Start date is not correct.")
            self.assertEqual(event.end_date, None, msg="End date is not correct.")
            self.assertEqual(event.date, None, msg="Date is not correct.")

        # Invalid dates:
        tests = [
            {
                "input": {
                    "start_date": "2020-01-01",
                    "end_date": "2019-01-01",
                },
                "expected": ValidationError,
                "msg": "start_date > end_date",
            },
            {
                "input": {
                    "start_date": "2020-01-01",
                    "end_date": "2900-01-01",
                },
                "expected": ValidationError,
                "msg": "end_date > present",
            },
            {
                "input": {
                    "start_date": "invalid date",
                    "end_date": "invalid date",
                },
                "expected": ValidationError,
                "msg": "invalid start_date and end_date",
            },
            {
                "input": {
                    "start_date": "invalid date",
                    "end_date": "2020-01-01",
                },
                "expected": ValidationError,
                "msg": "invalid start_date",
            },
            {
                "input": {
                    "start_date": "2020-01-01",
                    "end_date": "invalid date",
                },
                "expected": ValidationError,
                "msg": "invalid end_date",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                with self.assertRaises(test["expected"]):
                    data_model.Event(**test["input"])

    def test_data_event_date_and_location_strings(self):
        tests = [
            {
                "input": {
                    "start_date": "2020-01-01",
                    "end_date": "2021-01-16",
                    "location": "My Location",
                },
                "expected_with_time_span": [
                    "My Location",
                    "Jan. 2020 to Jan. 2021",
                    "1 year 1 month",
                ],
                "expected_without_time_span": [
                    "My Location",
                    "Jan. 2020 to Jan. 2021",
                ],
                "msg": "start_date, end_date, and location are provided",
            },
            {
                "input": {
                    "date": "My Birthday",
                    "location": "My Location",
                },
                "expected_with_time_span": [
                    "My Location",
                    "My Birthday",
                ],
                "expected_without_time_span": [
                    "My Location",
                    "My Birthday",
                ],
                "msg": "date and location are provided",
            },
            {
                "input": {
                    "date": "2020-01-01",
                },
                "expected_with_time_span": [
                    "Jan. 2020",
                ],
                "expected_without_time_span": [
                    "Jan. 2020",
                ],
                "msg": "date is provided",
            },
            {
                "input": {
                    "start_date": "2020-01-01",
                    "end_date": "2021-01-16",
                },
                "expected_with_time_span": [
                    "Jan. 2020 to Jan. 2021",
                    "1 year 1 month",
                ],
                "expected_without_time_span": [
                    "Jan. 2020 to Jan. 2021",
                ],
                "msg": "start_date and end_date are provided",
            },
            {
                "input": {
                    "location": "My Location",
                },
                "expected_with_time_span": [
                    "My Location",
                ],
                "expected_without_time_span": [
                    "My Location",
                ],
                "msg": "location is provided",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                event = data_model.Event(**test["input"])
                result = event.date_and_location_strings_with_timespan
                self.assertEqual(result, test["expected_with_time_span"])

                result = event.date_and_location_strings_without_timespan
                self.assertEqual(result, test["expected_without_time_span"])

    def test_data_event_highlight_strings(self):
        tests = [
            {
                "highlights": [
                    "My Highlight 1",
                    "My Highlight 2",
                ],
                "expected": [
                    "My Highlight 1",
                    "My Highlight 2",
                ],
                "msg": "highlights are provided",
            },
            {
                "highlights": [],
                "expected": [],
                "msg": "highlights are not provided",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                event = data_model.Event(highlights=test["highlights"])
                result = event.highlight_strings
                self.assertEqual(result, test["expected"])

    def test_data_event_markdown_url(self):
        tests = [
            {
                "url": "https://www.linkedin.com/in/username",
                "expected": "[view on LinkedIn](https://www.linkedin.com/in/username)",
                "msg": "LinkedIn link",
            },
            {
                "url": "https://www.github.com/sinaatalay",
                "expected": "[view on GitHub](https://www.github.com/sinaatalay)",
                "msg": "Github link",
            },
            {
                "url": "https://www.instagram.com/username",
                "expected": "[view on Instagram](https://www.instagram.com/username)",
                "msg": "Instagram link",
            },
            {
                "url": "https://www.youtube.com/",
                "expected": "[view on YouTube](https://www.youtube.com/)",
                "msg": "Youtube link",
            },
            {
                "url": "https://www.google.com/",
                "expected": "[view on my website](https://www.google.com/)",
                "msg": "Other links",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                event = data_model.Event(url=test["url"])
                result = event.markdown_url
                self.assertEqual(result, test["expected"])

    def test_data_event_month_and_year(self):
        tests = [
            {
                "input": {
                    "start_date": "2020-01-01",
                    "end_date": "2021-01-16",
                },
                "expected": None,
                "msg": "start_date and end_date are provided",
            },
            {
                "input": {
                    "date": "My Birthday",
                },
                "expected": "My Birthday",
                "msg": "custom date is provided",
            },
            {
                "input": {
                    "date": "2020-01-01",
                },
                "expected": "Jan. 2020",
                "msg": "date is provided",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                event = data_model.Event(**test["input"])
                result = event.month_and_year
                self.assertEqual(result, test["expected"])

    def test_data_education_entry_highlight_strings(self):
        tests = [
            {
                "input": {
                    "institution": "My Institution",
                    "area": "My Area",
                    "gpa": 3.5,
                    "highlights": [
                        "My Highlight 1",
                        "My Highlight 2",
                    ],
                },
                "expected": [
                    "GPA: 3.5",
                    "My Highlight 1",
                    "My Highlight 2",
                ],
                "msg": "gpa and highlights are provided",
            },
            {
                "input": {
                    "institution": "My Institution",
                    "area": "My Area",
                    "gpa": None,
                    "highlights": [
                        "My Highlight 1",
                        "My Highlight 2",
                    ],
                },
                "expected": [
                    "My Highlight 1",
                    "My Highlight 2",
                ],
                "msg": "gpa is not provided, but highlights are",
            },
            {
                "input": {
                    "institution": "My Institution",
                    "area": "My Area",
                    "gpa": 3.5,
                    "highlights": [],
                },
                "expected": [
                    "GPA: 3.5",
                ],
                "msg": "gpa is provided, but highlights are not",
            },
            {
                "input": {
                    "institution": "My Institution",
                    "area": "My Area",
                    "gpa": None,
                    "highlights": [],
                },
                "expected": [],
                "msg": "neither gpa nor highlights are provided",
            },
            {
                "input": {
                    "institution": "My Institution",
                    "area": "My Area",
                    "gpa": 3.5,
                    "transcript_url": "https://www.example.com/",
                    "highlights": None,
                },
                "expected": [
                    "GPA: 3.5 ([Transcript](https://www.example.com/))",
                ],
                "msg": "gpa and transcript_url are provided, but highlights are not",
            },
            {
                "input": {
                    "institution": "My Institution",
                    "area": "My Area",
                    "gpa": "3.5",
                    "transcript_url": "https://www.example.com/",
                    "highlights": [
                        "My Highlight 1",
                        "My Highlight 2",
                    ],
                },
                "expected": [
                    "GPA: 3.5 ([Transcript](https://www.example.com/))",
                    "My Highlight 1",
                    "My Highlight 2",
                ],
                "msg": "gpa, transcript_url, and highlights are provided",
            },
        ]

        for test in tests:
            with self.subTest(msg=test["msg"]):
                education = data_model.EducationEntry(**test["input"])
                result = education.highlight_strings
                self.assertEqual(result, test["expected"])

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
        self.assertEqual(result, expected)

    def test_data_connection_url(self):
        tests = [
            {
                "input": {
                    "name": "LinkedIn",
                    "value": "username",
                },
                "expected": "https://www.linkedin.com/in/username",
            },
            {
                "input": {
                    "name": "GitHub",
                    "value": "sinaatalay",
                },
                "expected": "https://www.github.com/sinaatalay",
            },
            {
                "input": {
                    "name": "Instagram",
                    "value": "username",
                },
                "expected": "https://www.instagram.com/username",
            },
            {
                "input": {
                    "name": "phone",
                    "value": "+909999999999",
                },
                "expected": "+909999999999",
            },
            {
                "input": {
                    "name": "email",
                    "value": "example@example.com",
                },
                "expected": "mailto:example@example.com",
            },
            {
                "input": {
                    "name": "website",
                    "value": "https://www.example.com/",
                },
                "expected": "https://www.example.com/",
            },
            {
                "input": {
                    "name": "location",
                    "value": "My Location",
                },
                "expected": None,
            },
        ]

        for test in tests:
            with self.subTest(msg=test["input"]["name"]):
                connection = data_model.Connection(**test["input"])
                result = connection.url
                self.assertEqual(result, test["expected"])

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
                    "link_text": "My Custom Link Text",
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

        with self.subTest(msg="check link_text"):
            cv = data_model.CurriculumVitae(**input)
            self.assertEqual(cv.sections[1].link_text, "My Custom Link Text")

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

    def test_read_input_file(self):
        test_input = {
            "cv": {
                "name": "John Doe",
            }
        }

        # write dictionary to a file as json:
        input_file_path = os.path.join(os.path.dirname(__file__), "test_input.json")
        json_string = json.dumps(test_input)
        with open(input_file_path, "w") as file:
            file.write(json_string)

        # read the file:
        result = data_model.read_input_file(input_file_path)

        # remove the file:
        os.remove(input_file_path)

        with self.subTest(msg="read input file"):
            self.assertEqual(
                result.cv.name,
                test_input["cv"]["name"],
            )

        with self.subTest(msg="nonexistent file"):
            with self.assertRaises(FileNotFoundError):
                data_model.read_input_file("nonexistent.json")
