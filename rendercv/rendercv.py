import os
import json
import logging
import re

from jinja2 import Environment, FileSystemLoader

from data.data_model import RenderCVDataModel

# from . import tinytex # https://github.com/praw-dev/praw/blob/master/praw/reddit.py
# from . import templates, sonra mesela: classic.render() tarzi seyler olabilir
from tinytex.render import render




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
        loader=FileSystemLoader(templatePath), trim_blocks=True, lstrip_blocks=True
    )

    def markdown_to_latex(value: str) -> str:
        """
        To be continued...
        """
        # convert links
        link = re.search("\[(.*)\]\((.*?)\)", value)
        if link is not None:
            link = link.groups()
            oldLinkString = "[" + link[0] + "](" + link[1] + ")"
            newLinkString = "\hrefExternal{" + link[1] + "}{" + link[0] + "}"

            value = value.replace(oldLinkString, newLinkString)

        return value
    
    environment.filters["markdown_to_latex"] = markdown_to_latex

    environment.block_start_string = "((*"
    environment.block_end_string = "*))"
    environment.variable_start_string = "<<"
    environment.variable_end_string = ">>"
    environment.comment_start_string = "((#"
    environment.comment_end_string = "#))"

    template = environment.get_template(f"{templateName}.tex.j2")

    inpur_name = "personal"

    input_file_path = os.path.join(workspace, "tests", "inputs", f"{inpur_name}.json")
    with open(input_file_path) as file:
        raw_json = json.load(file)

    data = RenderCVDataModel(**raw_json)

    output_latex_file = template.render(design=data.design.options, cv=data.cv)

    # Create an output file and write the rendered LaTeX code to it:
    output_file_path = os.path.join(workspace, "tests", "outputs", f"{inpur_name}.tex")
    os.makedirs(os.path.dirname(output_file_path), exist_ok=True)
    with open(output_file_path, "w") as file:
        file.write(output_latex_file)

    render(output_file_path)
