"""This script generates the example entry figures and creates an environment for
documentation templates using `mkdocs-macros-plugin`. For example, the content of the
example entries found in
"[Structure of the YAML Input File](https://docs.rendercv.com/user_guide/structure_of_the_yaml_input_file/)"
are coming from this script.
"""

import io
import pathlib
import shutil
import tempfile
from typing import Any

import pdfCropMargins
import ruamel.yaml

import rendercv.data_models as dm
import rendercv.renderer as r

repository_root = pathlib.Path(__file__).parent.parent
rendercv_path = repository_root / "rendercv"
image_assets_directory = pathlib.Path(__file__).parent / "assets" / "images"

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
    "authors": ["J. Doe", "***H. Tom***", "S. Doe", "A. Andsurname"],
    "date": "2021-12-08",
    "journal": "IEEE Transactions on Applied Superconductivity",
    "doi": "10.1109/TASC.2023.3340648",
}

one_line_entry = {
    "label": "Programming",
    "details": "Python, C++, JavaScript, MATLAB",
}

bullet_entry = {
    "bullet": "This is a bullet entry.",
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
        "bullet_entry",
        "text_entry",
    ]

    entries_showcase = dict()
    for entry in entries:
        proper_entry_name = entry.replace("_", " ").title()
        entries_showcase[proper_entry_name] = {
            "yaml": dictionary_to_yaml(eval(entry)),
            "figures": [
                {
                    "path": f"../assets/images/{theme}/{entry}.png",
                    "alt_text": f"{proper_entry_name} in {theme}",
                    "theme": theme,
                }
                for theme in dm.available_themes
            ],
        }

    env.variables["showcase_entries"] = entries_showcase

    # for theme templates reference docs:
    themes_path = rendercv_path / "themes"
    theme_templates = dict()
    for theme in dm.available_themes:
        theme_templates[theme] = dict()
        for theme_file in themes_path.glob(f"{theme}/*.tex"):
            theme_templates[theme][
                theme_file.stem.replace(".j2", "")
            ] = theme_file.read_text()

    env.variables["theme_templates"] = theme_templates

    # available themes strings (put available themes between ``)
    themes = [f"`{theme}`" for theme in dm.available_themes]
    env.variables["available_themes"] = ", ".join(themes)

    # available social networks strings (put available social networks between ``)
    social_networks = [
        f"`{social_network}`" for social_network in dm.available_social_networks
    ]
    env.variables["available_social_networks"] = ", ".join(social_networks)


def generate_entry_figures():
    """Generate an image for each entry type and theme."""
    # Generate PDF figures for each entry type and theme
    entries = {
        "education_entry": dm.EducationEntry(**education_entry),
        "experience_entry": dm.ExperienceEntry(**experience_entry),
        "normal_entry": dm.NormalEntry(**normal_entry),
        "publication_entry": dm.PublicationEntry(**publication_entry),
        "one_line_entry": dm.OneLineEntry(**one_line_entry),
        "text_entry": f"{text_entry}",
        "bullet_entry": dm.BulletEntry(**bullet_entry),
    }
    themes = dm.available_themes

    with tempfile.TemporaryDirectory() as temporary_directory:
        # create a temporary directory:
        temporary_directory_path = pathlib.Path(temporary_directory)
        for theme in themes:
            design_dictionary = {
                "theme": theme,
                "disable_page_numbering": True,
                "disable_last_updated_date": True,
            }
            if theme == "moderncv":
                # moderncv theme does not support these options:
                del design_dictionary["disable_page_numbering"]
                del design_dictionary["disable_last_updated_date"]

            for entry_type, entry in entries.items():
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
                output_directory = image_assets_directory / theme
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
                png_file_path = r.pdf_to_pngs(output_pdf_file_path)[0]
                desired_png_file_path = output_pdf_file_path.with_suffix(".png")

                # If the image exists, remove it
                if desired_png_file_path.exists():
                    desired_png_file_path.unlink()

                # Move the image to the desired location
                png_file_path.rename(desired_png_file_path)

                # Remove the pdf file
                output_pdf_file_path.unlink()


def update_index():
    """Update the index.md file by copying the README.md file."""
    index_file_path = repository_root / "docs" / "index.md"
    readme_file_path = repository_root / "README.md"
    shutil.copy(readme_file_path, index_file_path)


if __name__ == "__main__":
    generate_entry_figures()
    print("Entry figures generated successfully.")
