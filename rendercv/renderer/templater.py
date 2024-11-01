"""
The `rendercv.renderer.templater` module contains all the necessary classes and
functions for templating the $\\LaTeX$ and Markdown files from the `RenderCVDataModel`
object.
"""

import copy
import pathlib
import re
from datetime import date as Date
from typing import Any, Literal, Optional

import jinja2

from .. import data


class TemplatedFile:
    """This class is a base class for `LaTeXFile` and `MarkdownFile` classes. It
    contains the common methods and attributes for both classes. These classes are used
    to generate the $\\LaTeX$ and Markdown files with the data model and Jinja2
    templates.

    Args:
        data_model: The data model.
        environment: The Jinja2 environment.
    """

    def __init__(
        self,
        data_model: data.RenderCVDataModel,
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
        entry: Optional[data.Entry] = None,
        **kwargs,
    ) -> str:
        """Template one of the files in the `themes` directory.

        Args:
            template_name: The name of the template file.
            entry: The title of the section.

        Returns:
            The templated file.
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
            today=data.format_date(Date.today(), date_style="FULL_MONTH_NAME YEAR"),
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
        data_model: data.RenderCVDataModel,
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
            The preamble, header, and sections of the $\\LaTeX$ file.
        """
        # Template the preamble, header, and sections:
        preamble = self.template("Preamble")
        header = self.template("Header")
        sections: list[tuple[str, list[str], str]] = []
        for section in self.cv.sections:
            section_beginning = self.template(
                "SectionBeginning",
                section_title=escape_latex_characters(section.title),
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
        entry: Optional[data.Entry] = None,
        **kwargs,
    ) -> str:
        """Template one of the files in the `themes` directory.

        Args:
            template_name: The name of the template file.
            entry: The data model of the entry.

        Returns:
            The templated file.
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

    def get_full_code(self) -> str:
        """Get the $\\LaTeX$ code of the file.

        Returns:
            The $\\LaTeX$ code.
        """
        preamble, header, sections = self.render_templates()
        latex_code: str = super().get_full_code(
            "main.j2.tex",
            preamble=preamble,
            header=header,
            sections=sections,
        )
        return latex_code

    def create_file(self, file_path: pathlib.Path):
        """Write the $\\LaTeX$ code to a file."""
        file_path.write_text(self.get_full_code(), encoding="utf-8")


class MarkdownFile(TemplatedFile):
    """This class represents a Markdown file. It generates the Markdown code with the
    data model and Jinja2 templates. It inherits from the `TemplatedFile` class.
    Markdown files are generated to produce an HTML which can be copy-pasted to
    [Grammarly](https://app.grammarly.com/) for proofreading.
    """

    def render_templates(self) -> tuple[str, list[tuple[str, list[str]]]]:
        """Render and return all the templates for the Markdown file.

        Returns:
            The header and sections of the Markdown file.
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
        entry: Optional[data.Entry] = None,
        **kwargs,
    ) -> str:
        """Template one of the files in the `themes` directory.

        Args:
            template_name: The name of the template file.
            entry: The data model of the entry.

        Returns:
            The templated file.
        """
        result = super().template(
            "markdown",
            template_name,
            "md",
            entry,
            **kwargs,
        )
        return result

    def get_full_code(self) -> str:
        """Get the Markdown code of the file.

        Returns:
            The Markdown code.
        """
        header, sections = self.render_templates()
        markdown_code: str = super().get_full_code(
            "main.j2.md",
            header=header,
            sections=sections,
        )
        return markdown_code

    def create_file(self, file_path: pathlib.Path):
        """Write the Markdown code to a file."""
        file_path.write_text(self.get_full_code(), encoding="utf-8")


