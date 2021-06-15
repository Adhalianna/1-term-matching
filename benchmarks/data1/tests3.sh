#!/bin/bash

small_dict="wiki_alpha_small"
medium_dict="wiki_alpha_medium"
big_dict="wiki_alpha"

dictionaries=("$small_dict" "$medium_dict" "$big_dict")


short_text="BNW_0"
medium_text="BNW_1"
full_text="BNW_2"

documents=("$short_text" "$medium_dict" "$full_text")

#---------------------------------------------------------------

echo "The third test collection uses postgres full-text search capabilities but with a modifed text search configuration."
echo "Fist part of the queries will count the number of matches found."
echo "The second part of the set will perform extra queries that return something else than a count of results"
echo "The time of execution will be measured by Postgres."

#---------------------------------------------------------------

declare -A stats

#this part somewhat violates "do not repeat yourself" rule... 
small_dict_entries=`echo "SELECT count(id) FROM dicts.$small_dict" \
    | psql -d term_matching_db -U term_matcher \
    | grep -m 1 -Eo '[0-9]{1,9}'`
stats[$small_dict]="$small_dict_entries"

medium_dict_entries=`echo "SELECT count(id) FROM dicts.$medium_dict" \
    | psql -d term_matching_db -U term_matcher \
    | grep -m 1 -Eo '[0-9]{1,9}'`
stats[$medium_dict]="$medium_dict_entries"

big_dict_entries=`echo "SELECT count(id) FROM dicts.$big_dict" \
    | psql -d term_matching_db -U term_matcher \
    | grep -m 1 -Eo '[0-9]{1,9}'`
stats[$big_dict]="$big_dict_entries"

short_text_words=`echo "SELECT regexp_split_to_table(lower(docs.document), " \
    "'([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
    "INTO TEMPORARY words " \
    "FROM docs " \
    "WHERE docs.title = '$short_text'; " \
    "SELECT count(*) " \
    "FROM words;" \
    | psql -d term_matching_db -U term_matcher \
    | grep -m 2 -Eo '[0-9]{1,9}' \
    | tail -n 1`
stats[$short_text]="$short_text_words"

full_text_words=`echo "SELECT regexp_split_to_table(lower(docs.document), " \
    "'([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
    "INTO TEMPORARY words " \
    "FROM docs " \
    "WHERE docs.title = '$full_text'; " \
    "SELECT count(*) " \
    "FROM words;" \
    | psql -d term_matching_db -U term_matcher \
    | grep -m 2 -Eo '[0-9]{1,9}' \
    | tail -n 1`
stats[$full_text]="$full_text_words"

#---------------------------------------------------------------

_test() {
    local test_collection=$1
    local test_number=$2
    local query=$3 
    local dict=$4
    local doc=$5
    local uses_count=$6

    local test_name="$1-$2"
    local entries=${stats[$dict]}
    local words=${stats[$doc]}

    # NOTE: Check loose_notes.md!
    ./setup/dictionaries/configure_dicts.sh $dict "dicts_config"
    echo "UPDATE $dict SET term_query = phraseto_tsquery('dicts_config', term);" | psql -d term_matching_db -U term_matcher -q
    # NOTE: Check loose_notes.md!

    local results=$(echo "\timing on \\\ ${query}" | psql -d term_matching_db -U term_matcher)

    local count=$(grep -Eo "\s[[:digit:]]+$" <<< $results | tail -n 1)
    local time=$(grep -Eo "[0-9]*[,\.][0-9]* ms" <<< $results | tail -n 1)
    
    echo "[TEST $test_name] $entries dictionary entries ($dict) | $words text words ($doc) | $count matches | $time"

    local formatted_time=$(grep -m 1 -Eo "[0-9]*.[0-9]*" <<< $time)
    local formatted_time=$(echo $formatted_time | awk '{print int($1)}')
    local formatted_time="$formatted_time millisecond"
    if [ $uses_count = true ] ; then
        echo "INSERT INTO tests VALUES (DEFAULT, '$test_name', now(), '$test_collection', '$dict', $entries, '$doc', $words, INTERVAL '$formatted_time', $count);" | psql -d term_matching_db -U term_matcher
    else
        echo "INSERT INTO tests VALUES (DEFAULT, '$test_name', now(), '$test_collection', '$dict', $entries, '$doc', $words, INTERVAL '$formatted_time', -1);" | psql -d term_matching_db -U term_matcher
    fi
}

