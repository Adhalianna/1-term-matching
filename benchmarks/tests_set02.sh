#!/bin/bash

alias p="echo"

p "The second tests' set uses postgres full-text search capabilities."
p "It requires data set 1."
p "Each test query of part 1 will count the number of matches found."
p "The second part of the set will perform extra queries that return something more than a count of results"
p "The time of execution will be measured by Postgres."


p "---"
p "TESTS' SET 2 | TEST 0 - DATA STATISTICS"
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
p "TESTS' SET 2 | TEST 1-1 - TSQUERY FROM A DICTIONARY"
p "---"

p "Small dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology_small.term_query" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Small dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology_small.term_query" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology_medium.term_query" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology_medium.term_query" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology.term_query" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology.term_query" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "---"
p "TESTS' SET 2 | TEST 1-2 - TSQUERY FROM A DICTIONARY WITH AN INDEX"
p "---"

#Creating the index
p "CREATE INDEX btree_wiki_biology_indx ON dicts.wiki_biology USING GIST (term_query);" | psql -d term_matching_db -U term_matcher -q
p "CREATE INDEX btree_wiki_biology_m_indx ON dicts.wiki_biology_medium USING GIST (term_query);" | psql -d term_matching_db -U term_matcher -q
p "CREATE INDEX btree_wiki_biology_s_indx ON dicts.wiki_biology_small USING GIST (term_query);" | psql -d term_matching_db -U term_matcher -q

p "Small dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology_small.term_query" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Small dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_small.id) " \
"FROM dicts.wiki_biology_small, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology_small.term_query" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology_medium.term_query" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Medium dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology_medium.id) " \
"FROM dicts.wiki_biology_medium, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology_medium.term_query" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, short text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology.term_query" \
"AND docs.title = 'BNW_short';" | psql -d term_matching_db -U term_matcher

p "Full dictionary, full text:"
p "\timing on \\\ " \
"SELECT count(dicts.wiki_biology.id) " \
"FROM dicts.wiki_biology, docs " \
"WHERE docs.ts_tokens @@ dicts.wiki_biology.term_query" \
"AND docs.title = 'BNW_full';" | psql -d term_matching_db -U term_matcher

#Dropping the index
p "DROP INDEX btree_wiki_biology_indx ON dicts.wiki_biology;" | psql -d term_matching_db -U term_matcher -q
p "DROP INDEX btree_wiki_biology_m_indx ON dicts.wiki_biology_medium;" | psql -d term_matching_db -U term_matcher -q
p "DROP INDEX btree_wiki_biology_s_indx ON dicts.wiki_biology_small;" | psql -d term_matching_db -U term_matcher -q


p "---"
p "TESTS' SET 2 | TEST 2-1 - OTHER QUERIES BASED ON FULL-TEXT SEARCH"
p "---"


p "---"
p "TESTS OF TESTS' SET 2 COMPLETE"
p "---"