# RenderCV

[![test](https://github.com/sinaatalay/rendercv/actions/workflows/test.yaml/badge.svg?branch=main)](https://github.com/sinaatalay/rendercv/actions/workflows/test.yaml)
[![coverage](https://coverage-badge.samuelcolvin.workers.dev/sinaatalay/rendercv.svg)](https://coverage-badge.samuelcolvin.workers.dev/redirect/sinaatalay/rendercv)
[![pypi-version](https://img.shields.io/pypi/v/rendercv?label=PyPI%20version&color=rgb(0%2C79%2C144))](https://pypi.python.org/pypi/rendercv)
[![pypi-downloads](https://img.shields.io/pepy/dt/rendercv?label=PyPI%20downloads&color=rgb(0%2C%2079%2C%20144))](https://pypistats.org/packages/rendercv)


RenderCV is a $\LaTeX$ CV/resume generator from a JSON/YAML input file. The primary motivation behind the RenderCV is to allow the separation between the content and design of a CV. If you want to see RenderCV in action, you can check out [this YouTube video](https://youtu.be/0aXEArrN-_c?feature=shared).

It takes a YAML file that looks like this:

```yaml
cv:
  name: John Doe
  location: Your Location
  email: youremail@yourdomain.com
  phone: tel:+90-541-999-99-99
  website: https://yourwebsite.com/
  social_networks:
    - network: LinkedIn
      username: yourusername
    - network: GitHub
      username: yourusername
  sections:
    summary:
      - This is an example resume to showcase the capabilities
        of the open-source LaTeX CV generator, [RenderCV](https://github.com/sinaatalay/rendercv).
        A substantial part of the content is taken from [here](https://www.careercup.com/resume),
        where a *clean and tidy CV* pattern is proposed by **Gayle
        L. McDowell**.
    education:
      - start_date: 2000-09
        end_date: 2005-05
        highlights:
          - 'GPA: 3.9/4.0 ([Transcript](https://example.com))'
          - '**Coursework:** Software Foundations, Computer Architecture,
            Algorithms, Artificial Intelligence, Comparison of
            Learning Algorithms, Computational Theory.'
        institution: University of Pennsylvania
        area: Computer Science
        degree: BS
    experience:
    ...
```

And then produces these PDFs and their $\LaTeX$ code (click on images to preview PDFs):

| `classic` theme | `sb2nov` theme | `moderncv` theme |
|:---------------:|----------------|------------------|
|[![Classic Theme Example of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/classic.png)](https://raw.githubusercontent.com/sinaatalay/rendercv/main/examples/John_Doe_ClassicTheme_CV.pdf)|[![Sb2nov Theme Example of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/sb2nov.png)](https://raw.githubusercontent.com/sinaatalay/rendercv/main/examples/John_Doe_Sb2novTheme_CV.pdf)|[![Moderncv Theme Example of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/moderncv.png)](https://raw.githubusercontent.com/sinaatalay/rendercv/main/examples/John_Doe_ModerncvTheme_CV.pdf)|


It also generates an HTML file so that the content can be pasted into Grammarly for spell-checking:

![Grammarly for RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/grammarly.gif)

RenderCV also validates the input file, and if there are any problems, it tells users where the issues are and how they can fix them:

![CLI of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/cli.gif)

## Quick Start Guide

> RenderCV doesn't require a $\LaTeX$ installation; it comes with it!

1.  Install [Python](https://www.python.org/downloads/) (3.10 or newer).
2.  Run the command below to install RenderCV.
    ```bash
    pip install rendercv
    ```
3.  Run the command below to generate a starting input file (`Full_Name_CV.yaml`).
    ```bash
    rendercv new "Full Name"
    ```
4.  Edit the contents of `Full_Name_CV.yaml` in your favorite editor (*tip: use an editor that supports JSON Schemas*).
5.  Run the command below to generate your $\LaTeX$ CV.
    ```bash
    rendercv render Full_Name_CV.yaml
    ```

You can find a comprehensive user guide that covers the data model (YAML structure) and adding custom themes in greater detail [here](https://sinaatalay.github.io/rendercv/user_guide).

## Motivation

Writing the content of a CV and designing a CV are separate issues, and they should be treated separately. RenderCV attempts to provide this separation. With this approach, users are encouraged not to worry too much about the appearance of their CV but to concentrate on the content.

You can automatize your CV generation process with RenderCV and version control your CV in a well-structured manner. It will make updating your CV as simple as updating the YAML input file.

Here are some answers to frequently asked questions about RenderCV:

### Why should I bother using RenderCV instead of $\LaTeX$? I can version-control $\LaTeX$ code too!

Because:

- RenderCV is a tool that allows you to separate your CV content from your $\LaTeX$ code. $\LaTeX$ is still there, and you can leverage it by moving your custom $\LaTeX$ CV to RenderCV.
- You might want to version control the content and design of your CV separately without mixing them into each other. You cannot achieve this with $\LaTeX$. If you have a plain $\LaTeX$ CV, changing your design will require you to do almost everything from scratch.
- Updating a YAML file may be easier than updating a $\LaTeX$ file.
- You will have a lot of code duplication if you make your CV in $\LaTeX$ because a CV is a list of sections with lists of entries. With RenderCV, you will have only one $\LaTeX$ code for each entry type, which will be duplicated automatically based on the YAML input.
- Spell checking may be difficult to do in $\LaTeX$. You will need to copy and paste each sentence separately to some other software for spell-checking. With RenderCV, it's one copy-paste.

### Is it flexible enough?

RenderCV gives you the flexibility required for a CV, but not more. RenderCV forces users to be strict about the content of their CVs, and that's helpful! A CV is a strict and structured document, and you may not want to change that strictness arbitrarily.

You can't make design mistakes with RenderCV, but you can be flexible enough. It supports Markdown syntax, so you can put links anywhere or make your text italic or bold. Additionally, you can specify various design options (margins, colors, font sizes, etc.) in your input file's `design` section.

### Isn't putting all of my data into a YAML file cumbersome?

If you do it for RenderCV once, you may not have to do it again for a long time. It will help you to avoid this process in the future.

## Documentation

The source code of RenderCV is well-commented and documented. Reading the source code might be fun as the software structure is explained with docstrings and comments.

A detailed user guide can be found [here](https://sinaatalay.github.io/rendercv/user_guide).

Reference to the code can be found [here](https://sinaatalay.github.io/rendercv/reference).

The changelog can be found [here](https://sinaatalay.github.io/rendercv/changelog).

## Contributing

All contributions to RenderCV are welcome! For development, you will need to clone the repository recursively, as TinyTeX is being used as a submodule:

```bash
git clone --recursive https://github.com/sinaatalay/rendercv.git
```

All code and development tool specifications are in `pyproject.toml`.