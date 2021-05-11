CREATE SCHEMA IF NOT EXISTS dicts;
CREATE SCHEMA IF NOT EXISTS docs;

ALTER ROLE term_matcher SET search_path TO dicts, docs;

