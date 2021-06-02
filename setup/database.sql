CREATE SCHEMA IF NOT EXISTS dicts;

GRANT ALL PRIVILEGES ON SCHEMA dicts TO term_matcher;

ALTER USER term_matcher SET search_path TO dicts, public;

CREATE TABLE IF NOT EXISTS docs(
    id serial primary key,
    title varchar(255),
    document text not null,
    ts_tokens tsvector
);

CREATE TABLE IF NOT EXISTS tests(
    id serial primary key,
    test_name varchar(31) not null,
    dict_entries integer not null CHECK (dict_entries >= 0),
    document_words integer not null CHECK (document_words >= 0),
    execution_time real
);

-- CREATE TEXT SEARCH CONFIGURATION public.current_config (
--     COPY = pg_catalog.simple
-- );


-- ALTER TEXT SEARCH CONFIGURATION public.current_config
--     DROP MAPPING FOR email, url, url_path, sfloat, float;


-- SET default_text_search_config = 'public.current_config';