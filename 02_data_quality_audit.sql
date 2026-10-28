-- ============================================================
-- 02_data_quality_audit.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- CASE STUDY: A data quality bug in the well_pollution table,
-- AND a bug in the audit query that first hid it.
--
-- THE FINDING:
--   Records were marked "Clean" while biological contamination
--   was above the safe threshold (> 0.01 CFU/mL). Two rounds of
--   problems were found: 38 incorrect results, then (after the
--   audit query itself was corrected) 26 incorrect descriptions.
--
-- THE ROOT CAUSE:
--   Descriptions began with "Clean" as a prefix in the
--   scientist's notes (e.g. 'Clean Bacteria: E. coli'). Data-
--   entry staff used the prefix instead of the measurement to
--   set the results column.
--
-- THE AUDIT-QUERY BUG:
--   My first audit used the pattern 'Clean\_%'. The backslash
--   escapes the underscore, making it a LITERAL underscore
--   instead of the LIKE wildcard. Nothing matched. The query
--   only worked because of a second condition that caught the
--   results errors. After fixing results, the broken description
--   check silently returned 0 — hiding 26 more issues.
--
-- STATUS: Fully fixed and verified. This file documents the
-- case study; the UPDATE statements are in 03_data_cleaning.sql.
-- ============================================================


-- ------------------------------------------------------------
-- 1. THE AUDIT QUERY (corrected version)
--
-- Two failure signatures:
--   a) description begins with 'Clean '
--   b) results = 'Clean' but biological > 0.01
--
-- History:
--   Before any fix:      38 rows (matched via (b) only —
--                        the original 'Clean\_%' never fired)
--   After results fix:   26 rows (revealed once (a) was corrected)
--   After full fix:       0 rows
-- ------------------------------------------------------------

SELECT
    source_id,
    date,
    description,
    pollutant_ppm,
    biological,
    results
FROM well_pollution
WHERE description LIKE 'Clean %'
   OR (results = 'Clean' AND biological > 0.01);


-- ------------------------------------------------------------
-- 2. WHAT THE BUG LOOKED LIKE (representative row)
--
--   source_id:     AkRu08749224
--   description:   Clean Bacteria: E. coli
--   biological:    9.28085             ← contaminated
--   results:       Contaminated: Biological
--
-- The results column had already been corrected, but the
-- description still carried the misleading "Clean" prefix.
-- Anyone reading the description would have misread the record.
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- 3. THE FIX
--
-- Applied via a copy table (see 03_data_cleaning.sql for the
-- full safe workflow). Two rounds of corrections:
--
-- Round 1 — fix results where the measurement said otherwise:
--   UPDATE well_pollution
--   SET results = 'Contaminated: Biological'
--   WHERE biological > 0.01 AND results = 'Clean';
--   → 38 rows affected
--
-- Round 2 — fix descriptions with the stale "Clean" prefix:
--   UPDATE well_pollution
--   SET description = 'Bacteria: E. coli'
--   WHERE description = 'Clean Bacteria: E. coli';
--   → 26 rows affected
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- 4. VERIFICATION
--
-- Re-run the audit after the fix. Zero rows = every record
-- agrees with its own measurement.
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS remaining_bugs
FROM well_pollution
WHERE description LIKE 'Clean %'
   OR (results = 'Clean' AND biological > 0.01);

-- Expected: 0


-- ------------------------------------------------------------
-- 5. LESSONS LEARNED
--
-- 1. A classification column must always be cross-checked
--    against the underlying measurement. Prefixes in free-text
--    descriptions are not data — they are notes.
-- 2. An audit query that returns 0 can be lying. Verify the
--    query itself before trusting its silence. The escaped
--    underscore 'Clean\_%' looked like it was checking
--    descriptions but matched nothing.
-- 3. Use LIKE 'Clean %' (literal space) rather than
--    LIKE 'Clean_%' — the underscore is a wildcard that
--    silently matches any single character, which is fine
--    here but easy to misread as "underscore".
-- 4. Always fix on a copy, verify, then apply to the live
--    table.
-- ------------------------------------------------------------