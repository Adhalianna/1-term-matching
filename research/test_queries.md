First attempt on querying over a dictionary from parsed text:
```
SELECT * FROM dicts.wikigraph 
JOIN(
    SELECT ts_parse('default', docs.document) 
    AS token 
    FROM docs
) AS tokens 
ON dicts.wikigraph.term = tokens.token::varchar;
```