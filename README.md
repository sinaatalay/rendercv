<div align="center">
<h1>RenderCV</h1>

_The engine of the [RenderCV App](https://rendercv.com)_

[![test](https://github.com/sinaatalay/rendercv/actions/workflows/test.yaml/badge.svg?branch=main)](https://github.com/sinaatalay/rendercv/actions/workflows/test.yaml)
[![coverage](https://coverage-badge.samuelcolvin.workers.dev/sinaatalay/rendercv.svg)](https://coverage-badge.samuelcolvin.workers.dev/redirect/sinaatalay/rendercv)
[![docs](<https://img.shields.io/badge/docs-mkdocs-rgb(0%2C79%2C144)>)](https://docs.rendercv.com)
[![pypi-version](<https://img.shields.io/pypi/v/rendercv?label=PyPI%20version&color=rgb(0%2C79%2C144)>)](https://pypi.python.org/pypi/rendercv)
[![pypi-downloads](<https://img.shields.io/pepy/dt/rendercv?label=PyPI%20downloads&color=rgb(0%2C%2079%2C%20144)>)](https://pypistats.org/packages/rendercv)

</div>

RenderCV allows you to create a high-quality CV as a PDF from a YAML input file. It supports Markdown syntax and gives you complete control over the $\LaTeX$ code.

The primary motivation behind RenderCV is to provide a concrete framework that allows:

- Version controlling a CV's content and design separately and in an organized manner.
- Building an automated pipeline that updates the final output (PDF, $\LaTeX$, Markdown, HTML, and PNGs) whenever the content is modified.
- Making the CV's design uniform and nicely structured without room for human errors.

RenderCV offers built-in $\LaTeX$ and Markdown templates ready to produce high-quality CVs. However, the templates are entirely arbitrary and can easily be updated to leverage RenderCV's capabilities with custom CV themes.

RenderCV takes a YAML file that looks like this:

```yaml
cv:
  name: John Doe
  location: Your Location
  email: youremail@yourdomain.com
  sections:
    this_is_a_section_title:
      - This is a type of entry, TextEntry—just a plain string.
      - You may have as many entries as you want under a section.
      - RenderCV offers a variety of entry types such as TextEntry,
        BulletEntry, EducationEntry, ExperienceEntry, NormalEntry,
        OneLineEntry, PublicationEntry.
      - Each entry type has its own set of attributes and different
        looks.
    my_education_section:
      - institution: Boğaziçi University
        area: Mechanical Engineering
        degree: BS
        start_date: 2024-09
        end_date: 2029-05
        highlights:
          - "GPA: 3.9/4.0 ([Transcript](https://example.com))"
          - "**Coursework:** Structural Analysis, Thermodynamics,
            Heat Transfer"
    experience: ...
```

Then, it produces one of these PDFs with its corresponding $\LaTeX$ code, Markdown file, HTML file, and images as PNGs. Each of these is an example of one of 4 built-in themes of RenderCV. Click on the images below to preview PDF files.

| [![Classic Theme Example of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/classic.png)](https://github.com/sinaatalay/rendercv/blob/main/examples/John_Doe_ClassicTheme_CV.pdf)    | [![Sb2nov Theme Example of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/sb2nov.png)](https://github.com/sinaatalay/rendercv/blob/main/examples/John_Doe_Sb2novTheme_CV.pdf)                                     |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Moderncv Theme Example of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/moderncv.png)](https://github.com/sinaatalay/rendercv/blob/main/examples/John_Doe_ModerncvTheme_CV.pdf) | [![Engineeringresumes Theme Example of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/engineeringresumes.png)](https://github.com/sinaatalay/rendercv/blob/main/examples/John_Doe_EngineeringresumesTheme_CV.pdf) |

The contents of the HTML file can be pasted into Grammarly or any word processor for spelling and grammar checking.

![Grammarly for RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/grammarly.gif)

It also validates the input file. If there are any problems, it tells users where the problems are and how they can fix them.

![CLI of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/cli.gif)

RenderCV comes with a JSON Schema so that the YAML input file can be filled out interactively.

![JSON Schema of RenderCV](https://raw.githubusercontent.com/sinaatalay/rendercv/main/docs/assets/images/schema.gif)

## Quick Start Guide

Either use the [RenderCV App](https://rendercv.com), [`rendercv-pipeline`](https://github.com/sinaatalay/rendercv-pipeline), or follow the steps below.

1.  Install [Python](https://www.python.org/downloads/) (3.10 or newer).
2.  Run the command below in a terminal to install RenderCV.
    ```bash
    pip install rendercv
    ```
3.  Run the command below to generate starting input files.
    ```bash
    rendercv new "Full Name"
    ```
4.  Edit the contents of `Full_Name_CV.yaml` in your favorite editor (_tip: use an editor that supports JSON Schemas_).
5.  Run the command below to generate your CV.
    ```bash
    rendercv render Full_Name_CV.yaml
    ```

[Here](https://docs.rendercv.com/user_guide/), you can find a comprehensive user guide that covers the YAML input file structure and command-line interface (CLI) in greater detail.

### Docker

A docker image is available on [Dockerhub](https://hub.docker.com/r/mathiasvda/rendercv)

Example usage:

1.  Run the command below to generate starting input files.

```sh
$ docker run -it -v <path-to-your-cv-directory>:/data mathiasvda/rendercv rendercv new "Full name"
```

2.  Edit the contents of `Full_Name_CV.yaml` in your favorite editor (_tip: use an editor that supports JSON Schemas_).

3.  Run the command below to generate your CV.

```sh
$ docker run -it -v <path-to-your-cv-directory>:/data mathiasvda/rendercv rendercv render Full_name_CV.yaml
```

### Gitlab

[GitLab](https://gitlab.com/) also allows to automate actions, similar to GitHub. Below is an example [.gitlab-ci.yml](https://docs.gitlab.com/ee/ci/) file that uses the Docker image to render the CV. The example assumes that you have initialised (rendercv new "Full name") your CV yaml file and the theme folder and pushed them to your repository.

```yml
stages:
  - render

render:
  image:
    name: mathiasvda/rendercv
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  stage: render
  script:
    - rendercv render Full_name_CV.yaml
  artifacts:
    paths:
      - rendercv_output/
```

## Motivation

Writing the content of a CV and designing a CV are separate issues that should be treated separately. RenderCV attempts to provide this separation. This approach encourages users to concentrate on the content without getting distracted by the appearance of their CV and vice versa.

RenderCV also provides a set of utilities that automate most of the manual work involved in the CV updating process. After updating a single sentence or date in the YAML input file written in pure English, RenderCV will:

- Re-create your $\LaTeX$ file,
- Render a new PDF file,
- Create a new Markdown file,
- Create a new HTML document, and
- Create images of each page of the PDF file as PNGs.

> Why use RenderCV instead of $\LaTeX$? I can version-control $\LaTeX$ code too!

RenderCV is not a replacement for $\LaTeX$. It is a set of utilities designed to create and manage $\LaTeX$ CVs. If you're currently using $\LaTeX$ to create your CV, you should try RenderCV. Using your existing $\LaTeX$ themes in RenderCV is very easy.

Advantages of RenderCV over using pure $\LaTeX$:

- RenderCV will separate the content of your CV from your $\LaTeX$ code. They will sit in independent files, and RenderCV will use both to generate your CV.
- You will be able to version-control your $\LaTeX$ code and content separately.
- Updating your content in a YAML file is easier than updating a complex $\LaTeX$ file.
- A pure $\LaTeX$ CV will have many code duplications because a CV is a document with a list of sections that contain a list of entries. RenderCV has only one $\LaTeX$ code for each entry type, duplicated automatically based on the YAML input file.
- Spell-checking is not very straightforward in $\LaTeX$ documents.

## Documentation

- [User Guide](https://docs.rendercv.com/user_guide)
- [Developer Guide](https://docs.rendercv.com/developer_guide)
- [Overview of Source Code](https://docs.rendercv.com/reference)
- [Changelog](https://docs.rendercv.com/changelog)

## Contributing

All contributions to RenderCV are welcome! To get started, please read [the developer guide](https://docs.rendercv.com/developer_guide).
