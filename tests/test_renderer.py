import math
import filecmp
import shutil
import os
import copy
import pathlib

import pytest
import jinja2
import time_machine
import pypdf

from rendercv import renderer as r
from rendercv import data_models as dm

from .conftest import update_auxiliary_files, folder_name_dictionary


def test_latex_file_class(tmp_path, rendercv_data_model, jinja2_environment):
    latex_file = r.LaTeXFile(rendercv_data_model, jinja2_environment)
    latex_file.get_latex_code()
    latex_file.generate_latex_file(tmp_path / "test.tex")


def test_markdown_file_class(tmp_path, rendercv_data_model, jinja2_environment):
    latex_file = r.MarkdownFile(rendercv_data_model, jinja2_environment)
    latex_file.get_markdown_code()
    latex_file.generate_markdown_file(tmp_path / "test.tex")


@pytest.mark.parametrize(
    "string, expected_string",
    [
        ("My Text", "My Text"),
        ("My # Text", "My \\# Text"),
        ("My % Text", "My \\% Text"),
        ("My & Text", "My \\& Text"),
        ("My ~ Text", "My \\textasciitilde{} Text"),
        ("##%%&&~~", "\\#\\#\\%\\%\\&\\&\\textasciitilde{}\\textasciitilde{}"),
        (
            (
                "[link](you shouldn't escape whatever is in here & % # ~) [second"
                " link](https://myurl.com)"
            ),
            (
                "[link](you shouldn't escape whatever is in here & % # ~) [second"
                " link](https://myurl.com)"
            ),
        ),
        ("$a=5_4^3$", "$a=5_4^3$"),
    ],
)
def test_escape_latex_characters_not_strict(string, expected_string):
    assert r.escape_latex_characters(string, strict=False) == expected_string


def test_escape_latex_characters_strict():
    string = "$a=5_4^3$"
    expected_string = "\\$a=5\\_4\\textasciicircum{}3\\$"
    assert r.escape_latex_characters(string, strict=True) == expected_string


@pytest.mark.parametrize(
    "markdown_string, expected_latex_string",
    [
        ("My Text", "My Text"),
        ("**My** Text", "\\textbf{My} Text"),
        ("*My* Text", "\\textit{My} Text"),
        ("***My*** Text", "\\textbf{\\textit{My}} Text"),
        ("[My](https://myurl.com) Text", "\\href{https://myurl.com}{My} Text"),
        ("`My` Text", "`My` Text"),
        (
            "[**My** *Text* ***Is*** `Here`](https://myurl.com)",
            (
                "\\href{https://myurl.com}{\\textbf{My} \\textit{Text}"
                " \\textbf{\\textit{Is}} `Here`}"
            ),
        ),
        (
            "Some other *** tests, which should be tricky* to parse!**",
            "Some other \\textbf{\\textit{ tests, which should be tricky} to parse!}",
        ),
    ],
)
def test_markdown_to_latex(markdown_string, expected_latex_string):
    assert r.markdown_to_latex(markdown_string) == expected_latex_string


def test_transform_markdown_sections_to_latex_sections(rendercv_data_model):
    new_data_model = copy.deepcopy(rendercv_data_model)
    new_sections_input = r.transform_markdown_sections_to_latex_sections(
        new_data_model.cv.sections_input
    )
    new_data_model.cv.sections_input = new_sections_input

    assert isinstance(new_data_model, dm.RenderCVDataModel)
    assert new_data_model.cv.name == rendercv_data_model.cv.name
    assert new_data_model.design == rendercv_data_model.design
    assert new_data_model.cv.sections != rendercv_data_model.cv.sections


