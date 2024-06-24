"""This script generates the `examples` folder in the repository root."""

import os
import pathlib
import shutil

import rendercv.cli as cli
import rendercv.data_models as dm
import rendercv.renderer as r

repository_root = pathlib.Path(__file__).parent.parent
rendercv_path = repository_root / "rendercv"
image_assets_directory = pathlib.Path(__file__).parent / "assets" / "images"


def generate_examples():
    """Generate example YAML and PDF files."""
    examples_directory_path = pathlib.Path(__file__).parent.parent / "examples"

    # check if the examples directory exists, if not create it
    if not examples_directory_path.exists():
        examples_directory_path.mkdir()

    os.chdir(examples_directory_path)
    themes = dm.available_themes
    for theme in themes:
        cli.cli_command_new(
            "John Doe",
            theme,
            dont_create_theme_source_files=True,
            dont_create_markdown_source_files=True,
        )
        yaml_file_path = examples_directory_path / "John_Doe_CV.yaml"

        # Rename John_Doe_CV.yaml:
        proper_theme_name = theme.capitalize() + "Theme"
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

        # convert first page of the pdf to an image:
        png_file_paths = r.pdf_to_pngs(new_pdf_file_path)
        firt_page_png_file_path = png_file_paths[0]
        if len(png_file_paths) > 1:
            # remove the other pages
            for png_file_path in png_file_paths[1:]:
                png_file_path.unlink()

        desired_png_file_path = image_assets_directory / f"{theme}.png"

        # If the image exists, remove it
        if desired_png_file_path.exists():
            desired_png_file_path.unlink()

        # Move the image to the desired location
        firt_page_png_file_path.rename(desired_png_file_path)


if __name__ == "__main__":
    generate_examples()
    print("Examples generated successfully.")
