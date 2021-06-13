#!/usr/bin/python3.9
import psycopg2  #https://wiki.postgresql.org/wiki/Psycopg2_Tutorial
from psycopg2 import sql as sql
import sys
import re

try:
    action = sys.argv[1]
    table_name = sys.argv[2]
except IndexError:
    print("Specify either 'generate', 'configure' or 'all' as the first program parameter.")
    print("'generate' will stop at creating a file that can be used as a thesaurus dictionary.")
    print("'configure' will create or switch the text search configuration used by the database to use the generated thesaurus dictionary.")
    print("Next specify a name of the table from which you wish to generate the dictionary.")
    exit(1)


# Database 
try:
    db = psycopg2.connect("dbname=term_matching_db user=term_matcher password=term_matcher")
except:
    print("Failed to connect to the database.")
    exit(1)


# Opening a cursor that performs database operations
cur = db.cursor()

if action == "generate" or action == "all":
    try:
        path = sys.argv[3]
    except IndexError:
        print("As a second argument pass a path to the shared directory used by your Postgres instance to store text search data ($SHAREDIR/tsearch_data)")
        print("For example, in Manjaro's default instaltion of PostgreSQL (2021 here) the path would be: /usr/share/postgresql/tsearch_data")
        exit(1)


    terms = []
    try:
        cur.execute(sql.SQL("SELECT dicts.{name}.term FROM dicts.{name};").format(name=sql.Identifier(table_name)))
        terms = cur.fetchall()
    except:
        print("Failed to fetch terms from a dictionary.")

    db.commit()


    try:
        thesaurus_dict = open(path + "/thes_" + table_name + ".ths", "w")
    except PermissionError:
        raise SystemExit("Run the software with permissions necessary to put a new file under the provided path.")
        
    syn_dict = open(path + "/syn_" + table_name + ".syn", "w") # currently not used!

    stop_words = []
    with open(path + "/english.stop") as fp:
        lines = fp.readlines()
        for line in lines:
            stop_words.append(line.replace('\n', ""))

    for term in terms:
        try:
            the_string = term[0].strip("'")
        except:
            the_string = ""
        if the_string.isalpha() != True:
            translated_string = the_string.replace(' ', '_')
            for stpword in stop_words:
                the_string = re.sub(r"\b" + stpword + r"\b", "?", the_string)
            if the_string != "":
                thesaurus_dict.write(the_string + " : " + translated_string + "\n")
                syn_dict.write(translated_string + "   " + translated_string +"\n")
        else:
            syn_dict.write(the_string + "   " + the_string + "\n")


cur.close()
db.close()
