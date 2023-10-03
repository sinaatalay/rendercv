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

    def test_data_cv_name(self):
        cv_dict = {"name": "John Doe Test"}
        cv = data_model.CurriculumVitae(**cv_dict)
        self.assertEqual(cv.name, "John Doe Test")

        with self.assertRaises(ValidationError):
            cv_dict = {}
            data_model.CurriculumVitae(**cv_dict)

    def test_data_cv_email(self):
        # Test invalid emails
        cv_dict = {"name": "John Doe", "email": "wrongEmail"}
        with self.assertRaises(ValidationError):
            data_model.CurriculumVitae(**cv_dict)

        cv_dict["email"] = "anotherWrongEmail@.com"
        with self.assertRaises(ValidationError):
            data_model.CurriculumVitae(**cv_dict)

        # Test empty email field
        cv_dict["email"] = ""
        with self.assertRaises(ValidationError):
            data_model.CurriculumVitae(**cv_dict)

        # Test valid email
        cv_dict["email"] = "johndoe@example.com"
        cv = data_model.CurriculumVitae(**cv_dict)
        self.assertEqual(cv.email, "johndoe@example.com")

    def test_data_cv_phone(self):
        # Test invalid phone numbers
        cv_dict = {"name": "John Doe", "phone": "123456789"}
        with self.assertRaises(ValidationError):
            data_model.CurriculumVitae(**cv_dict)

        cv_dict["phone"] = "12"
        with self.assertRaises(ValidationError):
            data_model.CurriculumVitae(**cv_dict)

        # Test empty phone field
        cv_dict["phone"] = ""
        with self.assertRaises(ValidationError):
            data_model.CurriculumVitae(**cv_dict)

        # Test valid phone numbers
        cv_dict["phone"] = "+1-512-456-9999"
        cv = data_model.CurriculumVitae(**cv_dict)
        self.assertEqual(cv.phone, "tel:+1-512-456-9999")

        cv_dict["phone"] = "+90(555) 555 55 55"
        cv = data_model.CurriculumVitae(**cv_dict)
        self.assertEqual(cv.phone, "tel:+90-555-555-55-55")

        cv_dict["phone"] = "+86 139 1099 8888"
        cv = data_model.CurriculumVitae(**cv_dict)
        self.assertEqual(cv.phone, "tel:+86-139-1099-8888")
    
    def test_data_cv_website(self):
        # Test invalid website
        cv_dict = {"name": "John Doe", "website": "wrongWebsite"}
        with self.assertRaises(ValidationError):
            data_model.CurriculumVitae(**cv_dict)

        cv_dict["website"] = "anotherWrongWebsit@e.com"
        with self.assertRaises(ValidationError):
            data_model.CurriculumVitae(**cv_dict)

        # Test empty website field
        cv_dict["website"] = ""
        with self.assertRaises(ValidationError):
            data_model.CurriculumVitae(**cv_dict)

        # Test valid websites
        cv_dict["website"] = "https://example.com"
        cv = data_model.CurriculumVitae(**cv_dict)
        self.assertEqual(cv.website, Url("https://example.com/"))

        cv_dict["website"] = "http://www.example.com"
        cv = data_model.CurriculumVitae(**cv_dict)
        self.assertEqual(cv.website, Url("http://www.example.com/"))

if __name__ == "__main__":
    unittest.main()
