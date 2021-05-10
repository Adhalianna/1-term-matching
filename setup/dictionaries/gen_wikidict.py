#!/usr/bin/python3.9
import wikipedia
import psycopg2

# Database 
try:
    db = psycopg2.connect("dbname=term_matching_db user=term_matcher password=term_matcher")
except:
    print("Failed to connect to the database.")

# Opening a cursor that performs database operations
db_cur = db.cursor()



