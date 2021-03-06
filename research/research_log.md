# Resarch log

* Started with research on term matching in general. Learnt about inverse indexes used full-text search problems e.g. in Lucene search engine. Some of the first findings in that matter included:
  * Some youtube videos about how Lucene works: ["Text search with Lucene"](https://www.youtube.com/watch?v=x37B_lCi_gc)
  * A [wikipedia article](https://en.wikipedia.org/wiki/Inverted_index) about inverted indexes
* Simultaneously researched string matching in general and algorithms used to find a term as a string in a longer string.
  * A great deal of that ended revolving around Aho-Corasick automata and tries. Seemed like the most efficient approach to the problem (after some modifications) but not a one that could be implemented quickly with an existing database software. Aho-Corasick algorithm is supposed to be used by existing search engines (e.g. Lucene) to build inverted indexes but even after closer inspection of Lucene's core API that algorithm seemed too hard to expose. Aho-Corasick is efficiently used in databases storing DNA code however in its typical form it could not be used to perform fuzzy matching and would need to be partitioned in some way to be able to serve as an index. A similar data structure which is closer to a tree could be used to translate fuzzy matching and some kind of partitioning of the memory onto the automata is a trie. In the end it was considered a dead end because of involved complexity but an interesting idea nevertheless. It is probably used in text search but never exposed well enough to solve a problem that is somewhat inverse to the full-text search.
    * Found [a discussion about Aho-Corasick scalability](https://stackoverflow.com/questions/5133916/scalability-of-aho-corasick). Not particurarly promising at first (the newer the answers the more promising it is, perspective changes with better hardware it seems) but some of the proposed ideas probably did not even had a chance to be fully implemented.
    * Another interesting discussion on stackoverflow was [about inserts and deletes](https://stackoverflow.com/questions/53288664/updating-an-aho-corasick-trie-in-the-face-of-inserts-and-deletes)
    * Also some studying resources about Aho-Corasick: [YouTube video about dictionary links in Aho-Corasick](https://www.youtube.com/watch?v=O7_w001f58c), [YouTube video about dictionary links in Aho-Corasick](https://www.youtube.com/watch?v=OFKxWFew_L0), [Wikipedia article about Aho-Corasick](https://en.wikipedia.org/wiki/Aho%E2%80%93Corasick_algorithm)
    * Some research papers about variations of Aho-Corasick: [Aho-Corasick + fuzzy string matching](https://cs.stackexchange.com/questions/93339/a-fuzzy-string-matching-algorithm-for-finding-all-occurrences-from-a-set-of-stri), [a general paper about variations of the automata](https://dl.acm.org/doi/abs/10.1145/3200842.3200850)
* Another kind of research dead end was a topic of natural language processing used to e.g. teach neural networks. Turned out to result in inefficient search phrases. Despite that, some light was shed on various approaches to fuzzy matching:
  * [n-gram model](https://en.wikipedia.org/wiki/N-gram#Applications_and_considerations)
  * A tree that uses Levenshtein distance - [a BK-tree](https://signal-to-noise.xyz/post/bk-tree/)
* Having realised most of that was a waste of time in terms of project realization somehow managed to find a new track with PostgreSQL full-text search functionality.
* The potentially applicable part of the research was collected in a file named [brainstorming_solutions.md](brainstorming_solutions.md).
* Moved on to generating dictionaries. Found a wikipedia module for Python. Started to learn to use Python and psycopg2. 
* The first attempt at generating a dictionary involved a file with a list of terms which definitions would be queried. It turned out to be an ineffective way of collecting sample data.
* Added a script that parsed pdf to plain text that could be inserted into database.
* A lot of time was spent on polishing the script that genereted dictionaries using Wikipedia API. First tests on dictionaries created this way with entries around 2000, 20000 seemed to give unreliable results (execution time less than 1s). Because of that many attempts were done to achieve a much bigger dictionary (70000 entries). The script would crash for multiple reasons mid exuction. To collect around 70000 entries the script was running whole day. Most common reason of a crash was lost internet connection. However, later it turned out that some queries perform much worse than expected (80 minutes) and much worse than what was considered to be a naive solution. Nevertheless, a resourceful machine (16 threads, 32GB RAM, SSD) was discovered to be a nuisance in some cases.
* Started creating tests (benchmarks) which after a while had to be refactored to be able to write them faster and collect results inside the database.
* One of test cases based on regex had to be excluded because of parsing problems (see [loose_notes](loose_notes.md))
* Expanded knowledge about PostgreSQL and SQL greatly.
* During testing found some interesting results in the net about a _fuzzystrmatch_ module for Postgres. Added new tests using the module.
* After several problems with benchmarks the sample data was reconsidered.
* Many more fixes and refactorizations were done to the tests after that.
* The test execution logs were analyzed with a help of some queries all of which was summarized in the [report.md](../results/report.md) file.

## Final thoughts

### Main difficulties

1) Scripting (enourmous number of errors and problems with python modules)
2) Generating data (because of errors in scripts and unstable internet connection)
3) Unexpectedly poor performance of some queries
4) Not testing enough early enough
5) Overindulging in unnecessary research
6) Messy scripting

### Areas that could be improved

* Enable usage of language different than english
* Improve test generation and benchmarking experience
* Generate dictionaries with wordnet
* More tested queries, more clever queries, more queries based on regex and ilike as those performed the best
* Refactoring and documenting code
* Running more tests
* Fetching sample texts from the internet, like dictionaries, instead of relying on PDF files.

<!-- But, isn't completing anything a success already? -->