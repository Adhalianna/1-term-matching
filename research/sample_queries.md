# Sample queries

The following are example queries that can be ran on the database. They are not
designed with benchmarking in mind, rather they serve as a way of familariazing
with all the possibilities present in the database.

## PostgreSQL full text search functionalities
This set of queries is based on full text search functionality present in the
Postgres database. Full text search functions operate on `tsvector` and
`tsquery` data types.

### tsquery from a dictionary

The following tells whether there are any matches in the documents (mind that
this check all the documents present in the docs table) with the
[wikigraph](../setup/dictionaries/wikigraph.py) dictionary. It's limited to
true/false answers. The comparison between tsquery and tsvector is however
performed only once in this case.

`ts_tokens` field in the `docs` is of a tsvector type.

```sql
SELECT docs.ts_tokens @@ to_tsquery(
    array_to_string(
        ARRAY( --all terms from dictionary put into an array
            SELECT phraseto_tsquery(dicts.wikigraph.term) 
            FROM dicts.wikigraph
        ),
        ' | ' --delemiter, an OR operator
    )::text
) AS does_it_contain
FROM docs;
```

In contrast the following will return the terms that got matched but each term
is checked against tsvector separately. Depending on the level of optimization
present in the database this may perform similar to the previous query.

```sql
SELECT 
    dicts.wikigraph.term, 
    left(dicts.wikigraph.definition, 300) --stripping the returned definitions to 300 chars
FROM dicts.wikigraph, docs
WHERE docs.ts_tokens @@ phraseto_tsquery(dicts.wikigraph.term);
```

To get the fragments of the document in which the matched terms are present a
ts_headline function must be used. It does not however use a preprocessed
tsvector.

```sql
SELECT ts_headline(docs.document, phraseto_tsquery(dicts.wikigraph.term)), dicts.wikigraph.term, left(dicts.wikigraph.definition, 300) definition
FROM dicts.wikigraph, docs
WHERE docs.ts_tokens @@ phraseto_tsquery(dicts.wikigraph.term);
```

The important feature of all of this queries is that they all use a **Postgres
dictionary** which changes queried terms and words into **lexemes**. This makes
the searching in a way **fuzzy**.

### A Postgres dictionary from the dictionary

```sql
CREATE TEXT SEARCH DICTIONARY wikigraph_dict(
    TEMPLATE = thesaurus,
    DictFile = myDict,
    Dictionary = pg_catalog.english_stem
)
```


## Queries based on LIKE



