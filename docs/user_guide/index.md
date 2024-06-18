# User Guide

This page provides everything you need to know about the usage of RenderCV.

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

    This directory contains the Markdown source code of RenderCV's default Markdown template. You can update its contents to tweak the Markdown and HTML output of the CV.

Please refer to the [here](cli.md#options-of-the-rendercv-new-command) for the complete list of CLI options available for the `new` command.

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
-   Images of each page of the PDF file in PNG format, `Your_Name_CV_1.png`, `Your_Name_CV_page_2.png`, etc.
-   The CV in Markdown format, `Your_Name_CV.md`.
-   The CV in HTML format, `Your_Name_CV.html`.
-   Some log and auxiliary files related to the $\LaTeX$ compilation process.

If the theme and Markdown source files are found in the directory, they will override the default built-in theme and Markdown template. You don't need to provide all the source files; you can just provide the ones you want to override.

Please refer to the [here](cli.md#options-of-the-rendercv-render-command) for the complete list of CLI options available for the `render` command.

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

- [templates of the `classic` theme](../reference/themes/classic.md)
- [templates of the `engineeringresumes` theme](../reference/themes/engineeringresumes.md)
- [templates of the `sb2nov` theme](../reference/themes/sb2nov.md)
- [templates of the `moderncv` theme](../reference/themes/moderncv.md)

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

Please refer to the [here](cli.md#options-of-the-rendercv-create-theme-command) for the complete list of CLI options available for the `create-theme` command.
