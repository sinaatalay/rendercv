import os
import json
import logging
import re

from jinja2 import Environment, FileSystemLoader

from ruamel.yaml import YAML

from rendercv.data_model import RenderCVDataModel
from rendercv.tinytex import run_latex

if __name__ == "__main__":
    # logging config:
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(name)s - %(levelname)s - %(message)s",
    )

    workspace = os.path.dirname(os.path.dirname(__file__))
    templateName = "classic"
    templatePath = os.path.join(workspace, "rendercv", "templates", templateName)
    environment = Environment(
        loader=FileSystemLoader(templatePath),
        trim_blocks=True,
        lstrip_blocks=True,
    )
    environment.globals.update(str=str)

    def markdown_to_latex(value: str) -> str:
        """
        To be continued...
        """
        if value is None:
            raise ValueError("markdown_to_latex should only be used on strings!")

        # convert links
        link = re.search(r"\[(.*)\]\((.*?)\)", value)
        if link is not None:
            link = link.groups()
            oldLinkString = "[" + link[0] + "](" + link[1] + ")"
            newLinkString = "\hrefExternal{" + link[1] + "}{" + link[0] + "}"

            value = value.replace(oldLinkString, newLinkString)

        return value

    def is_markdown(value: str) -> bool:
        """
        To be continued...
        """
        if re.search(r"\[(.*)\]\((.*?)\)", value) is not None:
            return True
        else:
            return False

    environment.filters["markdown_to_latex"] = markdown_to_latex
    environment.filters["is_markdown"] = is_markdown

    environment.block_start_string = "((*"
    environment.block_end_string = "*))"
    environment.variable_start_string = "<<"
    environment.variable_end_string = ">>"
    environment.comment_start_string = "((#"
    environment.comment_end_string = "#))"

    template = environment.get_template(f"{templateName}.tex.j2")

    inpur_name = "personal"

    input_file_path = os.path.join(workspace, "tests", "inputs", f"{inpur_name}.yaml")
    with open(input_file_path) as file:
        yaml = YAML()
        raw_json = yaml.load(file)

    data = RenderCVDataModel(**raw_json)

    output_latex_file = template.render(design=data.design.options, cv=data.cv)

    # Create an output file and write the rendered LaTeX code to it:
    output_file_path = os.path.join(workspace, "tests", "outputs", f"{inpur_name}.tex")
    os.makedirs(os.path.dirname(output_file_path), exist_ok=True)
    with open(output_file_path, "w") as file:
        file.write(output_latex_file)

    run_latex(output_file_path)
