-- ============================================================
-- 06_water_source_analysis.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- Deep dive into the water_source table: how many of each type
-- exist, how many people each type serves, and which types
-- should be prioritised for repair.
--
-- Ground truth in this dataset:
--   - 39,650 sources serving 27,628,140 people
--   - shared_tap dominates: 43.2% of the population
--   - wells are the most numerous (17,383) but serve the fewest
--     people per source (279)
--
-- CRITICAL CAVEAT: tap_in_home and tap_in_home_broken records
-- are NOT one row per household. They aggregate ~100+ nearby
-- households into a single record. See Section 3.
-- ============================================================


-- ============================================================
-- SECTION 1 — HOW MANY OF EACH SOURCE TYPE?
-- ============================================================

SELECT
    type_of_water_source,
    COUNT(*) AS num_sources
FROM water_source
GROUP BY type_of_water_source
ORDER BY num_sources DESC;

-- Result:
--   type_of_water_source  | num_sources
--   --------------------- | -----------
--   well                  |     17,383
--   tap_in_home           |      7,265
--   tap_in_home_broken    |      5,856
--   shared_tap            |      5,767
--   river                 |      3,379
--   --------------------- | -----------
--   Total                 |     39,650
--
-- INSIGHT: Wells are by far the most numerous source type
-- (43.8% of all sources) — but Section 3 will show they serve
-- the fewest people per source. Quantity of sources ≠ reach.


-- ============================================================
-- SECTION 2 — HOW MANY PEOPLE DOES EACH TYPE SERVE?
-- ============================================================

SELECT
    type_of_water_source,
    SUM(number_of_people_served) AS population_served,
    ROUND(
        100.0 * SUM(number_of_people_served)
              / (SELECT SUM(number_of_people_served) FROM water_source),
        1
    ) AS pct_of_total
FROM water_source
GROUP BY type_of_water_source
ORDER BY population_served DESC;

-- Result:
--   type_of_water_source  | population_served | pct
--   --------------------- | ----------------- | ----
--   shared_tap            |      11,945,272   | 43.2
--   well                  |       4,841,724   | 17.5
--   tap_in_home           |       4,678,880   | 16.9
--   tap_in_home_broken    |       3,799,720   | 13.8
--   river                 |       2,362,544   |  8.6
--   --------------------- | ----------------- | ----
--   Total                 |      27,628,140   | 100.0
--
-- INSIGHT: Shared taps serve 43% of all citizens — one source
-- type reaches almost half the country. Any repair strategy
-- that doesn't address shared taps is missing the biggest
-- segment of the population.


-- ============================================================
-- SECTION 3 — AVERAGE PEOPLE PER SOURCE (with caveat)
-- ============================================================

SELECT
    type_of_water_source,
    COUNT(*)                              AS num_sources,
    SUM(number_of_people_served)          AS total_people,
    ROUND(AVG(number_of_people_served), 0) AS avg_people_per_source
FROM water_source
GROUP BY type_of_water_source
ORDER BY avg_people_per_source DESC;

-- Result:
--   type_of_water_source  | num_sources | total_people | avg
--   --------------------- | ----------- | ------------ | ----
--   shared_tap            |       5,767 |   11,945,272 | 2,071
--   river                 |       3,379 |    2,362,544 |   699
--   tap_in_home_broken    |       5,856 |    3,799,720 |   649
--   tap_in_home           |       7,265 |    4,678,880 |   644
--   well                  |      17,383 |    4,841,724 |   279
--
-- ⚠️ INTERPRETATION CAVEAT — read before quoting these numbers:
--
--   For shared_tap, river, and well, "avg people per source"
--   is LITERAL. 2,071 real people share one public shared tap.
--   699 real people fetch from one river point.
--
--   For tap_in_home and tap_in_home_broken, it is NOT literal.
--   Those records bundle ~100+ households into a single row.
--   The surveyor notes explain that the average household has
--   ~6 people, so:
--
--     tap_in_home        → 644 ÷ 6 ≈ 107 households per record
--     tap_in_home_broken → 649 ÷ 6 ≈ 108 households per record
--
--   So "644 people share one tap_in_home" is misleading. In
--   reality, ~107 families each have their own tap, but the
--   counts were combined into one record to avoid ~1 million
--   rows in the database.
--
--   This caveat drives the ranking in Section 4.


