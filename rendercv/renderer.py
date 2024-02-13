"""
This module contains functions and classes for generating a $\\LaTeX$ file from the data
model and rendering the $\\LaTeX$ file to produce a PDF.

The $\\LaTeX$ files are generated with
[Jinja2](https://jinja.palletsprojects.com/en/3.1.x/) templates. Then, the $\\LaTeX$
file is rendered into a PDF with [TinyTeX](https://yihui.org/tinytex/), a $\\LaTeX$
distribution.
"""

import subprocess
import re
import os
import pathlib
import importlib.resources
import shutil
import sys
from datetime import date as Date
from typing import Optional, Literal, Any

import jinja2
import markdown
import fpdf

from . import data_models as dm


class TemplatedFile:
    """This class is a base class for LaTeXFile and MarkdownFile classes. It contains
    the common methods and attributes for both classes. These classes are used to
    generate the LaTeX and Markdown files with the data model and Jinja2 templates.

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

    def template(
        self,
        theme_name,
        template_name: Literal[
            "EducationEntry",
            "ExperienceEntry",
            "NormalEntry",
            "PublicationEntry",
            "OneLineEntry",
            "TextEntry",
            "Header",
            "Preamble",
            "SectionBeginning",
            "SectionEnding",
        ],
        extension: str,
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
            str: The templated file.
        """
        template = self.environment.get_template(
            f"{theme_name}/{template_name}.j2.{extension}"
        )

        # Loop through the entry attributes and make them "" if they are None:
        # This is necessary because otherwise they will be templated as "None" since
        # it's the string representation of None.

        # Only don't touch the date fields, because only date_string is called and
        # setting dates to "" will cause problems.
        fields_to_ignore = ["start_date", "end_date", "date"]

        if entry is not None and not isinstance(entry, str):
            entry_dictionary = entry.model_dump()
            for key, value in entry_dictionary.items():
                if value is None and key not in fields_to_ignore:
                    entry.__setattr__(key, "")

        # The arguments of the template can be used in the template file:
        result = template.render(
            cv=self.cv,
            design=self.design,
            entry=entry,
            section_title=section_title,
            today=Date.today().strftime("%B %Y"),
            is_first_entry=is_first_entry,
        )

        return result

    def get_full_code(self, main_template_name: str, **kwargs) -> str:
        """Combine all the templates to get the full code of the file."""
        main_template = self.environment.get_template(main_template_name)
        latex_code = main_template.render(
            **kwargs,
        )
        return latex_code


class LaTeXFile(TemplatedFile):
    """This class represents a $\\LaTeX$ file. It generates the $\\LaTeX$ code with the
    data model and Jinja2 templates. It inherits from the TemplatedFile class.
    """

    def render_templates(self):
        """Render and return all the templates for the $\\LaTeX$ file.

        Returns:
            Tuple[str, str, List[Tuple[str, List[str], str]]]: The preamble, header, and
                sections of the $\\LaTeX$ file.
        """
        # Template the preamble, header, and sections:
        preamble = self.template("Preamble")
        header = self.template("Header")
        sections = []
        for section in self.cv.sections:
            section_beginning = self.template(
                "SectionBeginning", section_title=section.title
            )
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
            section_ending = self.template("SectionEnding", section_title=section.title)
            sections.append((section_beginning, entries, section_ending))

        return preamble, header, sections

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
            "SectionBeginning",
            "SectionEnding",
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
        """Template one of the files in the `themes` directory."""
        result = super().template(
            self.design.theme,
            template_name,
            "tex",
            entry,
            section_title,
            is_first_entry,
        )
        return result

    def get_latex_code(self):
        """Get the $\\LaTeX$ code of the file."""
        preamble, header, sections = self.render_templates()
        return self.get_full_code(
            "main.j2.tex",
            preamble=preamble,
            header=header,
            sections=sections,
        )

    def generate_latex_file(self, file_path: pathlib.Path):
        """Write the $\\LaTeX$ code to a file."""
        file_path.write_text(self.get_latex_code(), encoding="utf-8")


