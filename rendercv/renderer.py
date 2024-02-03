"""
This module contains functions and classes for generating a $\\LaTeX$ file from the data
model and rendering the $\\LaTeX$ file to produce a PDF.

The $\\LaTeX$ files are generated with [Jinja2](https://jinja.palletsprojects.com/en/3.1.x/)
templates. Then, the $\\LaTeX$ file is rendered into a PDF with
[TinyTeX](https://yihui.org/tinytex/), a $\\LaTeX$ distribution.
"""

import subprocess
import re
import pathlib
import sys
from datetime import date as Date
from typing import Optional, Literal

import jinja2

from . import data_models as dm
from .terminal_reporter import time_the_event_below


class LaTeXFile:
    """This class represents a $\\LaTeX$ file. It generates the $\\LaTeX$ code with the
    data model and Jinja2 templates.

    Args:
        data_model (dm.RenderCVDataModel): The data model.
        environment (jinja2.Environment): The Jinja2 environment.
    """

    def __init__(
        self,
        data_model: dm.RenderCVDataModel,
        environment: jinja2.Environment,
    ):
        self.cv = data_model.cv
        self.design = data_model.design
        self.environment = environment

        # Template the preamble, header, and sections:
        self.preamble = self.template("Preamble")
        self.header = self.template("Header")
        self.sections = []
        for section in self.cv.sections:
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
        """Template one of the files in the `themes` directory.

        Args:
            template_name (str): The name of the template file.
            entry (Optional[
                        dm.EducationEntry,
                        dm.ExperienceEntry,
                        dm.NormalEntry,
                        dm.PublicationEntry,
                        dm.OneLineEntry,
                        str
                    ]): The data model of the entry.
            section_title (Optional[str]): The title of the section.
            is_first_entry (Optional[bool]): Whether the entry is the first one in the
                section.

        Returns:
            str: The templated $\\LaTeX$ code.
        """
        template = self.environment.get_template(
            f"{self.design.theme}/{template_name}.j2.tex"
        )

        # Loop through the entry attributes and make them "" if they are None:
        # This is necessary because otherwise Jinja2 will template them as "None".
        if entry is not None and not isinstance(entry, str):
            for key, value in entry.model_dump().items():
                if value is None:
                    entry.__setattr__(key, "")

        # The arguments of the template can be used in the template file:
        latex_code = template.render(
            cv=self.cv,
            design=self.design,
            entry=entry,
            section_title=section_title,
            today=Date.today().strftime("%B %Y"),
            is_first_entry=is_first_entry,
        )

        return latex_code

    def get_latex_code(self):
        """Get the $\\LaTeX$ code of the file."""
        main_template = self.environment.get_template("main.j2.tex")
        latex_code = main_template.render(
            header=self.header,
            preamble=self.preamble,
            sections=self.sections,
        )
        return latex_code

    def write_to_file(self, file_path: pathlib.Path):
        """Write the $\\LaTeX$ code to a file."""
        with open(file_path, "w") as latex_file:
            latex_file.write(self.get_latex_code())


def make_matched_part_something(
    value: str, something: str, match_str: Optional[str] = None
) -> str:
    """Make the matched parts of the string something. If the match_str is None, the
    whole string will be made something.

    Warning:
        This function shouldn't be used directly. Use
        [make_matched_part_bold](renderer.md#rendercv.rendering.make_matched_part_bold),
        [make_matched_part_underlined](renderer.md#rendercv.rendering.make_matched_part_underlined),
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

    This function can be used as a Jinja2 filter in templates.

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

    This function can be used as a Jinja2 filter in templates.

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

    This function can be used as a Jinja2 filter in templates.

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


def make_matched_part_non_line_breakable(
    value: str, match_str: Optional[str] = None
) -> str:
    """Make the matched parts of the string non line breakable. If the match_str is
    None, the whole string will be made nonbreakable.

    This function can be used as a Jinja2 filter in templates.

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

    This function can be used as a Jinja2 filter in templates.

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

    This function can be used as a Jinja2 filter in templates.

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


