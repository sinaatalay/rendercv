import unittest
from rendercv import data_model, rendering

from datetime import date as Date


class TestRendercv(unittest.TestCase):
    def test_check_spelling(self):
        sentences = [
            "This is a sentence.",
            "This is a sentance with special characters &@#&^@*#&)((!@#_)()).",
            "12312309 Thisdf sdfsd is a sentence *safds\{\}[[[]]]",
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


if __name__ == "__main__":
    unittest.main()
