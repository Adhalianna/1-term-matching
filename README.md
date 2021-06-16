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

The project started with a research on possible solutions. A summary of that reasearch is located in the [brainstorming_solutions](research/brainstorming_solutions.md) file. The remaining part of the research and the work was documented in the [research_log](research/research_log.md). In the [workplan](research/workplan.md) file can be found a section with todos. In case of unclarities it might be useful as an extra resource. The benchmarks of tested solutions were summarized in [the report](results/report.md)

# Python dependencies

Please use either `pip install` or acquire them from other prefered repositories (e.g. Manjaro has packages for all of those in its repositories). The [initialize.sh](initialize.sh) script will run `pip install`.

* Python 3
* wikipedia
* psycopg2
* pdftotext - depends on poppler library
# Project structure

The project is organized into 4 main categories:
* __benchamrks__ - containing tests that can be run collected into sets (name 'collection' may appear too in the project)
* __research__ - containing mainly text files
* __results__ - storing markdown files that summarize the project
* __setup__ - containg scripts that will initialize the database, generate dictionaries, insert texts and sample pdfs that can be efficiently parsed to such texts (see [workplan](workplan.md) for details on planned restructurization)

## Initialize

The easiest way to start using the repository is to run the [initialize.sh](initialize.sh) script and wait for results.
## Running benchmarks

Benchmarks are most often called here _tests_. It is best to execute them using [initialize script](initialize.sh) but new ones depending on different sets of data can be created. Each test execution is logged to the database and can be used later by analyzing queries which examples can be found in [the report](results/report.md). 

## Using scripts

* `./setup/dictionaries/wikigraph.py` - generates a dictionary following links from a start page untill a specified depth is reached. It takes as arguments:
    1) Start page
    2) Search depth 
    3) Dictionary table name 
    4) Language prefix of wikipedia _(optional, "en" recommended anyway)_
* `./setup/texts/parse_pdf.py` - parses a PDF file and inserts it to the database. It takes as arguments:
    1) Filename or path to the PDF file
    2) Document title
    3) Number of size variations to create _(optional but "3" required for the tests to work correctly)_
* `./setup/dictionaries/generate_postgresdict.py` - creates a file that can be used a text search dictionary based on an existing table which is meant to be used as a dictionary
    1) The name of a table with the dictionary
    2) The path to the directory storing Postgres' text search dictionaries (try: _\`pg_config --sharedir\`/tsearch_data_)
* `./setup/dictionaries/configure_dicts.sh` - creates and alters a text search configuration of given name. It takes as arguments:
    1) Name of a dictionary for which the configuration is to be altered
    2) Name of a new configuration *(optional, "dicts_config" by default)*
* `./benchmarks/test_sets/set*` - runs a chosen collection of sets. 
    1) A base name of a dictionary to be used with an assumption that two other dictionaries with suffix *_small* and *_medium* also exist 
    2) A title of a text/document with an assumption that it was inserted to the database with a parse_pdf.py script which resulted in the title being suffixed: *_0*, *_1*, *_2* (3 size variations)
    3) An index. It varies the resultant test_id. It is not necessary to be able to distinguish tests by the used data but it can be used to make it simpler. _(optional)_

Example usage of almost all of the scripts can be found in the data_sets directory which stores not mentioned here [prepare_data](benchmarks/data_sets/prepare_data1.sh) scripts that utilize the documented scripts.


