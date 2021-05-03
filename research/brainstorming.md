# How the problem can be solved?

* do it __the most naive way__: query each phrase of provided text (can be done just for comparison with other methods but is not an acceptable solution)
* make Lucene build an index based on provided text and query all the dictionary entries (looks a bit too much like _the most naive way_, might be even worse?)
* do the same but with Sphinx, supposedly builds indexes quicker
* query the dictionary entries against parsed text document (might be actually faster than making Lucene/Sphinx build an index for each query  but probably still worse than the naive approach)
* study [this](https://kandepet.com/dissecting-lucene-the-index-format/), maybe the needle in a haystack problem can be in the end solved with Lucene changing its most popular behaviour into a desired one.
* change Lucene's behaviour at index creation level to discard terms that are not in the dictionary writing own implementation of [Analyzer.ReuseStrategy](https://lucene.apache.org/core/4_4_0/core/org/apache/lucene/analysis/Analyzer.ReuseStrategy.html) (still seems very far from efficient)
* run aho-corasick on a text and map returned phrases to ids of matched dictionary terms - there are some ready implementions, maybe writing a software won't be that much time consuming but it won't be scalable without some new solutions introduced so it is __the last thing to consider__
* use Postgres _tsquery_ and _tsvector_ [like here](https://compose.com/articles/mastering-postgresql-tools-full-text-search-and-phrase-search/)
* 




