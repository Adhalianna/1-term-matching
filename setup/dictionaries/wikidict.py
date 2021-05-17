#!/usr/bin/python3.9
import wikipedia #https://towardsdatascience.com/wikipedia-api-for-python-241cfae09f1c
import psycopg2 #https://wiki.postgresql.org/wiki/Psycopg2_Tutorial

# Database 
try:
    db = psycopg2.connect("dbname=term_matching_db user=term_matcher password=term_matcher")
except:
    print("Failed to connect to the database.")

# Opening a cursor that performs database operations
cur = db.cursor()

try:
    cur.execute("""CREATE TABLE IF NOT EXISTS dicts.wikidict(
        id serial primary key,
        term varchar(255) not null,
        definition text
        );""")
except:
    print("Failed to create table wikidict.")

db.commit()

wikipedia.set_lang("en")
# Open a file and iterate over it 
with open("wikidict.txt", 'r') as index_file:
    total_lines = sum(1 for _ in index_file)
    print("There are " + str(total_lines) + " lines total.")
with open("wikidict.txt", 'r') as index_file:
    count = 0
    for line in index_file:
        term = line.partition("(")[0].strip().lower()
        entry = (term, wikipedia.summary(line))
        cur.execute("""INSERT INTO dicts.wikidict(term, definition)
        VALUES(%s, %s)""", entry)
        count+=1
        print("inserting term '" + term + "', (" + str(count) + "/" + str(total_lines) + ").")
db.commit()

db.close()
cur.close()