# 1. Term matching and identification

## Objective

1. There is a text document (a few pages of plain text)
2. There is a database of terms: single or multiple words (a dictionary); large

The objective is to identify all terms in the document (mind that querying each word from the document separately with the database is not an option). 

Measure performance and scalability of chosen approaches.

### Secondary objective

Provide a fuzzy match to deal with inflection.

### Guidelines to keep in mind

* Must run under Linux and macOS.
* The repository must be self-sufficient, all data and instructions on setting up the dependencies included.
* Keep setup minimal.
* Documentation in markdown included.
* Results easy to evaluate.
* Self-evaluation of the project included.

---

# Project realization

The project started with research on possible solutions. A summary of that reasearch is located in the [brainstorming_solutions](research/brainstorming_solutions.md) file.

---

## Python dependencies

* Python 3
* wikipedia
* psycopg2
* pdftotext - depends on poppler
