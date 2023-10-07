import unittest
from rendercv import data_model, rendering

from datetime import date as Date
from pydantic import ValidationError
from pydantic_core import Url


class TestRendercv(unittest.TestCase):
    def test_check_spelling(self):
        sentences = [
            "This is a sentence.",
            "This is a sentance with special characters &@#&^@*#&)((!@#_)()).",
            r"12312309 Thisdf sdfsd is a sentence *safds\{\}[[[]]]",
        ]

        for sentence in sentences:
            data_model.check_spelling(sentence)

    def test_compute_time_span_string(self):
        start_date = Date(year=2020, month=1, day=1)
        end_date = Date(year=2021, month=1, day=1)
        expected = "1 year 1 month"
        result = data_model.compute_time_span_string(start_date, end_date)
        self.assertEqual(result, expected)

        start_date = Date(year=2020, month=1, day=1)
        end_date = Date(year=2020, month=2, day=1)
        expected = "1 month"
        result = data_model.compute_time_span_string(start_date, end_date)
        self.assertEqual(result, expected)

        start_date = Date(year=2020, month=1, day=1)
        end_date = Date(year=2023, month=3, day=2)
        expected = "3 years 2 months"
        result = data_model.compute_time_span_string(start_date, end_date)
        self.assertEqual(result, expected)

        start_date = Date(year=2020, month=1, day=1)
        end_date = Date(year=1982, month=1, day=1)
        with self.assertRaises(ValueError):
            data_model.compute_time_span_string(start_date, end_date)

    def test_format_date(self):
        date = Date(year=2020, month=1, day=1)
        expected = "Jan. 2020"
        result = data_model.format_date(date)
        self.assertEqual(result, expected)

        date = Date(year=1983, month=12, day=1)
        expected = "Dec. 1983"
        result = data_model.format_date(date)
        self.assertEqual(result, expected)

        date = Date(year=2045, month=6, day=1)
        expected = "June 2045"
        result = data_model.format_date(date)
        self.assertEqual(result, expected)

    def test_data_Event_check_dates(self):
        # Inputs with correct dates:
        inputs = [
            {
                "start_date": Date(year=2020, month=1, day=1),
                "end_date": Date(year=2021, month=1, day=1),
            },
            {
                "start_date": Date(year=2020, month=1, day=1),
                "end_date": None,
            },
            {
                "start_date": Date(year=2020, month=1, day=1),
                "end_date": "present",
            },
            {"date": "My Birthday"},
        ]

        for input in inputs:
            with self.subTest(msg="start_date < end_date"):
                data_model.Event(**input)

        # Inputs with incorrect dates:
        inputs = [
            {
                "start_date": Date(year=2020, month=1, day=1),
                "end_date": Date(year=2019, month=1, day=1),
            },
            {
                "start_date": Date(year=2020, month=1, day=1),
                "end_date": Date(year=2400, month=1, day=1),
            },
        ]
        for input in inputs:
            with self.subTest(msg="start_date > end_date"):
                with self.assertRaises(ValidationError):
                    data_model.Event(**input)

        # Other inputs:
        input = {
            "start_date": Date(year=2020, month=1, day=1),
            "end_date": "present",
            "date": "My Birthday",
        }
        event = data_model.Event(**input)
        with self.subTest(msg="start_date, end_date, and date are all provided"):
            self.assertEqual(event.date, None)
            self.assertEqual(event.start_date, input["start_date"])
            self.assertEqual(event.end_date, input["end_date"])

        input = {
            "start_date": Date(year=2020, month=1, day=1),
            "end_date": None,
            "date": "My Birthday",
        }
        event = data_model.Event(**input)
        with self.subTest(msg="start_date and date are provided"):
            self.assertEqual(event.start_date, None)
            self.assertEqual(event.end_date, None)
            self.assertEqual(event.date, input["date"])

        input = {
            "start_date": None,
            "end_date": Date(year=2020, month=1, day=1),
            "date": "My Birthday",
        }
        event = data_model.Event(**input)
        with self.subTest(msg="end_date and date are provided"):
            self.assertEqual(event.start_date, None)
            self.assertEqual(event.end_date, None)
            self.assertEqual(event.date, input["date"])

        input = {
            "start_date": None,
            "end_date": None,
            "date": "My Birthday",
        }
        event = data_model.Event(**input)
        with self.subTest(msg="only date is provided"):
            self.assertEqual(event.start_date, None)
            self.assertEqual(event.end_date, None)
            self.assertEqual(event.date, input["date"])


if __name__ == "__main__":
    unittest.main()
