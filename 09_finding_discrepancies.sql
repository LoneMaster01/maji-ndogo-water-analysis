-- ============================================================
-- 09_finding_discrepancies.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- Part 3: Comparing Surveyor Scores to Auditor Scores
-- Identifies the 102 records where the assigned employee 
-- recorded a different score than the independent auditor.
-- ============================================================

-- Create a permanent View for the incorrect records
-- This joins the auditor report to the surveyor visits, 
-- filters for the first visit (to avoid duplicates), 
-- and isolates rows where the scores do not match.
CREATE VIEW Incorrect_records AS (
    SELECT 
        a.location_id,
        v.record_id,
        e.employee_name,
        a.true_water_source_score AS auditor_score,
        q.subjective_quality_score AS employee_score,
        a.statements
    FROM md_water_services.auditor_report a
    JOIN md_water_services.visits v ON a.location_id = v.location_id
    JOIN md_water_services.water_quality q ON v.record_id = q.record_id
    JOIN md_water_services.employee e ON e.assigned_employee_id = v.assigned_employee_id
    WHERE v.visit_count = 1
      AND a.true_water_source_score <> q.subjective_quality_score
);

-- Verification: Should return 102 rows
SELECT COUNT(*) FROM Incorrect_records;