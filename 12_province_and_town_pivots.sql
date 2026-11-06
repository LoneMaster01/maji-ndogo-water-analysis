-- ============================================================
-- 12_province_and_town_pivots.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- Part 4: Pivot tables to analyze water source distribution 
-- by province and town.
-- ============================================================

-- 1. Province-Level Analysis
WITH province_totals AS (
    SELECT 
        province_name, 
        SUM(people_served) AS People_served_per_province
    FROM md_water_services.combined_analysis_table
    GROUP BY province_name          
)
SELECT 
    ct.province_name,
    ROUND((SUM(CASE WHEN source_type = 'river' THEN people_served ELSE 0 END) * 100.0 / pt.People_served_per_province), 0) AS river,
    ROUND((SUM(CASE WHEN source_type = 'shared_tap' THEN people_served ELSE 0 END) * 100.0 / pt.People_served_per_province), 0) AS shared_tap,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home' THEN people_served ELSE 0 END) * 100.0 / pt.People_served_per_province), 0) AS tap_in_home,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken' THEN people_served ELSE 0 END) * 100.0 / pt.People_served_per_province), 0) AS tap_in_home_broken,
    ROUND((SUM(CASE WHEN source_type = 'well' THEN people_served ELSE 0 END) * 100.0 / pt.People_served_per_province), 0) AS well
FROM md_water_services.combined_analysis_table ct
JOIN province_totals pt ON ct.province_name = pt.province_name
GROUP BY ct.province_name, pt.People_served_per_province
ORDER BY ct.province_name;


-- 2. Town-Level Analysis (using composite join to prevent duplicate town names mixing)
WITH town_totals AS (
    SELECT 
        province_name, 
        town_name, 
        SUM(people_served) AS People_served_per_town
    FROM md_water_services.combined_analysis_table
    GROUP BY province_name, town_name     
)
SELECT 
    ct.province_name,
    ct.town_name,
    ROUND((SUM(CASE WHEN source_type = 'river' THEN people_served ELSE 0 END) * 100.0 / tt.People_served_per_town), 0) AS river,
    ROUND((SUM(CASE WHEN source_type = 'shared_tap' THEN people_served ELSE 0 END) * 100.0 / tt.People_served_per_town), 0) AS shared_tap,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home' THEN people_served ELSE 0 END) * 100.0 / tt.People_served_per_town), 0) AS tap_in_home,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken' THEN people_served ELSE 0 END) * 100.0 / tt.People_served_per_town), 0) AS tap_in_home_broken,
    ROUND((SUM(CASE WHEN source_type = 'well' THEN people_served ELSE 0 END) * 100.0 / tt.People_served_per_town), 0) AS well
FROM md_water_services.combined_analysis_table ct
JOIN town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY ct.province_name, ct.town_name, tt.People_served_per_town
ORDER BY ct.province_name, ct.town_name;