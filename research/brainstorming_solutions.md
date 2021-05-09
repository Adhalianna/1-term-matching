# How the problem can be solved?

A messy list of possible approaches and links to resources that could be further studied.

## The ideas that seem good

* Use Postgres _tsquery_ and _tsvector_  like in the tutorial [here](https://compose.com/articles/mastering-postgresql-tools-full-text-search-and-phrase-search/).
* Try and change the dictionary that will be used into a [Postgresql dictionary](https://www.postgresql.org/docs/9.1/textsearch-dictionaries.html).
* Study [this all](https://www.postgresql.org/docs/9.5/textsearch.html) to have a better understanding of full-text search possibilities of PostgreSQL.
## The bad ideas

Those are to be reconsidered when there are no more good ideas to be implemented and still too few solutions are inspected. 

* Do it __the most naive way__: query each phrase of provided text (can be done just for comparison with other methods but is not an acceptable solution.
* Make Lucene build an index based on provided text and query all the dictionary entries (looks a bit too much like _the most naive way_, might be even worse).
* Do the same but with Sphinx, supposedly builds indexes quicker.
* Query the dictionary entries against simply tokenized text document.
* Study [this](https://kandepet.com/dissecting-lucene-the-index-format/), maybe the needle in a haystack problem can be in the end solved with Lucene changing its most popular behaviour into a desired one?
* Change Lucene's behaviour at index creation level to discard terms that are not in the dictionary writing own implementation of [Analyzer.ReuseStrategy](https://lucene.apache.org/core/4_4_0/core/org/apache/lucene/analysis/Analyzer.ReuseStrategy.html) (still seems very far from efficient).
* Run Aho-Corasick on a text and map returned phrases to ids of matched dictionary terms - there are some ready implementions, maybe writing a software won't be that  time consuming but it also will not scalable without some new solutions introduced so it is __the last thing to consider__.
* Some specifif queries are written in [this paper](http://www.vldb.org/conf/2004/IND3P3.PDF) and there are some optimizations mentioned too. It seems somewhat old however and its solutions might be already implemented in the databases.



