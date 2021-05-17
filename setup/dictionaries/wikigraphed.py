#!/usr/bin/python3.9
import wikipedia #https://towardsdatascience.com/wikipedia-api-for-python-241cfae09f1c
                 #https://stackabuse.com/getting-started-with-pythons-wikipedia-api/
import psycopg2  #https://wiki.postgresql.org/wiki/Psycopg2_Tutorial
import sys


wikipedia.set_lang("en")

try:
    start_page = wikipedia.search(sys.argv[1], results=1)
    depth = int(sys.argv[2])
except IndexError:
    raise SystemExit("""Invalid program argument. Pass a name of a wikipedia page you want to start parsing and a depth of search by references.
    Optionally add a prefix of a wikipedia website that will change the language""")

if len(sys.argv) > 3:
    wikipedia.set_lang(sys.argv[3])

print("Using page:")
print(wikipedia.page(start_page).title)
print(wikipedia.summary(start_page, sentences=2) + " [...]")


pages = []
pages.append(start_page)
already_calculated = 0

for i in range(depth):
    print("Current depth " + str(i) + ".")
    for j in pages[already_calculated::]:
        pages.extend(wikipedia.page(j).links)
        print(pages)
    already_calculated = len(pages)

print("Found " + str(len(pages)) + " articles that can be changed into dictionary entries")

# Database 
try:
    db = psycopg2.connect("dbname=term_matching_db user=term_matcher password=term_matcher")
except:
    print("Failed to connect to the database.")

# Opening a cursor that performs database operations
cur = db.cursor()

try:
    cur.execute("""CREATE TABLE IF NOT EXISTS dicts.wikigraph(
        id serial primary key,
        term varchar(255) not null,
        definition text
        );""")
except:
    print("Failed to create table wikidict.")

db.commit()




db.commit()

db.close()
cur.close()