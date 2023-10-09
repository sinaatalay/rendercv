"""This module implements LaTeX file generation and LaTeX runner utilities for RenderCV.
"""
import subprocess
import os
import re
import shutil
from datetime import date
import logging
import time

from rendercv.data_model import RenderCVDataModel

from jinja2 import Environment, PackageLoader
from ruamel.yaml import YAML

logger = logging.getLogger(__name__)


def markdown_to_latex(markdown_string: str) -> str:
    """Convert a markdown string to LaTeX.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        markdown_to_latex("This is a **bold** text with an [*italic link*](https://google.com).")
        ```

        will return:

        `#!pytjon "This is a \\textbf{bold} text with a \\hrefExternal{https://google.com}{\\textit{link}}."`

    Args:
        value (str): The markdown string to convert.

    Returns:
        str: The LaTeX string.
    """
    if not isinstance(markdown_string, str):
        raise ValueError("markdown_to_latex should only be used on strings!")

    # convert links
    links = re.findall(r"\[([^\]\[]*)\]\((.*?)\)", markdown_string)
    if links is not None:
        for link in links:
            link_text = link[0]
            link_url = link[1]

            old_link_string = f"[{link_text}]({link_url})"
            new_link_string = "\\hrefExternal{" + link_url + "}{" + link_text + "}"

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

    latex_string = markdown_string

    return latex_string


def markdown_link_to_url(value: str) -> bool:
    """Convert a markdown link to a normal string URL.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        markdown_link_to_url("[Google](https://google.com)")
        ```

        will return:

        `#!python "https://google.com"`

    Args:
        value (str): The markdown link to convert.

    Returns:
        str: The URL as a string.
    """
    if not isinstance(value, str):
        raise ValueError("markdown_to_latex should only be used on strings!")

    link = re.search(r"\[(.*)\]\((.*?)\)", value)
    if link is not None:
        url = link.groups()[1]
        if url == "":
            raise ValueError(f"The markdown link {value} is empty!")
        return url
    else:
        raise ValueError("markdown_link_to_url should only be used on markdown links!")


def make_it_something(value: str, something: str, match_str: str = None) -> str:
    """Make the matched parts of the string something. If the match_str is None, the
    whole string will be made something.

    Warning:
        This function shouldn't be used directly. Use
        (make_it_bold)[#rendercv.rendering.make_it_bold],
        (make_it_underlined)[#rendercv.rendering.make_it_underlined], or
        (make_it_italic)[#rendercv.rendering.make_it_italic] instead.
    """
    if not isinstance(value, str):
        raise ValueError(f"{something} should only be used on strings!")

    if match_str is not None and not isinstance(match_str, str):
        raise ValueError("The string to match should be a string!")

    if something == "make_it_bold":
        keyword = "textbf"
    elif something == "make_it_underlined":
        keyword = "underline"
    elif something == "make_it_italic":
        keyword = "textit"

    if match_str is None:
        return f"\\{keyword}{{{value}}}"

    if match_str in value:
        value = value.replace(match_str, f"\\{keyword}{{{match_str}}}")
        return value
    else:
        return value


def make_it_bold(value: str, match_str: str = None) -> str:
    """Make the matched parts of the string bold. If the match_str is None, the whole
    string will be made bold.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        make_it_bold_if("Hello World!", "Hello")
        ```

        will return:

        `#!python "\\textbf{Hello} World!"`

    Args:
        value (str): The string to make bold.
        match_str (str): The string to match.
    """
    return make_it_something(value, "make_it_bold", match_str)


def make_it_underlined(value: str, match_str: str = None) -> str:
    """Make the matched parts of the string underlined. If the match_str is None, the
    whole string will be made underlined.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        make_it_underlined_if("Hello World!", "Hello")
        ```

        will return:

        `#!python "\\underline{Hello} World!"`

    Args:
        value (str): The string to make underlined.
        match_str (str): The string to match.
    """
    return make_it_something(value, "make_it_underlined", match_str)


def make_it_italic(value: str, match_str: str = None) -> str:
    """Make the matched parts of the string italic. If the match_str is None, the whole
    string will be made italic.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        make_it_italic_if("Hello World!", "Hello")
        ```

        will return:

        `#!python "\\textit{Hello} World!"`

    Args:
        value (str): The string to make italic.
        match_str (str): The string to match.
    """
    return make_it_something(value, "make_it_italic", match_str)


def divide_length_by(length: str, divider: float) -> str:
    r"""Divide a length by a number.

    Length is a string with the following regex pattern: `\d+\.?\d* *(cm|in|pt|mm|ex|em)`
    """
    # Get the value as a float and the unit as a string:
    value = re.search(r"\d+\.?\d*", length).group()
    unit = re.findall(r"[^\d\.\s]+", length)[0]

    return str(float(value) / divider) + " " + unit


