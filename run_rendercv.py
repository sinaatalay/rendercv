import rendercv.__main__ as rendercv

# input_file_path = "personal.yaml"
# rendercv.main(input_file_path)

# This script is equivalent to running the following command in the terminal:
# python -m rendercv personal.yaml
# or
# rendercv personal.yaml

from rendercv.data_model import RenderCVDataModel

jsoan = RenderCVDataModel.model_json_schema()
import json
# write json to file
with open("json_schema.json", "w") as f:
    f.write(json.dumps(jsoan))

