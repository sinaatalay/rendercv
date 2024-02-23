# RenderCV: User Guide




After you've installed RenderCV with

```bash
pip install rendercv
```

you can start rendering your CV.

Firstly, go to the directory where you want your CV files located and run:

```bash
rendercv new "Your Full Name"
```

This will create a YAML input file for RenderCV called `Your_Name_CV.yaml`. Open this generated file in your favorite IDE and start editing. It governs all the features of RenderCV.

!!! tip

    To maximize your productivity while editing the input YAML file, set up RenderCV's JSON Schema in your IDE. It will validate your inputs on the fly and give auto-complete suggestions.

    === "Visual Studio Code"

        1.  Install [YAML language support](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) extension.
        2.  Then the Schema will be automatically set up because the file ends with `_CV.yaml`.

    === "Other"

        1.  Ensure your editor of choice has support for YAML schema validation.
        2.  Add the following line at the top of `Your_Name_CV.yaml`:

            ``` yaml
            # yaml-language-server: $schema=https://github.com/sinaatalay/rendercv/blob/main/schema.json?raw=true
            ```

After you're done editing your input file, run the command below to render your CV:
```bash
rendercv render Your_Name_CV.yaml
```

## Entry Types

There are five entry types in RenderCV:

1.  *EducationEntry*
2.  *ExperienceEntry*
3.  *NormalEntry*
4.  *OneLineEntry*
5.  *PublicationEntry*

The whole CV consists of these entries.

{% for entry_name, entry in showcase_entries.items() %}
## {{ entry_name }}
```yaml
{{ entry["yaml"] }}
```
    {% for figure in entry["figures"] %}
`{{ figure["theme"] }}` theme:
![figure["alt_text"]]({{ figure["path"] }})
    {% endfor %}
{% endfor %}