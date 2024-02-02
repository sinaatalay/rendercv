"""This module implements LaTeX file generation and LaTeX runner utilities for RenderCV."""

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


class LaTeXFile:
    def __init__(
        self,
        cv: dm.CurriculumVitae,
        design: dm.Design,
        environment: jinja2.Environment,
        file_path,
    ):
        self.file_path = file_path
        self.cv = cv
        self.design = design
        self.environment = environment

        self.preamble = self.template("Preamble")
        self.header = self.template("Header")
        self.sections = []
        for section in cv.sections:
            title = self.template("SectionTitle", section_title=section.title)
            entries = []
            for i, entry in enumerate(section.entries):
                if i == 0:
                    is_first_entry = True
                else:
                    is_first_entry = False
                entries.append(
                    self.template(
                        section.entry_type,
                        entry=entry,
                        section_title=section.title,
                        is_first_entry=is_first_entry,
                    )
                )
            self.sections.append((title, entries))

    def template(
        self,
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
        entry: Optional[
            dm.EducationEntry
            | dm.ExperienceEntry
            | dm.NormalEntry
            | dm.PublicationEntry
            | dm.OneLineEntry
            | str  # TextEntry
        ] = None,
        section_title: Optional[str] = None,
        is_first_entry: Optional[bool] = None,
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
        education_entry_template = self.environment.get_template(
            f"{self.design.theme}/{template_name}.j2.tex"
        )

        # loop through the entry attributes and make them "" if they are None:
        if entry is not None and not isinstance(entry, str):
            for key, value in entry.model_dump().items():
                if value is None:
                    try:
                        entry.__setattr__(key, "")
                    except ValueError:
                        # then it means it's a computed property, can be ignored
                        pass

        latex_code = education_entry_template.render(
            cv=self.cv,
            design=self.design,
            entry=entry,
            section_title=section_title,
            today=Date.today().strftime("%B %Y"),
            is_first_entry=is_first_entry,
        )

        return latex_code

    def get_latex_code(self):
        main_template = self.environment.get_template("main.j2.tex")
        latex_code = main_template.render(
            header=self.header,
            preamble=self.preamble,
            sections=self.sections,
        )
        return latex_code


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
        loader=jinja2.PackageLoader("rendercv", os.path.join("themes")),
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


def generate_the_latex_file(
    rendercv_data_model: dm.RenderCVDataModel, output_file_path: str
) -> str:
    """ """
    environment = setup_theme_environment(rendercv_data_model.design.theme)
    latex_file_object = LaTeXFile(
        rendercv_data_model.cv,
        rendercv_data_model.design,
        environment,
        output_file_path,
    )

    with open(output_file_path, "w") as latex_file:
        latex_file.write(latex_file_object.get_latex_code())

    return latex_file_object.get_latex_code()


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

    tinytex_binaries = files("rendercv").joinpath("tinytex-release", "TinyTeX", "bin")
    if sys.platform == "win32":
        # Windows
        executable = str(tinytex_binaries.joinpath("windows", "lualatex.exe"))

    elif sys.platform == "linux" or sys.platform == "linux2":
        # Linux
        executable = str(tinytex_binaries.joinpath("x86_64-linux", "lualatex"))
    elif sys.platform == "darwin":
        # MacOS
        executable = str(tinytex_binaries.joinpath("universal-darwin", "lualatex"))
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
