# Working with the data 

First, if during benchmarking any test was interrupted or crashed it most likely left an entry in `tests` with a zero execution time. To clear the data from such artifacts simply run:

```sql
DELETE FROM tests WHERE execution_time = interval '0 milliseconds';
```

The complete set of collected statistics includes:
* Number of words in the text and number of entries in the dictionary
* Number of matches 
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
 1341 | 1-1-13  | 2021-06-16 00:42:19.478594 | 1-1           | wiki_cogn_medium  |          306 | Relativity(strip(to_tsvector('english', dicts.{name}.term)))_0  |          11019 | 00:00:00.252   |      17
 1342 | 1-1-14  | 2021-06-16 00:42:20.02892  | 1-1           | wiki_cogn_medium  |          306 | Relativity_1  |          23575 | 00:00:00.508   |      20
 1343 | 1-1-15  | 2021-06-16 00:42:20.817728 | 1-1           | wiki_cogn_medium  |          306 | Relativity_2  |          35096 | 00:00:00.745   |      20
 1344 | 1-1-16  | 2021-06-16 00:42:21.333059 | 1-1           | wiki_cogn         |          613 | Relativity_0  |          11019 | 00:00:00.473   |      34

...
```

Because of long execution times (despite using a rather resourceful PC, with 16 threads, 32 GB of RAM, SSD) most samples used rather short texts and small dictionaries.

```sql
---To see the test that executed the longest:
SELECT test_id, dict_name, dict_entries, document_words, execution_time
FROM tests
ORDER BY execution_time DESC
LIMIT 1;

 test_id |     dict_name     | dict_entries | document_name | document_words | execution_time 
---------+-------------------+--------------+---------------+----------------+----------------
 3-2-7   | wiki_alpha        |        17520 | BNW_0         |           6030 | 03:42:03.503
 --almost 4 hours!

```

Some tests were excluded after some errors which resulted in unordered collection ids.

# The most reliable

As reliabilty understood is the confidence that a given query will return as many correct matches as possible.

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
Once a bigger dictionary (*wiki_cogn_medium*) is used we can observe other characteristics of the queries:

```
   q1_match   |   q2_match   |     q3_match      |     q4_match      |   q5_match   
--------------+--------------+-------------------+-------------------+--------------
 time         | choice       | class             | choice            | choice
 norm!        | idea         | idea              | existence         | class
 mind         | idea         | mind              | idea              | idea
 meta!        | idea         | mind–body problem!| identity          | idea
 logic!       | identity     | time              | intelligence      | idea
 intelligence | identity     |                   | mind              | idea
 identity     | intelligence |                   | mind–body problem!| identity
 choice       | intelligence |                   | time              | identity
 class        | mind         |                   |                   | intelligence
 idea         | mind         |                   |                   | intelligence
 existence    | time         |                   |                   | meta!
              | time         |                   |                   | mind
              | time         |                   |                   | mind
              | time         |                   |                   | mind
              | time         |                   |                   | mind
              | time         |                   |                   | mind
              | time         |                   |                   | mind
              | time         |                   |                   | mind
              | time         |                   |                   | mind
              | time         |                   |                   | norm!
              |              |                   |                   | pain!
              |              |                   |                   | pain!
              |              |                   |                   | soul!
              |              |                   |                   | time
              |              |                   |                   | time
              |              |                   |                   | time
              |              |                   |                   | time
              |              |                   |                   | time
              |              |                   |                   | time
              |              |                   |                   | time
              |              |                   |                   | time
              |              |                   |                   | time
              |              |                   |                   | time
