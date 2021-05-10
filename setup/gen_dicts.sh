#!/bin/bash

common_requirements(){
    # Make sure psycopg2 is avaialble
    pip install psycopg2-binary
}

wikidict_requirements(){
    # Get wikipedia module for python
    pip install wikipedia
}

case $1 in
    "all")
        common_requirements
        wikidict_requirements
        ;;
    "wikidict")
        common_requirements
        wikidict_requirements
        ;;
    *)
        echo "Choose which generator to run, available options are:"
        echo "  all - generate all dictionaries."
        echo "  wikidict - generate only wikipedia based dictionary."\
        "The wikipedia based dictionary is a small dictionary of computer science related terms."\
        "The list of terms used can be modified by editing the file at setup/dictionaries/wikidict.txt"
        exit 1;
        ;;
esac





