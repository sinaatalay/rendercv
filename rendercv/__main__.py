import sys
import os

from .rendering import read_input_file, render_template, run_latex


def main():
    if len(sys.argv) < 2:
        raise ValueError("Please provide the input file path.")
    elif len(sys.argv) == 2:
        input_file_path = sys.argv[1]
    else:
        raise ValueError(
            "More than one input is provided. Please provide only one input, which is"
            " the input file path."
        )

    file_path = os.path.join(os.getcwd(), input_file_path)
    data = read_input_file(file_path)
    output_latex_file = render_template(data)
    run_latex(output_latex_file)


if __name__ == "__main__":
    main()
