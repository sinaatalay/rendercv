# Classic Theme

{% for template_name, template in theme_templates["classic"].items() %}
## {{ template_name }}

```latex
{{ template }}
```

{% endfor %}
