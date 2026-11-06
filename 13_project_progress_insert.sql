-- ============================================================
-- 13_project_progress_insert.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- Part 4: Creating the Project_progress table and populating
-- it with actionable repair tasks for the engineering team.
-- ============================================================

-- 1. Create the table with strict data integrity checks
CREATE TABLE Project_progress (
    Project_id SERIAL PRIMARY KEY,
    source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
    Address VARCHAR(50),
    Town VARCHAR(30),
    Province VARCHAR(30),
    Source_type VARCHAR(50),
    Improvement VARCHAR(50),
    Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
    Date_of_completion DATE,
    Comments TEXT
);

-- 2. Populate the table with actionable jobs for the engineers
INSERT INTO Project_progress (source_id, Address, Town, Province, Source_type, Improvement)
SELECT 
    s.source_id,
    l.address,
    l.town_name,
    l.province_name,
    s.type_of_water_source,
    CASE
        WHEN p.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
        WHEN p.results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN s.type_of_water_source = 'river' THEN 'Drill Well'
        WHEN s.type_of_water_source = 'shared_tap' AND v.time_in_queue >= 30
        THEN CONCAT('Install ', FLOOR(v.time_in_queue / 30), ' taps nearby')
        WHEN s.type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
        ELSE NULL
    END AS Improvement
FROM md_water_services.water_source s
LEFT JOIN md_water_services.well_pollution p ON s.source_id = p.source_id
INNER JOIN md_water_services.visits v ON s.source_id = v.source_id
INNER JOIN md_water_services.location l ON l.location_id = v.location_id
WHERE v.visit_count = 1
  AND (v.time_in_queue >= 30 OR p.results <> 'Clean' OR s.type_of_water_source IN ('river', 'tap_in_home_broken'));