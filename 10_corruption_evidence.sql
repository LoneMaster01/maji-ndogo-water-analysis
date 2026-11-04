-- ============================================================
-- 10_corruption_evidence.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- Part 3: Gathering Evidence of Corruption
-- Uses CTEs to identify employees who made an above-average 
-- number of mistakes, and cross-references their records 
-- with auditor statements mentioning "cash".
-- ============================================================

WITH error_count AS (
    -- Step 1: Count mistakes per employee
    SELECT 
        employee_name, 
        COUNT(*) AS NumberOfMistakes
    FROM md_water_services.Incorrect_records
    GROUP BY employee_name
),
suspect_list AS (
    -- Step 2: Filter for employees with above-average mistakes
    SELECT 
        employee_name, 
        NumberOfMistakes
    FROM error_count
    WHERE NumberOfMistakes > (
        SELECT AVG(NumberOfMistakes) FROM error_count
    )
)
-- Step 3: Pull all records for these suspects mentioning "cash"
SELECT 
    employee_name, 
    location_id, 
    statements
FROM md_water_services.Incorrect_records
WHERE employee_name IN (SELECT employee_name FROM suspect_list)
  AND statements LIKE '%cash%';

-- Verification Check: 
-- Change "IN" to "NOT IN" in the query above. 
-- It should return 0 rows, proving no other employees 
-- have bribery allegations against them.