def setup_jinja2_environment() -> jinja2.Environment:
    """Setup and return the Jinja2 environment for templating the $\\LaTeX$ files.

    Returns:
        jinja2.Environment: The theme environment.
    """
    # create a Jinja2 environment:
    environment = jinja2.Environment(
        loader=jinja2.PackageLoader("rendercv", "themes"),
        trim_blocks=True,
        lstrip_blocks=True,
    )

    # set custom delimiters for LaTeX templating:
    environment.block_start_string = "((*"
    environment.block_end_string = "*))"
    environment.variable_start_string = "<<"
    environment.variable_end_string = ">>"
    environment.comment_start_string = "((#"
    environment.comment_end_string = "#))"

    # add custom filters to make it easier to template the LaTeX files and add new
    # themes:
    environment.filters["make_it_bold"] = make_matched_part_bold
    environment.filters["make_it_underlined"] = make_matched_part_underlined
    environment.filters["make_it_italic"] = make_matched_part_italic
    environment.filters["make_it_nolinebreak"] = make_matched_part_non_line_breakable
    environment.filters["make_it_something"] = make_matched_part_something
    environment.filters["divide_length_by"] = divide_length_by
    environment.filters["abbreviate_name"] = abbreviate_name

    return environment


@time_the_event_below("Generating the LaTeX file")
def generate_latex_file(
    rendercv_data_model: dm.RenderCVDataModel, latex_file_path: pathlib.Path
):
    """Generate the $\\LaTeX$ file with the given data model and write it to the given
    path.
    """
    jinja2_environment = setup_jinja2_environment()
    latex_file_object = LaTeXFile(
        rendercv_data_model,
        jinja2_environment,
    )

    latex_file_object.write_to_file(latex_file_path)


@time_the_event_below("Generating the PDF file")
def latex_to_pdf(latex_file_path: pathlib.Path) -> pathlib.Path:
    """Run TinyTeX with the given $\\LaTeX$ file to generate the PDF.

    Args:
        latex_file_path (str): The path to the $\\LaTeX$ file to compile.
    Returns:
        pathlib.Path: The path to the generated PDF file.
    """
    # check if the file exists:
    if not latex_file_path.is_file():
        raise FileNotFoundError(f"The file {latex_file_path} doesn't exist!")

    tinytex_binaries_directory = (
        pathlib.Path(__file__).parent / "tinytex-release" / "TinyTeX" / "bin"
    )

    executables = {
        "win32": tinytex_binaries_directory / "windows" / "latexmk.exe",
        "linux": tinytex_binaries_directory / "x86_64-linux" / "latexmk",
        "darwin": tinytex_binaries_directory / "universal-darwin" / "latexmk",
    }

    if sys.platform not in executables:
        raise OSError(f"TinyTeX doesn't support the platform {sys.platform}!")

    # Run TinyTeX:
    with subprocess.Popen(
        [
            executables[sys.platform],
            str(latex_file_path),
            "-lualatex",
        ],
        cwd=latex_file_path.parent,
        stdout=subprocess.DEVNULL,  # don't capture the output
        stderr=subprocess.DEVNULL,  # don't capture the error
        stdin=subprocess.DEVNULL,  # don't allow TinyTeX to ask for user input
    ) as latex_process:
        latex_process.communicate()  # wait for the process to finish
        if latex_process.returncode != 0:
            raise RuntimeError(
                "Running TinyTeX has failed! For debugging, we suggest running the"
                " LaTeX file manually in overleaf.com or another LaTeX editor. If you"
                " can't solve the problem, please open an issue on GitHub.",
            )

    # check if the PDF file is generated:
    pdf_file_path = latex_file_path.with_suffix(".pdf")
    if not pdf_file_path.is_file():
        raise FileNotFoundError(
            "The PDF file couldn't be generated! If you can't solve the problem,"
            " please try to re-install RenderCV, or open an issue on GitHub."
        )

    return pdf_file_path
