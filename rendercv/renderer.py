"""
This module contains functions and classes for generating CVs as $\\LaTeX$ files, PDF
files, Markdown files, HTML files, and PNG files from the data model.

The $\\LaTeX$ and Markdown files are generated with
[Jinja2](https://jinja.palletsprojects.com/en/3.1.x/) templates. Then, the $\\LaTeX$
file is rendered into a PDF with [TinyTeX](https://yihui.org/tinytex/), a $\\LaTeX$
distribution. The markdown file is rendered into an HTML file with `markdown` package.
The PDF files are rendered into PNG files with `PyMuPDF`/`fitz` package.
"""

import copy
import importlib.resources
import pathlib
import re
import shutil
import subprocess
import sys
from datetime import date as Date
from typing import Any, Optional

import fitz
import jinja2
import markdown

from . import data_models as dm


class TemplatedFile:
    """This class is a base class for `LaTeXFile` and `MarkdownFile` classes. It
    contains the common methods and attributes for both classes. These classes are used
    to generate the $\\LaTeX$ and Markdown files with the data model and Jinja2
    templates.

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
        theme_name: str,
        template_name: str,
        extension: str,
        entry: Optional[dm.Entry] = None,
        **kwargs,
    ) -> str:
        """Template one of the files in the `themes` directory.

        Args:
            template_name (str): The name of the template file.
            entry (Optional[dm.Entry]): The title of the section.

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
            today=dm.format_date(Date.today(), use_full_name=True),
            **kwargs,
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
    data model and Jinja2 templates. It inherits from the `TemplatedFile` class.
    """

    def __init__(
        self,
        data_model: dm.RenderCVDataModel,
        environment: jinja2.Environment,
    ):
        latex_file_data_model = copy.deepcopy(data_model)

        if latex_file_data_model.cv.sections_input is not None:
            transformed_sections = transform_markdown_sections_to_latex_sections(
                latex_file_data_model.cv.sections_input
            )
            latex_file_data_model.cv.sections_input = transformed_sections

        super().__init__(latex_file_data_model, environment)

    def render_templates(self) -> tuple[str, str, list[tuple[str, list[str], str]]]:
        """Render and return all the templates for the $\\LaTeX$ file.

        Returns:
            Tuple[str, str, List[Tuple[str, List[str], str]]]: The preamble, header, and
                sections of the $\\LaTeX$ file.
        """
        # Template the preamble, header, and sections:
        preamble = self.template("Preamble")
        header = self.template("Header")
        sections: list[tuple[str, list[str], str]] = []
        for section in self.cv.sections:
            section_beginning = self.template(
                "SectionBeginning",
                section_title=section.title,
                entry_type=section.entry_type,
            )
            entries: list[str] = []
            for i, entry in enumerate(section.entries):
                is_first_entry = i == 0

                entries.append(
                    self.template(
                        section.entry_type,
                        entry=entry,
                        section_title=section.title,
                        entry_type=section.entry_type,
                        is_first_entry=is_first_entry,
                    )
                )
            section_ending = self.template(
                "SectionEnding",
                section_title=section.title,
                entry_type=section.entry_type,
            )
            sections.append((section_beginning, entries, section_ending))

        return preamble, header, sections

    def template(
        self,
        template_name: str,
        entry: Optional[dm.Entry] = None,
        **kwargs,
    ) -> str:
        """Template one of the files in the `themes` directory.

        Args:
            template_name (str): The name of the template file.
            entry (Optional[dm.Entry]): The data model of the entry.

        Returns:
            str: The templated file.
        """
        result = super().template(
            self.design.theme,
            template_name,
            "tex",
            entry,
            **kwargs,
        )

        result = revert_nested_latex_style_commands(result)

        return result

    def get_latex_code(self) -> str:
        """Get the $\\LaTeX$ code of the file.

        Returns:
            str: The $\\LaTeX$ code.
        """
        preamble, header, sections = self.render_templates()
        latex_code: str = self.get_full_code(
            "main.j2.tex",
            preamble=preamble,
            header=header,
            sections=sections,
        )
        return latex_code

    def generate_latex_file(self, file_path: pathlib.Path):
        """Write the $\\LaTeX$ code to a file."""
        file_path.write_text(self.get_latex_code(), encoding="utf-8")


class MarkdownFile(TemplatedFile):
    """This class represents a Markdown file. It generates the Markdown code with the
    data model and Jinja2 templates. It inherits from the `TemplatedFile` class.
    Markdown files are generated to produce an HTML which can be copy-pasted to
    [Grammarly](https://app.grammarly.com/) for proofreading.
    """

    def render_templates(self) -> tuple[str, list[tuple[str, list[str]]]]:
        """Render and return all the templates for the Markdown file.

        Returns:
            tuple[str, List[Tuple[str, List[str]]]]: The header and sections of the
                Markdown file.
        """
        # Template the header and sections:
        header = self.template("Header")
        sections: list[tuple[str, list[str]]] = []
        for section in self.cv.sections:
            section_beginning = self.template(
                "SectionBeginning",
                section_title=section.title,
                entry_type=section.entry_type,
            )
            entries: list[str] = []
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
                        entry_type=section.entry_type,
                        is_first_entry=is_first_entry,
                    )
                )
            sections.append((section_beginning, entries))

        result: tuple[str, list[tuple[str, list[str]]]] = (header, sections)
        return result

    def template(
        self,
        template_name: str,
        entry: Optional[dm.Entry] = None,
        **kwargs,
    ) -> str:
        """Template one of the files in the `themes` directory.

        Args:
            template_name (str): The name of the template file.
            entry (Optional[dm.Entry]): The data model of the entry.

        Returns:
            str: The templated file.
        """
        result = super().template(
            "markdown",
            template_name,
            "md",
            entry,
            **kwargs,
        )
        return result

    def get_markdown_code(self) -> str:
        """Get the Markdown code of the file.

        Returns:
            str: The Markdown code.
        """
        header, sections = self.render_templates()
        markdown_code: str = self.get_full_code(
            "main.j2.md",
            header=header,
            sections=sections,
        )
        return markdown_code

    def generate_markdown_file(self, file_path: pathlib.Path):
        """Write the Markdown code to a file."""
        file_path.write_text(self.get_markdown_code(), encoding="utf-8")


def revert_nested_latex_style_commands(latex_string: str) -> str:
    """Revert the nested $\\LaTeX$ style commands to allow users to unbold or
    unitalicize a bold or italicized text.

    Args:
        latex_string (str): The string to revert the nested $\\LaTeX$ style
            commands.

    Returns:
        str: The string with the reverted nested $\\LaTeX$ style commands.
    """
    # If there is nested \textbf, \textit, or \underline commands, replace the inner
    # ones with \textnormal:
    nested_commands_to_look_for = [
        "textbf",
        "textit",
        "underline",
    ]

    for command in nested_commands_to_look_for:
        nested_commands = True
        while nested_commands:
            # replace all the inner commands with \textnormal until there are no
            # nested commands left:

            # find the first nested command:
            nested_commands = re.findall(
                rf"\\{command}{{[^}}]*?(\\{command}{{.*?}})", latex_string
            )

            # replace the nested command with \textnormal:
            for nested_command in nested_commands:
                new_command = nested_command.replace(command, "textnormal")
                latex_string = latex_string.replace(nested_command, new_command)

    return latex_string


def escape_latex_characters(latex_string: str, strict: bool = True) -> str:
    """Escape $\\LaTeX$ characters in a string.

    This function is called during the reading of the input file. Before the validation
    process, each input field's special $\\LaTeX$ characters are escaped. It is also can
    be used as a Jinja2 filter in templates.

    Example:
        ```python
        escape_latex_characters("This is a # string.")
        ```
        will return:
        `#!python "This is a \\# string."`

    Args:
        latex_string (str): The string to escape.
        strict (bool): Whether to escape all the special $\\LaTeX$ characters or not. If
            you want to allow math input, set it to False.
    Returns:
        str: The escaped string.
    """

    # Dictionary of escape characters:
    escape_characters = {
        "#": "\\#",
        "%": "\\%",
        "&": "\\&",
        "~": "\\textasciitilde{}",
    }

    strict_escape_characters = {
        "$": "\\$",
        "_": "\\_",
        "^": "\\textasciicircum{}",
    }

    if strict:
        # To allow math input, users can use this function with strict = False
        escape_characters.update(strict_escape_characters)

    translation_map = str.maketrans(escape_characters)
    strict_translation_map = str.maketrans(strict_escape_characters)

    # Don't escape urls as hyperref package will do it automatically:
    # Also always escape link placeholders strictly (as we don't expect any math in
    # them):
    # Find all the links in the sentence:
    links = re.findall(r"\[(.*?)\]\((.*?)\)", latex_string)

    # Replace the links with a dummy string and save links with escaped characters:
    new_links = []
    for i, link in enumerate(links):
        placeholder = link[0]
        escaped_placeholder = placeholder.translate(strict_translation_map)
        escaped_placeholder = escaped_placeholder.translate(translation_map)
        url = link[1]

        original_link = f"[{placeholder}]({url})"
        latex_string = latex_string.replace(original_link, f"!!-link{i}-!!")

        new_link = f"[{escaped_placeholder}]({url})"
        new_links.append(new_link)

    # Loop through the letters of the sentence and if you find an escape character,
    # replace it with its LaTeX equivalent:
    latex_string = latex_string.translate(translation_map)

    # Replace !!-link{i}-!!" with the original urls:
    for i, new_link in enumerate(new_links):
        latex_string = latex_string.replace(f"!!-link{i}-!!", new_link)

    return latex_string


def markdown_to_latex(markdown_string: str) -> str:
    """Convert a markdown string to $\\LaTeX$.

    This function is called during the reading of the input file. Before the validation
    process, each input field is converted from markdown to $\\LaTeX$.

    Example:
        ```python
        markdown_to_latex("This is a **bold** text with an [*italic link*](https://google.com).")
        ```

        will return:

        `#!python "This is a \\textbf{bold} text with a \\href{https://google.com}{\\textit{link}}."`

    Args:
        markdown_string (str): The markdown string to convert.

    Returns:
        str: The $\\LaTeX$ string.
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
    bolds = re.findall(r"\*\*(.+?)\*\*", markdown_string)
    if bolds is not None:
        for bold_text in bolds:
            old_bold_text = f"**{bold_text}**"
            new_bold_text = "\\textbf{" + bold_text + "}"

            markdown_string = markdown_string.replace(old_bold_text, new_bold_text)

    # convert italic
    italics = re.findall(r"\*(.+?)\*", markdown_string)
    if italics is not None:
        for italic_text in italics:
            old_italic_text = f"*{italic_text}*"
            new_italic_text = "\\textit{" + italic_text + "}"

            markdown_string = markdown_string.replace(old_italic_text, new_italic_text)

    # convert code
    # not supported by rendercv currently
    # codes = re.findall(r"`([^`]*)`", markdown_string)
    # if codes is not None:
    #     for code_text in codes:
    #         old_code_text = f"`{code_text}`"
    #         new_code_text = "\\texttt{" + code_text + "}"

    #         markdown_string = markdown_string.replace(old_code_text, new_code_text)

    latex_string = markdown_string

    return latex_string


def transform_markdown_sections_to_latex_sections(
    sections: dict[str, dm.SectionInput],
) -> Optional[dict[str, dm.SectionInput]]:
    """
    Recursively loop through sections and convert all the markdown strings (user input
    is in markdown format) to $\\LaTeX$ strings. Also, escape special $\\LaTeX$
    characters.

    Args:
        sections (Optional[dict[str, dm.SectionInput]]): Sections with markdown strings.
    Returns:
        Optional[dict[str, dm.SectionInput]]: Sections with $\\LaTeX$ strings.
    """
    for key, value in sections.items():
        # loop through the list and apply markdown_to_latex and escape_latex_characters
        # to each item:
        transformed_list = []
        for entry in value:
            if isinstance(entry, str):
                # Then it means it's a TextEntry.
                result = markdown_to_latex(escape_latex_characters(entry, strict=False))
                transformed_list.append(result)
            else:
                # Then it means it's one of the other entries.
                entry_as_dict = entry.model_dump()
                for entry_key, value in entry_as_dict.items():
                    if isinstance(value, str):
                        result = markdown_to_latex(
                            escape_latex_characters(value, strict=False)
                        )
                        setattr(entry, entry_key, result)
                    elif isinstance(value, list):
                        for j, item in enumerate(value):
                            if isinstance(item, str):
                                value[j] = markdown_to_latex(
                                    escape_latex_characters(item, strict=False)
                                )
                        setattr(entry, entry_key, value)
                transformed_list.append(entry)

        sections[key] = transformed_list

    return sections


def replace_placeholders_with_actual_values(
    text: str, placeholders: dict[str, Optional[str]]
) -> str:
    """Replace the placeholders in a string with actual values.

    This function can be used as a Jinja2 filter in templates.

    Args:
        text (str): The text with placeholders.
        placeholders (dict[str, str]): The placeholders and their values.
    Returns:
        str: The string with actual values.
    """
    for placeholder, value in placeholders.items():
        text = text.replace(placeholder, str(value))

    return text


def make_matched_part_something(
    value: str, something: str, match_str: Optional[str] = None
) -> str:
    """Make the matched parts of the string something. If the match_str is None, the
    whole string will be made something.

    Warning:
        This function shouldn't be used directly. Use
        [make_matched_part_bold][rendercv.renderer.make_matched_part_bold],
        [make_matched_part_underlined][rendercv.renderer.make_matched_part_underlined],
        [make_matched_part_italic][rendercv.renderer.make_matched_part_italic],
        or
        [make_matched_part_non_line_breakable][rendercv.renderer.make_matched_part_non_line_breakable]
        instead.

    Args:
        value (str): The string to make something.
        something (str): The $\\LaTeX$ command to use.
        match_str (str): The string to match.
    Returns:
        str: The string with the matched part something.
    """
    if match_str is None:
        # If the match_str is None, the whole string will be made something:
        value = f"\\{something}{{{value}}}"
    elif match_str in value and match_str != "":
        # If the match_str is in the value, then make the matched part something:
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


def abbreviate_name(name: Optional[str]) -> str:
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
    if name is None:
        return ""

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
    items: Optional[list[Any]], attribute: str, value: Any
) -> Any:
    """Get an item from a list of items with a specific attribute value.

    Example:
        ```python
        get_an_item_with_a_specific_attribute_value(
            [item1, item2], # where item1.name = "John" and item2.name = "Jane"
            "name",
            "Jane"
        )
        ```
        will return:
        `item2`

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
    else:
        return None


# Only one Jinja2 environment is needed for all the templates:
jinja2_environment: Optional[jinja2.Environment] = None


def setup_jinja2_environment() -> jinja2.Environment:
    """Setup and return the Jinja2 environment for templating the $\\LaTeX$ files.

    Returns:
        jinja2.Environment: The theme environment.
    """
    global jinja2_environment
    themes_directory = pathlib.Path(__file__).parent / "themes"

    if jinja2_environment is None:
        # create a Jinja2 environment:
        # we need to add the current working directory because custom themes might be used.
        environment = jinja2.Environment(
            loader=jinja2.FileSystemLoader([pathlib.Path.cwd(), themes_directory]),
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
        environment.filters["make_it_nolinebreak"] = (
            make_matched_part_non_line_breakable
        )
        environment.filters["make_it_something"] = make_matched_part_something
        environment.filters["divide_length_by"] = divide_length_by
        environment.filters["abbreviate_name"] = abbreviate_name
        environment.filters["replace_placeholders_with_actual_values"] = (
            replace_placeholders_with_actual_values
        )
        environment.filters["get_an_item_with_a_specific_attribute_value"] = (
            get_an_item_with_a_specific_attribute_value
        )
        environment.filters["escape_latex_characters"] = escape_latex_characters

        jinja2_environment = environment
    else:
        # update the loader in case the current working directory has changed:
        jinja2_environment.loader = jinja2.FileSystemLoader(
            [pathlib.Path.cwd(), themes_directory]
        )

    return jinja2_environment


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

    latex_file_name = f"{str(rendercv_data_model.cv.name).replace(' ', '_')}_CV.tex"
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

    markdown_file_name = f"{str(rendercv_data_model.cv.name).replace(' ', '_')}_CV.md"
    markdown_file_path = output_directory / markdown_file_name
    markdown_file_object.generate_markdown_file(markdown_file_path)

    return markdown_file_path


def copy_theme_files_to_output_directory(
    theme_name: str,
    output_directory_path: pathlib.Path,
):
    """Copy the auxiliary files (all the files that don't end with `.j2.tex` and `.py`)
    of the theme to the output directory. For example, a theme can have custom
    fonts, and the $\\LaTeX$ needs it. If the theme is a custom theme, then it will be
    copied from the current working directory.

    Args:
        theme_name (str): The name of the theme.
        output_directory_path (pathlib.Path): Path to the output directory.
    """
    if theme_name in dm.available_themes:
        theme_directory_path = importlib.resources.files(
            f"rendercv.themes.{theme_name}"
        )
    else:
        # Then it means the theme is a custom theme. If theme_directory is not given
        # as an argument, then look for the theme in the current working directory.
        theme_directory_path = pathlib.Path(pathlib.Path.cwd()) / theme_name

        if not theme_directory_path.is_dir():
            raise FileNotFoundError(
                f"The theme {theme_name} doesn't exist in the current working"
                " directory!"
            )

    for theme_file in theme_directory_path.iterdir():
        dont_copy_files_with_these_extensions = [".j2.tex", ".py"]
        # theme_file.suffix returns the latest part of the file name after the last dot.
        # But we need the latest part of the file name after the first dot:
        try:
            suffix = re.search(r"\..*", theme_file.name)[0]
        except TypeError:
            suffix = ""

        if suffix not in dont_copy_files_with_these_extensions:
            if theme_file.is_dir():
                shutil.copytree(
                    str(theme_file),
                    output_directory_path / theme_file.name,
                    dirs_exist_ok=True,
                )
            else:
                shutil.copyfile(
                    str(theme_file), output_directory_path / theme_file.name
                )


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


def latex_to_pdf(
    latex_file_path: pathlib.Path, local_latex_command: Optional[str] = None
) -> pathlib.Path:
    """Run TinyTeX with the given $\\LaTeX$ file to generate the PDF.

    Args:
        latex_file_path (str): The path to the $\\LaTeX$ file to compile.
    Returns:
        pathlib.Path: The path to the generated PDF file.
    """
    # check if the file exists:
    if not latex_file_path.is_file():
        raise FileNotFoundError(f"The file {latex_file_path} doesn't exist!")

    if local_latex_command:
        executable = local_latex_command

        # check if the command is working:
        try:
            subprocess.run(
                [executable, "--version"],
                stdout=subprocess.DEVNULL,  # don't capture the output
                stderr=subprocess.DEVNULL,  # don't capture the error
            )
        except FileNotFoundError:
            raise FileNotFoundError(
                f"[blue]{executable}[/blue] isn't installed! Please install LaTeX and"
                " try again (or don't use the"
                " [bright_black]--use-local-latex-command[/bright_black] option)."
            )
    else:
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

        executable = executables[sys.platform]

        # check if the executable exists:
        if not executable.is_file():
            raise FileNotFoundError(
                f"The TinyTeX executable ({executable}) doesn't exist! If you are"
                " cloning the repository, make sure to clone it recursively to get the"
                " TinyTeX binaries. See the developer guide for more information."
            )

    # Run TinyTeX:
    command = [
        executable,
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
                "Unfortunately, RenderCV's built-in TinyTeX binaries couldn't render"
                " this LaTeX file into a PDF. This could be caused by one of two"
                " reasons:\n\n1- The theme templates might have been updated in a way"
                " RenderCV's TinyTeX cannot render. RenderCV's TinyTeX is minified to"
                " keep the package size small. As a result, it doesn't function like a"
                " general-purpose LaTeX distribution.\n2- Special characters, like"
                " Greek or Chinese letters, that are not compatible with the fonts used"
                " or RenderCV's TinyTeX might have been used.\n\nHowever, this issue"
                " can be resolved quickly. RenderCV allows you to run your own LaTeX"
                " distribution instead of the built-in TinyTeX. This can be done with"
                " the '--use-local-latex-command' option, as shown below:\n\nrendercv"
                " render --use-local-latex-command lualatex John_Doe_CV.yaml\n\nIf you"
                " ensure that the generated LaTeX file can be compiled by your local"
                " LaTeX distribution, RenderCV will work successfully. You can debug"
                " the generated LaTeX file in your LaTeX editor to resolve any bugs."
                " Then, you can start using RenderCV with your local LaTeX"
                " distribution.\n\nIf you can't solve the problem, please open an issue"
                " on GitHub."
            )
        else:
            try:
                output = output[0].decode("utf-8")
            except UnicodeDecodeError:
                output = output[0].decode("latin-1")

            if "Rerun to get" in output:
                # Run TinyTeX again to get the references right:
                subprocess.run(
                    command,
                    cwd=latex_file_path.parent,
                    stdout=subprocess.DEVNULL,  # don't capture the output
                    stderr=subprocess.DEVNULL,  # don't capture the error
                    stdin=subprocess.DEVNULL,  # don't allow TinyTeX to ask for user input
                )

    pdf_file_path = latex_file_path.with_suffix(".pdf")

    return pdf_file_path


def pdf_to_pngs(pdf_file_path: pathlib.Path) -> list[pathlib.Path]:
    """Convert the given PDF file to PNG files.

    Args:
        pdf_file_path (pathlib.Path): The path to the PDF file to convert.
    Returns:
        list[pathlib.Path]: The paths to the generated PNG files.
    """
    # check if the file exists:
    if not pdf_file_path.is_file():
        raise FileNotFoundError(f"The file {pdf_file_path} doesn't exist!")

    # convert the PDF to PNG:
    png_directory = pdf_file_path.parent
    png_file_name = pdf_file_path.stem
    png_files = []
    pdf = fitz.open(pdf_file_path)  # open the PDF file
    for page in pdf:  # iterate the pages
        image = page.get_pixmap(dpi=300)
        png_file_path = png_directory / f"{png_file_name}_{page.number+1}.png"
        image.save(png_file_path)
        png_files.append(png_file_path)

    return png_files


def markdown_to_html(markdown_file_path: pathlib.Path) -> pathlib.Path:
    """Convert a markdown file to HTML with the same name and in the same directory.
    It uses `rendercv/themes/main.j2.html` as the Jinja2 template.

    Args:
        markdown_file_path (pathlib.Path): The path to the markdown file to convert.
    Returns:
        pathlib.Path: The path to the generated HTML file.
    """
    # check if the file exists:
    if not markdown_file_path.is_file():
        raise FileNotFoundError(f"The file {markdown_file_path} doesn't exist!")

    # Convert the markdown file to HTML:
    markdown_text = markdown_file_path.read_text(encoding="utf-8")
    html_body = markdown.markdown(markdown_text)

    # Get the title of the markdown content:
    title = re.search(r"# (.*)\n", markdown_text)
    if title is None:
        title = ""
    else:
        title = title.group(1)

    jinja2_environment = setup_jinja2_environment()
    html_template = jinja2_environment.get_template("main.j2.html")
    html = html_template.render(html_body=html_body, title=title)

    # Write html into a file:
    html_file_path = markdown_file_path.parent / f"{markdown_file_path.stem}.html"
    html_file_path.write_text(html, encoding="utf-8")

    return html_file_path
