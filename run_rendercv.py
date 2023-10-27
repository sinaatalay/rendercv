from rendercv.__main__ import render
from rendercv.data_model import generate_json_schema
import os

input_file_path = "John_Doe_CV.yaml"
render(input_file_path) # type: ignore

# This script is equivalent to running the following command in the terminal:
# python -m rendercv personal.yaml
# or
# rendercv personal.yaml

# Generate schema.json
generate_json_schema(os.path.dirname(__file__))