def get_today() -> str:
    """Return today's date.

    Returns:
        str: Today's date.
    """

    today = date.today()
    return today.strftime("%B %d, %Y")


def get_path_to_font_directory(font_name: str) -> str:
    """Return the path to the fonts directory.

    Returns:
        str: The path to the fonts directory.
    """
    return os.path.join(os.path.dirname(__file__), "templates", "fonts", font_name)


def read_input_file(file_path: str) -> RenderCVDataModel:
    """Read the input file.

    Args:
        file_path (str): The path to the input file.

    Returns:
        str: The input file as a string.
    """
    start_time = time.time()
    logger.info(f"Reading and validating the input file {file_path} has started.")
    with open(file_path) as file:
        yaml = YAML()
        raw_json = yaml.load(file)

    data = RenderCVDataModel(**raw_json)

    end_time = time.time()
    time_taken = end_time - start_time
    logger.info(
        f"Reading and validating the input file {file_path} has finished in"
        f" {time_taken:.2f} s."
    )
    return data


def render_template(data: RenderCVDataModel, output_path: str = None) -> str:
    """Render the template using the given data.

    Args:
        data (RenderCVDataModel): The data to use to render the template.

    Returns:
        str: The path to the rendered LaTeX file.
    """
    start_time = time.time()
    logger.info("Rendering the LaTeX file has started.")
    # create a Jinja2 environment:
    environment = Environment(
        loader=PackageLoader("rendercv", "templates"),
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
    environment.filters["markdown_link_to_url"] = markdown_link_to_url
    environment.filters["make_it_bold"] = make_it_bold
    environment.filters["make_it_underlined"] = make_it_underlined
    environment.filters["make_it_italic"] = make_it_italic
    environment.filters["divide_length_by"] = divide_length_by

    # load the template:
    theme = data.design.theme
    template = environment.get_template(f"{theme}.tex.j2")

    output_latex_file = template.render(
        cv=data.cv,
        design=data.design,
        theme_options=data.design.options,
        today=get_today(),
    )

    # Create an output file and write the rendered LaTeX code to it:
    if output_path is None:
        output_path = os.getcwd()

    output_folder = os.path.join(output_path, "output")
    file_name = data.cv.name.replace(" ", "_") + "_CV.tex"
    output_file_path = os.path.join(output_folder, file_name)
    os.makedirs(os.path.dirname(output_file_path), exist_ok=True)
    with open(output_file_path, "w") as file:
        file.write(output_latex_file)

    # Copy the fonts directory to the output directory:
    # Remove the old fonts directory if it exists:
    if os.path.exists(os.path.join(os.path.dirname(output_file_path), "fonts")):
        shutil.rmtree(os.path.join(os.path.dirname(output_file_path), "fonts"))

    font_directory = get_path_to_font_directory(data.design.font)
    output_fonts_directory = os.path.join(os.path.dirname(output_file_path), "fonts")
    shutil.copytree(
        font_directory,
        output_fonts_directory,
        dirs_exist_ok=True,
    )

    end_time = time.time()
    time_taken = end_time - start_time
    logger.info(f"Rendering the LaTeX file has finished in {time_taken:.2f} s.")

    return output_file_path


def run_latex(latex_file_path):
    """
    Run TinyTeX with the given LaTeX file and generate a PDF.

    Args:
        latexFilePath (str): The path to the LaTeX file to compile.
    """
    start_time = time.time()
    logger.info("Running TinyTeX to generate the PDF has started.")
    latex_file = os.path.basename(latex_file_path)
    latex_file_path = os.path.normpath(latex_file_path)

    output_file = latex_file.replace(".tex", ".pdf")
    output_file_path = os.path.join(os.path.dirname(latex_file_path), output_file)

    # remove all files except the .tex file
    for file in os.listdir(os.path.dirname(latex_file_path)):
        if file.endswith(".tex") or file == "fonts":
            continue
        # remove the file:
        os.remove(os.path.join(os.path.dirname(latex_file_path), file))
    if os.name == "nt":
        tinytex_path = os.path.join(
            os.path.dirname(__file__),
            "vendor",
            "TinyTeX",
            "bin",
            "windows",
        )
        executable = os.path.join(tinytex_path, "lualatex.exe")

    else:
        tinytex_path = os.path.join(
            os.path.dirname(__file__),
            "vendor",
            "TinyTeX",
            "bin",
            "x86_64-linux",
        )
        executable = os.path.join(tinytex_path, "lualatex")

    subprocess.run(
        [
            executable,
            f"{latex_file}",
        ],
        cwd=os.path.dirname(latex_file_path),
        stdout=subprocess.DEVNULL,  # suppress latexmk output
    )
    end_time = time.time()
    time_taken = end_time - start_time
    logger.info(
        f"Running TinyTeX to generate the PDF has finished in {time_taken:.2f} s."
    )

    return os.path.join(
        os.path.dirname(latex_file_path), latex_file.replace(".tex", ".pdf")
    )