```
First, the word _"norm"_ is a false positive, words such as _"normally"_ do appear in the text but if we were interested in getting a definition words _"norm"_ and _"normally"_ have slightly different semantics. Simalrly words _"meta"_, _"logic"_, _"pain"_, _"soul"_ and the phrase _"mind-body problem"_. They were marked with an exclamation symbol. Out of 9 different words 4 were false positives in the case of query nr __5__. While query nr __2__ returned no false positives it also matched the smallest number of distinct terms (6). It can be also observed on the sample that the only queries capable of matching __phrases__ are queries nr __3__ and __4__. Among those two query number __4__ returns more matches. 

All the queries have different characteristics:

* __1__: Can match _"logic"_ in _"phsycoligically"_, prone to false positives, cannot match phrases
* __2__: Does not return any false positives but also can match only exactly identical to terms words and cannot match phrases.
* __3__: Can match phrases and return some (few) false positives but retruns less matches than nr __4__
* __4__: Can match phrases and return some false positives, more matches than nr __3__
* __5__: Returns the biggest number of matches and false positives

Repeating the analysis with even bigger dictionary leads to similar conclusions with a new note that the queries nr __3__ and __4__ return false matches mainly if not only on phrases and the difference in the amount of returned matches is rather significant.

## Verdict

Query nr __4__ might be considered the most reliable unless false positives on phrases are unacceptable.

# The fastest and the best scalling

First it may be desired to sort queries by execution time on a given data set:

```sql
SELECT collection_id, query, descr, avg(execution_time)
FROM tests INNER JOIN test_collections ON test_collections.id = collection_id
WHERE
    dict_name = 'wiki_alpha' AND
    document_name = 'BNW_2'
GROUP BY (collection_id, query, descr)
ORDER BY avg ASC;
```

What will be found then in the case of *wiki_alpha* and *BNW_2* is that the best performing are queries from set 1. In particular the fastest is the query which parses text into table of words and tries to find exactly the same words in the dictionary of term. 

```sql
-- the query returned from test_collections table as the fastest executing on a given sample
SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?"]*[[:space:]]+|\.)') tokens 
INTO TEMPORARY words FROM docs 
WHERE docs.title = 'DOC'; 
SELECT count(dicts.DICT.id) 
FROM dicts.DICT, words 
WHERE words.tokens = dicts.DICT.term;
```

The query exists in three variations as a test: with no index, with btree index, and hash index. Execution times of these are so short that it cannot be specified with such small sample which of those executes fastest (it can be guessed that it may be the one with hash index however). 

The second fastest executing is the query based on ILIKE operator.

```sql
SELECT count(dicts.DICT.id) 
FROM dicts.DICT, docs 
WHERE docs.document ILIKE concat('%', dicts.DICT.term, '%') AND docs.title = 'DOC';
```
The third is the query using levenshtein distance.

```sql
-- query using an optimized version of function calculating levenshtein distance
SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?"]*[[:space:]]+|\.)') tokens 
INTO TEMPORARY words FROM docs 
WHERE docs.title = 'DOC'; 
SELECT count(dicts.DICT.id) 
FROM dicts.DICT, words 
WHERE levenshtein_less_equal(words.tokens, dicts.DICT.term, 1) <= 1;
```

All the queries using text search functions of Postgres came after that (last).

## Average per entry or word

To see how long on average executed per each word of text or each entry in the dictionary:

```sql
SELECT collection_id, 
    avg(execution_time / dict_entries) AS average_execution_per_entry,
    avg(execution_time / document_words) AS average_execution_per_word 
INTO TEMPORARY avg_per -- the table will be used later
FROM tests
GROUP BY collection_id;

SELECT * FROM avg_per ORDER BY collection_id;

 collection_id | average_execution_per_entry | average_execution_per_word 
---------------+-----------------------------+----------------------------
 1-1           | 00:00:00.001661             | 00:00:00.000025
 1-3           | 00:00:00.000012             | 00:00:00
 1-4           | 00:00:00.000011             | 00:00:00
 1-5           | 00:00:00.000012             | 00:00:00
 2-1           | 00:00:00.023206             | 00:00:00.000356
 2-2           | 00:00:00.023399             | 00:00:00.000359
 3-2           | 00:00:00.037573             | 00:00:00.000575
 3-3           | 00:00:00.040846             | 00:00:00.000676
 4-1           | 00:00:00.006657             | 00:00:00.000102
 4-2           | 00:00:00.002528             | 00:00:00.000039

