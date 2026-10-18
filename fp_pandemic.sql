-- Фінальний проєкт: pandemic / infectious_cases (PostgreSQL 16)
-- Запуск: psql -d <db> -f fp_pandemic.sql (CSV лежить поруч)

-- Завдання 1
CREATE SCHEMA IF NOT EXISTS pandemic;
SET search_path TO pandemic;

DROP TABLE IF EXISTS pandemic.disease_cases CASCADE;
DROP TABLE IF EXISTS pandemic.entities CASCADE;
DROP TABLE IF EXISTS pandemic.infectious_cases CASCADE;

CREATE TABLE pandemic.infectious_cases (
    entity                TEXT,
    code                  TEXT,
    year                  INTEGER,
    number_yaws           TEXT,
    polio_cases           TEXT,
    cases_guinea_worm     TEXT,
    number_rabies         TEXT,
    number_malaria        TEXT,
    number_hiv            TEXT,
    number_tuberculosis   TEXT,
    number_smallpox       TEXT,
    number_cholera_cases  TEXT
);

\copy pandemic.infectious_cases FROM 'infectious_cases.csv' WITH (FORMAT csv, HEADER true, NULL '')

SELECT *
FROM pandemic.infectious_cases
ORDER BY entity, year
LIMIT 10;

SELECT
    COUNT(*)                                  AS n_rows,
    COUNT(DISTINCT entity)                    AS n_entities,
    COUNT(DISTINCT (entity, code))            AS n_entity_code_pairs,
    COUNT(*) FILTER (WHERE code IS NULL)      AS rows_without_code,
    COUNT(*) FILTER (WHERE number_rabies IS NULL) AS rows_without_rabies,
    MIN(year)                                 AS first_year,
    MAX(year)                                 AS last_year
FROM pandemic.infectious_cases;

-- Завдання 2: нормалізація до 3НФ
CREATE TABLE pandemic.entities (
    entity_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity     TEXT NOT NULL,
    code       TEXT,
    UNIQUE NULLS NOT DISTINCT (entity, code)
);

CREATE TABLE pandemic.disease_cases (
    case_id               INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity_id             INTEGER NOT NULL REFERENCES pandemic.entities (entity_id),
    year                  INTEGER NOT NULL CHECK (year BETWEEN 1800 AND 2100),
    number_yaws           NUMERIC,
    polio_cases           NUMERIC,
    cases_guinea_worm     NUMERIC,
    number_rabies         NUMERIC,
    number_malaria        NUMERIC,
    number_hiv            NUMERIC,
    number_tuberculosis   NUMERIC,
    number_smallpox       NUMERIC,
    number_cholera_cases  NUMERIC,
    UNIQUE (entity_id, year)
);

INSERT INTO pandemic.entities (entity, code)
SELECT DISTINCT
    entity,
    NULLIF(TRIM(code), '') AS code
FROM pandemic.infectious_cases
ORDER BY entity, code;

INSERT INTO pandemic.disease_cases (
    entity_id, year,
    number_yaws, polio_cases, cases_guinea_worm, number_rabies, number_malaria,
    number_hiv, number_tuberculosis, number_smallpox, number_cholera_cases
)
SELECT
    e.entity_id,
    ic.year,
    NULLIF(TRIM(ic.number_yaws), '')::NUMERIC,
    NULLIF(TRIM(ic.polio_cases), '')::NUMERIC,
    NULLIF(TRIM(ic.cases_guinea_worm), '')::NUMERIC,
    NULLIF(TRIM(ic.number_rabies), '')::NUMERIC,
    NULLIF(TRIM(ic.number_malaria), '')::NUMERIC,
    NULLIF(TRIM(ic.number_hiv), '')::NUMERIC,
    NULLIF(TRIM(ic.number_tuberculosis), '')::NUMERIC,
    NULLIF(TRIM(ic.number_smallpox), '')::NUMERIC,
    NULLIF(TRIM(ic.number_cholera_cases), '')::NUMERIC
FROM pandemic.infectious_cases AS ic
JOIN pandemic.entities AS e
    ON e.entity = ic.entity
   AND e.code IS NOT DISTINCT FROM NULLIF(TRIM(ic.code), '');

