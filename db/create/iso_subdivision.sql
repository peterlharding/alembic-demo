-- ============================================================================
--  iso_subdivision  — ISO 3166-2. Formerly `state`.
-- ============================================================================

-- DROP TABLE IF EXISTS public.iso_subdivision;

CREATE TABLE public.iso_subdivision (
    id               integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_code     text    NOT NULL REFERENCES public.iso_country(code),
    subdivision_code text    NOT NULL,
    name             text    NOT NULL,
    subdivision_type text    NOT NULL DEFAULT 'state',
    status           text    NOT NULL DEFAULT 'active',
    notes            text    NOT NULL DEFAULT '',
    parent_id        integer REFERENCES public.iso_subdivision(id),

    iso_3166_2 text GENERATED ALWAYS AS (country_code || '-' || subdivision_code) STORED,

    CONSTRAINT iso_subdivision_code_key   UNIQUE (country_code, subdivision_code),
    CONSTRAINT iso_subdivision_name_key   UNIQUE (country_code, name),
    CONSTRAINT iso_subdivision_code_check CHECK (subdivision_code ~ '^[A-Z0-9]{1,3}$'),
    CONSTRAINT iso_subdivision_name_check CHECK (char_length(name) BETWEEN 1 AND 128),
    CONSTRAINT iso_subdivision_status_check
        CHECK (status IN ('active', 'inactive')),
    CONSTRAINT iso_subdivision_type_check CHECK (subdivision_type IN
        ('state', 'territory', 'parish', 'province', 'region',
         'district', 'county', 'prefecture'))
);

--  No separate index on (country_code) is needed: iso_subdivision_code_key
--  is a btree whose leading column is country_code, and Postgres uses
--  leading-prefix matches for both the FK check and "list all in country".

COMMENT ON TABLE public.iso_subdivision IS
    'ISO 3166-2 country subdivisions: states, territories, provinces, regions.';
COMMENT ON COLUMN public.iso_subdivision.parent_id IS
    'Nullable self-reference. ISO 3166-2 nests subdivisions in some countries.';


-- ============================================================================
