## <<entry.title>> ((* if entry.doi *))([<<entry.doi>>](<<entry.doi_url>>))((* elif entry.url *))([<<entry.url>>](<<entry.clean_url>>))((* endif *))

((* if entry.date_string *))
- <<entry.date_string>>
((* endif *))
- <<entry.authors|join(", ")>>
((* if entry.journal *))
- <<entry.journal>>
((* endif *))
