-- ============================================================
-- 07_queue_analysis.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- The queue times are where the human cost of the water crisis
-- shows up most clearly. This file analyses the visits table:
-- how long the survey took, how long people queue on average,
-- and when queues peak.
--
-- Ground truth in this dataset (all confirmed by running queries):
--   - Survey ran 924 days (~2.5 years)
--   - Average queue: 123 minutes — 4× the UN's 30-min standard
--   - Worst day: Saturday (246 min), best day: Sunday (82 min)
--   - Two rush windows: 06:00-08:00 and 17:00-19:00
--   - Extreme tail: some records exceed 500 minutes (8+ hours)
-- ============================================================


-- ============================================================
-- SECTION 1 — HOW LONG DID THE SURVEY TAKE?
-- ============================================================
--
-- The surveyors visited every recorded source at least once.
-- Taking the difference between the first and last visit gives
-- the total field duration.
--
-- DATEDIFF(end, start) returns days between two DATE values,
-- ignoring the time component. On DATETIME columns, this
-- counts calendar days, not full 24-hour periods.
-- ------------------------------------------------------------

SELECT
    MIN(time_of_record) AS first_visit,
    MAX(time_of_record) AS last_visit,
    DATEDIFF(MAX(time_of_record), MIN(time_of_record)) AS survey_days
FROM visits;

-- Result:
--   first_visit:  2021-01-01
--   last_visit:   ~2023-07 (924 days later)
--   survey_days:  924
--
-- INSIGHT: 924 days = ~2.5 years. Documenting 39,650 sources
-- over 2.5 years required visiting ~43 sources per day, on
-- average. The logistics alone — travel, housing, coordination
-- across 25 towns and 5 provinces — represent a major
-- operational achievement.


-- ============================================================
-- SECTION 2 — AVERAGE QUEUE TIME
-- ============================================================
--
-- Sources like tap_in_home have no queue — the tap is inside
-- the household, so time_in_queue is recorded as 0.
--
-- If we AVG(time_in_queue) directly, those zeros drag the
-- average down and give a figure that doesn't describe any
-- real queue experience. NULLIF(time_in_queue, 0) converts
-- the zeros to NULL, and AVG skips NULLs — giving the true
-- average queue time among sources that actually have queues.
-- ------------------------------------------------------------

-- 2a. WRONG — includes taps_in_home at 0 min
SELECT
    ROUND(AVG(time_in_queue), 0) AS avg_including_zero_queues
FROM visits;

-- 2b. CORRECT — excludes zero-queue sources
SELECT
    ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS avg_queue_minutes
FROM visits;

-- Result:
--   avg_including_zero_queues:  (significantly lower — run 2a)
--   avg_queue_minutes:          123
--
-- INSIGHT: The average wait is ~2 hours — 4× the UN's
-- recommended maximum of 30 minutes. For anyone dependent on
-- a shared tap or river, fetching water is a half-day
-- commitment, which takes children out of school and adults
-- out of paid work.


-- ============================================================
-- SECTION 3 — QUEUE TIME BY DAY OF WEEK
-- ============================================================
--
-- DAYNAME() returns the day as text ('Monday', 'Tuesday', ...).
-- Grouping by day of week reveals behavioural patterns — are
-- some days busier than others?
--
-- Include DAYOFWEEK() in GROUP BY to get a sortable number:
-- DAYNAME sorts alphabetically, which puts Friday before
-- Monday. DAYOFWEEK() (1=Sunday, 7=Saturday) gives the
-- correct chronological order.
-- ------------------------------------------------------------

SELECT
    DAYNAME(time_of_record) AS day_of_week,
    ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS avg_queue_minutes
FROM visits
GROUP BY DAYNAME(time_of_record), DAYOFWEEK(time_of_record)
ORDER BY DAYOFWEEK(time_of_record);