class MarkdownFile(TemplatedFile):
    """This class represents a Markdown file. It generates the Markdown code with the
    data model and Jinja2 templates. It inherits from the TemplatedFile class. Markdown
    files are generated to produce a PDF which can be copy-pasted to
    [Grammarly](https://app.grammarly.com/) for proofreading.

    Args:
        data_model (dm.RenderCVDataModel): The data model.
        environment (jinja2.Environment): The Jinja2 environment.
    """

    def render_templates(self):
        """Render and return all the templates for the Markdown file.

        Returns:
            Tuple[str, List[Tuple[str, List[str]]]: The header and sections of the
                Markdown file.
        """
        # Template the header and sections:
        header = self.template("Header")
        sections = []
        for section in self.cv.sections:
            section_beginning = self.template(
                "SectionBeginning", section_title=section.title
            )
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
            sections.append((section_beginning, entries))

        return header, sections

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
            "SectionBeginning",
            "SectionEnding",
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
        """Template one of the files in the `themes` directory."""
        result = super().template(
            "markdown",
            template_name,
            "md",
            entry,
            section_title,
            is_first_entry,
        )
        return result

    def get_markdown_code(self):
        """Get the Markdown code of the file."""
        header, sections = self.render_templates()
        return self.get_full_code(
            "main.j2.md",
            header=header,
            sections=sections,
        )

    def generate_markdown_file(self, file_path: pathlib.Path):
        """Write the Markdown code to a file."""
        file_path.write_text(self.get_markdown_code(), encoding="utf-8")


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

    Args:
        value (str): The string to make something.
        something (str): The LaTeX command to use.
        match_str (str): The string to match.
    Returns:
        str: The string with the matched part something.
    """
    if match_str is None:
        value = f"\\{something}{{{value}}}"
    elif match_str in value and match_str != "":
        value = value.replace(match_str, f"\\{something}{{{match_str}}}")

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
    Returns:
        str: The string with the matched part bold.
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
    Returns:
        str: The string with the matched part underlined.
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
    Returns:
        str: The string with the matched part italic.
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
    Returns:
        str: The string with the matched part non line breakable.
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
    number_of_words = len(name.split(" "))

    if number_of_words == 1:
        return name

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

    Args:
        length (str): The length to divide.
        divider (float): The number to divide the length by.
    Returns:
        str: The divided length.
    """
    # Get the value as a float and the unit as a string:
    value = re.search(r"\d+\.?\d*", length)

    if value is None:
        raise ValueError(f"Invalid length {length}!")
    else:
        value = value.group()

    if divider <= 0:
        raise ValueError(f"The divider must be greater than 0, but got {divider}!")

    unit = re.findall(r"[^\d\.\s]+", length)[0]

    return str(float(value) / divider) + " " + unit


def get_an_item_with_a_specific_attribute_value(
    items: list[Any], attribute: str, value: Any
) -> Any:
    """Get an item from a list of items with a specific attribute value.

    This function can be used as a Jinja2 filter in templates.

    Args:
        items (list[Any]): The list of items.
        attribute (str): The attribute to check.
        value (Any): The value of the attribute.
    Returns:
        Any: The item with the specific attribute value.
    """
    if items is not None:
        for item in items:
            if not hasattr(item, attribute):
                raise AttributeError(
                    f"The attribute {attribute} doesn't exist in the item {item}!"
                )
            else:
                if getattr(item, attribute) == value:
                    return item

    return None