-- ============================================================
-- SECTION 4 — RANKING BY POPULATION SERVED
-- ============================================================

-- 4a. Full ranking — every source type
SELECT
    type_of_water_source,
    SUM(number_of_people_served) AS population_served,
    RANK() OVER (
        ORDER BY SUM(number_of_people_served) DESC
    ) AS rank_by_population
FROM water_source
GROUP BY type_of_water_source
ORDER BY rank_by_population;

-- Result:
--   type_of_water_source  | population_served | rank
--   --------------------- | ----------------- | ----
--   shared_tap            |      11,945,272   |  1
--   well                  |       4,841,724   |  2
--   tap_in_home           |       4,678,880   |  3
--   tap_in_home_broken    |       3,799,720   |  4
--   river                 |       2,362,544   |  5


-- 4b. Improvable ranking — exclude tap_in_home
--
-- Why exclude tap_in_home? Those households already have
-- private taps. There is nothing to improve by building a
-- new tap where one already exists. tap_in_home_broken
-- stays in the list because repairing broken infrastructure
-- IS actionable.
SELECT
    type_of_water_source,
    SUM(number_of_people_served) AS population_served,
    RANK() OVER (
        ORDER BY SUM(number_of_people_served) DESC
    ) AS priority_rank
FROM water_source
WHERE type_of_water_source <> 'tap_in_home'
GROUP BY type_of_water_source
ORDER BY priority_rank;

-- Result:
--   type_of_water_source  | population_served | priority_rank
--   --------------------- | ----------------- | -------------
--   shared_tap            |      11,945,272   |       1
--   well                  |       4,841,724   |       2
--   tap_in_home_broken    |       3,799,720   |       3
--   river                 |       2,362,544   |       4
--
-- INSIGHT: shared_tap is #1 by a wide margin — 2.5× the
-- population served by wells. If the repair budget only
-- covered one intervention type, shared_tap is the answer.


-- ============================================================
-- SECTION 5 — VERIFICATION
-- ============================================================

-- 5a. Grand totals
SELECT
    COUNT(*) AS total_sources,
    SUM(number_of_people_served) AS total_people
FROM water_source;
-- Result: 39,650 sources, 27,628,140 people

-- 5b. Percentages sum to 100
SELECT
    ROUND(
        SUM(pct),
        1
    ) AS sum_of_pct
FROM (
    SELECT
        ROUND(100.0 * SUM(number_of_people_served)
              / (SELECT SUM(number_of_people_served) FROM water_source),
              2) AS pct
    FROM water_source
    GROUP BY type_of_water_source
) AS p;
-- Result: 100.0

-- 5c. No gaps in the improvable ranking
SELECT
    MAX(priority_rank) AS highest_rank,
    COUNT(*)           AS total_improvable_types
FROM (
    SELECT
        RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) AS priority_rank
    FROM water_source
    WHERE type_of_water_source <> 'tap_in_home'
    GROUP BY type_of_water_source
) AS r;
-- Result: 4 and 4 — ranks 1-4 with no gaps


-- ============================================================
-- SECTION 6 — KEY TAKEAWAYS
-- ============================================================
--
-- 1. shared_tap is the single most impactful repair target.
--    43.2% of the population (11.9 million people) depends
--    on shared taps, and 2,071 people queue at one on average.
--    Any repair plan that doesn't prioritise shared taps
--    misses the largest segment of the population.
--
-- 2. Wells are numerous but small. 17,383 wells (43.8% of
--    sources) serve only 17.5% of the population — 279 people
--    each. Wells are a coverage story, not a load story.
--    Fixing them matters for reach; fixing shared taps
--    matters for scale.
--
-- 3. tap_in_home numbers need interpretation. "644 people
--    share a tap_in_home" is misleading — those records bundle
--    ~107 households, each with its own tap, averaged at 6
--    people per home. The infrastructure may be broken, but
--    the "tap" is already installed. Repair ≠ install.
--
-- 4. 31% of the population has home infrastructure (16.9%
--    working + 13.8% broken). Within that group, ~45% are
--    broken (3.8M of 8.5M). Repairing existing home
--    infrastructure could relieve queue pressure at shared
--    taps without building anything new.
--
-- 5. The improvable ranking (Section 4b) gives the action
--    order: shared_tap → well → tap_in_home_broken → river.
--    Each step down halves the population affected.
-- ============================================================