```
What may be surprising is that we obtained some zeroes for the average execution times per X of tests 1-3, 1-4, 1-5. Those are the queries that were noted as executing the fastest. Most likely the results of division were just too small.

## Scalling

To see which queries increasd their execution times the fastest as particular factors (number of words or entries) changed the correlation between those can be analyzed: 

```sql
SELECT collection_id, corr(extract(millisecond from execution_time), dict_entries)
    AS corr_time_entries,
    corr(extract(millisecond from execution_time), document_words)
    AS corr_time_words
INTO TEMPORARY correlations
FROM tests
GROUP BY collection_id
ORDER BY collection_id;

SELECT * FROM correlations ORDER BY collection_id;

 collection_id |   corr_time_entries   |  corr_time_words   
---------------+-----------------------+--------------------
 1-1           |    0.7389588170505224 | 0.5955215114074272
 1-3           |  0.040435665505373815 |  0.836830316944089
 1-4           |   0.07502927893195839 | 0.9349687081991315
 1-5           | -0.017198994996155213 | 0.7459563964974941
 2-1           |    0.7424903045196033 | 0.5912299931930896
 2-2           |    0.7399300871749407 | 0.5918817489907435
 3-2           |    0.6950105284922827 | 0.4564570931725876
 3-3           |    0.7864563101826214 | 0.5232363846459195
 4-1           |    0.7464957420036574 |  0.587805354429871
 4-2           |    0.7503190159759695 | 0.5969340199855534
```

Execution time scalling with entries:

```sql
SELECT avg_per.collection_id, corr_time_entries, average_execution_per_entry
FROM test_collections
INNER JOIN correlations ON correlations.collection_id = test_collections.id
INNER JOIN avg_per ON avg_per.collection_id = test_collections.id
ORDER BY @ corr_time_entries DESC
LIMIT 3;

-- execution time increasing with the number of entries
 collection_id | corr_time_entries  | average_execution_per_entry 
---------------+--------------------+-----------------------------
 3-3           | 0.7864563101826214 | 00:00:00.040846
 4-2           | 0.7503190159759695 | 00:00:00.002528
 4-1           | 0.7464957420036574 | 00:00:00.006657


... ORDER BY @ corr_time_entries ASC ...

-- execution time least affected by the number of entries
 collection_id |   corr_time_entries   | average_execution_per_entry 
---------------+-----------------------+-----------------------------
 1-5           | -0.017198994996155213 | 00:00:00.000012
 1-3           |  0.040435665505373815 | 00:00:00.000012
 1-4           |   0.07502927893195839 | 00:00:00.000011
```

Execution time scalling with words:

```sql
... ORDER BY @ corr_time_words DESC ...

-- execution time increasing with the number of words
 collection_id |  corr_time_words   | average_execution_per_word 
---------------+--------------------+----------------------------
 1-4           | 0.9349687081991315 | 00:00:00
 1-3           |  0.836830316944089 | 00:00:00
 1-5           | 0.7459563964974941 | 00:00:00


... ORDER BY @ corr_time_words ASC ...

-- execution time least affected by the number of words
 collection_id |  corr_time_words   | average_execution_per_word 
---------------+--------------------+----------------------------
 3-2           | 0.4564570931725876 | 00:00:00.000575
 3-3           | 0.5232363846459195 | 00:00:00.000676
 4-1           |  0.587805354429871 | 00:00:00.000102
```

# The most disappointing

Queries that used Postgres full text search functionalities with a default configuration executed the slowest and returned few matches. The queries that used a custom configuration executed slower than the ones using a default configuration for English language. The difference between those two configurations was the use of extra synonym and thesaurus dictionaries. 

