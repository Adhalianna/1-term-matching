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
        id int not null primary key,
        term varchar(255) not null,
        definition text
        );""")
except:
    print("Failed to create table wikidict.")



# Open a file and iterate over it
# with open("wikidict.txt", 'r') as index_file:
#     for line in index_file:


db.commit()
db.close()
cur.close()