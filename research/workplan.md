# Timing

* Deadline: ~8th of June
* Time left after workplan meeting: 6 weeks

# Initial workplan

* __week 1__: research further solutions to the problem and start researching technologies
* __week 2__: prepare first data set and look further into possible solutions working on the data
* __week 3__: choose a set of final solutions to go with and familiarize yourself with required technology further
* __week 4__: scale up the database, design and run tests
* __week 5__: if research went well and the solutions are utilized properly, work on "fuzziness" issue otherwise work on delays
* __week 6__: 
	* if not started before and it still seems doable work on "fuziness" issue
	* work on delays if there are any
	* __most importantly__, wrap it up and summarize

# Realization of guidelines and project objectives

The documentation should be expanded at each step of the project to keep track of all the decisions made, their drawbacks and any information that should be included in the self-evaluation.

# Todos

* ~~Brainstorm all possible approaches to the problem~~
* ~~Prepare initial test data~~
* Remove the pdfs and use an SQL dump instead
* ~~Complete the postgres dictionary generating approach~~
* ~~Add various warnings about the tests based on data set 1 (generating the data takes a day at least...)~~
* ~~Fix [wikigraph script](setup/dictionaries/wikigraph.py) so that it does not insert empty entries.~~ ??
* Complete [research log](research/research_log.md)
* Create dictionaries using wordnet
* ~~Refactor the first two sections of each tests' set/collection into something more universal and easier to edit (but before check loose_notes.md)~~
* ~~Run tests with smaller dictionaries (70000 records take too much time with text-search functions)~~
* \[Optional] Parametarize the project to be able to use a different than english language
* \[Optional refactoring] Skip creating user on the OS and make scripts parametarized with database name, user name and password.
* \[Optional] Move project to Docker. 