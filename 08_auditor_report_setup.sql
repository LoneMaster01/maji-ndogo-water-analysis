-- ============================================================
-- 08_auditor_report_setup.sql
-- Maji Ndogo Water Access — SQL Analysis
--
-- Part 3: Integrating the Auditor's Report
-- This file documents the creation and import of the 
-- independent auditor's re-examination data.
-- ============================================================

-- 1. Create the table structure
DROP TABLE IF EXISTS `auditor_report`;
CREATE TABLE `auditor_report` (
    `location_id` VARCHAR(32),
    `type_of_water_source` VARCHAR(64),
    `true_water_source_score` INT DEFAULT NULL,
    `statements` VARCHAR(255)
);

-- 2. Import the CSV data
-- Note: The raw CSV used semicolons (;) as delimiters and Windows line breaks (\r\n)
LOAD DATA LOCAL INFILE 'C:/path/to/Auditor_report.csv'
INTO TABLE auditor_report
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

-- Verification: Should return 1620 records
SELECT COUNT(*) FROM auditor_report;