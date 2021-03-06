#!/bin/bash



dictionary_name="$1"
configuration_name="$2"
synonym_dict="syn_fuzzy_"$dictionary_name



echo "DROP TEXT SEARCH CONFIGURATION IF EXISTS $configuration_name;" | psql -d term_matching_db -U term_matcher
echo "DROP TEXT SEARCH DICTIONARY IF EXISTS $synonym_dict;" | psql -d term_matching_db -U term_matcher

echo "CREATE TEXT SEARCH DICTIONARY $synonym_dict (" \
"TEMPLATE = synonym, " \
"SYNONYMS = $synonym_dict " \
");" | psql -d term_matching_db -U term_matcher

echo "CREATE TEXT SEARCH CONFIGURATION $configuration_name (" \
"COPY = pg_catalog.english " \
");" | psql -d term_matching_db -U term_matcher

echo "ALTER TEXT SEARCH CONFIGURATION $configuration_name " \
"ALTER MAPPING FOR asciiword, asciihword, hword_asciipart, word, hword, hword_part " \
"WITH $synonym_dict" | psql -d term_matching_db -U term_matcher