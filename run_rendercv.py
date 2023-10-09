"""
This module is a script to run the RenderCV and generate a CV as a PDF.
"""

import os


import rendercv.__main__ as rendercv

input_name = "personal"
workspace = os.path.dirname(__file__)
file_path = os.path.join(workspace, "tests", "inputs", f"{input_name}.yaml")

rendercv.main(args=[file_path])
