# Things to keep in mind
* generate_postgresdict.py assumes that English language is used
* A command `pg_config --sharedir` can be used to get the $SHAREDIR of given postgres instance
* Test collection #3 reconfigures text search configuration for each query. This behaviour deviates from other tests.
* To clear all test data: `TRUNCATE TABLE test_collections CASCADE;`
* Test 1-2 had to be cancelled because of problems at creating a regex pattern from a dict term.
* Tests that do not count matches had to be cancelled because of problems with parsing the results.
* All scripts assume starting from the repository root.
* Use that distinct()! The report would have been cleaner.