def revert_nested_latex_style_commands(latex_string: str) -> str:
    """Revert the nested $\\LaTeX$ style commands to allow users to unbold or
    unitalicize a bold or italicized text.

    Args:
        latex_string: The string to revert the nested $\\LaTeX$ style commands.

    Returns:
        The string with the reverted nested $\\LaTeX$ style commands.
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


def escape_latex_characters(latex_string: str) -> str:
    """Escape $\\LaTeX$ characters in a string by adding a backslash before them.

    Example:
        ```python
        escape_latex_characters("This is a # string.")
        ```
        returns
        `"This is a \\# string."`

    Args:
        latex_string: The string to escape.

    Returns:
        The escaped string.
    """

    # Dictionary of escape characters:
    escape_characters = {
        "{": "\\{",
        "}": "\\}",
        # "\\": "\\textbackslash{}",
        "#": "\\#",
        "%": "\\%",
        "&": "\\&",
        "~": "\\textasciitilde{}",
        "$": "\\$",
        "_": "\\_",
        "^": "\\textasciicircum{}",
    }
    translation_map = str.maketrans(escape_characters)

    # Don't escape urls as hyperref package will do it automatically:
    # Find all the links in the sentence:
    links = re.findall(r"\[(.*?)\]\((.*?)\)", latex_string)

    # Replace the links with a dummy string and save links with escaped characters:
    new_links = []
    for i, link in enumerate(links):
        placeholder = link[0]
        escaped_placeholder = placeholder.translate(translation_map)
        url = link[1]

        original_link = f"[{placeholder}]({url})"
        latex_string = latex_string.replace(original_link, f"!!-link{i}-!!")

        new_link = f"[{escaped_placeholder}]({url})"
        new_links.append(new_link)

    # If there are equations in the sentence, don't escape the special characters:
    # Find all the equations in the sentence:
    equations = re.findall(r"(\$\$.*?\$\$)", latex_string)
    new_equations = []
    for i, equation in enumerate(equations):
        latex_string = latex_string.replace(equation, f"!!-equation{i}-!!")

        # Keep only one dollar sign for inline equations:
        new_equation = equation.replace("$$", "$")
        new_equations.append(new_equation)

    # Don't touch latex commands:
    # Find all the latex commands in the sentence:
    latex_commands = re.findall(r"\\[a-zA-Z]+\{.*?\}", latex_string)
    for i, latex_command in enumerate(latex_commands):
        latex_string = latex_string.replace(latex_command, f"!!-latex{i}-!!")

    # Loop through the letters of the sentence and if you find an escape character,
    # replace it with its LaTeX equivalent:
    latex_string = latex_string.translate(translation_map)

    # Replace !!-link{i}-!!" with the original urls:
    for i, new_link in enumerate(new_links):
        latex_string = latex_string.replace(f"!!-link{i}-!!", new_link)

    # Replace !!-equation{i}-!!" with the original equations:
    for i, new_equation in enumerate(new_equations):
        latex_string = latex_string.replace(f"!!-equation{i}-!!", new_equation)

    # Replace !!-latex{i}-!!" with the original latex commands:
    for i, latex_command in enumerate(latex_commands):
        latex_string = latex_string.replace(f"!!-latex{i}-!!", latex_command)

    return latex_string


def markdown_to_latex(markdown_string: str) -> str:
    """Convert a Markdown string to $\\LaTeX$.

    This function is called during the reading of the input file. Before the validation
    process, each input field is converted from Markdown to $\\LaTeX$.

    Example:
        ```python
        markdown_to_latex("This is a **bold** text with an [*italic link*](https://google.com).")
        ```

        returns

        `"This is a \\textbf{bold} text with a \\href{https://google.com}{\\textit{link}}."`

    Args:
        markdown_string: The Markdown string to convert.

    Returns:
        The $\\LaTeX$ string.
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
    sections: dict[str, data.SectionContents],
) -> Optional[dict[str, data.SectionContents]]:
    """
    Recursively loop through sections and convert all the Markdown strings (user input
    is in Markdown format) to $\\LaTeX$ strings. Also, escape special $\\LaTeX$
    characters.

    Args:
        sections: Sections with Markdown strings.

    Returns:
        Sections with $\\LaTeX$ strings.
    """
    for key, value in sections.items():
        # loop through the list and apply markdown_to_latex and escape_latex_characters
        # to each item:
        transformed_list = []
        for entry in value:
            if isinstance(entry, str):
                # Then it means it's a TextEntry.
                result = markdown_to_latex(escape_latex_characters(entry))
                transformed_list.append(result)
            else:
                # Then it means it's one of the other entries.
                fields_to_skip = ["doi"]
                entry_as_dict = entry.model_dump()
                for entry_key, value in entry_as_dict.items():
                    if entry_key in fields_to_skip:
                        continue
                    if isinstance(value, str):
                        result = markdown_to_latex(escape_latex_characters(value))
                        setattr(entry, entry_key, result)
                    elif isinstance(value, list):
                        for j, item in enumerate(value):
                            if isinstance(item, str):
                                value[j] = markdown_to_latex(
                                    escape_latex_characters(item)
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
        text: The text with placeholders.
        placeholders: The placeholders and their values.

    Returns:
        The string with actual values.
    """
    for placeholder, value in placeholders.items():
        text = text.replace(placeholder, str(value))

    return text


def make_matched_part_something(
    value: str,
    something: Literal["textbf", "underline", "textit", "mbox"],
    match_str: Optional[str] = None,
) -> str:
    """Make the matched parts of the string something. If the match_str is None, the
    whole string will be made something.

    Warning:
        This function shouldn't be used directly. Use `make_matched_part_bold`,
        `make_matched_part_underlined`, `make_matched_part_italic`, or
        `make_matched_part_non_line_breakable instead.
    Args:
        value: The string to make something.
        something: The $\\LaTeX$ command to use.
        match_str: The string to match.

    Returns:
        The string with the matched part something.
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

        returns

        `"\\textbf{Hello} World!"`

    Args:
        value: The string to make bold.
        match_str: The string to match.

    Returns:
        The string with the matched part bold.
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

        returns

        `"\\underline{Hello} World!"`

    Args:
        value: The string to make underlined.
        match_str: The string to match.

    Returns:
        The string with the matched part underlined.
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

        returns

        `"\\textit{Hello} World!"`

    Args:
        value: The string to make italic.
        match_str: The string to match.

    Returns:
        The string with the matched part italic.
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

        returns

        `"\\mbox{Hello} World!"`

    Args:
        value: The string to disable line breaks.
        match_str: The string to match.

    Returns:
        The string with the matched part non line breakable.
    """
    return make_matched_part_something(value, "mbox", match_str)


def abbreviate_name(name: Optional[str]) -> str:
    """Abbreviate a name by keeping the first letters of the first names.

    This function can be used as a Jinja2 filter in templates.

    Example:
        ```python
        abbreviate_name("John Doe")
        ```

        returns

        `"J. Doe"`

    Args:
        name: The name to abbreviate.

    Returns:
        The abbreviated name.
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

        returns

        `"5.2cm"`

    Args:
        length: The length to divide.
        divider: The number to divide the length by.

    Returns:
        The divided length.
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
        returns
        `item2`

    This function can be used as a Jinja2 filter in templates.

    Args:
        items: The list of items.
        attribute: The attribute to check.
        value: The value of the attribute.

    Returns:
        The item with the specific attribute value.
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
        The theme environment.
    """
    global jinja2_environment
    themes_directory = pathlib.Path(__file__).parent.parent / "themes"

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
