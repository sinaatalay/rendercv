import os
from rendercv.__main__ import main as rendercv_main
from rendercv.data_model import generate_json_schema

input_file_path = "personal.yaml"
rendercv_main(input_file_path)

# This script is equivalent to running the following command in the terminal:
# python -m rendercv personal.yaml
# or
# rendercv personal.yaml

# Generate schema.json
# generate_json_schema(os.path.join(os.path.dirname(__file__)))

