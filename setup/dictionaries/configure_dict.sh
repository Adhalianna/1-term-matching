#!/bin/bash

dictionary_name="$1"
synonym_dict="syn_"$dictionary_name
thesaurus_dict="thes_"$dictionary_name



echo "DROP TEXT SEARCH CONFIGURATION IF EXISTS dicts_config;" | psql -d term_matching_db -U term_matcher
echo "DROP TEXT SEARCH DICTIONARY IF EXISTS $thesaurus_dict;" | psql -d term_matching_db -U term_matcher
echo "DROP TEXT SEARCH DICTIONARY IF EXISTS $synonym_dict;" | psql -d term_matching_db -U term_matcher


echo "CREATE TEXT SEARCH DICTIONARY $thesaurus_dict (" \
"TEMPLATE = thesaurus, " \
"DictFile = $thesaurus_dict, " \
"Dictionary = pg_catalog.english_stem " \
");" | psql -d term_matching_db -U term_matcher

echo "CREATE TEXT SEARCH DICTIONARY $synonym_dict (" \
"TEMPLATE = synonym, " \
"SYNONYMS = $synonym_dict " \
");" | psql -d term_matching_db -U term_matcher

echo "CREATE TEXT SEARCH CONFIGURATION dicts_config (" \
"COPY = pg_catalog.english " \
");" | psql -d term_matching_db -U term_matcher

echo "ALTER TEXT SEARCH CONFIGURATION dicts_config " \
"ALTER MAPPING FOR asciiword, asciihword, hword_asciipart, word, hword, hword_part " \
"WITH $thesaurus_dict, $synonym_dict" | psql -d term_matching_db -U term_matcher