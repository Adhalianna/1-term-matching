CREATE SCHEMA IF NOT EXISTS dicts;

ALTER ROLE term_matcher SET search_path TO dicts;

CREATE TABLE IF NOT EXISTS docs(
    id serial primary key,
    title varchar(255), --optional field
    document text not null,
);
