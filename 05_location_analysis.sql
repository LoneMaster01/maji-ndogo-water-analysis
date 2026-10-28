-- ============================================================
-- 05_location_analysis.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- Where are the water sources? This file analyses the location
-- table to understand geographic coverage: how many records
-- exist per town, per province, and per urban/rural split.
--
-- Ground truth in this dataset:
--   - 39,650 total records in the location table
--   - 25 towns across 5 provinces
--   - 23,740 rural (59.9%) vs 15,910 urban (40.1%)
--   - "Rural" itself is a town_name value, not just a type
-- ============================================================


-- ============================================================
-- SECTION 1 — RECORDS PER TOWN
-- ============================================================
--
-- Each row in the location table is one water source location.
-- Grouping by town shows how many sources were surveyed in
-- each one.
-- ------------------------------------------------------------

SELECT
    town_name,
    COUNT(*) AS records_per_town
FROM location
GROUP BY town_name
ORDER BY records_per_town DESC;

-- Top 5 results:
--   town_name | records_per_town
--   --------- | ----------------
--   Rural     |     23,740
--   Harare    |      1,650
--   Amina     |      1,090
--   Lusaka    |      1,070
--   Mrembo    |        990
--
-- Across 25 towns total = 39,650 records.
-- The top 5 account for 28,540 records (72%); the remaining
-- 20 towns contribute the other ~11,110 (~28%).
--
-- INSIGHT: "Rural" is the dominant category, with 23,740
-- records — 60% of the entire dataset on its own. This is a
-- quirk of how the survey was structured: rather than naming
-- each rural community, sources in rural areas were grouped
-- under the generic town_name 'Rural'. The 24 named towns
-- together account for the remaining 15,910 records.


-- ============================================================
-- SECTION 2 — RECORDS PER PROVINCE
-- ============================================================
--
-- Province is a higher geographic layer than town. Each province
-- should have a comparable number of sources if the survey was
-- well-distributed.
-- ------------------------------------------------------------

SELECT
    province_name,
    COUNT(*) AS records_per_province
FROM location
GROUP BY province_name
ORDER BY records_per_province DESC;

-- Result:
--   province_name | records_per_province
--   ------------- | --------------------
--   Kilimani      |      9,510
--   Akatsi        |      8,940
--   Sokoto        |      8,220
--   Amanzi        |      6,950
--   Hawassa       |      6,030
--
-- Total: 39,650 records (matches Sections 1 and 3)
--
-- INSIGHT: Every province has between 6,030 and 9,510 records.
-- The spread is under 40% (max/min ratio ≈ 1.58), which suggests
-- the field team covered every province reasonably evenly. No
-- province was skipped or over-sampled. This is evidence the
-- dataset is reliable for national-level comparisons — a pattern
-- worth confirming before drawing country-wide conclusions.


-- ============================================================
-- SECTION 3 — URBAN vs RURAL SPLIT
-- ============================================================
--
-- The location_type column classifies each source as Urban or
-- Rural. This is the cleanest view of where the water crisis
-- actually is.
-- ------------------------------------------------------------

SELECT
    location_type,
    COUNT(*) AS records
FROM location
GROUP BY location_type
ORDER BY records DESC;

-- Result:
--   location_type | records
--   ------------- | -------
--   Rural         | 23,740
--   Urban         | 15,910
--
-- INSIGHT: 60% of all water sources are in rural areas
-- (23,740 / 39,650 = 59.9%). This has direct implications for
-- repair logistics: teams will spend the majority of their time
-- in areas where roads, supplies, and labour are harder to
-- access. Resource planning must reflect this, not assume an
-- even urban/rural split.


-- ============================================================
-- SECTION 4 — VERIFICATION
-- ============================================================
--
-- These queries confirm the totals across all three groupings
-- agree. A data quality check — if any of these disagree, the
-- location table has internal consistency issues.
-- ------------------------------------------------------------

-- 4a. Total records, total towns, total provinces
SELECT
    COUNT(*)                      AS total_records,
    COUNT(DISTINCT town_name)     AS total_towns,
    COUNT(DISTINCT province_name) AS total_provinces
FROM location;
-- Result: 39,650 records, 25 towns, 5 provinces

-- 4b. Rural percentage
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN location_type = 'Rural' THEN 1 ELSE 0 END)
              / COUNT(*),
        1
    ) AS pct_rural
FROM location;
-- Result: 59.9

-- 4c. Records per province as a percentage of total
SELECT
    province_name,
    COUNT(*) AS records,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM location), 1)
        AS pct_of_total
FROM location
GROUP BY province_name
ORDER BY records DESC;
-- Result:
--   Kilimani | 9,510 | 24.0
--   Akatsi   | 8,940 | 22.5
--   Sokoto   | 8,220 | 20.7
--   Amanzi   | 6,950 | 17.5
--   Hawassa  | 6,030 | 15.2
--
-- Range 15.2% to 24.0% — no province dominates.

-- 4d. Cross-check: do the two groupings reconcile?
SELECT 'by_province' AS view_name, SUM(c) AS grand_total
FROM (SELECT province_name, COUNT(*) AS c
      FROM location GROUP BY province_name) AS p
UNION ALL
SELECT 'by_location_type', SUM(c)
FROM (SELECT location_type, COUNT(*) AS c
      FROM location GROUP BY location_type) AS l;
-- Result: both rows show 39,650 — the groupings reconcile.


-- ============================================================
-- SECTION 5 — KEY TAKEAWAYS
-- ============================================================
--
-- 1. The survey is nationally representative. All 5 provinces
--    have between 6,030 and 9,510 records — no gap larger than
--    a factor of 1.6. And all 25 towns have documented sources,
--    supporting the claim that Maji Ndogo's water situation has
--    been properly canvassed.
--
-- 2. 60% of all sources are rural (23,740 of 39,650). Repair
--    logistics must account for this: rural repairs take more
--    time, fuel, and planning than urban ones. The team will
--    spend most of its time off the main roads.
--
-- 3. "Rural" is a single town_name with 23,740 records — the
--    survey grouped all rural communities under one label
--    rather than naming each one. Any per-town analysis must
--    treat this specially; a "town count" of 25 is misleading
--    if you don't know that one of them is an aggregate of
--    all rural sources, covering 60% of the entire dataset.
-- ============================================================