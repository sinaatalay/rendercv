# <<cv.name>>'s CV

((* if cv.phone *))
- ((* trans *))Phone((* endtrans *)): <<cv.phone|replace("tel:", "")|replace("-"," ")>>
((* endif *))
((* if cv.email *))
- ((* trans *))Email((* endtrans *)): [<<cv.email>>](mailto:<<cv.email>>)
((* endif *))
((* if cv.location *))
- ((* trans *))Location((* endtrans *)): <<cv.location>>
((* endif *))
((* if cv.website *))
- ((* trans *))Website((* endtrans *)): [<<cv.website|replace("https://","")|replace("/","")>>](<<cv.website>>)
((* endif *))
((* if cv.social_networks *))
    ((* for network in cv.social_networks *))
- <<network.network>>: [<<network.username>>](<<network.url>>)
    ((* endfor *))
((* endif *))
