# Structure of the YAML Input File

RenderCV's input file consists of four parts: `cv`, `design`, `locale_catalog` and `rendercv_settings`.

```yaml title="Your_Name_CV.yaml"
cv:
  ...
  YOUR CONTENT
  ...
design:
  ...
  YOUR DESIGN
  ...
locale_catalog:
  ...
  TRANSLATIONS TO YOUR LANGUAGE
  ...
rendercv_settings:
  ...
  RENDERCV SETTINGS
  ...
```

- The `cv` field is mandatory. It contains the **content of the CV**.
- The `design` field is optional. It contains the **design options of the CV**. If you don't provide a `design` field, RenderCV will use the default design options with the `classic` theme.
- The `locale_catalog` field is optional. You can provide translations for some of the strings used in the CV, for example, month abbreviations. RenderCV will use English strings if you don't provide a `locale_catalog` field.
- The `rendercv_settings` field is optional. It contains the **settings of RenderCV** (output paths, etc.). If you don't provide a `rendercv_settings` field, RenderCV will use the default settings.

!!! tip
    To maximize your productivity while editing the input YAML file, set up RenderCV's JSON Schema in your IDE. It will validate your inputs on the fly and give auto-complete suggestions.

    === "Visual Studio Code"

        1.  Install [YAML language support](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) extension.
        2.  Then the Schema will be automatically set up because the file ends with `_CV.yaml`.
        3.  Press `Ctrl + Space` to see the auto-complete suggestions.

    === "Other"

        1.  Ensure your editor of choice has support for JSON Schema.
        2.  Add the following line at the top of `Your_Name_CV.yaml`:

            ``` yaml
            # yaml-language-server: $schema=https://github.com/sinaatalay/rendercv/blob/main/schema.json?raw=true
            ```
        3. Press `Ctrl + Space` to see the auto-complete suggestions.

## "`cv`" field

The `cv` field of the YAML input starts with generic information, as shown below.

```yaml
cv:
  name: John Doe
  location: Your Location
  email: youremail@yourdomain.com
  phone: +905419999999 # (1)!
  website: https://example.com/
  social_networks:
    - network: LinkedIn # (2)!
      username: yourusername
    - network: GitHub 
      username: yourusername
  ...
```

1.  If you want to change the phone number formatting in the output, see the `locale_catalog` field's `phone_number_format` key.
2.  The available social networks are: {{available_social_networks}}.

None of the values above are required. You can omit any or all of them, and RenderCV will adapt to your input. These generic fields are used in the header of the CV.

The main content of your CV is stored in a field called `sections`.

```yaml hl_lines="12 13 14 15"
cv:
  name: John Doe
  location: Your Location
  email: youremail@yourdomain.com
  phone: +905419999999
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

### "`cv.sections`" field

The `cv.sections` field is a dictionary where the keys are the section titles, and the values are lists. Each item of the list is an entry for that section.

Here is an example:

```yaml hl_lines="3 7"
cv:
  sections:
    this_is_a_section_title: # (1)!
      - This is a TextEntry. # (2)!
      - This is another TextEntry under the same section.
      - This is another another TextEntry under the same section.
    this_is_another_section_title:
      - company: This time it's an ExperienceEntry. # (3)!
        position: Your position
        start_date: 2019-01-01
        end_date: 2020-01
        location: TX, USA
        highlights: 
          - This is a highlight (a bullet point).
          - This is another highlight.
      - company: Another ExperienceEntry.
        position: Your position
        start_date: 2019-01-01
        end_date: 2020-01-10
        location: TX, USA
        highlights: 
          - This is a highlight (a bullet point).
          - This is another highlight.
