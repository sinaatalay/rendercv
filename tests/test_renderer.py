import math

import pytest
import jinja2

from rendercv import renderer as r


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