SELECT 'infectious_cases (original)' AS table_name, COUNT(*) AS n_rows FROM pandemic.infectious_cases
UNION ALL SELECT 'entities',      COUNT(*) FROM pandemic.entities
UNION ALL SELECT 'disease_cases', COUNT(*) FROM pandemic.disease_cases;

SELECT e.entity_id, e.entity, e.code, d.year, d.polio_cases, d.number_rabies
FROM pandemic.disease_cases AS d
JOIN pandemic.entities AS e USING (entity_id)
ORDER BY e.entity, d.year
LIMIT 10;

-- Завдання 3
SELECT
    e.entity_id,
    e.entity,
    e.code,
    ROUND(AVG(d.number_rabies), 4) AS avg_rabies,
    MIN(d.number_rabies)           AS min_rabies,
    MAX(d.number_rabies)           AS max_rabies,
    SUM(d.number_rabies)           AS sum_rabies
FROM pandemic.disease_cases AS d
JOIN pandemic.entities AS e USING (entity_id)
WHERE d.number_rabies IS NOT NULL
GROUP BY e.entity_id, e.entity, e.code
ORDER BY AVG(d.number_rabies) DESC, e.entity
LIMIT 10;

-- Завдання 4
SELECT
    e.entity,
    d.year,
    MAKE_DATE(d.year, 1, 1)                                        AS year_start,
    CURRENT_DATE                                                   AS today,
    DATE_PART('year', AGE(CURRENT_DATE, MAKE_DATE(d.year, 1, 1)))::INTEGER AS year_diff
FROM pandemic.disease_cases AS d
JOIN pandemic.entities AS e USING (entity_id)
ORDER BY e.entity, d.year
LIMIT 15;

-- Завдання 5
CREATE OR REPLACE FUNCTION pandemic.years_since(p_year INTEGER)
RETURNS INTEGER
LANGUAGE sql
STABLE
AS $$
    SELECT DATE_PART('year', AGE(CURRENT_DATE, MAKE_DATE(p_year, 1, 1)))::INTEGER
$$;

CREATE OR REPLACE FUNCTION pandemic.avg_cases_per_period(
    p_cases_per_year NUMERIC,
    p_divisor        INTEGER
)
RETURNS NUMERIC
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT p_cases_per_year / NULLIF(p_divisor, 0)
$$;

SELECT
    e.entity,
    d.year,
    pandemic.years_since(d.year)                                           AS year_diff_function,
    DATE_PART('year', AGE(CURRENT_DATE, MAKE_DATE(d.year, 1, 1)))::INTEGER AS year_diff_builtin
FROM pandemic.disease_cases AS d
JOIN pandemic.entities AS e USING (entity_id)
ORDER BY e.entity, d.year
LIMIT 10;

SELECT COUNT(*) AS n_mismatches
FROM pandemic.disease_cases
WHERE pandemic.years_since(year)
      IS DISTINCT FROM DATE_PART('year', AGE(CURRENT_DATE, MAKE_DATE(year, 1, 1)))::INTEGER;

SELECT
    COUNT(*)                                                    AS n_rows_total,
    COUNT(*) FILTER (WHERE number_rabies ~ '^-?[0-9]+(\.[0-9]+)?$') AS n_numeric_rabies,
    COUNT(*) FILTER (WHERE number_rabies IS NULL)               AS n_empty_rabies
FROM pandemic.infectious_cases;

WITH rabies AS (
    SELECT
        entity,
        year,
        CASE
            WHEN number_rabies ~ '^-?[0-9]+(\.[0-9]+)?$' THEN number_rabies::NUMERIC
        END AS cases_per_year
    FROM pandemic.infectious_cases
)
SELECT
    entity,
    year,
    cases_per_year,
    ROUND(pandemic.avg_cases_per_period(cases_per_year, 12), 4) AS per_month,
    ROUND(pandemic.avg_cases_per_period(cases_per_year, 4), 4)  AS per_quarter,
    ROUND(pandemic.avg_cases_per_period(cases_per_year, 2), 4)  AS per_half_year
FROM rabies
WHERE cases_per_year IS NOT NULL
ORDER BY cases_per_year DESC, entity, year
LIMIT 10;
