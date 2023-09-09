import os
import subprocess

def run_latex(latexFilePath):
    latexFilePath = os.path.normpath(latexFilePath)
    latexFile = os.path.basename(latexFilePath)

    if os.name == "nt":
        # remove all files except the .tex file
        for file in os.listdir(os.path.dirname(latexFilePath)):
            if file.endswith(".tex"):
                continue
            os.remove(os.path.join(os.path.dirname(latexFilePath), file))
        
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
                # "-c",
                f"{latexFile}",
                "-synctex=1",
                "-interaction=nonstopmode",
                "-file-line-error",
            ],
            cwd=os.path.dirname(latexFilePath),
        )
    else:
        print("Only Windows is supported for now.")