_test_case() {
    local collection_name=$1
    local description=$2
    local query=$3
    local uses_count=${4:-true}

    local query_insertable=$(echo "$query" | tr -s " ")
    local query_insertable=${query_insertable//\'/\'\'}
    echo "INSERT INTO test_collections VALUES ('$collection_name', '$description', '${query_insertable}')" | psql -d term_matching_db -U term_matcher -q


    counter="0"
    for i in "${dictionaries[@]}"; do
        for j in "${documents[@]}"; do
            counter=$((counter + 1))
            local dict=$i
            local doc=$j
            local test_query=${query//DICT/$dict}
            local test_query=${test_query//DOC/$doc}
            _test "$collection_name" "$counter" "$test_query" "$dict" "$doc" "$uses_count"
        done
    done
}

#---------------------------------------------------------------

# # TEST 3-1

# q1=`echo "SELECT to_tsvector('dicts_config', docs.document) " \
# "FROM docs " \
# "WHERE docs.title = 'DOC';"`

# _test_case "3-1" "Generates a tsvector using a modified  text-search dictionary." "${q1}"


#---------------------------------------------------------------

# TEST 3-2

q2=`echo "SELECT count(dicts.DICT.id) " \
"FROM dicts.DICT, docs " \
"WHERE to_tsvector('dicts_config', docs.document) @@ dicts.DICT.term_query" \
"AND docs.title = 'DOC';"`

_test_case "3-2" "The text is parsed to a tsvector and each dictionary entry is used in the form of a previously prepared tsquery. Text search functions use a previously prepared text-search dictionary." "${q2}"

#---------------------------------------------------------------

# TEST 3-3

#Creating the index:
echo "CREATE INDEX gist_${big_dict}_indx ON dicts.${big_dict} USING GIST (term_query);" | psql -d term_matching_db -U term_matcher -q
echo "CREATE INDEX gist_${medium_dict}_indx ON dicts.${medium_dict} USING GIST (term_query);" | psql -d term_matching_db -U term_matcher -q
echo "CREATE INDEX gist_${small_dict}_indx ON dicts.${small_dict} USING GIST (term_query);" | psql -d term_matching_db -U term_matcher -q

q3=`echo "SELECT count(dicts.DICT.id) " \
"FROM dicts.DICT, docs " \
"WHERE to_tsvector('dicts_config', docs.document) @@ dicts.DICT.term_query" \
"AND docs.title = 'DOC';"`

_test_case "3-3" "The text is parsed to a tsvector and each dictionary entry is used in the form of a previously prepared tsquery. This case uses a GIST index on the tsquery. Text search functions use a previously prepared text-search dictionary." "${q3}"

echo "DROP INDEX gist_${big_dict}_indx;" | psql -d term_matching_db -U term_matcher -q
echo "DROP INDEX gist_${medium_dict}_indx;" | psql -d term_matching_db -U term_matcher -q
echo "DROP INDEX gist_${small_dict}_indx;" | psql -d term_matching_db -U term_matcher -q

#---------------------------------------------------------------

# # TEST 3-4

# q4=`echo "SELECT to_tsvector('dicts_config', docs.document) @@ to_tsquery('dicts_config', " \
# "array_to_string( " \
# "ARRAY( " \
# "SELECT dicts.DICT.term " \
# "FROM dicts.DICT " \
# "), " \
# "' | ' " \
# ")::text " \
# ") AS does_it_contain " \
# "FROM docs " \
# "WHERE docs.title = 'DOC';"`

# _test_case "3-4" "The whole dictionary is transformed into a single tsquery. It tells only whether there are any matches. Text search functions use a previously prepared text-search dictionary." "${q4}" "false"

# #---------------------------------------------------------------

# # TEST 3-5

# q5=`echo "SELECT " \
# "ts_headline(docs.document, phraseto_tsquery('dicts_config', dicts.DICT.term))" \
# "WHERE docs.ts_tokens @@ dicts.DICT.term_query"` \
# "AND docs.title = 'DOC'"

# _test_case "3-5" "A Postgres function ts_headline is used to show matches inside the text. Terms are used as previously prepared queries. Text search functions use a previously prepared text-search dictionary." "${q5}" "false"