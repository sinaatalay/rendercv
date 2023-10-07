"""This module implements LaTeX file generation and LaTeX runner utilities for RenderCV.
"""
import subprocess
import os
import re
import shutil

from jinja2 import Environment, PackageLoader


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


def markdown_url_to_url(value: str) -> bool:
    """Convert a markdown link to a normal string URL.

    This function is used as a Jinja2 filter.

    Example:
        ```python
        markdown_url_to_url("[Google](https://google.com)")
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
        return url
    else:
        raise ValueError("markdown_url_to_url should only be used on markdown links!")


def make_it_bold(value: str, match_str: str) -> str:
    """Make the matched parts of the string bold.

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
    if not isinstance(value, str):
        raise ValueError("make_it_bold_if should only be used on strings!")

    if not isinstance(match_str, str):
        raise ValueError("The string to match should be a string!")

    if match_str in value:
        value = value.replace(match_str, "\\textbf{" + match_str + "}")
        return value
    else:
        return value


def make_it_underlined(value: str, match_str: str) -> str:
    """Make the matched parts of the string underlined.

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
    if not isinstance(value, str):
        raise ValueError("make_it_underlined_if should only be used on strings!")

    if not isinstance(match_str, str):
        raise ValueError("The string to match should be a string!")

    if match_str in value:
        value = value.replace(match_str, "\\underline{" + match_str + "}")
        return value
    else:
        return value


def make_it_italic(value: str, match_str: str) -> str:
    """Make the matched parts of the string italic.

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
    if not isinstance(value, str):
        raise ValueError("make_it_italic_if should only be used on strings!")

    if not isinstance(match_str, str):
        raise ValueError("The string to match should be a string!")

    if match_str in value:
        value = value.replace(match_str, "\\textit{" + match_str + "}")
        return value
    else:
        return value


def print_today() -> str:
    """Return today's date.

    Returns:
        str: Today's date.
    """
    from datetime import date

    today = date.today()
    return today.strftime("%B %d, %Y")


def get_path_to_fonts_directory() -> str:
    """Return the path to the fonts directory.

    Returns:
        str: The path to the fonts directory.
    """
    return os.path.join(os.path.dirname(__file__), "templates", "fonts")


def render_template(data):
    """Render the template using the given data.

    Args:
        data (RenderCVDataModel): The data to use to render the template.

    Returns:
        str: The path to the rendered LaTeX file.
    """
    # templates_directory = os.path.dirname(os.path.dirname())

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

    # load the template:
    theme = data.design.theme
    template = environment.get_template(f"{theme}.tex.j2")

    # add custom filters:
    environment.filters["markdown_to_latex"] = markdown_to_latex
    environment.filters["markdown_url_to_url"] = markdown_url_to_url
    environment.filters["make_it_bold"] = make_it_bold
    environment.filters["make_it_underlined"] = make_it_underlined
    environment.filters["make_it_italic"] = make_it_italic

    output_latex_file = template.render(
        design=data.design.options,
        cv=data.cv,
        today=print_today(),
        fonts_directory=get_path_to_fonts_directory(),
    )

    # Create an output file and write the rendered LaTeX code to it:
    output_file_path = os.path.join(os.getcwd(), "tests", "outputs", "test.tex")
    os.makedirs(os.path.dirname(output_file_path), exist_ok=True)
    with open(output_file_path, "w") as file:
        file.write(output_latex_file)

    # Copy the fonts directory to the output directory:
    fonts_directory = get_path_to_fonts_directory()
    output_fonts_directory = os.path.join(os.path.dirname(output_file_path), "fonts")
    os.makedirs(output_fonts_directory, exist_ok=True)
    for directory in os.listdir(fonts_directory):
        if directory == "SourceSans3":
            # copy the SourceSans3 fonts:
            source_directory = os.path.join(fonts_directory, directory)

            shutil.copytree(
                source_directory,
                output_fonts_directory,
                dirs_exist_ok=True,
            )

    return output_file_path


def run_latex(latex_file_path):
    """
    Run TinyTeX with the given LaTeX file and generate a PDF.

    Args:
        latexFilePath (str): The path to the LaTeX file to compile.
    """
    latex_file_path = os.path.normpath(latex_file_path)
    latex_file = os.path.basename(latex_file_path)

    if os.name == "nt":
        # remove all files except the .tex file
        for file in os.listdir(os.path.dirname(latex_file_path)):
            if file.endswith(".tex") or file == "fonts":
                continue
            os.remove(os.path.join(os.path.dirname(latex_file_path), file))

        tinytexPath = os.path.join(
            os.path.dirname(__file__),
            "vendor",
            "TinyTeX",
            "bin",
            "windows",
        )
        print("PDF generatation started!")
        subprocess.run(
            [
                f"{tinytexPath}\\latexmk.exe",
                "-lualatex",
                # "-c",
                f"{latex_file}",
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
            ],
            cwd=os.path.dirname(latex_file_path),
            stdout=subprocess.DEVNULL,
        )
        print("PDF generated successfully!")
    else:
        print(
            "Only Windows is supported for now. But you can still use the generated"
            " .tex file to generate the PDF. Go to overleaf.com and upload the .tex"
            " file there to generate the PDF."
        )