def setup_jinja2_environment() -> jinja2.Environment:
    """Setup and return the Jinja2 environment for templating the $\\LaTeX$ files.

    Returns:
        jinja2.Environment: The theme environment.
    """
    # create a Jinja2 environment:
    # we need to add the current working directory because custom themes might be used.
    themes_directory = pathlib.Path(__file__).parent / "themes"
    environment = jinja2.Environment(
        loader=jinja2.FileSystemLoader([os.getcwd(), themes_directory]),
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
    environment.filters["get_an_item_with_a_specific_attribute_value"] = (
        get_an_item_with_a_specific_attribute_value
    )

    return environment


def generate_latex_file(
    rendercv_data_model: dm.RenderCVDataModel, output_directory: pathlib.Path
) -> pathlib.Path:
    """Generate the $\\LaTeX$ file with the given data model and write it to the output
    directory.

    Args:
        rendercv_data_model (dm.RenderCVDataModel): The data model.
        output_directory (pathlib.Path): Path to the output directory.
    Returns:
        pathlib.Path: The path to the generated $\\LaTeX$ file.
    """
    # create output directory if it doesn't exist:
    if not output_directory.is_dir():
        output_directory.mkdir(parents=True)

    jinja2_environment = setup_jinja2_environment()
    latex_file_object = LaTeXFile(
        rendercv_data_model,
        jinja2_environment,
    )

    latex_file_name = f"{rendercv_data_model.cv.name.replace(' ', '_')}_CV.tex"
    latex_file_path = output_directory / latex_file_name
    latex_file_object.generate_latex_file(latex_file_path)

    return latex_file_path


def generate_markdown_file(
    rendercv_data_model: dm.RenderCVDataModel, output_directory: pathlib.Path
) -> pathlib.Path:
    """Generate the Markdown file with the given data model and write it to the output
    directory.

    Args:
        rendercv_data_model (dm.RenderCVDataModel): The data model.
        output_directory (pathlib.Path): Path to the output directory.
    Returns:
        pathlib.Path: The path to the generated Markdown file.
    """
    # create output directory if it doesn't exist:
    if not output_directory.is_dir():
        output_directory.mkdir(parents=True)

    jinja2_environment = setup_jinja2_environment()
    markdown_file_object = MarkdownFile(
        rendercv_data_model,
        jinja2_environment,
    )

    markdown_file_name = f"{rendercv_data_model.cv.name.replace(' ', '_')}_CV.md"
    markdown_file_path = output_directory / markdown_file_name
    markdown_file_object.generate_markdown_file(markdown_file_path)

    return markdown_file_path


def copy_theme_files_to_output_directory(
    theme_name: str, output_directory: pathlib.Path
):
    """Copy the auxiliary files (all the files that don't end with `.j2.tex` and `.py`)
    of the theme to the output directory. For example, the "classic" theme has custom
    fonts, and the $\\LaTeX$ needs it.

    Args:
        theme_name (str): The name of the theme.
        output_directory (pathlib.Path): Path to the output directory.
    """
    try:
        theme_directory = importlib.resources.files(f"rendercv.themes.{theme_name}")
    except ModuleNotFoundError:
        # Then it means the theme is a custom theme:
        theme_directory = pathlib.Path(os.getcwd()) / theme_name

    for theme_file in theme_directory.iterdir():
        if not ("j2.tex" in theme_file.name or "py" in theme_file.name):
            if theme_file.is_dir():
                shutil.copytree(
                    str(theme_file),
                    output_directory / theme_file.name,
                    dirs_exist_ok=True,
                )
            else:
                shutil.copyfile(str(theme_file), output_directory / theme_file.name)


def generate_latex_file_and_copy_theme_files(
    rendercv_data_model: dm.RenderCVDataModel, output_directory: pathlib.Path
) -> pathlib.Path:
    """Generate the $\\LaTeX$ file with the given data model in the output directory and
    copy the auxiliary theme files to the output directory.

    Args:
        rendercv_data_model (dm.RenderCVDataModel): The data model.
        output_directory (pathlib.Path): Path to the output directory.
    Returns:
        pathlib.Path: The path to the generated $\\LaTeX$ file.
    """
    latex_file_path = generate_latex_file(rendercv_data_model, output_directory)
    copy_theme_files_to_output_directory(
        rendercv_data_model.design.theme, output_directory
    )
    return latex_file_path


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
        "win32": tinytex_binaries_directory / "windows" / "pdflatex.exe",
        "linux": tinytex_binaries_directory / "x86_64-linux" / "pdflatex",
        "darwin": tinytex_binaries_directory / "universal-darwin" / "pdflatex",
    }

    if sys.platform not in executables:
        raise OSError(f"TinyTeX doesn't support the platform {sys.platform}!")

    # Run TinyTeX:
    command = [
        executables[sys.platform],
        str(latex_file_path.absolute()),
    ]
    with subprocess.Popen(
        command,
        cwd=latex_file_path.parent,
        stdout=subprocess.PIPE,  # capture the output
        stderr=subprocess.DEVNULL,  # don't capture the error
        stdin=subprocess.DEVNULL,  # don't allow TinyTeX to ask for user input
    ) as latex_process:
        output = latex_process.communicate()  # wait for the process to finish
        if latex_process.returncode != 0:
            raise RuntimeError(
                "Running TinyTeX has failed! For debugging, we suggest running the"
                " LaTeX file manually in https://overleaf.com.",
                "If you want to run it locally, run the command below in the terminal:",
                " ".join([str(command_part) for command_part in command]),
                "If you can't solve the problem, please open an issue on GitHub.",
            )
        else:
            output = output[0].decode("utf-8")
            if "Rerun to get" in output:
                # Run TinyTeX again to get the references right:
                subprocess.run(
                    command,
                    cwd=latex_file_path.parent,
                    stdout=subprocess.DEVNULL,  # don't capture the output
                    stderr=subprocess.DEVNULL,  # don't capture the error
                    stdin=subprocess.DEVNULL,  # don't allow TinyTeX to ask for user input
                )

    # check if the PDF file is generated:
    pdf_file_path = latex_file_path.with_suffix(".pdf")
    if not pdf_file_path.is_file():
        raise RuntimeError(
            "The PDF file couldn't be generated! If you can't solve the problem,"
            " please try to re-install RenderCV, or open an issue on GitHub."
        )

    return pdf_file_path


