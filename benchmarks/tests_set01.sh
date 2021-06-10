#!/bin/bash

echo "The first tests' set is based on ILIKE, regular expressions and simple string equality operators."
echo "It requires data set 1."
echo "The first part of tests will perform queries on each term existing in a dictionary."
echo "The second one will use different approach and query each word in a document."
echo "Those queries will be repeated after creating indexes on the dictionaries."
echo "Each test query will count the number of matches found."
echo "The time of execution will be measured by Postgres."


echo "---"
echo "TESTS' SET 1 | TEST 0 - DATA STATISTICS"
echo "---"

echo "The number of entries in the small dictionary:"
echo "SELECT count(id) FROM dicts.wiki_biology_small;" | psql -d term_matching_db -U term_matcher

echo "The number of entries in the medium dictionary:"
echo "SELECT count(id) FROM dicts.wiki_biology_medium;" | psql -d term_matching_db -U term_matcher

echo "The number of entries in the full dictionary:"
echo "SELECT count(id) FROM dicts.wiki_biology;" | psql -d term_matching_db -U term_matcher

echo "The number of words on first 20 pages of \"Brave New World\""
echo "SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short';" \
" " \
"SELECT count(*) " \
"FROM words;" | psql -d term_matching_db -U term_matcher

echo "The number of words in a copy of \"Brave New World\":"
echo "SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full';" \
" " \
"SELECT count(*) " \
"FROM words;" | psql -d term_matching_db -U term_matcher



echo "---"
echo "TESTS' SET 1 | TEST 1-1 - ILIKE OPERATOR"
echo "---"

echo "Small dictionary, short text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology_small.term, '%') " \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Small dictionary, full text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology_small.term, '%') " \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

echo "Medium dictionary, short text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology_medium.term, '%') " \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Medium dictionary, full text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology_medium.term, '%') " \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

echo "Full dictionary, short text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology.term, '%') " \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Full dictionary, full text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology.term, '%') " \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher


echo "---"
echo "TESTS' SET 1 | TEST 1-2 - REGULAR EXPRESSIONS"
echo "---"

echo "Small dictionary, short text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.document ~* dicts.wiki_biology_small.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Small dictionary, full text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.document ~* dicts.wiki_biology_small.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

echo "Medium dictionary, short text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.document ~* dicts.wiki_biology_medium.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Medium dictionary, full text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.document ~* dicts.wiki_biology_medium.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

echo "Full dictionary, short text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.document ~* dicts.wiki_biology.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Full dictionary, full text:"
echo "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.document ~* dicts.wiki_biology.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

echo "---"
echo "TESTS' SET 1 | TEST 2-1 - EACH WORD IN A DOCUMENT"
echo "---"

echo "Small dictionary, short text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, words " \
"WHERE words.tokens = dicts.wiki_biology_small.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Small dictionary, full text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, words " \
"WHERE words.tokens = dicts.wiki_biology_small.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

echo "Medium dictionary, short text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, words " \
"WHERE words.tokens = dicts.wiki_biology_medium.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Medium dictionary, full text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, words " \
"WHERE words.tokens = dicts.wiki_biology_medium.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

echo "Full dictionary, short text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, words " \
"WHERE words.tokens = dicts.wiki_biology.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Full dictionary, full text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, words " \
"WHERE words.tokens = dicts.wiki_biology.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

echo "---"
echo "TESTS' SET 1 | TEST 2-2 - EACH WORD AFTER INDEXING THE DICTIONARY WITH B-TREE"
echo "---"

#Creating the index:
echo "CREATE INDEX btree_wiki_biology_indx ON dicts.wiki_biology USING btree (term) WITH (fillfactor = 100);" | psql -d term_matching_db -U term_matcher -q
echo "CREATE INDEX btree_wiki_biology_m_indx ON dicts.wiki_biology_medium USING btree (term) WITH (fillfactor = 100);" | psql -d term_matching_db -U term_matcher -q
echo "CREATE INDEX btree_wiki_biology_s_indx ON dicts.wiki_biology_small USING btree (term) WITH (fillfactor = 100);" | psql -d term_matching_db -U term_matcher -q


echo "Small dictionary, short text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, words " \
"WHERE words.tokens = dicts.wiki_biology_small.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Small dictionary, full text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, words " \
"WHERE words.tokens = dicts.wiki_biology_small.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

echo "Medium dictionary, short text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, words " \
"WHERE words.tokens = dicts.wiki_biology_medium.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Medium dictionary, full text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, words " \
"WHERE words.tokens = dicts.wiki_biology_medium.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

echo "Full dictionary, short text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, words " \
"WHERE words.tokens = dicts.wiki_biology.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

echo "Full dictionary, full text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, words " \
"WHERE words.tokens = dicts.wiki_biology.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

#Dropping the index:
echo "DROP INDEX btree_wiki_biology_indx;" | psql -d term_matching_db -U term_matcher -q
echo "DROP INDEX btree_wiki_biology_m_indx;" | psql -d term_matching_db -U term_matcher -q
echo "DROP INDEX btree_wiki_biology_s_indx;" | psql -d term_matching_db -U term_matcher -q

echo "---"
echo "TESTS' SET 1 | TEST 2-2 - EACH WORD AFTER INDEXING THE DICTIONARY WITH HASH"
echo "---"

#Creating the index:
echo "CREATE INDEX hash_wiki_biology_indx ON dicts.wiki_biology USING hash (term);" | psql -d term_matching_db -U term_matcher -q
echo "CREATE INDEX hash_wiki_biology_m_indx ON dicts.wiki_biology_medium USING hash (term);" | psql -d term_matching_db -U term_matcher -q
echo "CREATE INDEX hash_wiki_biology_s_indx ON dicts.wiki_biology_small USING hash (term);" | psql -d term_matching_db -U term_matcher -q


echo "Small dictionary, short text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, words " \
"WHERE words.tokens = dicts.wiki_biology_small.term;" | psql -d term_matching_db -U term_matcher

echo "Small dictionary, full text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, words " \
"WHERE words.tokens = dicts.wiki_biology_small.term;" | psql -d term_matching_db -U term_matcher

echo "Medium dictionary, short text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, words " \
"WHERE words.tokens = dicts.wiki_biology_medium.term;" | psql -d term_matching_db -U term_matcher

echo "Medium dictionary, full text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, words " \
"WHERE words.tokens = dicts.wiki_biology_medium.term;" | psql -d term_matching_db -U term_matcher

echo "Full dictionary, short text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, words " \
"WHERE words.tokens = dicts.wiki_biology.term;" | psql -d term_matching_db -U term_matcher

echo "Full dictionary, full text:"
echo "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, words " \
"WHERE words.tokens = dicts.wiki_biology.term;" | psql -d term_matching_db -U term_matcher

#Dropping the index:
echo "DROP INDEX hash_wiki_biology_indx;" | psql -d term_matching_db -U term_matcher -q
echo "DROP INDEX hash_wiki_biology_m_indx;" | psql -d term_matching_db -U term_matcher -q
echo "DROP INDEX hash_wiki_biology_s_indx;" | psql -d term_matching_db -U term_matcher -q



echo "---"
echo "TESTS OF TESTS' SET 1 COMPLETE"
echo "---"