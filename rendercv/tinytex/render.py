import os
import subprocess


def render(latexFilePath):
    latexFilePath = os.path.normpath(latexFilePath)
    if os.name == "nt":
        tinytexPath = os.path.join(
            os.path.dirname(__file__),
            "vendor",
            "TinyTeX",
            "bin",
            "windows",
        )
        subprocess.run(
            [
                f"{tinytexPath}\\latexmk.exe",
                "-lualatex",
                "-c",
                "test.tex",
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
                "test.tex",
            ],
            cwd=os.path.dirname(latexFilePath),
        )
    else:
        print("Only Windows is supported for now.")
