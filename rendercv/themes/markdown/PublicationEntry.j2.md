## <<entry.title>> ((* if entry.doi != "" *))([<<entry.doi>>](<<entry.doi_url>>))((* endif *))

- <<entry.date_string>>
- <<entry.authors|join(", ")>>
((* if entry.journal != "" *))- <<entry.journal>> ((* endif *))
