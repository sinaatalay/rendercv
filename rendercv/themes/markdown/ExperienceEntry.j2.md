((* if entry.positions *))
## <<entry.company>>
((* for item in entry.positions *))
- <<item.name>> <<item.date_string>>
((* endfor *))
((* else *))
## <<entry.company>>, <<entry.position>>
((* endif *))

((* if entry.date_string *))- <<entry.date_string>>
((* endif *))
((* if entry.location *))- <<entry.location>>
((* endif *))
((* for item in entry.highlights *))
- <<item>>
((* endfor *))
