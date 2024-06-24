# Structure of the YAML Input File

RenderCV's input file consists of three parts: `cv`, `design`, and `locale_catalog`.

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
```

- The `cv` field is mandatory. It contains the **content of the CV**.
- The `design` field is optional. It contains the **design options of the CV**. If you don't provide a `design` field, RenderCV will use the default design options with the `classic` theme.
- The `locale_catalog` field is optional. You can provide translations for some of the strings used in the CV, for example, month abbreviations. RenderCV will use English strings if you don't provide a `locale_catalog` field.

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
  label: Mechanical Engineer
  location: Your Location
  email: youremail@yourdomain.com
  phone: +905419999999
  website: https://example.com/
  social_networks:
    - network: LinkedIn # (1)!
      username: yourusername
    - network: GitHub 
      username: yourusername
  ...
```

1.  The available social networks are: {{available_social_networks}}.

None of the values above are required. You can omit any or all of them, and RenderCV will adapt to your input. These generic fields are used in the header of the CV.

The main content of your CV is stored in a field called `sections`.

```yaml hl_lines="12 13 14 15"
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

### "`cv.sections`" field

The `cv.sections` field is a dictionary where the keys are the section titles, and the values are lists. Each item of the list is an entry for that section.

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

There are seven different entry types in RenderCV. Different types of entries cannot be mixed under the same section, so for each section, you can only use one type of entry.

The available entry types are: [`EducationEntry`](#education-entry), [`ExperienceEntry`](#experience-entry), [`PublicationEntry`](#publication-entry), [`NormalEntry`](#normal-entry), [`OneLineEntry`](#one-line-entry), [`BulletEntry`](#bullet-entry), and [`TextEntry`](#text-entry).

Each entry type is a different object (a dictionary). Below, you can find all the entry types along with their optional/mandatory fields and how they appear in each built-in theme.

{% for entry_name, entry in showcase_entries.items() %}
#### {{ entry_name }}

{% if entry_name == "Education Entry" %}

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

{% elif entry_name == "Experience Entry" %}

**Mandatory Fields:**

- `company`: The name of the company.
- `position`: Your position.

**Optional Fields:**

- `location`: The location.
- `start_date`: The start date in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format.
- `end_date`: The end date in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format or "present".
- `date`: The date as a custom string or in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format. This will override `start_date` and `end_date`.
- `highlights`: A list of bullet points.

{% elif entry_name == "Publication Entry" %}

**Mandatory Fields:**

- `title`: The title of the publication.
- `authors`: The authors of the publication.

**Optional Fields:**

- `doi`: The DOI of the publication.
- `journal`: The journal of the publication.
- `date`: The date as a custom string or in `YYYY-MM-DD`, `YYYY-MM`, or `YYYY` format.

{% elif entry_name == "Normal Entry" %}


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
- `details`: The value of the entry.

{% elif entry_name == "Bullet Entry" %}

**Mandatory Fields:**

- `bullet`: The bullet point.

{% elif entry_name == "Text Entry" %}

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

## "`design`" field

The `cv` field of the input contains your content, and the `design` field contains your design options. The `design` field starts with a theme name. Currently, the available themes are: {{available_themes}}. However, custom themes can also be used (see [here](index.md#creating-custom-themes-with-the-create-theme-command).)

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

This field is what makes RenderCV a multilingual tool. RenderCV uses some English strings to render PDFs. For example, it takes the dates in ISO format (`2020-01-01`) and converts them into human-friendly strings (`"Jan 2020"`). However, you can override these strings for your own language or needs with the `locale_catalog` field.

Here is an example:

```yaml
locale_catalog:
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
