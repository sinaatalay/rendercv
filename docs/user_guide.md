# RenderCV: User Guide

This document provides everything you need to know about the usage of RenderCV.

## Installation

> RenderCV doesn't require a $\LaTeX$ installation; it comes with it!

1. Install [Python](https://www.python.org/downloads/) (3.10 or newer).

2. Run the command below to install RenderCV.

```bash
pip install rendercv
```

or

```bash
python -m pip install rendercv
```

## Generating the input file

To get started, navigate to the directory where you want to create your CV and run the command below to create the input file.

```bash
rendercv new "Your Full Name"
```

or

```bash
python -m rendercv new "Your Full Name"
```

This will create a YAML input file for RenderCV called `Your_Name_CV.yaml`. Open this file in your favorite IDE and start editing.

!!! tip

    To maximize your productivity while editing the input YAML file, set up RenderCV's JSON Schema in your IDE. It will validate your inputs on the fly and give auto-complete suggestions.

    === "Visual Studio Code"

        1.  Install [YAML language support](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) extension.
        2.  Then the Schema will be automatically set up because the file ends with `_CV.yaml`.

    === "Other"

        1.  Ensure your editor of choice has support for JSON Schema.
        2.  Add the following line at the top of `Your_Name_CV.yaml`:

            ``` yaml
            # yaml-language-server: $schema=https://github.com/sinaatalay/rendercv/blob/main/schema.json?raw=true
            ```

## The YAML structure of the input file

RenderCV's input file consists of two parts: `cv` and `design`.

```yaml
cv:
  ...
  YOUR CONTENT
  ...
design:
  ...
  YOUR DESIGN
  ...
```

The `cv` part contains only the **content of the CV**, and the `design` part contains only the **design options of the CV**. That's how the design and content are separated.

### "`cv`" section of the YAML input

The `cv` section of the YAML input starts with generic information, as shown below:

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
  ...
```

None of the values above are required. You can omit any or all of them, and RenderCV will adapt to your input.

The main content of your CV is stored in a field called sections.

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
    ...
    YOUR CONTENT
    ...
```

The `sections` field is a dictionary where the keys are the section titles, and the values are lists. Each item of the list is an entry for that section.

Here is an example:

```yaml
cv:
  sections:
    this_is_a_section_title:
      - This is a TextEntry.
      - This is another TextEntry under the same section.
      - This is another another TextEntry under the same section.
    this_is_another_section_title:
      - company: This time it's an ExperienceEntry.
        position: Your position
        start_date: 2019-01-01
        end_date: 2020-01
        location: TX, USA
        highlights: 
          - This is a highlight (bullet point).
          - This is another highlight.
      - company: Another ExperienceEntry.
        position: Your position
        start_date: 2019-01-01
        end_date: 2020-01-10
        location: TX, USA
        highlights: 
          - This is a highlight (bullet point).
          - This is another highlight.
```

There are six different entry types in RenderCV. Different types of entries cannot be mixed under the same section, so for each section, you can only use one type of entry.

The available entry types are: [`EducationEntry`](#education-entry), [`ExperienceEntry`](#experience-entry), [`PublicationEntry`](#publication-entry), [`NormalEntry`](#normal-entry), [`OneLineEntry`](#one-line-entry), and [`TextEntry`](#text-entry).

Each entry type is a different object (a dictionary). All of the entry types and their corresponding look in each built-in theme are shown below:

{% for entry_name, entry in showcase_entries.items() %}
#### {{ entry_name }}
```yaml
{{ entry["yaml"] }}
```
    {% for figure in entry["figures"] %}
`{{ figure["theme"] }}` theme:
![figure["alt_text"]]({{ figure["path"] }})
    {% endfor %}
{% endfor %}

### "`design`" section of the YAML input

The `cv` part of the input contains your content, and the `design` part contains your design. The `design` part starts with a theme name. Currently, there are three built-in themes (`classic`, `sb2nov`, and `moderncv`), but custom themes can also be used (see [below](#using-custom-themes).)

```yaml
design:
  theme: classic
  ...
```

Each theme has different options for design. `classic` and `sb2nov` almost use identical options, but `moderncv` is slightly different. Please use an IDE that supports JSON schema to avoid missing any available options for the theme (see [above](#generating-the-input-file)).

An example `design` part for a `classic` theme is shown below:

```yaml
design:
  theme: classic
  color: rgb(0,79,144)
  disable_page_numbering: false
  font_size: 10pt
  header_font_size: 30 pt
  page_numbering_style: NAME - Page PAGE_NUMBER of TOTAL_PAGES
  page_size: a4paper
  show_last_updated_date: true
  text_alignment: justified
  margins: 
    page:
      bottom: 2 cm
      left: 1.24 cm
      right: 1.24 cm
      top: 2 cm
    section_title:
      bottom: 0.2 cm
      top: 0.2 cm
    entry_area:
      date_and_location_width: 4.1 cm
      left_and_right: 0.2 cm
      vertical_between: 0.12 cm
    highlights_area:
      left: 0.4 cm
      top: 0.10 cm
      vertical_between_bullet_points: 0.10 cm
    header:
      bottom: 0.2 cm
      horizontal_between_connections: 1.5 cm
      vertical_between_name_and_connections: 0.2 cm
```

## Command-line interface (CLI)

Currently, RenderCV has two command-line interface functions: `new`, and `render`.

### `rendercv new`

`rendercv new YOUR_FULL_NAME` generates a sample YAML input file to get started. An optional `theme` input allows you to generate a YAML file for a specific built-in theme.

```bash
rendercv new --theme THEME_NAME "John Doe"
```

### `rendercv render`

`rendercv render INPUT_FILE_PATH` renders the given YAML input file. An optional `use-local-latex-command` option can be used to generate the CV with the local LaTeX installation.

```bash
rendercv render --use-local-latex-command pdflatex John_Doe_CV.yaml
```


## Using custom themes

RenderCV allows you to move your $\LaTeX$ CV code to RenderCV. To do this, you will need to create some files:

``` { .sh .no-copy }
├── yourcustomtheme
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

Each of these `*.j2.tex` files is $\LaTeX$ code with some Python in it. These files allow RenderCV to create your CV out of the YAML input.

The best way to understand how they work is to look at the source code of built-in themes. For example, the content of `ExperienceEntry.j2.tex` for the `moderncv` theme is shown below:

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

The values between `<<` and `>>` are the names of Python variables, allowing you to write a $\\LaTeX$ CV without writing any content. Those will be replaced with the values found in the YAML input. Also, the values between `((*` and `*))` are Python blocks, allowing you to use loops and conditional statements.

The process of generating $\\LaTeX$ files like this is called "templating," and it's achieved with a Python package called [Jinja](https://jinja.palletsprojects.com/en/3.1.x/).

### Creating custom theme options

If you want to have some `design` options under your YAML input file's `design` section for your custom theme, you can create a `__init__.py` file inside your theme directory.

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