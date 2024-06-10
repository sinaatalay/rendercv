# User Guide

This document provides everything you need to know about the usage of RenderCV.

## Installation

> RenderCV doesn't require a $\LaTeX$ installation; it comes with it!

1. Install [Python](https://www.python.org/downloads/) (3.10 or newer).

2. Run the command below to install RenderCV.

```bash
pip install rendercv
```

## Getting started with the `new` command

To get started, navigate to the directory where you want to create your CV and run the command below to create the input files.

```bash
rendercv new "Your Full Name"
```
This command will create the following files:

-   A YAML input file called `Your_Name_CV.yaml`.

    This file will contain all the content and design options of your CV.

-   A directory called `classic`.

    This directory contains the $\LaTeX$ source code of RenderCV's default built-in theme, `classic`. You can update its contents to tweak the appearance of the output PDF file.

-   A directory called `markdown`.

    This directory contains the Markdown source code of RenderCV's default Markdown template. You can update its contents to tweak the Markdown output of the CV.

### Options of the `new` command

The `new` command has some options:

- `#!bash --theme "THEME_NAME"`: Generates files for a specific built-in theme, instead of the default `classic` theme. Currently, the available themes are: {{available_themes}}. 
```bash
rendercv new "Your Full Name" --theme "THEME_NAME" 
```

- `#!bash --dont-create-theme-source-files`: Prevents the creation of the theme source files. By default, the theme source files are created.
```bash
rendercv new "Your Full Name" --dont-create-theme-source-files
```

- `#!bash --dont-create-markdown-source-files`: Prevents the creation of the Markdown source files. By default, the Markdown source files are created.
```bash
rendercv new "Your Full Name" --dont-create-markdown-source-files
```

## Structure of the YAML input file

The YAML input file contains all the content and design options of your CV. A detailed explanation of the structure of the YAML input file is provided [here](structure_of_the_yaml_input_file.md).


## Rendering the CV with the `render` command

To render a YAML input file, run the command below.

```bash
rendercv render "Your_Name_CV.yaml"
```

This command will generate a directory called `rendercv_output`, which contains the following files:

-   The CV in PDF format, `Your_Name_CV.pdf`.
-   $\LaTeX$ source code of the PDF file, `Your_Name_CV.tex`.
-   PNG files for each page of the PDF file.
-   The CV in Markdown format, `Your_Name_CV.md`.
-   An HTML file from the Markdown file, `Your_Name_CV.html`.
    
    This file is generated so that it can be opened in a browser and pasted into Grammarly or similar tools for spell and grammar checking.

-   Some log and auxiliary files related to the $\LaTeX$ compilation process.

If the theme and Markdown source files are found in the directory, they will override the default built-in theme and Markdown template. You don't need to provide all the source files; you can just provide the ones you want to override.

### Options of the `render` command

The `render` command has some options:

- `#!bash --use-local-latex-command "LATEX_COMMAND"`: Generates the CV with the local $\LaTeX$ installation, i.e., runs `LATEX_COMMAND`. By default, RenderCV uses its own TinyTeX distribution.
```bash
rendercv render "Your_Name_CV.yaml" --use-local-latex-command "pdflatex" 
```
- `#!bash --output-folder-name "OUTPUT_FOLDER_NAME"`: Generates the output files in a folder with the given name. By default, the output folder name is `rendercv_output`. The output folder will be created in the current working directory.
```bash
rendercv render "Your_Name_CV.yaml" --output-folder-name "OUTPUT_FOLDER_NAME"
```

- `#!bash --latex-path LATEX_PATH`: Copies the generated $\LaTeX$ source code from the output folder and pastes it to the specified path.
```bash
rendercv render "Your_Name_CV.yaml" --latex-path "PATH"
```

- `#!bash --pdf-path PDF_PATH`: Copies the generated PDF file from the output folder and pastes it to the specified path.
```bash
rendercv render "Your_Name_CV.yaml" --pdf-path "PATH"
```

- `#!bash --markdown-path MARKDOWN_PATH`: Copies the generated Markdown file from the output folder and pastes it to the specified path.
```bash
rendercv render "Your_Name_CV.yaml" --markdown-path "PATH"
```

- `#!bash --html-path HTML_PATH`: Copies the generated HTML file from the output folder and pastes it to the specified path.
```bash
rendercv render "Your_Name_CV.yaml" --html-path "PATH"
```

- `#!bash --png-path PNG_PATH`: Copies the generated PNG files from the output folder and pastes them to the specified path.
```bash
rendercv render "Your_Name_CV.yaml" --png-path "PATH"
```

- `#!bash --dont-generate-markdown`: Prevents the generation of the Markdown file.
```bash
rendercv render "Your_Name_CV.yaml" --dont-generate-markdown
```

- `#!bash --dont-generate-html`: Prevents the generation of the HTML file.
```bash
rendercv render "Your_Name_CV.yaml" --dont-generate-html
```

- `#!bash --dont-generate-png`: Prevents the generation of the PNG files.
```bash
rendercv render "Your_Name_CV.yaml" --dont-generate-png
```

- `#!bash --ANY.LOCATION.IN.THE.YAML.FILE "VALUE"`: Overrides the value of `ANY.LOCATION.IN.THE.YAML.FILE` with `VALUE`. This option can be used to avoid storing sensitive information in the YAML file. Sensitive information, like phone numbers, can be passed as a command-line argument with environment variables. This method is also beneficial for creating multiple CVs using the same YAML file by changing only a few values. Here are a few examples:
```bash
rendercv render "Your_Name_CV.yaml" --cv.phone "+905555555555"
```
```bash
rendercv render "Your_Name_CV.yaml" --cv.sections.education.1.institution "Your University"
```

    Multiple `#!bash --ANY.LOCATION.IN.THE.YAML.FILE "VALUE"` options can be used in the same command.

## Creating custom themes with the `create-theme` command

RenderCV is a general $\LaTeX$ CV framework. It allows you to use any $\LaTeX$ code to generate your CVs. To begin developing a custom theme, run the command below.

```bash
rendercv create-theme "mycustomtheme"
```

This command will create a directory called `mycustomtheme`, which contains the following files:

``` { .sh .no-copy }
├── mycustomtheme
│   ├── __init__.py
│   ├── Preamble.j2.tex
│   ├── Header.j2.tex
│   ├── EducationEntry.j2.tex
│   ├── ExperienceEntry.j2.tex
│   ├── NormalEntry.j2.tex
│   ├── OneLineEntry.j2.tex
│   ├── PublicationEntry.j2.tex
│   ├── TextEntry.j2.tex
│   ├── SectionBeginning.j2.tex
│   └── SectionEnding.j2.tex
└── Your_Full_Name_CV.yaml
```

The files are copied from the `classic` theme. You can update the contents of these files to create your custom theme.

Each of these `*.j2.tex` files is $\LaTeX$ code with some Python in it. These files allow RenderCV to create your CV out of the YAML input.

The best way to understand how they work is to look at the source code of built-in themes:

- [`classic` templates](../reference/themes/classic.md)
- [`engineeringresumes` templates](../reference/themes/engineeringresumes.md)
- [`sb2nov` templates](../reference/themes/sb2nov.md)
- [`moderncv` templates](../reference/themes/moderncv.md)

For example, the content of `ExperienceEntry.j2.tex` for the `moderncv` theme is shown below:

```latex
\cventry{
    ((* if design.show_only_years *))
    <<entry.date_string_only_years>>
    ((* else *))
    <<entry.date_string>>
    ((* endif *))
}{
    <<entry.position>>
}{
    <<entry.company>>
}{
    <<entry.location>>
}{}{}
((* for item in entry.highlights *))
\cvline{}{\small <<item>>}
((* endfor *))
```

The values between `<<` and `>>` are the names of Python variables, allowing you to write a $\\LaTeX$ CV without writing any content. They will be replaced with the values found in the YAML input. Also, the values between `((*` and `*))` are Python blocks, allowing you to use loops and conditional statements.

The process of generating $\\LaTeX$ files like this is called "templating," and it's achieved with a Python package called [Jinja](https://jinja.palletsprojects.com/en/3.1.x/).

Also, the `__init__.py` file found in the theme directory is used to define the design options of the custom theme. You can define your custom design options in this file.

For example, an `__init__.py` file is shown below:

```python
from typing import Literal

import pydantic

class YourcustomthemeThemeOptions(pydantic.BaseModel):
    theme: Literal["yourcustomtheme"]
    option1: str
    option2: str
    option3: int
    option4: bool
```

Then, RenderCV will parse your custom design options from the YAML input, and you can use these variables inside your `*.j2.tex` files as shown below:

```latex
<<design.option1>>
<<design.option2>>
((* if design.option4 *))
    <<design.option3>>
((* endif *))
```

### Options of the `create-theme` command

The `create-theme` command has some options:

- `#!bash --based-on "THEME_NAME"`: Generates a custom theme based on the specified built-in theme, instead of the default `classic` theme. Currently, the available themes are: {{available_themes}}. 
```bash
rendercv create-theme "mycustomtheme" --based-on "THEME_NAME"
```

## Frequently Asked Questions (FAQ)

### Can I use custom fonts?

To be answered.

### Can I add a background image?

To be answered.

### How good is it in terms of parseability by ATS?

To be answered.

### How to add links?

To be answered.

### How to use Greek letters?

To be answered.

### Can I add a profile picture?

To be answered.

### How can I switch the order of `company` and `position` in ExperienceEntry?

To be answered.