import tempfile
import pathlib
import importlib
import importlib.machinery
import importlib.util
import io
import os
import sys
import shutil
from typing import Any

import pdfCropMargins
import ruamel.yaml
import pypdfium2

# Import rendercv. I import the data_models and renderer modules like this instead
# of using `import rendercv` because in order for that to work, the current working
# directory must be the root of the project. To make it convenient for the user, I
# import the modules using the full path of the files.
rendercv_path = pathlib.Path(__file__).parent.parent / "rendercv"


def import_a_module(module_name: str, file_path: pathlib.Path):
    """Imports a module from a file.

    Args:
        module_name (str): The name of the module.
        file_path (pathlib.Path): The path to the file.
    Returns:
        Any: The imported module.
    """
    spec = importlib.util.spec_from_file_location(module_name, file_path)
    module = importlib.util.module_from_spec(spec)  # type: ignore
    sys.modules[module_name] = module
    spec.loader.exec_module(module)  # type: ignore
    return module


# Import rendercv:
rendercv = import_a_module("rendercv", rendercv_path / "__init__.py")

# Import the rendercv.data_models as dm:
dm = import_a_module("rendercv.data_models", rendercv_path / "data_models.py")

# Import the rendercv.renderer as r:
r = import_a_module("rendercv.renderer", rendercv_path / "renderer.py")

# Import the rendercv.cli as cli:
cli = import_a_module("rendercv.cli", rendercv_path / "cli.py")

# The entries below will be pasted into the documentation as YAML, and their
# corresponding figures will be generated with this script.
education_entry = {
    "institution": "Boğaziçi University",
    "location": "Istanbul, Turkey",
    "degree": "BS",
    "area": "Mechanical Engineering",
    "start_date": "2015-09",
    "end_date": "2020-06",
    "highlights": [
        "GPA: 3.24/4.00 ([Transcript](https://example.com))",
        "Awards: Dean's Honor List, Sportsperson of the Year",
    ],
}

experience_entry = {
    "company": "Some Company",
    "location": "TX, USA",
    "position": "Software Engineer",
    "start_date": "2020-07",
    "end_date": "2021-08-12",
    "highlights": [
        (
            "Developed an [IOS application](https://example.com) that has received"
            " more than **100,000 downloads**."
        ),
        "Managed a team of **5** engineers.",
    ],
}

normal_entry = {
    "name": "Some Project",
    "location": "Remote",
    "date": "2021-09",
    "highlights": [
        "Developed a web application with **React** and **Django**.",
        "Implemented a **RESTful API**",
    ],
}

publication_entry = {
    "title": (
        "Magneto-Thermal Thin Shell Approximation for 3D Finite Element Analysis of"
        " No-Insulation Coils"
    ),
    "authors": ["John Doe", "Harry Tom", "Sina Doe", "Anotherfirstname Andsurname"],
    "date": "2021-12-08",
    "journal": "IEEE Transactions on Applied Superconductivity",
    "doi": "10.1109/TASC.2023.3340648",
}

one_line_entry = {
    "name": "Programming",
    "details": "Python, C++, JavaScript, MATLAB",
}

text_entry = (
    "This is a *TextEntry*. It is only a text and can be useful for sections like"
    " **Summary**. To showcase the TextEntry completely, this sentence is added, but it"
    " doesn't contain any information."
)


def dictionary_to_yaml(dictionary: dict[str, Any]):
    """Converts a dictionary to a YAML string.

    Args:
        dictionary (dict[str, Any]): The dictionary to be converted to YAML.
    Returns:
        str: The YAML string.
    """
    yaml_object = ruamel.yaml.YAML()
    yaml_object.width = 60
    yaml_object.indent(mapping=2, sequence=4, offset=2)
    with io.StringIO() as string_stream:
        yaml_object.dump(dictionary, string_stream)
        yaml_string = string_stream.getvalue()
    return yaml_string


def define_env(env):
    # see https://mkdocs-macros-plugin.readthedocs.io/en/latest/macros/
    entries = [
        "education_entry",
        "experience_entry",
        "normal_entry",
        "publication_entry",
        "one_line_entry",
        "text_entry",
    ]

    entries_showcase = dict()
    for entry in entries:
        proper_entry_name = entry.replace("_", " ").title()
        entries_showcase[proper_entry_name] = {
            "yaml": dictionary_to_yaml(eval(entry)),
            "figures": [
                {
                    "path": f"assets/images/{theme}/{entry}.png",
                    "alt_text": f"{proper_entry_name} in {theme}",
                    "theme": theme,
                }
                for theme in dm.available_themes
            ],
        }

    env.variables["showcase_entries"] = entries_showcase


