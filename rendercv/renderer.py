"""This module implements LaTeX file generation and LaTeX runner utilities for RenderCV.
"""
import subprocess
import os
import re
import shutil
from datetime import date as Date
import logging
import time
from typing import Optional, Literal
import sys
from importlib.resources import files

from . import data_models as dm

import jinja2

logger = logging.getLogger(__name__)


def markdown_to_latex(markdown_string: str) -> str:
    """Convert a markdown string to LaTeX.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        markdown_to_latex("This is a **bold** text with an [*italic link*](https://google.com).")
        ```

        will return:

        `#!pytjon "This is a \\textbf{bold} text with a \\href{https://google.com}{\\textit{link}}."`

    Args:
        markdown_string (str): The markdown string to convert.

    Returns:
        str: The LaTeX string.
    """
    # convert links
    links = re.findall(r"\[([^\]\[]*)\]\((.*?)\)", markdown_string)
    if links is not None:
        for link in links:
            link_text = link[0]
            link_url = link[1]

            old_link_string = f"[{link_text}]({link_url})"
            new_link_string = "\\href{" + link_url + "}{" + link_text + "}"

            markdown_string = markdown_string.replace(old_link_string, new_link_string)

    # convert bold
    bolds = re.findall(r"\*\*([^\*]*)\*\*", markdown_string)
    if bolds is not None:
        for bold_text in bolds:
            old_bold_text = f"**{bold_text}**"
            new_bold_text = "\\textbf{" + bold_text + "}"

            markdown_string = markdown_string.replace(old_bold_text, new_bold_text)

    # convert italic
    italics = re.findall(r"\*([^\*]*)\*", markdown_string)
    if italics is not None:
        for italic_text in italics:
            old_italic_text = f"*{italic_text}*"
            new_italic_text = "\\textit{" + italic_text + "}"

            markdown_string = markdown_string.replace(old_italic_text, new_italic_text)

    # convert code
    codes = re.findall(r"`([^`]*)`", markdown_string)
    if codes is not None:
        for code_text in codes:
            old_code_text = f"`{code_text}`"
            new_code_text = "\\texttt{" + code_text + "}"

            markdown_string = markdown_string.replace(old_code_text, new_code_text)

    latex_string = markdown_string

    return latex_string


def make_matched_part_something(
    value: str, something: str, match_str: Optional[str] = None
) -> str:
    """Make the matched parts of the string something. If the match_str is None, the
    whole string will be made something.

    Warning:
        This function shouldn't be used directly. Use
        [make_matched_part_bold](renderer.md#rendercv.rendering.make_matched_part_bold),
        [make_matched_pard_underlined](renderer.md#rendercv.rendering.make_matched_pard_underlined),
        [make_matched_part_italic](renderer.md#rendercv.rendering.make_matched_part_italic),
        or
        [make_matched_part_non_line_breakable](renderer.md#rendercv.rendering.make_matched_part_non_line_breakable)
        instead.
    """
    if match_str is None:
        return f"\\{something}{{{value}}}"

    elif match_str in value:
        value = value.replace(match_str, f"\\{something}{{{match_str}}}")
        return value

    else:
        return value


def make_matched_part_bold(value: str, match_str: Optional[str] = None) -> str:
    """Make the matched parts of the string bold. If the match_str is None, the whole
    string will be made bold.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        make_it_bold("Hello World!", "Hello")
        ```

        will return:

        `#!python "\\textbf{Hello} World!"`

    Args:
        value (str): The string to make bold.
        match_str (str): The string to match.
    """
    return make_matched_part_something(value, "textbf", match_str)


def make_matched_part_underlined(value: str, match_str: Optional[str] = None) -> str:
    """Make the matched parts of the string underlined. If the match_str is None, the
    whole string will be made underlined.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        make_it_underlined("Hello World!", "Hello")
        ```

        will return:

        `#!python "\\underline{Hello} World!"`

    Args:
        value (str): The string to make underlined.
        match_str (str): The string to match.
    """
    return make_matched_part_something(value, "underline", match_str)


def make_matched_part_italic(value: str, match_str: Optional[str] = None) -> str:
    """Make the matched parts of the string italic. If the match_str is None, the whole
    string will be made italic.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        make_it_italic("Hello World!", "Hello")
        ```

        will return:

        `#!python "\\textit{Hello} World!"`

    Args:
        value (str): The string to make italic.
        match_str (str): The string to match.
    """
    return make_matched_part_something(value, "textit", match_str)


