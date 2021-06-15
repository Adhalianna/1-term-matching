#!/bin/bash

read -r -p "Are you sure you want to run the script? It will drop previously created dictionaries. [Y/n]" input

case $input in
    [yY][eE][sS]|[yY])
        ;;
    [nN][oO]|[nN])
        exit
        ;;
    *)
        echo "Invalid input..."
        exit 1
        ;;
esac

# Clear-up at start
echo "DROP TABLE IF EXISTS dicts.wiki_cogn;" | psql -d term_matching_db -U term_matcher -q
echo "DROP TABLE IF EXISTS dicts.wiki_cogn_medium;" | psql -d term_matching_db -U term_matcher -q
echo "DROP TABLE IF EXISTS dicts.wiki_cogn_small;" | psql -d term_matching_db -U term_matcher -q

# Create the base (full, big) dictionary 
./setup/dictionaries/wikigraph.py "Embodied cognition" 2 wiki_cogn en

echo "UPDATE dicts.wiki_cogn " \
"SET term_query = phraseto_tsquery(dicts.wiki_cogn.term);" | psql -d term_matching_db -U term_matcher -q # wikigraph.py was update to create tsquery on insert so this is unnecessary (or not?)


# Create a medium sized dictionary having half the entries of the original
echo "CREATE TABLE dicts.wiki_cogn_medium AS" \
"SELECT id, term, term_query, term_vector, definition" \
"FROM dicts.wiki_cogn" \
"WHERE id % 2 = 0;" | psql -d term_matching_db -U term_matcher -q

# Create a small dictionary that has half the size of the medium one
echo "CREATE TABLE dicts.wiki_cogn_small AS" \
"SELECT id, term, term_query, term_vector, definition" \
"FROM dicts.wiki_cogn" \
"WHERE id % 4 = 0;" | psql -d term_matching_db -U term_matcher -q


# Import texts
./setup/texts/parse_pdf.py setup/texts/Einstein_Relativity.pdf Relativity

# Create new dictionaries to be used internally by Postgres
sudo ./setup/dictionaries/generate_postgresdict.py wiki_cogn "$(pg_config --sharedir)/tsearch_data"
sudo ./setup/dictionaries/generate_postgresdict.py wiki_cogn_medium "$(pg_config --sharedir)/tsearch_data"
sudo ./setup/dictionaries/generate_postgresdict.py wiki_cogn_small "$(pg_config --sharedir)/tsearch_data"


