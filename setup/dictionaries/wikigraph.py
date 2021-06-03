#!/usr/bin/python3.9
import wikipedia #https://towardsdatascience.com/wikipedia-api-for-python-241cfae09f1c
                 #https://stackabuse.com/getting-started-with-pythons-wikipedia-api/
import psycopg2  #https://wiki.postgresql.org/wiki/Psycopg2_Tutorial
from psycopg2 import sql as sql #https://www.psycopg.org/docs/sql.html#module-psycopg2.sql
import sys


wikipedia.set_lang("en")

try:
    start_page = wikipedia.search(sys.argv[1], results=1)
    depth = int(sys.argv[2])
except IndexError:
    raise SystemExit("""Missing program arguments. Pass a name of a wikipedia page you want to start parsing and a depth of search by references.
    Optionally add a prefix of a wikipedia website that will change the language as the last argument""")

if len(sys.argv) > 3:
    table_name = sys.argv[3]
else:
    table_name = "wikigraph"

if len(sys.argv) > 4:
    wikipedia.set_lang(sys.argv[4])

print("Using page:")
print(wikipedia.page(start_page, auto_suggest=False).title)
print(wikipedia.summary(start_page,auto_suggest=False, sentences=2) + " [...]")
print("---")

# Aggregate pages penetrating wikipedia through links
pages = []
pages.append(start_page[0])
already_calculated = 0

for i in range(depth):
    print("Current depth " + str(i) + "...")
    for j in pages[already_calculated:]:
        try:
            new_pages = wikipedia.page(j, auto_suggest=False).links
        except wikipedia.exceptions.WikipediaException:
            try:
                new_pages = wikipedia.page(wikipedia.search(j.partition("(")[0], results=1), auto_suggest=False).links
            except:
                try:
                    new_pages = wikipedia.page(wikipedia.search(j, results=1)[0], auto_suggest=False).links
                except:
                    new_pages = []
        
        already_calculated = len(pages)
        pages.extend(new_pages)

# Summarize
pages = dict.fromkeys(pages)
pages_num = str(len(pages))
print("---")
print("Found " + pages_num + " articles that can be changed into dictionary entries")
print("---")

# Database 
try:
    db = psycopg2.connect("dbname=term_matching_db user=term_matcher password=term_matcher")
except:
    print("Failed to connect to the database.")

# Opening a cursor that performs database operations
cur = db.cursor()

try:
    cur.execute(sql.SQL("DROP TABLE IF EXISTS dicts.{}").format(sql.Identifier(table_name)))
    cur.execute(sql.SQL("""CREATE TABLE IF NOT EXISTS dicts.{} (
        id serial primary key,
        term varchar(255) not null,
        term_query tsquery,
        term_vector tsvector,
        definition text
        );""").format(sql.Identifier(table_name)))
except:
    print("Failed to create table.")
    exit(1)

db.commit()


# Inserting into the database
count = 1
total = len(pages)
for item in pages:
    try:
        definition =  wikipedia.summary(item, auto_suggest=False)
    except wikipedia.exceptions.WikipediaException:
        try:
            definition =  wikipedia.summary(wikipedia.search(item.partition("(")[0], results=1)[0], auto_suggest=False)
        except:
            try:
                definition =  wikipedia.summary(wikipedia.search(item, results=1)[0], auto_suggest=False)
            except:
                definition = ""
    term = item.partition("(")[0].strip().lower()
    entry = (term, term, definition)
    cur.execute(sql.SQL("""INSERT INTO dicts.{} (term, term_query, definition)
    VALUES(%s, phraseto_tsquery(%s), %s)""").format(sql.Identifier(table_name)), entry)
    db.commit()
    count += 1
    progress = count / total
    if count % 20 == 0:
        print("Entered: "+ str(count) + ", Progress: " + str(round(progress * 100, 2)) + "%.")

db.close()
cur.close()

print("---")
print("Data successfully committed to the database!")
