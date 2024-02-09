import math
import filecmp
import shutil
import pathlib

import pytest
import jinja2
import time_machine

from rendercv import renderer as r
from rendercv import data_models as dm


def test_latex_file_class(tmp_path, rendercv_data_model, jinja2_environment):
    latex_file = r.LaTeXFile(rendercv_data_model, jinja2_environment)
    latex_file.get_latex_code()
    latex_file.generate_latex_file(tmp_path / "test.tex")


@pytest.mark.parametrize(
    "value, something, match_str, expected",
    [
        ("Hello World", "textbf", None, "\\textbf{Hello World}"),
        ("Hello World", "textbf", "World", "Hello \\textbf{World}"),
        ("Hello World", "textbf", "Universe", "Hello World"),
        ("", "textbf", "Universe", ""),
        ("Hello World", "textbf", "", "Hello World"),
    ],
)
def test_make_matched_part_something(value, something, match_str, expected):
    result = r.make_matched_part_something(value, something, match_str)
    assert result == expected


@pytest.mark.parametrize(
    "value, match_str, expected",
    [
        ("Hello World", None, "\\textbf{Hello World}"),
        ("Hello World", "World", "Hello \\textbf{World}"),
        ("Hello World", "Universe", "Hello World"),
        ("", "Universe", ""),
        ("Hello World", "", "Hello World"),
    ],
)
def test_make_matched_part_bold(value, match_str, expected):
    result = r.make_matched_part_bold(value, match_str)
    assert result == expected


@pytest.mark.parametrize(
    "value, match_str, expected",
    [
        ("Hello World", None, "\\underline{Hello World}"),
        ("Hello World", "World", "Hello \\underline{World}"),
        ("Hello World", "Universe", "Hello World"),
        ("", "Universe", ""),
        ("Hello World", "", "Hello World"),
    ],
)
def test_make_matched_part_underlined(value, match_str, expected):
    result = r.make_matched_part_underlined(value, match_str)
    assert result == expected


@pytest.mark.parametrize(
    "value, match_str, expected",
    [
        ("Hello World", None, "\\textit{Hello World}"),
        ("Hello World", "World", "Hello \\textit{World}"),
        ("Hello World", "Universe", "Hello World"),
        ("", "Universe", ""),
        ("Hello World", "", "Hello World"),
    ],
)
def test_make_matched_part_italic(value, match_str, expected):
    result = r.make_matched_part_italic(value, match_str)
    assert result == expected


@pytest.mark.parametrize(
    "value, match_str, expected",
    [
        ("Hello World", None, "\\mbox{Hello World}"),
        ("Hello World", "World", "Hello \\mbox{World}"),
        ("Hello World", "Universe", "Hello World"),
        ("", "Universe", ""),
        ("Hello World", "", "Hello World"),
    ],
)
def test_make_matched_part_non_line_breakable(value, match_str, expected):
    result = r.make_matched_part_non_line_breakable(value, match_str)
    assert result == expected


@pytest.mark.parametrize(
    "name, expected",
    [
        ("John Doe", "J. Doe"),
        ("John Jacob Jingleheimer Schmidt", "J. J. J. Schmidt"),
        ("SingleName", "SingleName"),
        ("", ""),
    ],
)
def test_abbreviate_name(name, expected):
    result = r.abbreviate_name(name)
    assert result == expected


@pytest.mark.parametrize(
    "length, divider, expected",
    [
        ("10pt", 2, "5.0pt"),
        ("15cm", 3, "5.0cm"),
        ("20mm", 4, "5.0mm"),
        ("25ex", 5, "5.0ex"),
        ("30em", 6, "5.0em"),
        ("10pt", 3, "3.33pt"),
        ("10pt", 4, "2.5pt"),
        ("0pt", 1, "0.0pt"),
    ],
)
def test_divide_length_by(length, divider, expected):
    result = r.divide_length_by(length, divider)
    assert math.isclose(
        float(result[:-2]), float(expected[:-2]), rel_tol=1e-2
    ), f"Expected {expected}, but got {result}"


@pytest.mark.parametrize(
    "length, divider",
    [("10pt", 0), ("10pt", -1), ("invalid", 4)],
)
def test_invalid_divide_length_by(length, divider):
    with pytest.raises(ValueError):
        r.divide_length_by(length, divider)


