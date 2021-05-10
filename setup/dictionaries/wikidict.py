#!/usr/bin/python3.9
import wikipedia #https://towardsdatascience.com/wikipedia-api-for-python-241cfae09f1c
import psycopg2 

# Database 
try:
    db = psycopg2.connect("dbname=term_matching_db user=term_matcher password=term_matcher")
except:
    print("Failed to connect to the database.")

# Opening a cursor that performs database operations
db_cur = db.cursor()



