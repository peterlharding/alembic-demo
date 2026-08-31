
-- ============================================================================
--  Application schema — reworked to current PostgreSQL conventions
--
--  Target:  PostgreSQL 13 or later (gen_random_uuid() is built in; no pgcrypto)
--  Naming:  Option A — `iso_` prefix for ISO-standardised reference data,
--                      unprefixed names for application-defined tables.
--
--  Conventions applied throughout:
--    * timestamptz everywhere — never `timestamp without time zone`
--    * GENERATED ... AS IDENTITY instead of SERIAL + nextval() defaults
--    * text + CHECK constraints instead of varchar(n)
--    * notes columns are NOT NULL DEFAULT '''''''' consistently
--    * a foreign key on every code column that references another table
--
--  READ THE "OPEN QUESTIONS" SECTION AT THE FOOT BEFORE RUNNING THIS.
--
--  Apply with:  psql -d yourdb -v ON_ERROR_STOP=1 -f schema.sql
-- ============================================================================


-- ----------------------------------------------------------------------------
--  Teardown — uncomment only for a clean rebuild. Order is reverse-dependency.
-- ----------------------------------------------------------------------------
-- DROP TABLE IF EXISTS public.locality;
-- DROP TABLE IF EXISTS public.iso_subdivision;
-- DROP TABLE IF EXISTS public.iso_country;


BEGIN;

SET search_path = public;


-- ============================================================================
--  iso_country  — ISO 3166-1. Reference data.
-- ============================================================================
--  Natural primary key: `code` is externally defined, globally unique, and
--  stable. A surrogate integer would force a join for every display.

CREATE TABLE public.iso_country (
    code         text     NOT NULL PRIMARY KEY,
    iso3         text     NOT NULL,
    num3         smallint NOT NULL,
    name         text     NOT NULL,
    withdrawn_on date,

    CONSTRAINT iso_country_iso3_key   UNIQUE (iso3),
    CONSTRAINT iso_country_num3_key   UNIQUE (num3),
    CONSTRAINT iso_country_name_key   UNIQUE (name),
    CONSTRAINT iso_country_code_check CHECK (code ~ '"'"'^[A-Z]{2}$'"'"'),
    CONSTRAINT iso_country_iso3_check CHECK (iso3 ~ '"'"'^[A-Z]{3}$'"'"'),
    CONSTRAINT iso_country_num3_check CHECK (num3 BETWEEN 1 AND 999),
    CONSTRAINT iso_country_name_check CHECK (char_length(name) BETWEEN 1 AND 128)
);

--  ISO 3166-1 numeric codes carry leading zeros (Australia is 036, not 36).
--  Stored as smallint for compactness; this column renders the canonical form.
ALTER TABLE public.iso_country
    ADD COLUMN num3_code text
    GENERATED ALWAYS AS (lpad(num3::text, 3, '"'"'0'"'"')) STORED;

COMMENT ON TABLE public.iso_country IS
    '"'"'ISO 3166-1 country codes. Reference data; changes are migrations.'"'"';
COMMENT ON COLUMN public.iso_country.withdrawn_on IS
    '"'"'Date ISO retired this code (AN, CS, ...). NULL means current. Rows are '"'"'
    '"'"'retained so historical foreign keys stay valid.'"'"';


-- ============================================================================
--  iso_subdivision  — ISO 3166-2. Formerly `state`.
-- ============================================================================

CREATE TABLE public.iso_subdivision (
    id               integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code     text    NOT NULL REFERENCES public.iso_country(code),
    subdivision_code text    NOT NULL,
    name             text    NOT NULL,
    subdivision_type text    NOT NULL DEFAULT '"'"'state'"'"',
    status           text    NOT NULL DEFAULT '"'"'active'"'"',
    notes            text    NOT NULL DEFAULT '"'"''"'"',
    parent_id        integer REFERENCES public.iso_subdivision(id),

    iso_3166_2 text GENERATED ALWAYS AS (country_code || '"'"'-'"'"' || subdivision_code) STORED,

    CONSTRAINT iso_subdivision_code_key   UNIQUE (country_code, subdivision_code),
    CONSTRAINT iso_subdivision_name_key   UNIQUE (country_code, name),
    CONSTRAINT iso_subdivision_code_check CHECK (subdivision_code ~ '"'"'^[A-Z0-9]{1,3}$'"'"'),
    CONSTRAINT iso_subdivision_name_check CHECK (char_length(name) BETWEEN 1 AND 128),
    CONSTRAINT iso_subdivision_status_check
        CHECK (status IN ('"'"'active'"'"', '"'"'inactive'"'"')),
    CONSTRAINT iso_subdivision_type_check CHECK (subdivision_type IN
        ('"'"'state'"'"', '"'"'territory'"'"', '"'"'province'"'"', '"'"'region'"'"',
         '"'"'district'"'"', '"'"'county'"'"', '"'"'prefecture'"'"'))
);

