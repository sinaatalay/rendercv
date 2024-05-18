<div align="center">
<h1>RenderCV</h1>

*A* $\LaTeX$ *CV/resume framework*.

[![test](https://github.com/sinaatalay/rendercv/actions/workflows/test.yaml/badge.svg?branch=main)](https://github.com/sinaatalay/rendercv/actions/workflows/test.yaml)
[![coverage](https://coverage-badge.samuelcolvin.workers.dev/sinaatalay/rendercv.svg)](https://coverage-badge.samuelcolvin.workers.dev/redirect/sinaatalay/rendercv)
[![docs](https://img.shields.io/badge/docs-mkdocs-rgb(0%2C79%2C144))](https://docs.rendercv.com)
[![pypi-version](https://img.shields.io/pypi/v/rendercv?label=PyPI%20version&color=rgb(0%2C79%2C144))](https://pypi.python.org/pypi/rendercv)
[![pypi-downloads](https://img.shields.io/pepy/dt/rendercv?label=PyPI%20downloads&color=rgb(0%2C%2079%2C%20144))](https://pypistats.org/packages/rendercv)

</div>

RenderCV is a $\LaTeX$ CV/resume framework. It allows you to create a high-quality CV as a PDF from a YAML file with full Markdown syntax support and complete control over the $\LaTeX$ code.

The primary motivation behind the RenderCV is to provide people with a concrete framework that will allow

- Version controlling a CV's content and design separately in an organized manner.
- Building an automated pipeline that can generate the CV as PDF, markdown, and PNG files.
- Making the CV's design uniform and nicely structured without room for human errors.

RenderCV offers built-in $\LaTeX$ and Markdown templates ready to produce high-quality CVs. However, the templates are entirely arbitrary and can easily be updated to leverage RenderCV's capabilities with your custom CV themes.

RenderCV takes a YAML file that looks like this:

```yaml
cv:
  name: John Doe
  location: Your Location
  email: youremail@yourdomain.com
  sections:
    this_is_a_section_title:
      - This is a type of entry, TextEntry—just a plain string.
      - You can have as many entries as you want under a section.
      - RenderCV offers a variety of entry types, such as TextEntry,
        BulletEntry, EducationEntry, ExperienceEntry, NormalEntry,
        OneLineEntry, PublicationEntry.
      - Each entry type has its own set of attributes and different
        looks.
    my_education_section:
      - institution: Boğaziçi University
        area: Mechanical Engineering
        degree: BS
        start_date: 2000-09
        end_date: 2005-05
        highlights:
          - 'GPA: 3.9/4.0 ([Transcript](https://example.com))'
          - '**Coursework:** Structural Analysis, Thermodynamics,
            Heat Transfer'
    experience:
      ...
```

Then, it produces one of these PDFs with its corresponding $\LaTeX$ code, markdown file, and images as PNGs. Each of these is an example of one of four built-in themes of RenderCV. Click on images to preview PDFs.

| [![Classic Theme Example of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/classic.png)](https://github.com/sinaatalay/rendercv/blob/main/examples/John_Doe_ClassicTheme_CV.pdf)    | [![Sb2nov Theme Example of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/sb2nov.png)](https://github.com/sinaatalay/rendercv/blob/main/examples/John_Doe_Sb2novTheme_CV.pdf)                                     |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Moderncv Theme Example of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/moderncv.png)](https://github.com/sinaatalay/rendercv/blob/main/examples/John_Doe_ModerncvTheme_CV.pdf) | [![Engineeringresumes Theme Example of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/engineeringresumes.png)](https://github.com/sinaatalay/rendercv/blob/main/examples/John_Doe_EngineeringresumesTheme_CV.pdf) |



It also generates an HTML file so all the content can be pasted into Grammarly or any word processor for spelling and grammar checking.

![Grammarly for RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/grammarly.gif)


It also validates the input file, and if there are any problems, it tells users where the problems are and how they can fix them.

![CLI of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/cli.gif)


RenderCV comes with a JSON Schema so that the input YAML file can be filled out interactively.

![JSON Schema of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/schema.gif)


## Quick Start Guide

> RenderCV doesn't require a $\LaTeX$ installation; it comes with it!

1.  Install [Python](https://www.python.org/downloads/) (3.10 or newer).
2.  Run the command below in a terminal to install RenderCV.
    ```bash
    pip install rendercv
    ```
3.  Run the command below to generate a starting input files.
    ```bash
    rendercv new "Full Name"
    ```
4.  Edit the contents of `Full_Name_CV.yaml` in your favorite editor (*tip: use an editor that supports JSON Schemas*). The templates can be modified as well.
5.  Run the command below to generate your CV.
    ```bash
    rendercv render Full_Name_CV.yaml
    ```

[Here](https://docs.rendercv.com/user_guide/), you can find a comprehensive user guide that covers the data model (YAML structure) and command-line interface (CLI) in greater detail.

## Motivation

Writing the content of a CV and designing a CV are separate issues that should be treated separately. RenderCV attempts to provide this separation. This approach encourages users to concentrate on the content without getting distracted by the appearance of their CV and vice versa.

RenderCV also provides a general set of utilities that will automate most of the manual work involved in the CV updating process. After updating a single sentence or a date in the YAML input file written in pure English, RenderCV will
- re-create your $\LaTeX$ file.
- render a new PDF file.
- create a new Markdown file.
- create a new HTML document to be pasted into word processors for spelling and grammar checking.
- create PNG files for each page.

> Why should I bother using RenderCV instead of $\LaTeX$? I can version-control $\LaTeX$ code too!

RenderCV is not a replacement for $\LaTeX$, but it's a general set of utilities designed to create and manage $\LaTeX$ CVs. If you're currently using $\LaTeX$ to create your CV, you should try RenderCV. Using your existing $\LaTeX$ themes in RenderCV is very easy.

Here are some advantages of RenderCV over using pure $\LaTeX$:

- RenderCV will separate the content of your CV from your $\LaTeX$ code. They will sit in independent files, and RenderCV will use both to generate your CV.
- You will be able to version-control your design and content separately.
- Updating your content in a YAML file is easier than updating a complex $\LaTeX$ file.
- A pure $\LaTeX$ CV will have many code duplications because a CV is a document with a list of sections that contain a list of entries. RenderCV has only one $\LaTeX$ code for each entry type, duplicated automatically based on the YAML input file.
- Spell-checking is not very straightforward in $\LaTeX$ documents.

## Documentation

The source code of RenderCV is well-commented and documented. Reading the source code might be fun as the software structure is explained with docstrings and comments.

The detailed user guide can be found [here](https://docs.rendercv.com/user_guide).

The developer guide can be found [here](https://docs.rendercv.com/developer_guide).

Reference to the code can be found [here](https://docs.rendercv.com/reference).

The changelog can be found [here](https://docs.rendercv.com/changelog).

## Contributing

All contributions to RenderCV are welcome! For development, you will need to clone the repository recursively, as TinyTeX is being used as a submodule:

```bash
git clone --recursive https://github.com/sinaatalay/rendercv.git
```

All code and development tool specifications are in `pyproject.toml`. Also, don't forget to read [the developer guide](https://docs.rendercv.com/developer_guide).