def make_matced_part_non_line_breakable(
    value: str, match_str: Optional[str] = None
) -> str:
    """Make the matched parts of the string non line breakable. If the match_str is
    None, the whole string will be made nonbreakable.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        make_it_nolinebreak("Hello World!", "Hello")
        ```

        will return:

        `#!python "\\mbox{Hello} World!"`

    Args:
        value (str): The string to disable line breaks.
        match_str (str): The string to match.
    """
    return make_matched_part_something(value, "mbox", match_str)


def abbreviate_name(name: str) -> str:
    """Abbreviate a name by keeping the first letters of the first names.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        abbreviate_name("John Doe")
        ```

        will return:

        `#!python "J. Doe"`

    Args:
        name (str): The name to abbreviate.
    Returns:
        str: The abbreviated name.
    """
    first_names = name.split(" ")[:-1]
    first_names_initials = [first_name[0] + "." for first_name in first_names]
    last_name = name.split(" ")[-1]
    abbreviated_name = " ".join(first_names_initials) + " " + last_name

    return abbreviated_name


def divide_length_by(length: str, divider: float) -> str:
    r"""Divide a length by a number. Length is a string with the following regex
    pattern: `\d+\.?\d* *(cm|in|pt|mm|ex|em)`

    This function is used as a Jinja2 filter.

    Example:
        ```python
        divide_length_by("10.4cm", 2)
        ```

        will return:

        `#!python "5.2cm"`
    """
    # Get the value as a float and the unit as a string:
    value = re.search(r"\d+\.?\d*", length)

    if value is None:
        raise ValueError(f"Invalid length {length}!")
    else:
        value = value.group()

    unit = re.findall(r"[^\d\.\s]+", length)[0]

    return str(float(value) / divider) + " " + unit


def setup_theme_environment(theme_name: str) -> jinja2.Environment:
    """Setup and return the theme environment.

    Args:
        theme_name (str): The name of the theme to use.

    Returns:
        jinja2.Environment: The theme environment.
    """
    # create a Jinja2 environment:
    environment = jinja2.Environment(
        loader=jinja2.PackageLoader("rendercv", os.path.join("themes", theme_name)),
        trim_blocks=True,
        lstrip_blocks=True,
    )

    # add new functions to the environment:
    environment.globals.update(str=str)

    # set custom delimiters for LaTeX templating:
    environment.block_start_string = "((*"
    environment.block_end_string = "*))"
    environment.variable_start_string = "<<"
    environment.variable_end_string = ">>"
    environment.comment_start_string = "((#"
    environment.comment_end_string = "#))"

    # add custom filters:
    environment.filters["markdown_to_latex"] = markdown_to_latex
    environment.filters["make_it_bold"] = make_matched_part_bold
    environment.filters["make_it_underlined"] = make_matched_part_underlined
    environment.filters["make_it_italic"] = make_matched_part_italic
    environment.filters["make_it_nolinebreak"] = make_matced_part_non_line_breakable
    environment.filters["make_it_something"] = make_matched_part_something
    environment.filters["divide_length_by"] = divide_length_by
    environment.filters["abbreviate_name"] = abbreviate_name

    return environment


def template(
    cv: dm.CurriculumVitae,
    design: dm.Design,
    template_name: Literal[
        "EducationEntry",
        "ExperienceEntry",
        "NormalEntry",
        "PublicationEntry",
        "OneLineEntry",
        "TextEntry",
        "Header",
        "Preamble",
        "SectionTitle",
    ],
    environment: jinja2.Environment,
    entry: Optional[
        dm.EducationEntry
        | dm.ExperienceEntry
        | dm.NormalEntry
        | dm.PublicationEntry
        | dm.OneLineEntry
        | str  # TextEntry
    ] = None,
    section_title: Optional[str] = None,
) -> str:
    """Template one of the files in the `templates` directory.

    Args:
        cv (dm.CurriculumVitae): The CV.
        design (dm.Design): The design.
        entry (dm.EducationEntry): The education entry.
        enty_type (Literal["EducationEntry", "ExperienceEntry", "NormalEntry", "PublicationEntry", "OneLineEntry", "TextEntry"]): The type of the entry.
        environment (jinja2.Environment): The Jinja2 environment.

    Returns:
        str: The rendered education entry.
    """
    education_entry_template = environment.get_template(f"{template_name}.j2.tex")

    latex_code = education_entry_template.render(
        cv=cv,
        design=design,
        entry=entry,
        section_title=section_title,
        today=Date.today().strftime("%B %Y"),
    )

    return latex_code