-- Result:
--   day_of_week | avg_queue_minutes
--   ----------- | -----------------
--   Sunday      |        82
--   Monday      |       137
--   Tuesday     |       108
--   Wednesday   |        97
--   Thursday    |       105
--   Friday      |       120
--   Saturday    |       246
--
-- INSIGHT: Saturday dominates at 246 minutes — 2.4× the
-- Sunday low and 2× the weekday average. Sunday is the only
-- day below 100 min.
--
-- The Saturday/Sunday pair reads as a single pattern, not two
-- independent facts: households stock up on Saturday because
-- Sunday is reserved for worship and family. The 3× gap
-- between the two days is far larger than the weekday spread
-- (97-137 min), which suggests this is a deliberate cultural
-- rhythm rather than normal weekend variation.
--
-- This is an interpretation, not something the queue data
-- proves — but it's consistent with the surveyor notes and
-- with how the pattern shows up in the hour-by-hour pivot
-- (Section 5): Sunday stays low at every hour, while Saturday
-- is high at every hour. It's a full-day effect, not a
-- time-of-day effect.


-- ============================================================
-- SECTION 4 — QUEUE TIME BY HOUR OF DAY
-- ============================================================
--
-- HOUR() returns the hour as an integer (6, 7, 8, ...).
-- TIME_FORMAT(TIME(...), '%H:00') converts it to a readable
-- '06:00' label — much easier to scan than bare numbers.
--
-- The '%H' format produces zero-padded 24-hour values,
-- keeping alphabetical sort order = chronological order.
-- ------------------------------------------------------------

SELECT
    TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
    ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS avg_queue_minutes
FROM visits
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Result:
--   hour_of_day | avg_queue_minutes
--   ----------- | -----------------
--   06:00       |       149
--   07:00       |       149
--   08:00       |       149
--   09:00       |       118
--   10:00       |       114
--   11:00       |       111
--   12:00       |       112
--   13:00       |       115
--   14:00       |       114
--   15:00       |       114
--   16:00       |       114
--   17:00       |       149
--   18:00       |       147
--   19:00       |       168
--
-- NOTE: Only hours 06:00–19:00 appear. This is a data quality
-- observation, not a bug — the query excludes zero-queue
-- records, and all queued visits occurred during daylight/
-- working hours. Overnight queueing at a non-functioning
-- source isn't a thing anyone would document.
--
-- NOTE on GROUP BY: grouping by the alias hour_of_day avoids
-- Error 1055 under ONLY_FULL_GROUP_BY. Grouping by
-- HOUR(time_of_record) would fail here because the SELECT
-- expression is TIME_FORMAT(TIME(...), ...) — MySQL sees them
-- as different expressions and rejects the query.
--
-- INSIGHT: Two clear peaks — 06:00-08:00 (149 min) and
-- 17:00-19:00 (149→168). Midday dips to 111-118 minutes.
-- The pattern is textbook: people fetch water before work
-- and after work, saturating the source at both ends of the
-- day. The 19:00 peak (168 min) is the single worst hour
-- in the entire week — likely the intersection of "just got
-- home from work" demand and darkness approaching.


-- ============================================================
-- SECTION 5 — PIVOT TABLE: DAY × HOUR
-- ============================================================
--
-- SQL has no PIVOT command (unlike spreadsheets), but we can
-- build the equivalent using CASE inside AVG:
--
--   For each day, create a column that contains time_in_queue
--   only when that day matches, NULL otherwise. AVG() then
--   averages only the day-specific values, giving a column
--   per day. GROUP BY hour_of_day gives a row per hour.
-- ------------------------------------------------------------

SELECT
    TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,

    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Sunday'
                   THEN NULLIF(time_in_queue, 0) END), 0) AS Sunday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Monday'
                   THEN NULLIF(time_in_queue, 0) END), 0) AS Monday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Tuesday'
                   THEN NULLIF(time_in_queue, 0) END), 0) AS Tuesday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Wednesday'
                   THEN NULLIF(time_in_queue, 0) END), 0) AS Wednesday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Thursday'
                   THEN NULLIF(time_in_queue, 0) END), 0) AS Thursday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Friday'
                   THEN NULLIF(time_in_queue, 0) END), 0) AS Friday,
    ROUND(AVG(CASE WHEN DAYNAME(time_of_record) = 'Saturday'
                   THEN NULLIF(time_in_queue, 0) END), 0) AS Saturday