@pytest.mark.parametrize(
    "string, placeholders, expected_string",
    [
        ("Hello, {name}!", {"{name}": None}, "Hello, None!"),
        (
            "{greeting}, {name}!",
            {"{greeting}": "Hello", "{name}": "World"},
            "Hello, World!",
        ),
        ("No placeholders here.", {}, "No placeholders here."),
        (
            "{missing} placeholder.",
            {"{not_missing}": "value"},
            "{missing} placeholder.",
        ),
        ("", {"{placeholder}": "value"}, ""),
    ],
)
def test_replace_placeholders_with_actual_values(string, placeholders, expected_string):
    result = r.replace_placeholders_with_actual_values(string, placeholders)
    assert result == expected_string


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
        (None, ""),
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
            label="Test1",
            details="Test2",
        ),
        dm.OneLineEntry(
            label="Test3",
            details="Test4",
        ),
    ]
    result = r.get_an_item_with_a_specific_attribute_value(
        entry_objects, "label", "Test3"
    )
    assert result == entry_objects[1]
    result = r.get_an_item_with_a_specific_attribute_value(
        entry_objects, "label", "DoesntExist"
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


@pytest.mark.parametrize(
    "theme_name",
    dm.available_themes,
)
@pytest.mark.parametrize(
    "curriculum_vitae_data_model",
    [
        "rendercv_empty_curriculum_vitae_data_model",
        "rendercv_filled_curriculum_vitae_data_model",
    ],
)
@time_machine.travel("2024-01-01")
def test_generate_latex_file(
    tmp_path,
    auxiliary_files_directory_path,
    request,
    theme_name,
    curriculum_vitae_data_model,
):
    reference_directory_path = (
        auxiliary_files_directory_path
        / "test_generate_latex_file"
        / f"{theme_name}_{folder_name_dictionary[curriculum_vitae_data_model]}"
    )

    cv_data_model = request.getfixturevalue(curriculum_vitae_data_model)

    file_name = f"{str(cv_data_model.name).replace(' ', '_')}_CV.tex"
    output_file_path = tmp_path / "make_sure_it_generates_the_directory" / file_name
    reference_file_path = reference_directory_path / file_name

    data_model = dm.RenderCVDataModel(
        cv=cv_data_model,
        design={"theme": theme_name},
    )
    r.generate_latex_file(data_model, tmp_path / "make_sure_it_generates_the_directory")
    # Update the auxiliary files if update_auxiliary_files is True
    if update_auxiliary_files:
        r.generate_latex_file(data_model, reference_directory_path)

    assert filecmp.cmp(output_file_path, reference_file_path)


@pytest.mark.parametrize(
    "theme_name",
    dm.available_themes,
)
@pytest.mark.parametrize(
    "curriculum_vitae_data_model",
    [
        "rendercv_empty_curriculum_vitae_data_model",
        "rendercv_filled_curriculum_vitae_data_model",
    ],
)
@time_machine.travel("2024-01-01")
def test_generate_markdown_file(
    tmp_path,
    auxiliary_files_directory_path,
    request,
    theme_name,
    curriculum_vitae_data_model,
):
    reference_directory_path = (
        auxiliary_files_directory_path
        / "test_generate_markdown_file"
        / f"{theme_name}_{folder_name_dictionary[curriculum_vitae_data_model]}"
    )

    cv_data_model = request.getfixturevalue(curriculum_vitae_data_model)

    file_name = f"{str(cv_data_model.name).replace(' ', '_')}_CV.md"
    output_file_path = tmp_path / "make_sure_it_generates_the_directory" / file_name
    reference_file_path = reference_directory_path / file_name

    data_model = dm.RenderCVDataModel(
        cv=cv_data_model,
    )
    r.generate_markdown_file(
        data_model, tmp_path / "make_sure_it_generates_the_directory"
    )
    # Update the auxiliary files if update_auxiliary_files is True
    if update_auxiliary_files:
        r.generate_markdown_file(data_model, reference_directory_path)

    assert filecmp.cmp(output_file_path, reference_file_path)


@pytest.mark.parametrize(
    "theme_name",
    dm.available_themes,
)
def test_copy_theme_files_to_output_directory(
    tmp_path, auxiliary_files_directory_path, theme_name
):
    reference_directory_path = (
        auxiliary_files_directory_path / "test_copy_theme_files_to_output_directory"
    )

    r.copy_theme_files_to_output_directory(theme_name, tmp_path)
    # Update the auxiliary files if update_auxiliary_files is True
    if update_auxiliary_files:
        reference_directory_path.mkdir(parents=True, exist_ok=True)
        r.copy_theme_files_to_output_directory(theme_name, reference_directory_path)

    assert filecmp.dircmp(tmp_path, reference_directory_path).diff_files == []


def test_copy_theme_files_to_output_directory_custom_theme(
    tmp_path, auxiliary_files_directory_path
):
    theme_name = "dummytheme"

    test_auxiliary_files_directory_path = (
        auxiliary_files_directory_path
        / "test_copy_theme_files_to_output_directory_custom_theme"
    )
    custom_theme_directory_path = test_auxiliary_files_directory_path / "dummytheme"
    reference_directory_path = (
        test_auxiliary_files_directory_path / "theme_auxiliary_files"
    )

    # Update the auxiliary files if update_auxiliary_files is True
    if update_auxiliary_files:
        # create dummytheme:
        if not custom_theme_directory_path.exists():
            custom_theme_directory_path.mkdir(parents=True, exist_ok=True)

        # create a txt file called test.txt in the custom theme directory:
        for entry_type_name in dm.entry_type_names:
            pathlib.Path(
                custom_theme_directory_path / f"{entry_type_name}.j2.tex"
            ).touch()
        pathlib.Path(custom_theme_directory_path / "Header.j2.tex").touch()
        pathlib.Path(custom_theme_directory_path / "Preamble.j2.tex").touch()
        pathlib.Path(custom_theme_directory_path / "SectionBeginning.j2.tex").touch()
        pathlib.Path(custom_theme_directory_path / "SectionEnding.j2.tex").touch()
        pathlib.Path(custom_theme_directory_path / "theme_auxiliary_file.cls").touch()
        pathlib.Path(custom_theme_directory_path / "theme_auxiliary_dir").mkdir(
            exist_ok=True
        )
        pathlib.Path(
            custom_theme_directory_path
            / "theme_auxiliary_dir"
            / "theme_auxiliary_file.txt"
        ).touch()
        init_file = pathlib.Path(custom_theme_directory_path / "__init__.py")

        init_file.touch()
        init_file.write_text(
            "from typing import Literal\n\nimport pydantic\n\n\nclass"
            " DummythemeThemeOptions(pydantic.BaseModel):\n    theme:"
            " Literal['dummytheme']\n"
        )

        # create reference_directory_path:
        os.chdir(test_auxiliary_files_directory_path)
        r.copy_theme_files_to_output_directory(theme_name, reference_directory_path)

    # change current working directory to the test_auxiliary_files_directory_path
    os.chdir(test_auxiliary_files_directory_path)

    # copy the auxiliary theme files to tmp_path:
    r.copy_theme_files_to_output_directory(theme_name, tmp_path)

    assert filecmp.dircmp(tmp_path, reference_directory_path).left_only == []
    assert filecmp.dircmp(tmp_path, reference_directory_path).right_only == []


@pytest.mark.parametrize(
    "theme_name",
    dm.available_themes,
)
@pytest.mark.parametrize(
    "curriculum_vitae_data_model",
    [
        "rendercv_empty_curriculum_vitae_data_model",
        "rendercv_filled_curriculum_vitae_data_model",
    ],
)
@time_machine.travel("2024-01-01")
def test_generate_latex_file_and_copy_theme_files(
    tmp_path,
    auxiliary_files_directory_path,
    request,
    theme_name,
    curriculum_vitae_data_model,
):
    reference_directory_path = (
        auxiliary_files_directory_path
        / "test_generate_latex_file_and_copy_theme_files"
        / f"{theme_name}_{folder_name_dictionary[curriculum_vitae_data_model]}"
    )

    data_model = dm.RenderCVDataModel(
        cv=request.getfixturevalue(curriculum_vitae_data_model),
        design={"theme": theme_name},
    )
    r.generate_latex_file_and_copy_theme_files(data_model, tmp_path)
    # Update the auxiliary files if update_auxiliary_files is True
    if update_auxiliary_files:
        r.generate_latex_file_and_copy_theme_files(data_model, reference_directory_path)

    assert filecmp.dircmp(tmp_path, reference_directory_path).left_only == []
    assert filecmp.dircmp(tmp_path, reference_directory_path).right_only == []


@pytest.mark.parametrize(
    "theme_name",
    dm.available_themes,
)
@pytest.mark.parametrize(
    "curriculum_vitae_data_model",
    [
        "rendercv_empty_curriculum_vitae_data_model",
        "rendercv_filled_curriculum_vitae_data_model",
    ],
)
@time_machine.travel("2024-01-01")
def test_latex_to_pdf(
    tmp_path,
    request,
    auxiliary_files_directory_path,
    theme_name,
    curriculum_vitae_data_model,
):
    latex_sources_path = (
        auxiliary_files_directory_path
        / "test_generate_latex_file_and_copy_theme_files"
        / f"{theme_name}_{folder_name_dictionary[curriculum_vitae_data_model]}"
    )
    reference_directory_path = (
        auxiliary_files_directory_path
        / "test_latex_to_pdf"
        / f"{theme_name}_{folder_name_dictionary[curriculum_vitae_data_model]}"
    )

    cv_data_model = request.getfixturevalue(curriculum_vitae_data_model)
    file_name_stem = f"{str(cv_data_model.name).replace(' ', '_')}_CV"

    # Update the auxiliary files if update_auxiliary_files is True
    if update_auxiliary_files:
        # copy the latex sources to the reference_directory_path
        shutil.copytree(
            latex_sources_path, reference_directory_path, dirs_exist_ok=True
        )

        # convert the latex code to a pdf
        reference_pdf_file_path = r.latex_to_pdf(
            reference_directory_path / f"{file_name_stem}.tex"
        )

        # remove the latex sources from the reference_directory_path, but keep the pdf
        for file in reference_directory_path.iterdir():
            if file.is_file() and file.suffix != ".pdf":
                file.unlink()

    # copy the latex sources to the tmp_path
    shutil.copytree(latex_sources_path, tmp_path, dirs_exist_ok=True)

    # convert the latex code to a pdf
    reference_pdf_file_path = reference_directory_path / f"{file_name_stem}.pdf"
    output_file_path = r.latex_to_pdf(tmp_path / f"{file_name_stem}.tex")

    text1 = pypdf.PdfReader(output_file_path).pages[0].extract_text()
    text2 = pypdf.PdfReader(reference_pdf_file_path).pages[0].extract_text()
    assert text1 == text2


def test_latex_to_pdf_invalid_latex_file():
    with pytest.raises(FileNotFoundError):
        file_path = pathlib.Path("file_doesnt_exist.tex")
        r.latex_to_pdf(file_path)


@pytest.mark.parametrize(
    "theme_name",
    dm.available_themes,
)
@pytest.mark.parametrize(
    "curriculum_vitae_data_model",
    [
        "rendercv_empty_curriculum_vitae_data_model",
        "rendercv_filled_curriculum_vitae_data_model",
    ],
)
@time_machine.travel("2024-01-01")
def test_markdown_to_html(
    tmp_path,
    request,
    auxiliary_files_directory_path,
    theme_name,
    curriculum_vitae_data_model,
):
    markdown_sources_path = (
        auxiliary_files_directory_path
        / "test_generate_markdown_file"
        / f"{theme_name}_{folder_name_dictionary[curriculum_vitae_data_model]}"
    )
    reference_directory = (
        auxiliary_files_directory_path
        / "test_markdown_to_html"
        / f"{theme_name}_{folder_name_dictionary[curriculum_vitae_data_model]}"
    )

    cv_data_model = request.getfixturevalue(curriculum_vitae_data_model)
    file_name_stem = f"{str(cv_data_model.name).replace(' ', '_')}_CV"

    # Update the auxiliary files if update_auxiliary_files is True
    if update_auxiliary_files:
        # copy the markdown sources to the reference_directory
        shutil.copytree(markdown_sources_path, reference_directory, dirs_exist_ok=True)

        # convert markdown to html
        r.markdown_to_html(reference_directory / f"{file_name_stem}.md")

        # remove the markdown sources from the reference_directory
        for file in reference_directory.iterdir():
            if file.is_file() and file.suffix != ".html":
                file.unlink()

    # copy the markdown sources to the tmp_path
    shutil.copytree(markdown_sources_path, tmp_path, dirs_exist_ok=True)

    # convert markdown to html
    output_file_path = r.markdown_to_html(tmp_path / f"{file_name_stem}.md")
    reference_file_path = (
        reference_directory / f"{file_name_stem}_PASTETOGRAMMARLY.html"
    )

    assert filecmp.cmp(output_file_path, reference_file_path)


def test_markdown_to_html_invalid_markdown_file():
    with pytest.raises(FileNotFoundError):
        file_path = pathlib.Path("file_doesnt_exist.md")
        r.markdown_to_html(file_path)
