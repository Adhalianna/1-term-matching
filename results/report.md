# Working with the data 

First, if during benchmarking any test was interrupted or crashed it most likely left an entry in `tests` with a zero execution time. To clear the data from such artifacts simply run:

```sql
DELETE FROM tests WHERE execution_time = interval '0 milliseconds';
```

The complete set of collected statistics includes:
* Number of words in the text and number of entries in the dictionary
* Number of matches (-1 in case of queries that returned different kind of information)
* Names of used dictionaries and texts
* Test and test collection id which can be used to refer to the used query and its description
* A timestamp

For example:

```sql
SELECT * FROM tests;

  id  | test_id |         exec_date          | collection_id |     dict_name     | dict_entries | document_name | document_words | execution_time | matches 
------+---------+----------------------------+---------------+-------------------+--------------+---------------+----------------+----------------+---------
 1338 | 1-1-10  | 2021-06-16 00:42:18.469682 | 1-1           | wiki_cogn_small   |          153 | Relativity_0  |          11019 | 00:00:00.142   |       5
 1339 | 1-1-11  | 2021-06-16 00:42:18.755672 | 1-1           | wiki_cogn_small   |          153 | Relativity_1  |          23575 | 00:00:00.245   |       8
 1340 | 1-1-12  | 2021-06-16 00:42:19.183726 | 1-1           | wiki_cogn_small   |          153 | Relativity_2  |          35096 | 00:00:00.388   |       8
 1341 | 1-1-13  | 2021-06-16 00:42:19.478594 | 1-1           | wiki_cogn_medium  |          306 | Relativity_0  |          11019 | 00:00:00.252   |      17
 1342 | 1-1-14  | 2021-06-16 00:42:20.02892  | 1-1           | wiki_cogn_medium  |          306 | Relativity_1  |          23575 | 00:00:00.508   |      20
 1343 | 1-1-15  | 2021-06-16 00:42:20.817728 | 1-1           | wiki_cogn_medium  |          306 | Relativity_2  |          35096 | 00:00:00.745   |      20
 1344 | 1-1-16  | 2021-06-16 00:42:21.333059 | 1-1           | wiki_cogn         |          613 | Relativity_0  |          11019 | 00:00:00.473   |      34

...
```

# The most reliable

Below is a list of queries that represent different strategies of acquiring the matches nested as a subqeueries. Execution of the following returns all matches collected in test cases with smallest dictionary and shortest text.

```sql
SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens
INTO TEMPORARY words
FROM docs
WHERE docs.title = 'BNW_0';

SELECT q1_match, q2_match, q3_match, q4_match, q5_match
FROM 
(
--Query number 1 (tests 1-1)
SELECT dicts.wiki_cogn_small.term AS q1_match
FROM dicts.wiki_cogn_small, docs
WHERE docs.document
ILIKE concat('%', dicts.wiki_cogn_small.term, '%')
AND docs.title = 'BNW_0'
ORDER BY q1_match
) AS Q1 
FULL OUTER JOIN 
(
--Query number 2 (tests 1-3 / 1-4 / 1-5)
SELECT dicts.wiki_cogn_small.term AS q2_match
FROM dicts.wiki_cogn_small, words
WHERE words.tokens = dicts.wiki_cogn_small.term
ORDER BY q2_match
) AS Q2 ON 1 = 0
FULL OUTER JOIN 
(
--Query number 3 (tests 2-1 / 2-2)
SELECT dicts.wiki_cogn_small.term AS q3_match
FROM dicts.wiki_cogn_small, docs
WHERE to_tsvector(docs.document) @@ dicts.wiki_cogn_small.term_query
AND docs.title = 'BNW_0'
ORDER BY q3_match
) AS Q3 ON 1 = 0
FULL OUTER JOIN 
(
--Query number 4 (tests 3-2 / 3-3 / 3-4)
SELECT dicts.wiki_cogn_small.term AS q4_match
FROM dicts.wiki_cogn_small, docs
WHERE to_tsvector('dicts_config', docs.document) @@ dicts.wiki_cogn_small.term_query
AND docs.title = 'BNW_0'
ORDER BY q4_match
) AS Q4 ON 1 = 0
FULL OUTER JOIN
(
--Query number 5 (tests 4-1 / 4-2)
SELECT dicts.wiki_cogn_small.term AS q5_match
FROM dicts.wiki_cogn_small, words
WHERE levenshtein(words.tokens, dicts.wiki_cogn_small.term) <= 1
ORDER BY q5_match
) AS Q5 ON 1 = 0;
```

```
(altered results for readability)

   q1_match   |   q2_match   | q3_match |   q4_match   |   q5_match   
--------------+--------------+----------+--------------+--------------
 choice       | choice       | class    | identity     | choice
 class        | identity     | mind     | intelligence | class
 identity     | identity     |          | mind         | identity
 intelligence | intelligence |          |              | identity
 mind         | intelligence |          |              | intelligence
              | mind         |          |              | intelligence
              | mind         |          |              | mind
              |              |          |              | mind
              |              |          |              | mind
              |              |          |              | mind
              |              |          |              | mind
              |              |          |              | mind
              |              |          |              | mind
              |              |          |              | mind
```
We can see that the queries found at most 5 different term matches. Among them only queries nr __1__ and __5__ found all 5 matches while queries nr __2__, __3__, __4__ did not match all possibilities. Investigating the queried text in any text editior that has a search functionality we can see that indeed all 5 terms are present and the word _"mind"_ appears at least 4 times. Queries nr __1__, __3__, __4__ were constructed in such a way that they would stop at the first match for a given term (They iterated over dictionary rather than text). It is surprising that the query nr __4__ which used text search functionalities with customized text search configuration __failed to match all the possibilities__, similarly query nr __3__ which used the default configuration. The reason why query nr __2__ failed to match term _"class"_ was because it occured in the form of _"classes"_. In the given sample none of the queries returned false positives. 

```
```

# The fastest

The toughest tests were the ones that used a dictionary with around 70 000 entries and a text containg a whole book (Huxley's "Brave New World"). This exam showed some disappointments and some clear winners:

```sql

```
```
```


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


