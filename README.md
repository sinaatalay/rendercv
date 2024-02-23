# RenderCV

[![test](https://github.com/sinaatalay/rendercv/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/sinaatalay/rendercv/actions/workflows/test.yaml)
[![coverage](https://coverage-badge.samuelcolvin.workers.dev/sinaatalay/rendercv.svg)](https://coverage-badge.samuelcolvin.workers.dev/redirect/sinaatalay/rendercv)

[![pypi-version](https://img.shields.io/pypi/v/rendercv?label=PyPI%20version&color=rgb(0%2C79%2C144))](https://pypi.python.org/pypi/rendercv)
[![pypi-downloads](https://img.shields.io/pepy/dt/rendercv?label=PyPI%20downloads&color=rgb(0%2C%2079%2C%20144))](https://pypi.python.org/pypi/rendercv)


RenderCV is a $\LaTeX$ CV/resume generator from a JSON/YAML input file. It is a $\LaTeX$ framework that can be used with any $\LaTeX$ CV. The primary motivation behind the RenderCV is to allow the separation between the content and design of a CV.

Write your content, and get a high-quality, professional-looking CV as a PDF with its $\LaTeX$ source!

It takes a YAML file that looks like this:

```yaml
...
```

And then produces these PDFs and their $\LaTeX$ code (click on images to preview PDFs):

| `classic` theme | `sb2nov` theme | `moderncv` theme |
|:---------------:|----------------|------------------|
|                 |                |                  |


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

You can find a comprehensive user guide that covers adding custom themes and the data model (YAML structure) in greater detail [here](https://sinaatalay.github.io/rendercv/user_guide).

## Motivation

Writing the content of a CV and designing a CV are separate issues, and they should be treated separately. RenderCV attempts to provide this separation and encourages users not to worry too much about the appearance of their CV but to concentrate on the content.

You can automatize your CV generation process with RenderCV and version control your CV in a well-structured manner. It will make updating your CV as simple as updating your YAML input file.

Here are some answers to frequently asked questions about RenderCV:

### Why should I bother using RenderCV instead of $\LaTeX$? I can version-control $\LaTeX$ code too!

Because:

- You might want to version control the content and design of your CV separately without mixing them into each other. You cannot achieve this with $\LaTeX$. If you have a plain $\LaTeX$ CV, changing your design will require you to do almost everything from scratch.
- If you return to your $\LaTeX$ CV code after a year, you may find yourself confused about all the commands like `\hpace{1cm}` you put in a year ago everywhere to make your CV work, and it may not be appealing to update your CV anymore. Why not separate $\LaTeX$ code from your content?
- You will have a lot of code duplication if you make your CV in $\LaTeX$ because a CV is a list of sections with lists of entries. Why not have only one $\LaTeX$ code for each entry type and let another software duplicate them for you?
- RenderCV is not a replacement for $\LaTeX$ in the context of CVs but a tool that allows you to create $\LaTeX$ CVs seamlessly. You can always move your $\LaTeX$ CV to RenderCV!
- Spell checking may be difficult to do in $\LaTeX$. You will need to copy and paste each sentence separately to some other software for spell-checking. With RenderCV, it's one copy-paste.
- It is not very easy to use $\LaTeX$ for CVs since they require a unique design.

### Is it flexible enough?

RenderCV gives you the flexibility required for a CV, but not more. RenderCV will force users to be strict about the content of their CVs, and that's helpful! Because CVs are strict documents, and you may not want to go in the wrong direction. You can't make design mistakes with RenderCV, but you can be flexible enough. It supports Markdown syntax, so you can put links anywhere or make your text italic or bold. Additionally, you can specify various design options in your input file's `design` section.

### Isn't putting all of my data into a YAML file cumbersome?

You always have to put all of your data somewhere to produce a PDF with all your data. If you do it for RenderCV once, you may not have to do it again for a long time. It will help you to avoid this process in the future.

## Documentation

The source code of RenderCV is well-commented and documented. Reading the source code might be fun as the software structure is explained with docstrings and comments.

A detailed user guide can be found [here](https://sinaatalay.github.io/rendercv/user_guide).

Reference to the code can be found [here](https://sinaatalay.github.io/rendercv/reference).

The changelog can be found [here](https://sinaatalay.github.io/rendercv/user_guide).

## Contributing

All contributions to RenderCV are welcome! For development, you will need to clone the repository recursively, as TinyTeX is being used as a submodule:

```bash
git clone --recursive https://github.com/sinaatalay/rendercv.git
```

All code and development tool specifications are in `pyproject.toml`.