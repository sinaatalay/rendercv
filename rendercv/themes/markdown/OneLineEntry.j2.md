((*- if entry.summary -*))
    ((* for item in entry.summary *))
        ((* if loop.first *))
- <<entry.label>>: <<item>>
        ((* else *))
  <<item>>
        ((* endif *))
    ((* endfor *))

    <<entry.details>>
((*- else -*))
- <<entry.label>>: <<entry.details>>
((*- endif -*))