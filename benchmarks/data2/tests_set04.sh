#!/bin/bash


small_dict="wiki_cogn_small"
medium_dict="wiki_cogn_medium"
big_dict="wiki_cogn"

dictionaries=("$small_dict" "$medium_dict" "$big_dict")


short_text="BNW_short"
long_text1="BNW_full"
long_text2="Relativity"

documents=("$short_text" "$long_text1" "$long_text2")

#---------------------------------------------------------------

echo "The first tests' set is based on ILIKE, regular expressions and simple string equality operators."
echo "It requires data set 1."
echo "The first part of tests will perform queries on each term existing in a dictionary."
echo "The second one will use different approach and query each word in a document."
echo "Those queries will be repeated after creating indexes on the dictionaries."
echo "Each test query will count the number of matches found."
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

long_text1_words=`echo "SELECT regexp_split_to_table(lower(docs.document), " \
    "'([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
    "INTO TEMPORARY words " \
    "FROM docs " \
    "WHERE docs.title = '$long_text1'; " \
    "SELECT count(*) " \
    "FROM words;" \
    | psql -d term_matching_db -U term_matcher \
    | grep -m 2 -Eo '[0-9]{1,9}' \
    | tail -n 1`
stats[$long_text1]="$long_text1_words"

long_text2_words=`echo "SELECT regexp_split_to_table(lower(docs.document), " \
    "'([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
    "INTO TEMPORARY words " \
    "FROM docs " \
    "WHERE docs.title = '$long_text2'; " \
    "SELECT count(*) " \
    "FROM words;" \
    | psql -d term_matching_db -U term_matcher \
    | grep -m 2 -Eo '[0-9]{1,9}' \
    | tail -n 1`
stats[$long_text2]="$long_text2_words"


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

    local results=$(echo "\timing on \\\ ${query}" | psql -d term_matching_db -U term_matcher)

    local count=$(grep -Eo "[0-9]*" <<< $results | head -n 1)
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

# TEST 4-1

echo "DROP TABLE words;" | psql -d term_matching_db -U term_matcher -q

q1=`echo "SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'DOC'; " \
"SELECT count(dicts.DICT.id) " \
"FROM dicts.DICT, words " \
"WHERE levenshtein(words.tokens,dicts.DICT.term) <= 1;"`

_test_case "4-1" "Compares words from text (parsed into separate table) to dictionary term using leveshtein distance." "${q1}"

#---------------------------------------------------------------

# TEST 4-2

echo "DROP TABLE words;" | psql -d term_matching_db -U term_matcher -q

q2=`echo "SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'DOC'; " \
"SELECT count(dicts.DICT.id) " \
"FROM dicts.DICT, words " \
"WHERE levenshtein_less_equal(words.tokens, dicts.DICT.term, 1);"`

_test_case "4-2" "Compares words from text (parsed into separate table) to dictionary term using leveshtein_less_equal function." "${q2}"