```

1. The section titles can be anything you want. They are the keys of the `sections` dictionary.
2. Each section is a list of entries. This section has three `TextEntry`s.
3. There are seven different entry types in RenderCV. Any of them can be used in the sections. This section has two `ExperienceEntry`s.

There are seven different entry types in RenderCV. Different types of entries cannot be mixed under the same section, so for each section, you can only use one type of entry.

The available entry types are: [`EducationEntry`](#educationentry), [`ExperienceEntry`](#experienceentry), [`PublicationEntry`](#publicationentry), [`NormalEntry`](#normalentry), [`OneLineEntry`](#onelineentry), [`BulletEntry`](#bulletentry), and [`TextEntry`](#textentry).

Each entry type is a different object (a dictionary). Below, you can find all the entry types along with their optional/mandatory fields and how they appear in each built-in theme.

{% for entry_name, entry in showcase_entries.items() %}
#### {{ entry_name }}

{% if entry_name == "EducationEntry" %}

**Mandatory Fields:**

- `institution`: The name of the institution.
- `area`: The area of study.

**Optional Fields:**

- `degree`: The type of degree.
- `location`: The location.
- `start_date`: The start date in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format.
- `end_date`: The end date in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format or "present".
- `date`: The date as a custom string or in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format. This will override `start_date` and `end_date`.
- `highlights`: A list of bullet points.

{% elif entry_name == "ExperienceEntry" %}

**Mandatory Fields:**

- `company`: The name of the company.
- `position`: Your position.

**Optional Fields:**

- `location`: The location.
- `start_date`: The start date in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format.
- `end_date`: The end date in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format or "present".
- `date`: The date as a custom string or in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format. This will override `start_date` and `end_date`.
- `highlights`: A list of bullet points.

{% elif entry_name == "PublicationEntry" %}

**Mandatory Fields:**

- `title`: The title of the publication.
- `authors`: The authors of the publication.

**Optional Fields:**

- `doi`: The DOI of the publication.
- `journal`: The journal of the publication.
- `date`: The date as a custom string or in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format.

{% elif entry_name == "NormalEntry" %}


**Mandatory Fields:**

- `name`: The name of the entry.

**Optional Fields:**

- `location`: The location.
- `start_date`: The start date in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format.
- `end_date`: The end date in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format or "present".
- `date`: The date as a custom string or in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format. This will override `start_date` and `end_date`.
- `highlights`: A list of bullet points.

{% elif entry_name == "OneLineEntry" %}

**Mandatory Fields:**

- `label`: The label of the entry.
- `details`: The details of the entry.

{% elif entry_name == "BulletEntry" %}

**Mandatory Fields:**

- `bullet`: The bullet point.

{% elif entry_name == "TextEntry" %}

**Mandatory Fields:**

- The text itself.

{% endif %}

```yaml
{{ entry["yaml"] }}
```
    {% for figure in entry["figures"] %}
=== "`{{ figure["theme"] }}` theme"
    ![figure["alt_text"]]({{ figure["path"] }})
    {% endfor %}
{% endfor %}

#### Markdown Syntax

All the fields in the entries support Markdown syntax.

You can make anything bold by surrounding it with `**`, italic with `*`, and links with `[]()`, as shown below.

```yaml
company: "**This will be bold**, *this will be italic*, 
  and [this will be a link](https://example.com)."
...
```

### Using arbitrary keys

RenderCV allows the usage of any number of extra keys in the entries. For instance, the following is an `ExperienceEntry` containing an additional key, `an_arbitrary_key`.

```yaml hl_lines="6"
company: Some Company
location: TX, USA
position: Software Engineer
start_date: 2020-07
end_date: '2021-08-12'
an_arbitrary_key: Developed an [IOS application](https://example.com).
highlights:
  - Received more than **100,000 downloads**.
  - Managed a team of **5** engineers.
```

By default, the `an_arbitrary_key` key will not affect the output as the built-in templates do not use it. However, you can use the `an_arbitrary_key` key in your custom templates. Further information on overriding the built-in templates with custom ones can be found [here](index.md#overriding-built-in-themes).

Also, you can use arbitrary keys in the `cv` field. You can use them anywhere in the templates, but generally, they are used in the header of the CV (`Header.j2.tex`).

```yaml hl_lines="3"
cv:
  name: John Doe
  label_as_an_arbitrary_key: Software Engineer
```

## "`design`" field

The `cv` field of the input contains your content, and the `design` field contains your design options. The `design` field starts with a theme name. Currently, the available themes are: {{available_themes}}. However, custom themes can also be used (see [here](index.md#creating-custom-themes-with-the-create-theme-command)).

```yaml
design:
  theme: classic
  ...
```

Each theme may have different options for design. `classic`, `sb2nov`, and `engineeringresumes` almost use identical options, but `moderncv` is slightly different. Please use an IDE that supports JSON schema to avoid missing any available options for the theme (see [above](#structure-of-the-yaml-input-file)).

An example `design` field for a `classic` theme is shown below:

```yaml
design:
  theme: classic
  color: blue
  disable_external_link_icons: false
  disable_last_updated_date: false
  last_updated_date_style: Last updated in TODAY
  disable_page_numbering: false
  page_numbering_style: NAME - Page PAGE_NUMBER of TOTAL_PAGES
  font: Source Sans 3
  font_size: 10pt
  header_font_size: "30 pt"
  page_size: a4paper
  show_timespan_in:
    - 'Experience'
  text_alignment: justified
  margins: 
    page:
      bottom: 2 cm
      left: 2 cm
      right: 2 cm
      top: 2 cm
    section_title:
      bottom: 0.2 cm
      top: 0.3 cm
    entry_area:
      date_and_location_width: 4.5 cm
      education_degree_width: 1 cm
      left_and_right: 0.2 cm
      vertical_between: 0.2 cm
    highlights_area:
      left: 0.4 cm
      top: 0.10 cm
      vertical_between_bullet_points: 0.10 cm
    header:
      bottom: 0.3 cm
      horizontal_between_connections: 0.5 cm
      vertical_between_name_and_connections: 0.3 cm
```

## "`locale_catalog`" field

This field is what makes RenderCV a multilingual tool. RenderCV uses some English strings to render PDFs. For example, it takes the dates in ISO format (`2020-01-01`) and converts them into human-friendly strings (`"Jan 2020"`). However, you can override these strings for your own language or needs with the `locale_catalog` field. Also, you can change the phone number formatting with the `phone_number_format` key.

Here is an example:

```yaml
locale_catalog:
  phone_number_format: national # (1)!
  date_style: "MONTH_ABBREVIATION YEAR" # (2)!
  abbreviations_for_months: # translation of the month abbreviations
    - Jan
    - Feb
    - Mar
    - Apr
    - May
    - Jun
    - Jul
    - Aug
    - Sep
    - Oct
    - Nov
    - Dec
  full_names_of_months: # translation of the full month names
    - January
    - February
    - March
    - April
    - May
    - June
    - July
    - August
    - September
    - October
    - November
    - December
  month: month      # translation of the word "month"
  months: months    # translation of the word "months"
  year: year        # translation of the word "year"
  years: years      # translation of the word "years"
  present: present  # translation of the word "present"
  to: to            # translation of the word "to"
```

1. The available phone number formats are: `national`, `international`, and `E164`.
2. The `MONTH_ABBREVIATION` and `YEAR` are placeholders. The available placeholders are: `FULL_MONTH_NAME`, `MONTH_ABBREVIATION`, `MONTH`, `MONTH_IN_TWO_DIGITS`, `YEAR`, and `YEAR_IN_TWO_DIGITS`.

## "`rendercv_settings`" field

The `rendercv_settings` field contains RenderCV settings. We plan to add more settings soon, such as the ability to bold specific words and disable sections. Currently, it only includes the `render_command` field, which contains all the CLI options of the [`rendercv render`](./cli.md#options-of-the-rendercv-render-command) command, as shown below. If CLI arguments are provided, they will override the values in the YAML file. All the fields are optional.
```yaml
rendercv_settings:
  render_command:
    output_folder_name: rendercv_output
    pdf_path: NAME_IN_SNAKE_CASE_CV.pdf # (1)!
    latex_path: NAME_IN_LOWER_SNAKE_CASE_cv.tex
    html_path: NAME_IN_KEBAB_CASE_CV.html
    markdown_path: null # (2)!
    dont_generate_html: false 
    dont_generate_markdown: false 
    dont_generate_png: false 
```

1. `NAME_IN_SNAKE_CASE` is a placeholder. The available placeholders are: `NAME_IN_SNAKE_CASE`, `NAME_IN_LOWER_SNAKE_CASE`, `NAME_IN_UPPER_SNAKE_CASE`, `NAME_IN_KEBAB_CASE`, `NAME_IN_LOWER_KEBAB_CASE`, `NAME_IN_UPPER_KEBAB_CASE`, `NAME`, `FULL_MONTH_NAME`, `MONTH_ABBREVIATION`, `MONTH`, `MONTH_IN_TWO_DIGITS`, `YEAR`, and `YEAR_IN_TWO_DIGITS`.
2. When the `markdown_path` field is set to `null`, RenderCV will not copy the Markdown file from the output folder to another location. See the [CLI documentation](./cli.md#options-of-the-rendercv-render-command) for more information.
