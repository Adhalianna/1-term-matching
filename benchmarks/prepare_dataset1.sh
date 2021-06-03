#!/bin/bash


# Clear-up at start
echo "DROP TABLE IF EXISTS dicts.wiki_biology;" | psql -d term_matching_db -U term_matcher -q
echo "DROP TABLE IF EXISTS dicts.wiki_biology_medium;" | psql -d term_matching_db -U term_matcher -q
echo "DROP TABLE IF EXISTS dicts.wiki_biology_small;" | psql -d term_matching_db -U term_matcher -q
echo "TRUNCATE TABLE docs;" | psql -d term_matching_db -U term_matcher -q


# Create the base (full, big) dictionary 
./setup/dictionaries/wikigraph.py Biology 2 wiki_biology en

echo "UPDATE dicts.wiki_biology " \
"SET term_query = phraseto_tsquery(dicts.wiki_biology.term);" | psql -d term_matching_db -U term_matcher -q # wikigraph.py was update to create tsquery on insert so this is unnecessary (or not?)


# Create a medium sized dictionary having half the entries of the original
echo "CREATE TABLE dicts.wiki_biology_medium AS" \
"SELECT id, term, term_query, term_vector, definition" \
"FROM dicts.wiki_biology" \
"WHERE id % 2 = 0;" | psql -d term_matching_db -U term_matcher -q

# Create a small dictionary that has half the size of the medium one
echo "CREATE TABLE dicts.wiki_biology_small AS" \
"SELECT id, term, term_query, term_vector, definition" \
"FROM dicts.wiki_biology" \
"WHERE id % 4 = 0;" | psql -d term_matching_db -U term_matcher -q


# Import text
./setup/texts/parse_pdf.py setup/texts/Brave_New_World.pdf BNW_full
./setup/texts/parse_pdf.py setup/texts/Brave_New_World_short.pdf BNW_short