def test_get_an_item_with_a_specific_attribute_value():
    entry_objects = [
        dm.OneLineEntry(
            name="Test1",
            details="Test2",
        ),
        dm.OneLineEntry(
            name="Test3",
            details="Test4",
        ),
    ]
    result = r.get_an_item_with_a_specific_attribute_value(
        entry_objects, "name", "Test3"
    )
    assert result == entry_objects[1]
    result = r.get_an_item_with_a_specific_attribute_value(
        entry_objects, "name", "DoesntExist"
    )
    assert result is None

    with pytest.raises(AttributeError):
        r.get_an_item_with_a_specific_attribute_value(entry_objects, "invalid", "Test5")


def test_setup_jinja2_environment():
    env = r.setup_jinja2_environment()

    # Check if the returned object is a jinja2.Environment instance
    assert isinstance(env, jinja2.Environment)

    # Check if the custom delimiters are correctly set
    assert env.block_start_string == "((*"
    assert env.block_end_string == "*))"
    assert env.variable_start_string == "<<"
    assert env.variable_end_string == ">>"
    assert env.comment_start_string == "((#"
    assert env.comment_end_string == "#))"

    # Check if the custom filters are correctly set
    assert "make_it_bold" in env.filters
    assert "make_it_underlined" in env.filters
    assert "make_it_italic" in env.filters
    assert "make_it_nolinebreak" in env.filters
    assert "make_it_something" in env.filters
    assert "divide_length_by" in env.filters
    assert "abbreviate_name" in env.filters
    assert "get_an_item_with_a_specific_attribute_value" in env.filters


themes = ["classic"]


@pytest.mark.parametrize(
    "theme_name",
    themes,
)
@time_machine.travel("2024-01-01")
def test_generate_latex_file(tmp_path, reference_files_directory_path, theme_name):
    file_name = f"{theme_name}_theme_CV.tex"
    output_file_path = tmp_path / "make_sure_it_generates_the_directory" / file_name
    reference_file_path = reference_files_directory_path / file_name

    data_model = dm.RenderCVDataModel(
        cv=dm.CurriculumVitae(name=f"{theme_name} theme"),
        design=dm.Design(theme=theme_name),
    )
    r.generate_latex_file(data_model, tmp_path / "make_sure_it_generates_the_directory")
    # Uncomment the line below to update the reference files:
    # r.generate_latex_file(data_model, reference_files_directory_path)

    assert filecmp.cmp(output_file_path, reference_file_path)


@pytest.mark.parametrize(
    "theme_name",
    themes,
)
def test_copy_theme_files_to_output_directory(
    tmp_path, reference_files_directory_path, theme_name
):
    reference_directory_path = (
        reference_files_directory_path / f"{theme_name}_theme_auxiliary_files"
    )

    r.copy_theme_files_to_output_directory(theme_name, tmp_path)
    # Uncomment the line below to update the reference files:
    # r.copy_theme_files_to_output_directory(
    #     theme_name, reference_files_directory_path / directory_name
    # )

    assert filecmp.dircmp(tmp_path, reference_directory_path).diff_files == []


@pytest.mark.parametrize(
    "theme_name",
    themes,
)
@time_machine.travel("2024-01-01")
def test_generate_latex_file_and_copy_theme_files(
    tmp_path, reference_files_directory_path, theme_name
):
    reference_directory = reference_files_directory_path / f"{theme_name}_theme_full"

    data_model = dm.RenderCVDataModel(
        cv=dm.CurriculumVitae(name=f"{theme_name} theme"),
        design=dm.Design(theme=theme_name),
    )
    r.generate_latex_file_and_copy_theme_files(data_model, tmp_path)
    # Uncomment the line below to update the reference files:
    # r.generate_latex_file_and_copy_theme_files(
    #     data_model, reference_directory
    # )

    assert filecmp.dircmp(tmp_path, reference_directory).diff_files == []


@pytest.mark.parametrize(
    "theme_name",
    themes,
)
def test_latex_to_pdf(tmp_path, reference_files_directory_path, theme_name):
    reference_directory = reference_files_directory_path / f"{theme_name}_theme_full"
    reference_pdf_file_path = reference_directory / f"{theme_name}_theme_CV.pdf"

    shutil.copytree(reference_directory, tmp_path, dirs_exist_ok=True)
    output_pdf_file_path = r.latex_to_pdf(tmp_path / f"{theme_name}_theme_CV.tex")
    # Uncomment the line below to update the reference files:
    # output_pdf_file_path = r.latex_to_pdf(
    #     reference_directory / f"{theme_name}_theme_CV.tex"
    # )

    assert filecmp.cmp(output_pdf_file_path, reference_pdf_file_path)


def test_latex_to_pdf_invalid_latex_file(tmp_path):
    with pytest.raises(FileNotFoundError):
        file_path = pathlib.Path("file_doesnt_exist.tex")
        r.latex_to_pdf(file_path)
