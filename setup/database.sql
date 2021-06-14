CREATE SCHEMA IF NOT EXISTS dicts;

GRANT ALL PRIVILEGES ON SCHEMA dicts TO term_matcher;

ALTER USER term_matcher SET search_path TO dicts, public;

CREATE TABLE docs(
    id serial primary key,
    title varchar(255),
    document text not null,
    ts_tokens tsvector
);

CREATE TABLE test_collections(
    id varchar(31) primary key,
    descr text,
    query text
);

CREATE TABLE tests(
    id serial primary key,
    test_id varchar(63) not null,
    exec_date timestamp,
    collection_id varchar(31) not null,
    dict_name varchar(63),
    dict_entries integer not null CHECK (dict_entries >= 0),
    document_name varchar(63),
    document_words integer not null CHECK (document_words >= 0),
    execution_time interval not null,
    matches integer not null CHECK (matches >= 0),
    constraint fk_test_case
        foreign key(collection_id) references test_collections(id)
);
