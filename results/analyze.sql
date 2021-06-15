DROP TABLE IF EXISTS correlations;
DROP TABLE IF EXISTS avg_per;


SELECT collection_id, 
    avg(execution_time) AS average_execution_on_big_data 
FROM tests
WHERE document_name = 'BNW_full'
AND dict_name = 'wiki_biology'
AND matches != -1
GROUP BY collection_id
ORDER BY collection_id;

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
LIMIT 1;

SELECT avg_per.collection_id, corr_time_entries, average_execution_per_entry, query AS query_which_entries_scaled_least
FROM test_collections
INNER JOIN correlations ON correlations.collection_id = test_collections.id
INNER JOIN avg_per ON avg_per.collection_id = test_collections.id
ORDER BY @ corr_time_entries ASC
LIMIT 1;

SELECT avg_per.collection_id, corr_time_words, average_execution_per_word, query AS query_which_words_scaled_quickest
FROM test_collections
INNER JOIN correlations ON correlations.collection_id = test_collections.id
INNER JOIN avg_per ON avg_per.collection_id = test_collections.id
ORDER BY @ corr_time_words DESC
LIMIT 1;

SELECT avg_per.collection_id, corr_time_entries, average_execution_per_word, query AS query_which_words_scaled_least
FROM test_collections
INNER JOIN correlations ON correlations.collection_id = test_collections.id
INNER JOIN avg_per ON avg_per.collection_id = test_collections.id
ORDER BY @ corr_time_entries ASC
LIMIT 1;

SELECT collection_id, dict_name, document_name, avg(matches / dict_entries ) AS avg_matches_per_entry, avg(matches / document_words) AS avg_matches_per_word
FROM tests
WHERE matches != -1
GROUP BY (collection_id, dict_entries, document_words)
ORDER BY (collection_id, dict_name, document_name);

SELECT collection_id, avg_matches_per_entry, avg_matches_per_word, query
FROM (
    SELECT collection_id, avg(matches / dict_entries ) AS avg_matches_per_entry, avg(matches / document_words) AS avg_matches_per_word
    FROM tests
    WHERE matches != -1
    GROUP BY collection_id
    ) AS foo INNER JOIN test_collections ON foo.collection_id = test_collections.id
ORDER BY collection_id;

SELECT count(*) FROM tests;



