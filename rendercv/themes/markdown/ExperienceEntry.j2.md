## <<entry.company>>, <<entry.position>>

((* if entry.date_string *))- <<entry.date_string>>
((* endif *))
((* if entry.location *))- <<entry.location>>
((* endif *))
((*- if entry.summary -*))
((* for item in entry.summary *))

   <<item>>
((* endfor *))
((*- endif -*))
((* for item in entry.highlights *))
- <<item>>
((* endfor *))
