#!/bin/bash


small_dict="wiki_biology_small"
medium_dict="wiki_biology_medium"
big_dict="wiki_biology"

dictionaries=("$small_dict" "$medium_dict" "$big_dict")


short_text="BNW_short"
full_text="BNW_full"

documents=("$short_text" "$full_text")

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

    local results=$(echo "\timing on \\\ ${query}" | psql -d term_matching_db -U term_matcher)

    local count=$(grep -Eo "[0-9]*" <<< $results | head -n 1)
    local time=$(grep -m 1 -Eo "[0-9]*[,\.][0-9]* ms (.*)" <<< $results)
    
    echo "[TEST $test_name] $entries dictionary entries ($dict) | $words text words ($doc) | $count matches | $time"

    local formatted_time=$(echo "$time" | grep -m 1 -Eo "[0-9]*" | head -n 1)
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

# TEST 1-1

q1=`echo "SELECT count(dicts.DICT.id) " \
"FROM dicts.DICT, docs " \
"WHERE docs.document " \
"ILIKE concat('%', dicts.DICT.term, '%') " \
"AND docs.title = 'DOC';"`

_test_case "1-1" "The text is searched for term matches using a query based on ILIKE." "${q1}"

#---------------------------------------------------------------

# TEST 1-2

q2=`echo "SELECT count(dicts.DICT.id) " \
"FROM dicts.DICT, docs " \
"WHERE docs.document ~* dicts.DICT.term" \
"AND docs.title = 'DOC';"`

_test_case "1-2" "The text is searched for term matches using a query based on regex." "${q2}"

#---------------------------------------------------------------

# TEST 1-3

q3=`echo "SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'DOC'; " \
"SELECT count(dicts.DICT.id) " \
"FROM dicts.DICT, words " \
"WHERE words.tokens = dicts.DICT.term"`

_test_case "1-3" "The text is parsed into separate words which are compared to each term." "${q3}"

#---------------------------------------------------------------

# TEST 1-4

#Creating the index:
echo "CREATE INDEX btree_${big_dict}_indx ON dicts.${big_dict} USING btree (term) WITH (fillfactor = 100);" | psql -d term_matching_db -U term_matcher -q
echo "CREATE INDEX btree_${medium_dict}_indx ON dicts.${medium_dict} USING btree (term) WITH (fillfactor = 100);" | psql -d term_matching_db -U term_matcher -q
echo "CREATE INDEX btree_${small_dict}_indx ON dicts.${small_dict} USING btree (term) WITH (fillfactor = 100);" | psql -d term_matching_db -U term_matcher -q

q4=`echo "SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'DOC'; " \
"SELECT count(dicts.DICT.id) " \
"FROM dicts.DICT, words " \
"WHERE words.tokens = dicts.DICT.term"`

_test_case "1-4" "The text is parsed into separate words which are compared to each term. There is a btree index on dictionary." "${q4}"

#Dropping the index:
echo "DROP INDEX btree_${big_dict}_indx;" | psql -d term_matching_db -U term_matcher -q
echo "DROP INDEX btree_${medium_dict}_indx;" | psql -d term_matching_db -U term_matcher -q
echo "DROP INDEX btree_${small_dict}_indx;" | psql -d term_matching_db -U term_matcher -q

#---------------------------------------------------------------

# TEST 1-5

#Creating the index:
echo "CREATE INDEX hash_${big_dict}_indx ON dicts.${big_dict} USING hash (term);" | psql -d term_matching_db -U term_matcher -q
echo "CREATE INDEX hash_${medium_dict}_indx ON dicts.${medium_dict} USING hash (term);" | psql -d term_matching_db -U term_matcher -q
echo "CREATE INDEX hash_${small_dict}_indx ON dicts.${small_dict} USING hash (term);" | psql -d term_matching_db -U term_matcher -q

q5=`echo "SELECT regexp_split_to_table(lower(docs.document), '([\.\;\,\:\?\"]*[[:space:]]+|\.)') tokens " \
"INTO TEMPORARY words " \
"FROM docs " \
"WHERE docs.title = 'DOC'; " \
"SELECT count(dicts.DICT.id) " \
"FROM dicts.DICT, words " \
"WHERE words.tokens = dicts.DICT.term"`

_test_case "1-5" "The text is parsed into separate words which are compared to each term. There is a hash index on dictionary." "${q5}"

#Dropping the index:
echo "DROP INDEX hash_${big_dict}_indx;" | psql -d term_matching_db -U term_matcher -q
echo "DROP INDEX hash_${medium_dict}_m_indx;" | psql -d term_matching_db -U term_matcher -q
echo "DROP INDEX hash_${small_dict}_indx;" | psql -d term_matching_db -U term_matcher -q