--  No separate index on (country_code) is needed: iso_subdivision_code_key
--  is a btree whose leading column is country_code, and Postgres uses
--  leading-prefix matches for both the FK check and "list all in country".

COMMENT ON TABLE public.iso_subdivision IS
    '"'"'ISO 3166-2 country subdivisions: states, territories, provinces, regions.'"'"';
COMMENT ON COLUMN public.iso_subdivision.parent_id IS
    '"'"'Nullable self-reference. ISO 3166-2 nests subdivisions in some countries.'"'"';


-- ============================================================================
--  locality  — cities, towns, suburbs. Formerly `city`.
-- ============================================================================
--  Not an ISO standard, hence no iso_ prefix. "Locality" is the official
--  Australian term (G-NAF, Australia Post) for what is colloquially a suburb.

CREATE TABLE public.locality (
    id               integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    country_code     text    NOT NULL,
    subdivision_code text    NOT NULL,
    locality_code    text    NOT NULL,
    name             text    NOT NULL,
    locality_type    text    NOT NULL DEFAULT '"'"'suburb'"'"',
    status           text    NOT NULL DEFAULT '"'"'active'"'"',
    notes            text    NOT NULL DEFAULT '"'"''"'"',

    --  Composite FK: validates the pair together. ('"'"'AU'"'"','"'"'CA'"'"') is two
    --  individually-valid codes naming nothing. Country validity follows
    --  transitively via iso_subdivision, so no direct FK to iso_country.
    CONSTRAINT locality_subdivision_fkey
        FOREIGN KEY (country_code, subdivision_code)
        REFERENCES public.iso_subdivision (country_code, subdivision_code)
        ON UPDATE CASCADE,

    CONSTRAINT locality_code_key    UNIQUE (country_code, subdivision_code, locality_code),
    CONSTRAINT locality_code_check  CHECK (locality_code ~ '"'"'^[A-Z0-9]{1,5}$'"'"'),
    CONSTRAINT locality_name_check  CHECK (char_length(name) BETWEEN 1 AND 128),
    CONSTRAINT locality_status_check
        CHECK (status IN ('"'"'active'"'"', '"'"'inactive'"'"')),
    CONSTRAINT locality_type_check  CHECK (locality_type IN
        ('"'"'city'"'"', '"'"'town'"'"', '"'"'suburb'"'"', '"'"'village'"'"',
         '"'"'locality'"'"', '"'"'municipality'"'"'))
);

--  Deliberately NOT unique on name: locality names genuinely repeat within a
--  single subdivision. A unique constraint here rejects valid gazetteer data.
CREATE INDEX locality_name_idx ON public.locality (country_code, lower(name));

--  UN/LOCODE. Enable ONLY if locality_code holds the 3-character location part
--  ('"'"'MEL'"'"'), not the full 5-character code ('"'"'AUMEL'"'"') — otherwise this
--  yields '"'"'AUAUMEL'"'"'. Verify first with the query in OPEN QUESTIONS below.
--
-- ALTER TABLE public.locality
--     ADD COLUMN unlocode text
--     GENERATED ALWAYS AS (country_code || locality_code) STORED;
-- CREATE UNIQUE INDEX locality_unlocode_key ON public.locality (unlocode);

COMMENT ON TABLE public.locality IS
    '"'"'Cities, towns, suburbs and rural localities within an ISO subdivision.'"'"';


-- ============================================================================
--  SEED DATA
-- ============================================================================



-- ============================================================================
--  OPEN QUESTIONS — resolve before or shortly after applying
-- ============================================================================
--
--  1. TIMEZONE OF MIGRATED DATA.  The source columns were `timestamp without
--     time zone`, so their values carry no offset. Converting them assumes a
--     zone. Check what the source server ran:
--
--         SHOW timezone;
--
--     then convert with the named zone, not a fixed offset — a fixed offset
--     silently shifts rows on the wrong side of a DST boundary:
--
--         old_column AT TIME ZONE '"'"'Australia/Melbourne'"'"'
--
--  2. locality_code FORMAT.  Determines whether the unlocode generated column
--     above is valid:
--
--         SELECT char_length(locality_code) AS len, count(*),
--                min(locality_code), max(locality_code)
--         FROM public.locality GROUP BY 1 ORDER BY 1;
--
--     All 3 -> enable unlocode. Any 5 -> locality_code is already the full
--     code; drop the generated column and add a CHECK that its first two
--     characters match country_code instead.
--
--  3. `status` SEMANTICS.  The original varchar(8) columns on state and city
--     were nullable with no constraint, so their meaning is not recoverable
--     from the schema. This file assumes a lifecycle flag (active/inactive)
--     and adds a separate *_type column for place classification. Confirm:
--
--         SELECT status, count(*) FROM public.state GROUP BY 1 ORDER BY 2 DESC;
--
--     Note varchar(8) could not hold '"'"'territory'"'"' (9 chars), so if it held
--     place types, Northern Territory and the ACT were already being rejected.
--
-- ============================================================================
