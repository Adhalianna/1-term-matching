# The fastest

The toughest tests were the ones that used a dictionary with around 70 000 entries and a text containg a whole book (Huxley's "Brave New World"). This exam showed some disappointments and some clear winners:

```sql
SELECT collection_id, average_execution_on_big_data, matches, descr, query
FROM (
    SELECT collection_id, 
        avg(execution_time) AS average_execution_on_big_data,
        max(matches) AS matches
    FROM tests 
    WHERE document_name = 'BNW_full'
    AND dict_name = 'wiki_biology'
    AND matches != -1
    GROUP BY collection_id
) AS foo
INNER JOIN test_collections ON collection_id = test_collections.id
ORDER BY average_execution_on_big_data;
```
```
```

# The most reliable

First peeking at the results of the queries and comparing them next to each other

```sql
--1 (tests 1-1)
SELECT dicts.wiki_biology.term
FROM dicts.wiki_biology, docs
WHERE docs.document
ILIKE concat('%', dicts.wiki_biology.term, '%')
AND docs.title = 'BNW_short'
LIMIT 20;

--2 (tests 1-3 / 1-4 / 1-5)
SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens
INTO TEMPORARY words
FROM docs
WHERE docs.title = 'BNW_short';
SELECT dicts.wiki_biology.term
FROM dicts.wiki_biology, words
WHERE words.tokens = dicts.wiki_biology.term
LIMIT 20;

--3 (tests 2-1 / 2-2)
SELECT dicts.wiki_biology.term
FROM dicts.wiki_biology, docs
WHERE to_tsvector(docs.document) @@ dicts.wiki_biology.term_query
AND docs.title = 'BNW_short'
LIMIT 20;

--4 (tests 3-2 / 3-3 / 3-4)
SELECT dicts.wiki_biology.term
FROM dicts.wiki_biology, docs
WHERE to_tsvector('dicts_config', docs.document) @@ dicts.wiki_biology.term_query
AND docs.title = 'BNW_short'
LIMIT 20;

--5 (tests 4-1 / 4-2)
SELECT dicts.wiki_biology.term
FROM dicts.wiki_biology, words
WHERE levenshtein(words.tokens, dicts.wiki_biology.term) <= 1
LIMIT 20;
```

```sql
--this in not how an actual queries result look like (the resu)

      1     |     2     |         3          |         4         |  5   |  
------------+-----------+--------------------+-------------------+------+
 scar       | metal     | process            | takes too long... | lund |
 budding    | bird      | lip                | takes too long... | lund |
 centimetre | history   | express            | takes too long... | lund |
 habit      | history   | missouri           | takes too long... | sic  |
 test       | history   | 3-hexanol ...      | takes too long... | sic  |
 behaviour  | history   | long-form journ... | takes too long... | sic  |
 caustic    | history   | shoot              | takes too long... | sic  |
 nu         | gravity   | iron               | takes too long... | sic  |
 gela       | privilege | 3-hydroxyisobut... | takes too long... | sic  |
 history    | privilege | 3-quinuclidinyl... | takes too long... | sic  |
 chi        | solved    | robert a. good     | takes too long... | von  |
 epsilon    | solved    | stephen g. brush   | takes too long... | von  |
 ash        | solved    | factor 10          | takes too long... | von  |
 nickel     | process   | lime               | takes too long... | von  |
 l          | process   | double-slit expe...| takes too long... | von  |
 æ          | process   | 5-methyluridine    | takes too long... | von  |
 ox         | process   | 5-methyluridine ...| takes too long... | von  |
 milli      | process   | ur                 | takes too long... | von  |
 jet        | process   | good               | takes too long... | von  |
 philo      | process   | turn               | takes too long... | von  |
```

When we compare the results with e.g. 5000 first characters of the used document and run some additional queries we might notice oddities of each query:
* Query number 4 takes too long to execute
* The word "privilege" does appear among those first words of the book and should be matched exactly as is (it exists in the dictionary). It precedes word "lips" which should be matched by _fuzzy_ queries. Query number 3 which does not match "privilege" before "lip" can be considered unreliable
* "nickel" appears before the "privilege" and "process" in the text
* Queries number 1, 3, 4 return matches by the order of appearance in the dictionary entries first. Queries number 2 and 5 iterated over words of the text first which makes the difference between their results odd.
* Query number 2 seems more reliable than the query number 5
* Word "epsilon" is a guarnteed match
* Words returned by query 1 have much higher ids than the words returned by query 3 suggesting that the query number 3 successfully matched what number 1 could not match.
* Phrase "double-slit experiment" does not appear in the book.



# The best scalling

```sql
SELECT collection_id, 
    avg(execution_time / dict_entries) AS average_execution_per_entry,
    avg(execution_time / document_words) AS average_execution_per_word 
INTO TEMPORARY avg_per 
FROM tests
GROUP BY collection_id;

SELECT collection_id, corr(extract(millisecond from execution_time), dict_entries)
    AS corr_time_entries,
    corr(extract(millisecond from execution_time), document_words)
    AS corr_time_words
INTO TEMPORARY correlations
FROM tests
GROUP BY collection_id
ORDER BY collection_id;

SELECT avg_per.collection_id, corr_time_entries, average_execution_per_entry, query AS query_which_entries_scaled_quickest
FROM test_collections
INNER JOIN correlations ON correlations.collection_id = test_collections.id
INNER JOIN avg_per ON avg_per.collection_id = test_collections.id
ORDER BY @ corr_time_entries DESC
LIMIT 3;

SELECT avg_per.collection_id, corr_time_entries, average_execution_per_entry, query AS query_which_entries_scaled_least
FROM test_collections
INNER JOIN correlations ON correlations.collection_id = test_collections.id
INNER JOIN avg_per ON avg_per.collection_id = test_collections.id
ORDER BY @ corr_time_entries ASC
LIMIT 3;

SELECT avg_per.collection_id, corr_time_words, average_execution_per_word, query AS query_which_words_scaled_quickest
FROM test_collections
INNER JOIN correlations ON correlations.collection_id = test_collections.id
INNER JOIN avg_per ON avg_per.collection_id = test_collections.id
ORDER BY @ corr_time_words DESC
LIMIT 3;

SELECT avg_per.collection_id, corr_time_entries, average_execution_per_word, query AS query_which_words_scaled_least
FROM test_collections
INNER JOIN correlations ON correlations.collection_id = test_collections.id
INNER JOIN avg_per ON avg_per.collection_id = test_collections.id
ORDER BY @ corr_time_entries ASC
LIMIT 3;
```

The query which scaled the worst with the increasing number of entries: test case 2-3 `SELECT to_tsvector(docs.documet) @@ to_tsquery( array_to_string( ARRAY( SELECT dicts.DICT.term FROM dicts.DICT ), ' | ' )::text ) AS does_it_contain FROM docs WHERE docs.title = 'DOC';`

The query which scaled the best with increasing number of entries: test case 2-2 `SELECT count(dicts.DICT.id) FROM dicts.DICT, docs WHERE to_tsvector(docs.documet) @@ dicts.DICT.term_query AND docs.title = 'DOC';`

The query which scaled the worst with the increasing number of words:


# The most disappointing


