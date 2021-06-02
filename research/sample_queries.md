# Sample queries

The following are example queries that can be ran on the database. They are not
designed with benchmarking in mind, rather they serve as a way of familariazing
with all the possibilities present in the database.


## Queries based on ILIKE, SIMILAR TO, and regular expressions

All the following queries are naive solutions that check for every word in the
dictionary if it is present in the documents.

### Queries using ILIKE

Inflections insensitive search based on pattern matching:

```sql
SELECT 
    dicts.wikigraph.term, 
    left(dicts.wikigraph.definition, 300)
FROM dicts.wikigraph, docs
WHERE docs.document ILIKE concat('%', dicts.wikigraph.term, '%');
```

```sql
SELECT count(dicts.wikigraph.term) --just like the previous one but counting
FROM dicts.wikigraph, docs
WHERE docs.document ILIKE concat('%', dicts.wikigraph.term, '%');
```

### Pattern matching with SIMILAR TO

An extremely naive approach, and a one giving incorrect results, to deal with
inflections would be to trim the endings of the words and allowing anything to
be attached instead.

```sql
SELECT 
    dicts.wikigraph.term, 
    left(dicts.wikigraph.definition, 300)
FROM dicts.wikigraph, docs
WHERE docs.document SIMILAR TO concat('%', left(dicts.wikigraph.term, -2), '[[:alpha:]]{0,5} %');
```

```sql
SELECT count(dicts.wikigraph.term)
FROM dicts.wikigraph, docs
WHERE docs.document SIMILAR TO concat('%', left(dicts.wikigraph.term, -2), '[[:alpha:]]{0,5} %');
```
The number of returned matches is suspsciously high (167, while methods that
seem to promise most accuracy return ~87)

### POSIX regular expressions

Unlike `LIKE` or `SIMILAR TO` pattern matching with regex does not require a
full string (document text in our case) to match but any substring to match
which might have a great impact on queries performance.

```sql
SELECT 
    dicts.wikigraph.term, 
    left(dicts.wikigraph.definition, 300)
FROM dicts.wikigraph, docs
WHERE docs.document ~* dicts.wikigraph.term;
```

```sql
SELECT count(dicts.wikigraph.term)
FROM dicts.wikigraph, docs
WHERE docs.document ~* dicts.wikigraph.term;
```

It gives (should give) identical results to the ILIKE example without an attempt
to deal with inflections.

## Parsing document into tokens

The following creates a temporary table with a single word in each row. It can
be used later to query each word against the dictionary. This approach will not
work however for phrases and it will not detect them.

```sql
SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens
INTO TEMPORARY words
FROM docs;
```

```sql
SELECT 
    dicts.wikigraph.term, 
    left(dicts.wikigraph.definition, 300) AS definition
FROM dicts.wikigraph, words
WHERE words.tokens = dicts.wikigraph.term;
```

```sql
SELECT count(words) --count the number of matching words in contrast to number of matched terms
FROM dicts.wikigraph, words
WHERE words.tokens = dicts.wikigraph.term;
```

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

```sql
SELECT count(dicts.wikigraph.term)
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

There are two ways to go about a solution based on making a new Postgres
dictionary. The simpler and quicker apprach is to simply pass the terms that
were collected in the dictionary in a file as a new Postgres dictionary. The
sligthly more complicated approach is to first use a stemming (normalizing)
dictionary present in the Postgres to parse the collected dictionary before
outputting them to a file that would become a new Postgres dictionary. The
latter approach can handle inflections. 

Both of those are however limited and cannot be applied to pharses (made of
multiple words). An intermediate Postgres dictionary of thesaurus type would be
needed to first change all the phrases into a single "word" (letter cluster). 

<!-- ```sql
CREATE TEXT SEARCH DICTIONARY wikigraph_dict(
    TEMPLATE = pg_catalog.simple,
    DictFile = myDict,
    Dictionary = pg_catalog.english_stem
)
``` -->