def generate_the_latex_file(
    rendercv_data_model: dm.RenderCVDataModel, output_file_path: str
) -> str:
    """ """
    environment = setup_theme_environment(rendercv_data_model.design.theme)

    # render the preamble:
    preamble = template(
        cv=rendercv_data_model.cv,
        design=rendercv_data_model.design,
        entry=None,
        template_name="Preamble",
        environment=environment,
    )

    latex_file = preamble + "\n\\begin{document}\n"

    # render the header:
    header = template(
        cv=rendercv_data_model.cv,
        design=rendercv_data_model.design,
        template_name="Header",
        environment=environment,
    )

    latex_file = latex_file + header + "\n"

    # render the sections:
    for section in rendercv_data_model.cv.sections:
        title = template(
            cv=rendercv_data_model.cv,
            design=rendercv_data_model.design,
            template_name="SectionTitle",
            environment=environment,
            section_title=section.title,
        )

        latex_file = latex_file + title + "\n"

        for entry in section.entries:
            entry = template(
                cv=rendercv_data_model.cv,
                design=rendercv_data_model.design,
                template_name=section.entry_type,
                environment=environment,
                entry=entry,
            )
            latex_file = latex_file + entry + "\n"

    latex_file = latex_file + "\\end{document}\n"

    # write the LaTeX file:
    with open(output_file_path, "w") as file:
        file.write(latex_file)

    return latex_file


def render_the_latex_file(latex_file_path: str) -> str:
    """
    Run TinyTeX with the given LaTeX file and generate a PDF.

    Args:
        latex_file_path (str): The path to the LaTeX file to compile.
    """
    start_time = time.time()
    logger.info("Running TinyTeX to generate the PDF has started.")
    latex_file_name = os.path.basename(latex_file_path)
    latex_file_path = os.path.normpath(latex_file_path)

    # check if the file exists:
    if not os.path.exists(latex_file_path):
        raise FileNotFoundError(f"The file {latex_file_path} doesn't exist!")

    output_file_name = latex_file_name.replace(".tex", ".pdf")
    output_file_path = os.path.join(os.path.dirname(latex_file_path), output_file_name)

    if sys.platform == "win32":
        # Windows
        executable = str(
            files("rendercv").joinpath(
                "vendor", "TinyTeX", "bin", "windows", "lualatex.exe"
            )
        )

    elif sys.platform == "linux" or sys.platform == "linux2":
        # Linux
        executable = str(
            files("rendercv").joinpath(
                "vendor", "TinyTeX", "bin", "x86_64-linux", "lualatex"
            )
        )
    elif sys.platform == "darwin":
        # MacOS
        executable = str(
            files("rendercv").joinpath(
                "vendor", "TinyTeX", "bin", "universal-darwin", "lualatex"
            )
        )
    else:
        raise OSError(f"Unknown OS {os.name}!")

    # Check if the executable exists:
    if not os.path.exists(executable):
        raise FileNotFoundError(
            f"The TinyTeX executable ({executable}) doesn't exist! Please install"
            " RenderCV again."
        )

    # Run TinyTeX:
    def run():
        with subprocess.Popen(
            [
                executable,
                f"{latex_file_name}",
            ],
            cwd=os.path.dirname(latex_file_path),
            stdout=subprocess.PIPE,
            stdin=subprocess.DEVNULL,  # don't allow TinyTeX to ask for user input
            text=True,
            encoding="utf-8",
        ) as latex_process:
            output, error = latex_process.communicate()

            if latex_process.returncode != 0:
                # Find the error line:
                for line in output.split("\n"):
                    if line.startswith("! "):
                        error_line = line.replace("! ", "")
                        break

                raise RuntimeError(
                    "Running TinyTeX has failed with the following error:",
                    f"{error_line}",
                    "If you can't solve the problem, please try to re-install RenderCV,"
                    " or open an issue on GitHub.",
                )

    run()
    run()  # run twice for cross-references

    # check if the PDF file is generated:
    if not os.path.exists(output_file_path):
        raise FileNotFoundError(
            f"The PDF file {output_file_path} couldn't be generated! If you can't"
            " solve the problem, please try to re-install RenderCV, or open an issue"
            " on GitHub."
        )

    # remove the unnecessary files:
    for file_name in os.listdir(os.path.dirname(latex_file_path)):
        if (
            file_name.endswith(".aux")
            or file_name.endswith(".log")
            or file_name.endswith(".out")
        ):
            os.remove(os.path.join(os.path.dirname(latex_file_path), file_name))

    end_time = time.time()
    time_taken = end_time - start_time
    logger.info(
        f"Running TinyTeX to generate the PDF ({output_file_path}) has finished in"
        f" {time_taken:.2f} s."
    )

    return output_file_path
