# RenderCV
[![CI](https://github.com/sinaatalay/rendercv/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/sinaatalay/rendercv/actions/workflows/ci.yaml)
[![coverage](https://coverage-badge.samuelcolvin.workers.dev/sinaatalay/rendercv.svg)](https://coverage-badge.samuelcolvin.workers.dev/redirect/sinaatalay/rendercv)
[![pypi-version](https://img.shields.io/pypi/v/rendercv?label=PyPI%20version&color=rgb(0%2C79%2C144))](https://pypi.python.org/pypi/rendercv)
[![pypi-downloads](https://img.shields.io/pepy/dt/rendercv?label=PyPI%20downloads&color=rgb(0%2C%2079%2C%20144))](https://pypi.python.org/pypi/rendercv)


RenderCV is a Python application that creates a $\LaTeX$ CV as a PDF from a JSON/YAML input file. Currently, it only supports one theme (*classic*). An example PDF can be seen [here](https://github.com/sinaatalay/rendercv/blob/main/John_Doe_CV.pdf?raw=true). More themes are planned to be supported in the future.

**What does it do?**

- It parses a YAML (or JSON) file that looks like this:
```yaml
cv:
  name: John Doe
  label: Mechanical Engineer
  location: Geneva, Switzerland
  email: johndoe@example.com
  phone: "+33749882538"
  website: https://example.com
  social_networks:
    - network: GitHub
      username: johndoe
    - network: LinkedIn
      username: johndoe
  education:
    - institution: My University
      url: https://example.com
      area: Mechanical Engineering
      study_type: BS
      location: Geneva, Switzerland
      start_date: "2017-09-01"
      end_date: "2023-01-01"
      transcript_url: https://example.com
      gpa: 3.10/4.00
      highlights:
        - "Class rank: 10 of 62"
    - institution: The University of Texas at Austin
      url: https://utexas.edu
      area: Mechanical Engineering, Student Exchange Program
      location: Austin, TX, USA
      start_date: "2021-08-01"
      end_date: "2022-01-15"
  work_experience:
    - company: AmIACompany
      position: Summer Intern
      location: Istanbul, Turkey
      url: https://example.com
      start_date: "2022-06-15"
      end_date: "2022-08-01"
      highlights:
        - AmIACompany is a **technology** (markdown is
          supported) company that provides web-based
          engineering applications that enable the
          simulation and optimization of products and
          manufacturing tools.
        - Modeled and simulated a metal-forming process deep
          drawing using finite element analysis with
          open-source software called CalculiX.
```
- Then, it validates the input, such as checking if the dates are consistent, checking if the URLs are correct, etc.
- Then, it creates a $\LaTeX$ file.
- Finally, it renders the $\LaTeX$ file to generate the PDF, and you don't need $\LaTeX$ installed on your PC because RenderCV comes with [TinyTeX](https://yihui.org/tinytex/).

![RenderCV example](docs/images/example.png)

## Quick Start Guide

1. Install [`Python3`](https://www.python.org/downloads/) (`3.10` or newer).
1. Install [`TinyTex`](https://yihui.org/tinytex/)
    `TinyTex` offers [four different bundles](https://github.com/rstudio/tinytex-releases#releases). The `TinyTex` (without a trailing number) is the bundle that has all the required dependencies, however, it is the second largest by size.
    1. macOS/Linux:
        ```shell
        curl -sL "https://yihui.org/tinytex/install-bin-unix.sh" | TINYTEX_INSTALLER=TinyTex sh
        ```
    1. Windows
        Download <https://yihui.org/tinytex/install-bin-windows.bat>. Open `Powershell`, navigate (`cwd`) to the file then run:
        ```shell
        TINYTEX_INSTALLER=TinyTex install-bin-windows.bat
        ```

    Alternatively, the smaller bundle `TinyTex-1` can be used if the following additional dependencies are installed:

        ```shell
        TINYTEX_INSTALLER=TinyTex-1 ...
        tlmgr install titlesec enumitem fontawesome5 eso-pic bookmark lastpage
        ```

1. Run the command below to install RenderCV.
    ```shell
    python3 -m pip install rendercv
    ```
1. Run the command below to generate a sample input file (`Full_Name_CV.yaml`). The file will be generated in the current working directory.
    ```shell
    rendercv new "Full Name"
    ```
1. Edit the contents of the `Full_Name_CV.yaml` file.
1. Run the command below to generate your $\LaTeX$ CV.
    ```bash
    rendercv render Full_Name_CV.yaml
    ```

## Detailed User Guide and Documentation

The code is documented and includes docstrings. For more information, see the following:
- [User guide](https://sinaatalay.github.io/rendercv/user_guide)
- [API reference](https://sinaatalay.github.io/rendercv/api_reference/)

## Contributing

All contributions to RenderCV are welcome, especially adding new $\LaTeX$ themes.
