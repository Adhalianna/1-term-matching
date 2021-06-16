#!/usr/bin/python3.9
import psycopg2  #https://wiki.postgresql.org/wiki/Psycopg2_Tutorial
from psycopg2 import sql as sql
import sys
import re

try:
    table_name = sys.argv[1]
except IndexError:
    print("Specify a name of the table from which you wish to generate the dictionary.")
    exit(1)


# Database 
try:
    db = psycopg2.connect("dbname=term_matching_db user=term_matcher password=term_matcher")
except:
    print("Failed to connect to the database.")
    exit(1)


# Opening a cursor that performs database operations
cur = db.cursor()

try:
    path = sys.argv[2]
except IndexError:
    print("As a second argument pass a path to the shared directory used by your Postgres instance to store text search data ($SHAREDIR/tsearch_data)")
    print("For example, in Manjaro's default instaltion of PostgreSQL (2021 here) the path would be: /usr/share/postgresql/tsearch_data")
    exit(1)


terms = []
try:
    cur.execute(sql.SQL("SELECT * FROM (SELECT trim(both '(,)' from unnest(strip(to_tsvector('english', dicts.{name}.term)))::text) FROM dicts.{name}) AS foo;").format(name=sql.Identifier(table_name)))
    terms = cur.fetchall()
except:
    print("Failed to fetch terms from a dictionary.")

db.commit()

try:
    syn_dict = open(path + "/syn_fuzzy_" + table_name + ".syn", "w") # currently not used!
except PermissionError:
    raise SystemExit("Run the software with permissions necessary to put a new file under the provided path.")

for term in terms:
    syn_dict.write(str(term[0]) + "   " + str(term[0]) +"\n")
cur.close()
db.close()
