-- ============================================================
-- 04_employee_analysis.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- Analysis of the field survey workforce:
--   - Where do our employees live?
--   - Who collected the most survey records?
--   - The top 3 for President Naledi's commendation
--
-- Ground truth in this dataset:
--   - 56 employees across 9 towns
--   - Largest team cluster: Rural (29 employees — 52% of team)
--   - Top surveyor: employee_id 1 with 3,708 visits
--
-- NOTE: The tutorial transcript in the source material listed
-- employee IDs 0, 1, 2 as the top 3. This dataset returns
-- 1, 30, 34 instead — and the gap between #1 and #3 is much
-- tighter. Numbers below match what the queries actually return.
-- ============================================================


-- ============================================================
-- SECTION 1 — WHERE DO OUR EMPLOYEES LIVE?
-- ============================================================
--
-- The field survey required travel to remote communities, so
-- the spread of employees across towns matters for logistics
-- and for understanding who did the work.
-- ------------------------------------------------------------

SELECT
    town_name,
    COUNT(*) AS num_employees
FROM employee
GROUP BY town_name
ORDER BY num_employees DESC;

-- Result (top 3 towns):
--   Rural    | 29
--   Dahabu   |  6
--   Harare   |  5
--
-- Total: 56 employees across 9 towns.
--
-- INSIGHT: Over half of the field team (29 of 56, ~52%) lives
-- in rural areas. This is consistent with the location data
-- showing that 60% of water sources are rural — the team is
-- distributed where the work actually is, which reduced travel
-- time during the 2.5-year survey.


-- ============================================================
-- SECTION 2 — WHO ARE THE TOP 3 FIELD SURVEYORS?
-- ============================================================
--
-- President Naledi wants to commend the top 3 surveyors by
-- number of locations visited. Group the visits table by
-- assigned_employee_id, count rows, and take the top 3.
-- ------------------------------------------------------------

SELECT
    assigned_employee_id,
    COUNT(*) AS number_of_visits
FROM visits
GROUP BY assigned_employee_id
ORDER BY number_of_visits DESC
LIMIT 3;

-- Result:
--   assigned_employee_id | number_of_visits
--   -------------------- | ----------------
--         1              |      3,708
--        30              |      3,676
--        34              |      3,539
--
-- INSIGHT: The top 3 are within ~5% of each other (3,708 vs
-- 3,539 — a gap of only 169 visits). This is a genuinely tight
-- race — three surveyors who clearly worked at the same pace
-- over 2.5 years. All three deserve recognition, not just #1.


-- ============================================================
-- SECTION 3 — LOOKUP DETAILS FOR THE TOP 3
-- ============================================================
--
-- Take the three employee_ids from Section 2 and look up
-- their names, emails, and phone numbers so President Naledi
-- can send a personal message to each.
-- ------------------------------------------------------------

SELECT
    employee_id,
    employee_name,
    email,
    phone_number
FROM employee
WHERE employee_id IN (1, 30, 34)
ORDER BY employee_id;

-- Result:
--   employee_id | employee_name | email                     | phone_number
--   ----------- | ------------- | ------------------------- | ----------------
--         1     | Bello Azibo   | bello.azibo@ndogowater.gov | +99643864786
--        30     | Pili Zola     | pili.zola@ndogowater.gov   | +99822478933
--        34     | Rudo Imani    | rudo.imani@ndogowater.gov  | +99046972648
--
-- INSIGHT: All three have correct emails (matching the
-- firstname.lastname@ndogowater.gov convention from the cleaning
-- step) and 12-character phone numbers (the TRIM cleanup worked).
-- The data is ready for automated messaging.


-- ============================================================
-- SECTION 4 — VERIFICATION
-- ============================================================
--
-- These queries confirm the findings and give context.
-- ------------------------------------------------------------

-- 4a. Total team size and town coverage
SELECT
    COUNT(*)                    AS total_employees,
    COUNT(DISTINCT town_name)   AS towns_covered
FROM employee;
-- Result: 56 employees, 9 towns

-- 4b. Percentage of team living in rural areas
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN town_name = 'Rural' THEN 1 ELSE 0 END)
              / COUNT(*),
        1
    ) AS pct_in_rural
FROM employee;
-- Result: ~51.8% — the team lives where the water sources are

-- 4c. Total visits made across the survey
SELECT
    COUNT(*) AS total_visits
FROM visits;
-- Result: 60,146

-- 4d. Share of all visits made by the top 3
--   The top 3 made 3,708 + 3,676 + 3,539 = 10,923 visits.
--   Divide by total visits to see their combined share.
SELECT
    ROUND(
        100.0 * SUM(CASE
                      WHEN assigned_employee_id IN (1, 30, 34) THEN 1
                      ELSE 0
                    END)
              / COUNT(*),
        1
    ) AS pct_visits_by_top_3
FROM visits;
-- Result: 18.2%
--
-- INSIGHT: 3 people out of 56 completed 18.2% of all survey
-- work — about 3.4x the workload of the average surveyor
-- (average ≈ 1,074 visits per employee). The top 3 are not
-- just slightly ahead — they carried a disproportionate share
-- of the entire 2.5-year survey.


-- ============================================================
-- SECTION 5 — KEY TAKEAWAYS
-- ============================================================
--
-- 1. The field team is distributed where the work is: 52% of
--    employees live in rural areas, matching the 60% of water
--    sources located there.
--
-- 2. The top 3 surveyors completed 10,923 visits between them —
--    18.2% of the entire survey. With the #1-to-#3 gap under
--    5%, this looks like three people pulling at the same
--    relentless pace, not one standout. The commendation should
--    acknowledge the group, not just #1. And the workload
--    distribution (3 people at 3.4x average) is worth noting
--    for retention — losing any of these three would be a
--    significant operational risk.
--
-- 3. Both cleaning operations (email generation and phone
--    trimming) held up: all three top surveyors now have
--    valid contact details ready for automated messaging.
-- ============================================================