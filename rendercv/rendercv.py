from jinja2 import Environment, FileSystemLoader
from data.content import CurriculumVitae
import os
import json

workspace = os.path.dirname(os.path.dirname(__file__))
environment = Environment(loader=FileSystemLoader(os.path.join(workspace, "rendercv", "templates")))
environment.block_start_string = "((*"
environment.block_end_string = "*))"
environment.variable_start_string = "((("
environment.variable_end_string = ")))"
environment.comment_start_string = "((="
environment.comment_end_string = "=))"

template = environment.get_template("template1.tex.j2")

input_file_path = os.path.join(workspace, "tests", "inputs", "test.json")
with open(input_file_path) as file:
    raw_json = json.load(file)

data = CurriculumVitae(**raw_json)

output_latex_file = template.render(data=data)

# Create an output file and write the rendered LaTeX code to it:
output_file_path = os.path.join(workspace, "tests", "outputs", "test.tex")
with open(output_file_path, "w") as file:
    file.write(output_latex_file)

    