-- ============================================================
-- 03_data_cleaning.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- Documentation of all data cleaning applied to the database.
-- Every UPDATE in this file was executed on a copy table first,
-- verified, then applied to the live table.
--
-- This file is a CASE STUDY — the data has already been cleaned.
-- The queries at the bottom verify the current state is correct.
-- ============================================================


-- ============================================================
-- SECTION 1 — EMPLOYEE EMAILS
-- ============================================================
--
-- Problem: The employee table had no email addresses. Reports
--          and figures need to be sent to staff.
--
-- Convention: first_name.last_name@ndogowater.gov
--
-- Approach:
--   1. REPLACE(employee_name, ' ', '.')  — space → full stop
--   2. LOWER(...)                        — force lower case
--   3. CONCAT(..., '@ndogowater.gov')    — append the domain
--
-- These steps were tested with SELECT first, then applied via
-- UPDATE. The UPDATE statement is documented below.
-- ------------------------------------------------------------

-- Step 1a — preview the transformation (safe, read-only)
SELECT
    employee_name,
    CONCAT(
        LOWER(REPLACE(employee_name, ' ', '.')),
        '@ndogowater.gov'
    ) AS new_email
FROM employee
LIMIT 5;

-- Step 1b — the UPDATE that was applied
-- UPDATE employee
-- SET email = CONCAT(
--     LOWER(REPLACE(employee_name, ' ', '.')),
--     '@ndogowater.gov'
-- );


-- ============================================================
-- SECTION 2 — EMPLOYEE PHONE NUMBERS
-- ============================================================
--
-- Problem: Phone numbers were stored with a trailing space,
--          making them 13 characters instead of the expected
--          12 (plus sign + area code + number).
--
-- Diagnosis:
--   SELECT LENGTH(phone_number) FROM employee;   -- returned 13
--   Expected: 12
--
-- Fix: TRIM removes leading and trailing spaces.
-- ------------------------------------------------------------

-- Step 2a — verify the length issue (should show 13)
SELECT
    phone_number,
    LENGTH(phone_number) AS current_length
FROM employee
LIMIT 5;

-- Step 2b — the UPDATE that was applied
-- UPDATE employee
-- SET phone_number = TRIM(phone_number);

-- Step 2c — verification (should show 12 for every row)
-- SELECT
--     phone_number,
--     LENGTH(phone_number) AS cleaned_length
-- FROM employee
-- LIMIT 5;


-- ============================================================
-- SECTION 3 — WELL POLLUTION: RESULTS COLUMN
-- ============================================================
--
-- Problem: 38 records were marked 'Clean' in the results
--          column even though biological contamination was
--          above the safe threshold (> 0.01 CFU/mL).
--
-- Root cause: Data-entry staff used the word "Clean" in the
--             description field instead of checking the actual
--             measurement to set the result.
--
-- Full audit narrative: see 02_data_quality_audit.sql
-- ------------------------------------------------------------

-- Step 3a — the fix that was applied (38 rows affected)
-- UPDATE well_pollution
-- SET results = 'Contaminated: Biological'
-- WHERE biological > 0.01 AND results = 'Clean';


-- ============================================================
-- SECTION 4 — WELL POLLUTION: DESCRIPTION COLUMN
-- ============================================================
--
-- Problem: 26 records still had descriptions starting with
--          'Clean Bacteria: ...' even after the results were
--          fixed. The "Clean" prefix in the description was
--          misleading — anyone reading it would misread the
--          record.
--
-- Discovery: The first version of the audit query used the
--            pattern 'Clean\_%'. The backslash escapes the
--            underscore into a literal, so the pattern matched
--            nothing. Once corrected to 'Clean %' (literal
--            space), these 26 records surfaced.
--
-- Fix: Strip the "Clean " prefix from every such description.
-- ------------------------------------------------------------

-- Step 4a — the fix that was applied (26 rows affected)
-- UPDATE well_pollution
-- SET description = 'Bacteria: E. coli'
-- WHERE description = 'Clean Bacteria: E. coli';


-- ============================================================
-- SECTION 5 — SAFE CLEANING WORKFLOW
-- ============================================================
--
-- Every UPDATE above followed this pattern:
--
--   1. CREATE TABLE <table>_copy AS SELECT * FROM <table>;
--   2. Run the UPDATE on the copy.
--   3. Run the audit / verification SELECT on the copy.
--   4. If clean, run the same UPDATE on the live table.
--   5. Verify the live table.
--   6. DROP TABLE <table>_copy;
--
-- Example, as applied to well_pollution:
--
--   CREATE TABLE well_pollution_copy AS
--   SELECT * FROM well_pollution;
--
--   UPDATE well_pollution_copy
--   SET results = 'Contaminated: Biological'
--   WHERE biological > 0.01 AND results = 'Clean';
--
--   -- Verify the copy has 0 remaining issues
--   SELECT COUNT(*) FROM well_pollution_copy
--   WHERE (results = 'Clean' AND biological > 0.01)
--      OR description LIKE 'Clean %';
--
--   -- If 0, apply to the live table
--   UPDATE well_pollution
--   SET results = 'Contaminated: Biological'
--   WHERE biological > 0.01 AND results = 'Clean';
--
--   -- Verify the live table
--   SELECT COUNT(*) FROM well_pollution
--   WHERE (results = 'Clean' AND biological > 0.01)
--      OR description LIKE 'Clean %';
--
--   DROP TABLE well_pollution_copy;
-- ------------------------------------------------------------


-- ============================================================
-- SECTION 6 — POST-CLEANING VERIFICATION
-- ============================================================
--
-- These queries confirm the current state of the data.
-- Run them any time to prove the cleaning is intact.
-- ------------------------------------------------------------

-- 6a. No employee is missing an email
SELECT
    COUNT(*) AS employees_missing_email
FROM employee
WHERE email IS NULL;
-- Expected: 0

-- 6b. No phone number has a trailing space
SELECT
    COUNT(*) AS phones_with_wrong_length
FROM employee
WHERE LENGTH(phone_number) <> 12;
-- Expected: 0

-- 6c. No well is marked 'Clean' while contaminated
SELECT
    COUNT(*) AS wells_marked_clean_but_contaminated
FROM well_pollution
WHERE results = 'Clean' AND biological > 0.01;
-- Expected: 0

-- 6d. No description still carries the misleading "Clean" prefix
SELECT
    COUNT(*) AS descriptions_with_stale_clean_prefix
FROM well_pollution
WHERE description LIKE 'Clean %';
-- Expected: 0

-- 6e. Combined audit (the same query as 02_data_quality_audit.sql)
SELECT
    COUNT(*) AS remaining_bugs
FROM well_pollution
WHERE description LIKE 'Clean %'
   OR (results = 'Clean' AND biological > 0.01);
-- Expected: 0


