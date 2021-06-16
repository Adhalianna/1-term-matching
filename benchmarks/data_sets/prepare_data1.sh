#!/bin/bash

cd $(dirname $0)

read -r -p "Do you wish to drop previously created for the data set dictionaries? [Y/n]" input

case $input in
    [yY][eE][sS]|[yY])
        echo "DROP TABLE IF EXISTS dicts.wiki_alpha;" | psql -d term_matching_db -U term_matcher -q
        echo "DROP TABLE IF EXISTS dicts.wiki_alpha_medium;" | psql -d term_matching_db -U term_matcher -q
        echo "DROP TABLE IF EXISTS dicts.wiki_alpha_small;" | psql -d term_matching_db -U term_matcher -q
        # Create the base (full, big) dictionary 
        ../../setup/dictionaries/wikigraph.py "Dominance hierarchy" 2 wiki_alpha en
        ;;
    [nN][oO]|[nN])
        ;;
    *)
        echo "Invalid input..."
        exit 1
        ;;
esac

# Import texts
../../setup/texts/parse_pdf.py ../../setup/texts/Brave_New_World.pdf BNW 3


echo "UPDATE dicts.wiki_alpha " \
"SET term_query = phraseto_tsquery(dicts.wiki_alpha.term);" | psql -d term_matching_db -U term_matcher -q # wikigraph.py was update to create tsquery on insert so this is unnecessary (or not?)


# Create a medium sized dictionary having half the entries of the original
echo "CREATE TABLE dicts.wiki_alpha_medium AS" \
"SELECT id, term, term_query, term_vector, definition" \
"FROM dicts.wiki_alpha" \
"WHERE id % 2 = 0;" | psql -d term_matching_db -U term_matcher -q

# Create a small dictionary that has half the size of the medium one
echo "CREATE TABLE dicts.wiki_alpha_small AS" \
"SELECT id, term, term_query, term_vector, definition" \
"FROM dicts.wiki_alpha" \
"WHERE id % 4 = 0;" | psql -d term_matching_db -U term_matcher -q

# Create new dictionaries to be used internally by Postgres
sudo ../../setup/dictionaries/generate_postgresdict.py wiki_alpha "$(pg_config --sharedir)/tsearch_data"
sudo ../../setup/dictionaries/generate_postgresdict.py wiki_alpha_medium "$(pg_config --sharedir)/tsearch_data"
sudo ../../setup/dictionaries/generate_postgresdict.py wiki_alpha_small "$(pg_config --sharedir)/tsearch_data"

sudo ../../setup/dictionaries/generate_fuzzy_postgresdict.py wiki_alpha "$(pg_config --sharedir)/tsearch_data"
sudo ../../setup/dictionaries/generate_fuzzy_postgresdict.py wiki_alpha_medium "$(pg_config --sharedir)/tsearch_data"
sudo ../../setup/dictionaries/generate_fuzzy_postgresdict.py wiki_alpha_small "$(pg_config --sharedir)/tsearch_data"
