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

The project started with a research on possible solutions. A summary of that reasearch is located in the [brainstorming_solutions](research/brainstorming_solutions.md) file. The remaining part of the research and the work was documented in the [research_log](research/research_log.md). In the [workplan](research/workplan.md) file can be found a section with todos. In case of unclarities it might be useful as an extra resource.

# Project structure

The project is organized into 4 main categories:
* __benchamrks__ - containing sample tests that can be run
* __research__ - containing mainly text files
* __results__ - storing queries that can be run after tests to analyze the benchmarks and a final report
* __setup__ - containg scripts that will initialize the database, generate dictionaries, insert texts and sample pdfs that can be efficiently parsed to such texts (see [workplan](workplan.md) for details on planned restructurization)

In general the repository is more of a benchmarking playground waiting to be refactored for better UX.

## Initialize

The easiest way to start using the repository is to run the [initialize.sh](initialize.sh) script and wait for results.
## Running benchmarks

Benchmarks are most often called here _tests_. Since the benchmarks make very few assumptions about used data they are not parametarized well yet (see [workplan](research/workplan.md)). They are grouped into directories basing on the data they rely on. To acquire the data necessary to run the benchmarks a script with a name starting with `prepare_dataset` must be run. The script will run dictionary generator which can be interrupted any time to achieve a different size of the dictionary. Each test execution is logged to the database and can be used later by analyzing queries which examples can be found in [analyze.sql](results/analyze.sql) and [the report](results/report.md). 

### Initialize script

The script at the root of the repository called [initialize.sh](initialize.sh) will only perform benchmarks from directory [data2](benchmarks/data2) as those can be finished in a reasonable time whilst the data preparation step under [data1](benchmarks/data1/prepare_dataset1.sh) will attempt to create an extremely big dictionary. (The process is best interrupted, stopped, with e.g. `ctrl+c` shortcut when the number of entries starts to look satisfying.)

## Using scripts

Currently there are two working scripts that generate dictionary or text and one which alters configuration:
* `./setup/dictionaries/wikigraph.py` - generates a dictionary following links from a start page untill a specified depth is reached. It takes as arguments:
    1) Start page _(necessary)_
    2) Search depth _(necessary)_
    3) Dictionary table name _(necessary)_
    4) Language prefix of wikipedia _(optional, "en" recommended anyway)_
* `./setup/texts/parse_pdf.py` - parses a PDF file and inserts it to the database. It takes as arguments:
    1) Filename or path to the PDF file _(necessary)_
    2) Document title _(necessary)_
* `./setup/dictionaries/configure_dicts.sh` - creates and alters a text search configuration of given name. It takes as arguments:
    1) Name of a dictionary for which the configuration is to be altered _(necessary)_
    2) Name of a new configuration _(optional, "dicts_config" by default)_

---

## Python dependencies

Please use either `pip install` or acquire them from other repositories. The [initialize.sh](initialize.sh) script will run `pip install`.

* Python 3
* wikipedia
* psycopg2
* pdftotext - depends on poppler
* nltk 