def markdown_to_html(markdown_file_path: pathlib.Path) -> pathlib.Path:
    """C
    Args:
        markdown_file_path (pathlib.Path): The path to the Markdown file to convert.
    Returns:
        pathlib.Path: The path to the generated PDF file.
    """

    # check if the file exists:
    if not markdown_file_path.is_file():
        raise FileNotFoundError(f"The file {markdown_file_path} doesn't exist!")

    pdf_file_path = markdown_file_path.with_suffix(".pdf")

    # Convert the markdown file to HTML:
    html = markdown.markdown(markdown_file_path.read_text(encoding="utf-8"))

    # write html into a file:
    html_file_path = markdown_file_path.with_suffix(".html")
    html_file_path.write_text(html, encoding="utf-8")

    # Convert the HTML to PDF:
    # classic_theme_fonts_path = (
    #     pathlib.Path(__file__).parent / "themes" / "classic" / "fonts"
    # )
    # regular_font_path = classic_theme_fonts_path / "SourceSans3-Regular.ttf"
    # bold_font_path = classic_theme_fonts_path / "SourceSans3-Bold.ttf"
    # italic_font_path = classic_theme_fonts_path / "SourceSans3-Italic.ttf"
    # bold_italic_font_path = classic_theme_fonts_path / "SourceSans3-BoldItalic.ttf"
    # pdf = fpdf.FPDF()
    # pdf.add_page()
    # pdf.add_font("SourceSans3", "", regular_font_path)
    # pdf.add_font("SourceSans3", "B", bold_font_path)
    # pdf.add_font("SourceSans3", "I", italic_font_path)
    # pdf.add_font("SourceSans3", "BI", bold_italic_font_path) # type: ignore
    # pdf.set_font("SourceSans3", size=10)
    # pdf.write_html(html)
    # os.chdir(markdown_file_path.parent)
    # pdf.output(pdf_file_path.name)

    return pdf_file_path
