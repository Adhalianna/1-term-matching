#!/usr/bin/python3.9
import psycopg2  #https://wiki.postgresql.org/wiki/Psycopg2_Tutorial
import sys

# Database 
try:
    db = psycopg2.connect("dbname=term_matching_db user=term_matcher password=term_matcher")
except:
    print("Failed to connect to the database.")


# Opening a cursor that performs database operations
cur = db.cursor()

try:
    cur.execute("DROP TABLE IF EXISTS dicts.wikigraph")
    cur.execute("""CREATE TABLE IF NOT EXISTS dicts.wikigraph(
        id serial primary key,
        term varchar(255) not null,
        definition text
        );""")
except:
    print("Failed to create table wikidict.")


db.commit()


# Do not commit before all inserts are completed
db.commit()

db.close()
cur.close()