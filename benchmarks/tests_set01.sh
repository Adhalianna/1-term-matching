#!/bin/bash

alias p="echo"

p "The first tests' set is based on ILIKE, regular expressions and simple string equality operators."
p "It requires data set 1."
p "The first part of tests will perform queries on each term existing in a dictionary."
p "The second one will use different approach and query each word in a document."
p "Those queries will be repeated after creating indexes on the dictionaries."
p "Each test query will count the number of matches found."
p "The time of execution will be measured by Postgres."


p "---"
p "TESTS' SET 1 | TEST 0 - DATA STATISTICS"
p "---"

p "The number of entries in the small dictionary:"
p "SELECT count(id) FROM dicts.wiki_biology_small;" | psql -d term_matching_db -U term_matcher

p "The number of entries in the medium dictionary:"
p "SELECT count(id) FROM dicts.wiki_biology_medium;" | psql -d term_matching_db -U term_matcher

p "The number of entries in the full dictionary:"
p "SELECT count(id) FROM dicts.wiki_biology;" | psql -d term_matching_db -U term_matcher

p "The number of words on first 20 pages of \"Brave New World\""
p "SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short';" \
" " \
"SELECT count(*) " \
"FROM words;" | psql -d term_matching_db -U term_matcher

p "The number of words in a copy of \"Brave New World\":"
p "SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full';" \
" " \
"SELECT count(*) " \
"FROM words;" | psql -d term_matching_db -U term_matcher



p "---"
p "TESTS' SET 1 | TEST 1-1 - ILIKE OPERATOR"
p "---"

p "Small dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology_small.term, '%') " \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Small dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology_small.term, '%') " \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology_medium.term, '%') " \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology_medium.term, '%') " \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology.term, '%') " \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.wiki_biology.term, '%') " \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher


p "---"
p "TESTS' SET 1 | TEST 1-2 - REGULAR EXPRESSIONS"
p "---"

p "Small dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.document ~* dicts.wiki_biology_small.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Small dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.document ~* dicts.wiki_biology_small.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.document ~* dicts.wiki_biology_medium.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.document ~* dicts.wiki_biology_medium.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.document ~* dicts.wiki_biology.term" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.document ~* dicts.wiki_biology.term" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "---"
p "TESTS' SET 1 | TEST 2-1 - EACH WORD IN A DOCUMENT"
p "---"

p "Small dictionary, short text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, words " \
"WHERE words.tokens = dicts.wiki_biology_small.term"
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Small dictionary, full text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, words " \
"WHERE words.tokens = dicts.wiki_biology_small.term"
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, short text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, words " \
"WHERE words.tokens = dicts.wiki_biology_medium.term"
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, full text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, words " \
"WHERE words.tokens = dicts.wiki_biology_medium.term"
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, short text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, words " \
"WHERE words.tokens = dicts.wiki_biology.term"
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, full text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, words " \
"WHERE words.tokens = dicts.wiki_biology.term"
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "---"
p "TESTS' SET 1 | TEST 2-2 - EACH WORD AFTER INDEXING THE DICTIONARY WITH B-TREE"
p "---"

#Creating the index:
p "CREATE INDEX btree_wiki_biology_indx ON dicts.wiki_biology USING btree (term) WITH (fillfactor = 100);" | psql -d term_matching_db -U term_matcher -q
p "CREATE INDEX btree_wiki_biology_m_indx ON dicts.wiki_biology_medium USING btree (term) WITH (fillfactor = 100);" | psql -d term_matching_db -U term_matcher -q
p "CREATE INDEX btree_wiki_biology_s_indx ON dicts.wiki_biology_small USING btree (term) WITH (fillfactor = 100);" | psql -d term_matching_db -U term_matcher -q


p "Small dictionary, short text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, words " \
"WHERE words.tokens = dicts.wiki_biology_small.term"
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Small dictionary, full text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, words " \
"WHERE words.tokens = dicts.wiki_biology_small.term"
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, short text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, words " \
"WHERE words.tokens = dicts.wiki_biology_medium.term"
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, full text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, words " \
"WHERE words.tokens = dicts.wiki_biology_medium.term"
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, short text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_short'; " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, words " \
"WHERE words.tokens = dicts.wiki_biology.term"
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, full text:"
p "\timing on \\\ " \
"SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'BNW_full'; " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, words " \
"WHERE words.tokens = dicts.wiki_biology.term"
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

#Dropping the index:
p "DROP INDEX btree_wiki_biology_indx;" | psql -d term_matching_db -U term_matcher -q
p "DROP INDEX btree_wiki_biology_m_indx;" | psql -d term_matching_db -U term_matcher -q
p "DROP INDEX btree_wiki_biology_s_indx;" | psql -d term_matching_db -U term_matcher -q


p "---"
p "TESTS OF TESTS SET 1 COMPLETE"
p "---"