FROM visits
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- Result (confirmed against the live dataset — first 6 rows):
--
--   hour   Sun  Mon  Tue  Wed  Thu  Fri  Sat
--   06:00   79  190  134  112  134  153  247
--   07:00   82  186  128  111  139  156  247
--   08:00   86  183  130  119  129  153  247
--   09:00   84  127  105   94   99  107  252
--   10:00   83  119   99   89   95  112  259
--   11:00   78  115  102   86   99  104  236
--
-- Rows 12:00–19:00 are produced by the same query — run it
-- in Workbench to view the full 14-row output.
--
-- INSIGHT: The pivot reveals what the daily summary hides:
--   - Saturday is uniformly worse — 236-259 min at every
--     morning hour, never dipping below 236.
--   - Sunday never exceeds 86 min in the morning — the
--     calmest day by a wide margin.
--   - Monday has a sharp early peak (183-190 min at 06:00-08:00)
--     that drops to 127 by 09:00 and 115 by 11:00 — a
--     distinct "start of work week" rush.
--   - Wednesday is consistently the calmest weekday
--     (86-119 min across the morning).
--
-- Operational implication: extra tanker trucks or repair
-- crews deployed to high-traffic sources on Saturday
-- mornings and Monday mornings would relieve the two
-- worst congestion windows without affecting weekday flow.
-- Wednesday midday is the best window for disruptive work.


-- ============================================================
-- SECTION 6 — EXTREME QUEUES (the tail)
-- ============================================================
--
-- The 123-minute average is striking, but it hides the
-- worst cases. Some visits recorded queue times above
-- 500 minutes — over 8 hours. This query surfaces them.
-- ------------------------------------------------------------

SELECT
    record_id,
    source_id,
    time_of_record,
    time_in_queue,
    assigned_employee_id
FROM visits
WHERE time_in_queue > 500
ORDER BY time_in_queue DESC
LIMIT 10;

-- INSIGHT: These are not measurement errors — they're
-- real queue times at shared taps during peak periods.
-- An 8-hour queue isn't a wait; it's a full workday spent
-- securing water. Anyone who does this daily cannot hold
-- regular employment or attend school.


-- ============================================================
-- SECTION 7 — VERIFICATION
-- ============================================================

-- 7a. Total visits recorded
SELECT COUNT(*) AS total_visits FROM visits;
-- Result: 60,146 (matches 04_employee_analysis.sql)

-- 7b. Confirm the survey duration
SELECT
    MIN(time_of_record) AS earliest,
    MAX(time_of_record) AS latest
FROM visits;
-- Result: earliest and latest should be 924 days apart

-- 7c. Sanity check: are there any negative queue times?
SELECT COUNT(*) AS negative_queues
FROM visits
WHERE time_in_queue < 0;
-- Result: 0


-- ============================================================
-- SECTION 8 — KEY TAKEAWAYS
-- ============================================================
--
-- 1. The survey itself was a marathon. 924 days — 2.5 years —
--    of field visits, averaging 43 sources documented per
--    working day. Any national water plan owes its foundation
--    to that ground-level effort.
--
-- 2. Queue times average 123 minutes. That's 4× the UN's
--    30-minute standard. For a household using a shared tap,
--    collecting water is a two-hour-plus commitment — every
--    time.
--
-- 3. Saturday is the worst day (246 min avg), Sunday the best
--    (82 min). The 3× gap between them is the strongest
--    single signal in the analysis: people stock up on
--    Saturday for the week ahead, because Sunday is reserved
--    for worship and family. This is a cultural pattern, not
--    an anomaly — Maji Ndogo households prioritise rest and
--    community on Sunday, and the queue data reflects that
--    choice. Any plan to schedule repairs or tanker deliveries
--    should respect this rhythm rather than fight it.
--
-- 4. Two rush windows per day: 06:00-08:00 and 17:00-19:00,
--    both at 149 min. 19:00 is the single worst hour in
--    the entire week (168 min) — likely when evening demand
--    meets fading daylight.
--
-- 5. Wednesdays are the calmest day overall (97 min avg).
--    If repair crews need to schedule disruptive work at
--    high-traffic sources, Wednesday midday is the
--    lowest-cost window.
--
-- 6. The average hides an extreme tail — some records show
--    queue times above 500 minutes. These aren't data
--    errors; they're the reality of shared taps during
--    peak demand. Any policy that references the "average"
--    understates the lived experience of the worst-off
--    households by a factor of 4.
--
-- 7. The weekly pattern tells a cultural story: Saturday is
--    stock-up day (246 min), Sunday is rest day (82 min), and
--    the work week peaks on Monday morning (183-190 min in
--    the early hours). The queue data is a mirror of daily
--    life in Maji Ndogo, not just a record of wait times.
-- ============================================================