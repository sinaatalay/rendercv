import unittest
import os
import shutil
import subprocess
import sys

from rendercv import rendering, data_model


class TestCLI(unittest.TestCase):
    def test_render(self):
        # Change the working directory to the root of the project:
        workspace_path = os.path.dirname(os.path.dirname(__file__))

        test_input_file_path = os.path.join(
            workspace_path, "tests", "reference_files", "John_Doe_CV_test.yaml"
        )
        subprocess.run(
            [sys.executable, "-m", "rendercv", "render", test_input_file_path],
            check=True,
        )

        # Read the necessary information and remove the output directory:
        output_file_path = os.path.join(workspace_path, "output", "John_Doe_CV.pdf")
        pdf_file_size = os.path.getsize(output_file_path)
        file_exists = os.path.exists(output_file_path)
        shutil.rmtree(os.path.join(workspace_path, "output"))

        # Check if the output file exists:
        self.assertTrue(file_exists, msg="PDF file couldn't be generated.")

        # Compare the pdf file with the reference pdf file:
        reference_pdf_file = os.path.join(
            workspace_path, "tests", "reference_files", "John_Doe_CV_reference.pdf"
        )
        reference_pdf_file_size = os.path.getsize(reference_pdf_file)
        ratio = min(reference_pdf_file_size, pdf_file_size) / max(
            reference_pdf_file_size, pdf_file_size
        )
        self.assertTrue(ratio > 0.98, msg="PDF file didn't match the reference.")

        # Wrong input:
        with self.subTest(msg="Wrong input"):
            with self.assertRaises(subprocess.CalledProcessError):
                subprocess.run(
                    [
                        sys.executable,
                        "-m",
                        "rendercv",
                        "wrong_input.yaml",
                    ],
                    check=True,
                )

    def test_new(self):
        # Change the working directory to the root of the project:
        workspace_path = os.path.dirname(os.path.dirname(__file__))

        subprocess.run(
            [sys.executable, "-m", "rendercv", "new", "John Doe"],
            check=True,
        )
        output_file_path = os.path.join(workspace_path, "John_Doe_CV.yaml")

        model: data_model.RenderCVDataModel = rendering.read_input_file(
            output_file_path
        )

        self.assertTrue(model.cv.name == "John Doe")
