"""
This module is a script to run the RenderCV and generate a CV as a PDF.
"""

import os

from ruamel.yaml import YAML

from rendercv.data_model import RenderCVDataModel
from rendercv.rendering import render_template, run_latex

input_name = "personal"
workspace = os.path.dirname(__file__)

input_file_path = os.path.join(workspace, "tests", "inputs", f"{input_name}.yaml")
with open(input_file_path) as file:
    yaml = YAML()
    raw_json = yaml.load(file)

data = RenderCVDataModel(**raw_json)
output_latex_file=render_template(data=data)

run_latex(output_latex_file)
