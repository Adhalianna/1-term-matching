# Things to keep in mind
* db_to_postgresdict.py assumes that English language is used
* db_to_postgresdict.py always names thesaurus dictionary *thes_dict* and the configuration *dicts_config*
* a command `pg_config --sharedir` can be used to get the $SHAREDIR of given postgres instance
* Test collection #3 reconfigures text search configuration for each query. This behaviour deviates from other tests.
* To clear all test data: `TRUNCATE TABLE test_collections CASCADE;`
* Test 1-2 had to be cancelled because of problems at creating a regex pattern from a dict term