## <<entry.company>>, <<entry.position>>

((* if entry.date_string *))- <<entry.date_string>>
((* endif *))
((* if entry.location *))- <<entry.location>>
((* endif *))

((* for client in entry.clients *))
### Client: <<client.name>>
((* for item in client.highlights *))
- <<item>>
((* endfor *))

((* endfor *))