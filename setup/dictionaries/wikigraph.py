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
    raise SystemExit("""Missing program arguments. Pass a name of a wikipedia page you want to start parsing and a depth of search by references.
    Optionally add a prefix of a wikipedia website that will change the language as the last argument""")

if len(sys.argv) > 3:
    wikipedia.set_lang(sys.argv[3])

print("Using page:")
print(wikipedia.page(start_page, auto_suggest=False).title)
print(wikipedia.summary(start_page,auto_suggest=False, sentences=2) + " [...]")

# Aggregate pages by links
pages = []
pages.append(start_page[0])
already_calculated = 0

for i in range(depth):
    print("Current depth " + str(i) + ".")
    for j in pages[already_calculated:]:
        try:
            new_pages = wikipedia.page(j, auto_suggest=False).links
        except wikipedia.exceptions.DisambiguationError:
            new_pages = wikipedia.page(wikipedia.search(j, results=1), auto_suggest=False).links
        already_calculated += len(new_pages)
        pages.extend(new_pages)

print("---")
pages = dict.fromkeys(pages)
pages_num = str(len(pages))
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
    cur.execute("DROP TABLE IF EXISTS dicts.wikigraph")
    cur.execute("""CREATE TABLE IF NOT EXISTS dicts.wikigraph(
        id serial primary key,
        term varchar(255) not null,
        definition text
        );""")
except:
    print("Failed to create table wikidict.")

db.commit()

# Inserting into the database
for item in pages:
    try:
        definition =  wikipedia.summary(item, auto_suggest=False)
    except wikipedia.exceptions.WikipediaException:
        try:
            definition =  wikipedia.summary(wikipedia.search(item.partition("(")[0], results=1)[0], auto_suggest=False)
        except wikipedia.exceptions.DisambiguationError:
            definition =  wikipedia.summary(wikipedia.search(item, results=1)[0], auto_suggest=False)
    term = item.partition("(")[0].strip().lower()
    entry = (term, definition)
    cur.execute("""INSERT INTO dicts.wikigraph(term, definition)
    VALUES(%s, %s)""", entry)
    print(str(term) + "...")
    #print(entry)

# Do not commit before all inserts are completed
db.commit()

db.close()
cur.close()

print("---")
print("Data successfully committed to the database!")
print("How would you feel now about donating to the wikipedia after all that crawling?")
wikipedia.donate()