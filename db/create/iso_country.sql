-- ============================================================================
--  iso_country  — ISO 3166-1. Reference data.
-- ============================================================================
--  Natural primary key: `code` is externally defined, globally unique, and
--  stable. A surrogate integer would force a join for every display.

-- DROP TABLE IF EXISTS public.iso_country;

CREATE TABLE public.iso_country (
    code         text     NOT NULL PRIMARY KEY,
    iso3         text     NOT NULL,
    num3         smallint NOT NULL,
    name         text     NOT NULL,
    withdrawn_on date,

    CONSTRAINT iso_country_iso3_key   UNIQUE (iso3),
    CONSTRAINT iso_country_num3_key   UNIQUE (num3),
    CONSTRAINT iso_country_name_key   UNIQUE (name),
    CONSTRAINT iso_country_code_check CHECK (code ~ '^[A-Z]{2}$'),
    CONSTRAINT iso_country_iso3_check CHECK (iso3 ~ '^[A-Z]{3}$'),
    CONSTRAINT iso_country_num3_check CHECK (num3 BETWEEN 1 AND 999),
    CONSTRAINT iso_country_name_check CHECK (char_length(name) BETWEEN 1 AND 128)
);

--  ISO 3166-1 numeric codes carry leading zeros (Australia is 036, not 36).
--  Stored as smallint for compactness; this column renders the canonical form.
ALTER TABLE public.iso_country
    ADD COLUMN num3_code text
    GENERATED ALWAYS AS (lpad(num3::text, 3, '0')) STORED;

COMMENT ON TABLE public.iso_country IS
    'ISO 3166-1 country codes. Reference data; changes are migrations.';
COMMENT ON COLUMN public.iso_country.withdrawn_on IS
    'Date ISO retired this code (AN, CS, ...). NULL means current. Rows are '
    'retained so historical foreign keys stay valid.';


-- ============================================================================
