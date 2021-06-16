#!/usr/bin/python3.9
import nltk
nltk.download('wordnet')

from nltk.corpus import wordnet as wn #https://www.tutorialspoint.com/python_text_processing/python_wordnet_interface.htm
import psycopg2
import sys

try:
    start_word = sys.argv[1]
    depth = int(sys.argv[2])
except IndexError:
    raise SystemExit("Missing program arguments. Pass a starting word and a depth of synonyms search. (e.g. depth 2: get synonyms of the word and their synonyms)")

if len(sys.argv) > 3:
    table_name = sys.argv[3]
else:
    table_name = "wordnet"

print("Using word:" + start_word)
print("---")

words = []
words.extend(wn.synsets(start_word))
already_calculated = 0

for i in range(depth):
    print("Current depth: " + str(i) + " ...")
    for j in words[already_calculated:]:
        new_pages = []
        for k in j.lemma_names():
            new_pages.extend(wn.synsets(list(set(k))))
        new_pages = set(new_pages)
        new_pages = list(new_pages)
        already_calculated = len(words)
        words.extend(new_pages)
    print(words)