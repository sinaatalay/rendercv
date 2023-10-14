"""
This module is a script to run the RenderCV and generate a CV as a PDF. It is an entry
point for the RenderCV package.
"""
import os
import logging
import sys

from rendercv.rendering import read_input_file, render_template, run_latex


def main(args=sys.argv[1:]):
    """
    This is the main function to run RenderCV.
    """
    logger = logging.getLogger(__name__)

    if len(args) != 1:
        raise ValueError("Please provide the input file path.")
    elif len(args) == 1:
        input_file_path = args[0]
    else:
        raise ValueError(
            "More than one input is provided. Please provide only one input, which is"
            " the input file path."
        )

    # input_file_path = sys.argv[1]
    file_path = os.path.join(os.getcwd(), input_file_path)
    data = read_input_file(file_path)
    output_latex_file = render_template(data)
    run_latex(output_latex_file)

if __name__ == "__main__":
    main(args=["tests/inputs/personal.yaml"])
