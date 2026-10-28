# Maji Ndogo Water Access — SQL Analysis

End-to-end SQL analysis of a national water survey (~27 million citizens,
2.5 years of field data), identifying which water sources serve the most
people, where queues are worst, and what repairs would have the highest impact.

## Background

Maji Ndogo is a fictional country whose water crisis was documented by
field surveyors. This project analyses that survey data to answer:

**Where should limited repair resources go first?**

## Dataset

Eight tables: `employee`, `location`, `visits`, `water_source`,
`water_quality`, `well_pollution`, `global_water_access`, `data_dictionary`.

Core columns: `source_id`, `type_of_water_source`, `number_of_people_served`,
`time_in_queue`, `time_of_record`, `biological`, `province_name`, `town_name`.

## Approach

### Part 1 — Data exploration and quality audit

| Step | What I did |
|---|---|
| **Exploration** | Listed all tables with `SHOW TABLES`; sampled each with `SELECT * ... LIMIT 5`; identified 5 water source types |
| **Quality audit** | Cross-checked `well_pollution` records where `results = 'Clean'` but `biological > 0.01` — found **38 misclassified rows** |
| **Root cause** | Some records had `description` beginning with the word "Clean" (e.g. `'Clean Bacteria: E. coli'`), and data-entry staff used that prefix instead of the actual `biological` value to set `results` |
| **Deeper audit** | After fixing results, corrected an escaping bug in my own audit query (`Clean\_%` → `Clean %`) which had been silently matching nothing — revealed **26 more misclassified descriptions** |
| **Safe cleaning** | Applied all `UPDATE` statements to a copy table first, verified with a `SELECT` audit query, then applied to the live table |

### Part 2 — Analysis

| Step | What I did |
|---|---|
| **Cleaning** | Generated employee emails with `CONCAT`/`LOWER`/`REPLACE`; fixed phone numbers with `TRIM` |
| **Location analysis** | Counted sources per town, province, and location type; calculated rural vs urban split |
| **Source analysis** | Counted sources by type, averaged people per source, calculated total population served, ranked by impact using `RANK()` |
| **Queue analysis** | Survey duration with `DATEDIFF`; average queue time with `NULLIF` to exclude zero-queue sources; queue times by day and hour |
| **Pivot table in SQL** | Built a day-of-week × hour-of-day matrix using `CASE` inside `AVG` (conditional aggregation) |

## Data quality verification

## Data quality verification

After all corrections, the audit query returns zero rows — every record
in `well_pollution` now agrees with its own measurement:

![Verification: 0 remaining bugs](outputs/01_verification_zero_rows.png)

Phone number cleanup also verified — every number is now the expected
12 characters, with no trailing spaces:

![Phone number length verification](outputs/02_cleaning_verification.png)

## Field team highlights

Top 3 surveyors by number of visits — three people who completed over
18% of the entire survey between them:

![Top surveyors by visit count](outputs/03_top_surveyors.png)

Full contact details for the top 3 — cleaned names, emails, and phone
numbers ready for President Naledi's commendation messages:

![Surveyor contact details](outputs/04_surveyor_details.png)

Full audit narrative: see [`02_data_quality_audit.sql`](02_data_quality_audit.sql).

## Key findings

- **60% of water sources are rural** — repair teams face harder logistics
- **43% of citizens use shared taps** — about 2,000 people per tap on average
- **31% have water infrastructure at home**, but **45% of those are broken**
- **18% use wells**, and only **28% of wells are clean**
- **Average queue time is 123 minutes** — four times the UN's 30-minute standard
- **Saturday queues are ~2× weekday queues**; morning and evening are the busiest hours
- **Wednesdays and Sundays have the shortest queues**
- **Some records show queue times over 500 minutes** — 8+ hours for water

## Important data caveat

`tap_in_home` and `tap_in_home_broken` records are **not one row per household**.
Surveyors combined ~160 nearby households into one record, so
`number_of_people_served = 956` means roughly 160 homes × 6 people,
not one tap serving 956 people individually. Any analysis of
"people per tap" must account for this — otherwise the average is
inflated by ~100×.
On average, one `tap_in_home` record represents ~107 households
(644 people ÷ 6 per household), not a single tap.

This is documented in `02_data_quality_audit.sql` because it materially
affects interpretation.

## Recommendations

1. **Fix shared taps first** — they serve the most people per intervention
2. **Repair broken home infrastructure** — one repair can relieve queue pressure for an entire neighbourhood
3. **Install UV/RO filters on wells** — cheapest way to make existing water safe
4. **Dispatch tankers to Saturday peak hours** as a short-term fix while taps are installed

## Tools used

MySQL 8.0, MySQL Workbench — window functions, CTEs, `CASE`, `NULLIF`,
`RANK`, date-time functions, conditional aggregation, `LIKE`-based cleaning.

## Author

Sheriff Balogun — [www.linkedin.com/in/sheriff-o-balogun](https://www.linkedin.com/in/sheriff-o-balogun) — Civil engineer transitioning to data analytics.