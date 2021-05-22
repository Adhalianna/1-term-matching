#!/usr/bin/python3.9
import psycopg2
import pdftotext
import sys
import re

# Get filename from arguments
try:
    filename = sys.argv[1]
except IndexError:
    raise SystemExit("""Missing program argument. Pass a name of a pdf file that
    is to be parsed and uploaded to the database.""")

with open(filename, "rb") as f:
    text = pdftotext.PDF(f)

print("Found a pdf file with " + str(len(text)) + " pages.")

# Remove whitespaces all over the places to save yourself some time and memory
for page in text:
    page.strip()

text = "\n\n".join(text)

white_space_strip = re.compile(r'\s{2,}|\n')
text = re.sub(white_space_strip, ' ', text)


print("The inserted version of the text will have " + str(len(text)) + " characters.")

# Database 
try:
    db = psycopg2.connect("dbname=term_matching_db user=term_matcher password=term_matcher")
except:
    print("Failed to connect to the database.")

# Opening a cursor that performs database operations
cur = db.cursor()

# Insert
try:
    text_to_insert = (text,)
    cur.execute("INSERT INTO docs(document) VALUES(%s)", text_to_insert)
    db.commit()
except:
    print("Failed to insert the text into the database.")

print("Data successfully committed to the database!")
