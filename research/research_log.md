* Started with research on term matching in general. Learnt about inverse indexes used full-text search problems e.g. in Lucene search engine. Some of the first findings in that matter included:
  * Some youtube videos about how Lucene works: ["Text search with Lucene"](https://www.youtube.com/watch?v=x37B_lCi_gc)
  * A [wikipedia article](https://en.wikipedia.org/wiki/Inverted_index) about inverted indexes
* Simultaneously researched string matching in general and algorithms used to find a term as a string in a longer string.
  * A great deal of that ended revolving around Aho-Corasick automata and tries. Seemed like the most efficient approach to the problem (after some modifications) but not a one that could be implemented quickly with an existing database software. Aho-Corasick algorithm is supposed to be used by existing search engines (e.g. Lucene) to build inverted indexes but even after closer inspection of Lucene's core API that algorithm seemed too hard to expose. Aho-Corasick is efficiently used in databases storing DNA code however in its typical form it could not be used to perform fuzzy matching and would need to be partitioned in some way to be able to serve as an index. A similar data structure which is closer to a tree could be used to translate fuzzy matching and some kind of partitioning of the memory onto the automata is a trie. In the end it was considered a dead end because of involved complexity but an interesting idea nevertheless. It is probably used in text search but never exposed well enough to solve a problem that is somewhat inverse to the full-text search.
    * Found [a discussion about Aho-Corasick scalability](https://stackoverflow.com/questions/5133916/scalability-of-aho-corasick). Not particurarly promising at first (the newer the answers the more promising it is, perspective changes with better hardware it seems) but some of the proposed ideas probably did not even had a chance to be fully implemented.
    * Another interesting discussion on stackoverflow was [about inserts and deletes](https://stackoverflow.com/questions/53288664/updating-an-aho-corasick-trie-in-the-face-of-inserts-and-deletes)
    * Also some studying resources about Aho-Corasick: (YouTube video about dictionary links in Aho-Corasick)[https://www.youtube.com/watch?v=O7_w001f58c], (YouTube video about dictionary links in Aho-Corasick)[https://www.youtube.com/watch?v=OFKxWFew_L0], (Wikipedia article about Aho-Corasick)[https://en.wikipedia.org/wiki/Aho%E2%80%93Corasick_algorithm]
    * Some research papers about variations of Aho-Corasick: (Aho-Corasick + fuzzy string matching)[https://cs.stackexchange.com/questions/93339/a-fuzzy-string-matching-algorithm-for-finding-all-occurrences-from-a-set-of-stri], (a paper generally about variations of the automata)[https://dl.acm.org/doi/abs/10.1145/3200842.3200850]
* Another kind of research dead end was a topic of natural language processing used to e.g. teach neural networks. Turned out to result in inefficient search phrases. Despite that, some light was shed on various approaches to fuzzy matching:
  * (n-gram model)[https://en.wikipedia.org/wiki/N-gram#Applications_and_considerations]
  * A tree that uses Levenshtein distance - (a BK-tree)[https://signal-to-noise.xyz/post/bk-tree/]
* Having realised most of that was a waste of time in terms of project realization somehow managed to find a new track with PostgreSQL full-text search functionality.
* The potentially applicable part of the research was collected in a file named [brainstorming_solutions.md](brainstorming_solutions.md).
* Moved on to generating dictionaries. Found a wikipedia module for Python. Started to learn to use Python and psycopg2. 
* The first attempt at generating a dictionary involved a file with a list of terms which definitions would be queried.
* to be continued