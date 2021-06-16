#!/usr/bin/python3.9
import psycopg2
import pdftotext
import sys
import re
import math

# Get filename from arguments
try:
    filename = sys.argv[1]
    title = sys.argv[2]
except IndexError:
    raise SystemExit("""Missing program argument! 
    First, pass a name of a pdf file that is to be parsed and uploaded to the database. 
    Second, add a title that will be inserted into the database""")

if sys.argv[3] is not None:
    sizes = int(sys.argv[3])
else:
    sizes = 1


with open(filename, "rb") as f:
    text = pdftotext.PDF(f)

page_num = len(text)

print("Found a pdf file with " + str(page_num) + " pages. It will be partitioned to create " + str(sizes) + " texts in the database.")

partition_size = math.floor(page_num / sizes)
print("The smalles text will use " + str(partition_size) + " pages.")


for i in range(sizes):
    # Remove whitespaces all over the places to save yourself some time and memory
    max_pages = (i + 1) * partition_size

    result_text = []
    for j in range(max_pages):
        result_text.append(text[j])
    result_text = "\n\n".join(result_text)

    white_space_strip = re.compile(r'\s{2,}|\n')
    result_text = re.sub(white_space_strip, ' ', result_text)

    print("The inserted version of the text will have " + str(len(result_text)) + " characters.")

    # Database 
    try:
        db = psycopg2.connect("dbname=term_matching_db user=term_matcher password=term_matcher")
    except:
        print("Failed to connect to the database.")

    # Opening a cursor that performs database operations
    cur = db.cursor()

    # Insert
    try:
        text_to_insert = (result_text,)
        cur.execute("INSERT INTO docs(document, title, ts_tokens) VALUES(%s, %s, to_tsvector(%s))", (text_to_insert, title + "_" + str(i), text_to_insert))
        db.commit()
    except:
        print("Failed to insert the text into the database.")
