-- ============================================================
-- 01_data_exploration.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- First pass through the database: list the tables, sample the
-- core ones, and identify what kinds of water sources exist.
-- This is the "get to know the data" step before any analysis.
-- ============================================================


-- ------------------------------------------------------------
-- 1. What tables exist in this database?
-- ------------------------------------------------------------
SHOW TABLES;

-- Expected tables:
--   data_dictionary, employee, global_water_access, location,
--   water_quality, visits, water_source, well_pollution


-- ------------------------------------------------------------
-- 2. Sample each core table to understand its structure.
-- LIMIT 5 keeps the output small — we only need to see shape,
-- column names, and a few representative values.
-- ------------------------------------------------------------

SELECT * FROM location       LIMIT 5;
SELECT * FROM visits         LIMIT 5;
SELECT * FROM water_source   LIMIT 5;
SELECT * FROM employee       LIMIT 5;


-- ------------------------------------------------------------
-- 3. What types of water source are recorded?
-- DISTINCT collapses repeated values so we see the categories,
-- not every row.
-- ------------------------------------------------------------

SELECT DISTINCT type_of_water_source
FROM water_source;

-- Expected types:
--   tap_in_home, tap_in_home_broken, well, shared_tap, river


-- ------------------------------------------------------------
-- 4. What does each column mean?
-- The database has its own data dictionary — check it rather
-- than guessing.
-- ------------------------------------------------------------

SELECT * FROM data_dictionary;


-- ------------------------------------------------------------
-- 5. How are water sources distributed geographically?
-- Quick counts per province and per location type to get a
-- feel for the scale of the survey.
-- ------------------------------------------------------------

SELECT
    province_name,
    COUNT(*) AS records_per_province
FROM location
GROUP BY province_name
ORDER BY records_per_province DESC;

SELECT
    location_type,
    COUNT(*) AS records_per_location_type
FROM location
GROUP BY location_type
ORDER BY records_per_location_type DESC;