def generate_entry_figures():
    """Generate an image for each entry type and theme."""
    # Generate PDF figures for each entry type and theme
    entries = {
        "education_entry": dm.EducationEntry(**education_entry),
        "experience_entry": dm.ExperienceEntry(**experience_entry),
        "normal_entry": dm.NormalEntry(**normal_entry),
        "publication_entry": dm.PublicationEntry(**publication_entry),
        "one_line_entry": dm.OneLineEntry(**one_line_entry),
        "text_entry": f'"{text_entry}',
    }
    themes = dm.available_themes

    pdf_assets_directory = pathlib.Path(__file__).parent / "assets" / "images"

    with tempfile.TemporaryDirectory() as temporary_directory:
        # create a temporary directory:
        temporary_directory_path = pathlib.Path(temporary_directory)
        for theme in themes:
            for entry_type, entry in entries.items():
                design_dictionary = {
                    "theme": theme,
                    "disable_page_numbering": True,
                    "show_last_updated_date": False,
                }
                if theme == "moderncv":
                    # moderncv theme does not support these options:
                    del design_dictionary["disable_page_numbering"]
                    del design_dictionary["show_last_updated_date"]

                # Create the data model with only one section and one entry
                data_model = dm.RenderCVDataModel(
                    **{
                        "cv": dm.CurriculumVitae(sections={entry_type: [entry]}),
                        "design": design_dictionary,
                    }
                )

                # Render:
                latex_file_path = r.generate_latex_file_and_copy_theme_files(
                    data_model, temporary_directory_path
                )
                pdf_file_path = r.latex_to_pdf(latex_file_path)

                # Prepare the output directory and file path:
                output_directory = pdf_assets_directory / theme
                output_directory.mkdir(parents=True, exist_ok=True)
                output_pdf_file_path = output_directory / f"{entry_type}.pdf"

                # Remove the file if it exists:
                if output_pdf_file_path.exists():
                    output_pdf_file_path.unlink()

                # Crop the margins
                pdfCropMargins.crop(
                    argv_list=[
                        "-p4",
                        "100",
                        "0",
                        "100",
                        "0",
                        "-a4",
                        "0",
                        "-30",
                        "0",
                        "-30",
                        "-o",
                        str(output_pdf_file_path.absolute()),
                        str(pdf_file_path.absolute()),
                    ]
                )

                # Convert pdf to an image
                image_name = output_pdf_file_path.with_suffix(".png")
                pdf = pypdfium2.PdfDocument(str(output_pdf_file_path.absolute()))
                page = pdf[0]
                image = page.render(scale=5).to_pil()

                # If the image exists, remove it
                if image_name.exists():
                    image_name.unlink()

                image.save(image_name)

                pdf.close()

                # Remove the pdf file
                output_pdf_file_path.unlink()


def generate_examples():
    """Generate example YAML and PDF files."""
    examples_directory_path = pathlib.Path(__file__).parent.parent / "examples"

    os.chdir(examples_directory_path)
    themes = dm.available_themes
    for theme in themes:
        cli.cli_command_new("John Doe", theme)
        yaml_file_path = examples_directory_path / "John_Doe_CV.yaml"

        # Rename John_Doe_CV.yaml:
        proper_theme_name = theme.replace("_", " ").title() + "Theme"
        new_yaml_file_path = (
            examples_directory_path / f"John_Doe_{proper_theme_name}_CV.yaml"
        )
        if new_yaml_file_path.exists():
            new_yaml_file_path.unlink()
        yaml_file_path.rename(new_yaml_file_path)
        yaml_file_path = new_yaml_file_path

        # Generate the PDF file:
        cli.cli_command_render(yaml_file_path)

        output_pdf_file = (
            examples_directory_path / "rendercv_output" / "John_Doe_CV.pdf"
        )

        # Move pdf file to the examples directory:
        new_pdf_file_path = examples_directory_path / f"{yaml_file_path.stem}.pdf"
        if new_pdf_file_path.exists():
            new_pdf_file_path.unlink()
        output_pdf_file.rename(new_pdf_file_path)

        # Remove the rendercv_output directory:
        rendercv_output_directory = examples_directory_path / "rendercv_output"

        shutil.rmtree(rendercv_output_directory)


if __name__ == "__main__":
    generate_entry_figures()
    generate_examples()
