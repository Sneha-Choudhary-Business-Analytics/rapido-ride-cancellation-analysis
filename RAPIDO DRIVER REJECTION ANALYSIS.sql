-- ============================================================
--  RAPIDO DRIVER REJECTION ANALYSIS
--  Author: Sneha Choudhary
--  Tool: MySQL Workbench
-- ============================================================

-- STEP 1: Create & select your database
-- ============================================================
CREATE DATABASE IF NOT EXISTS rapido_analysis;
-- ============================================================
--  RAPIDO DRIVER REJECTION ANALYSIS
--  Author: Sneha Choudhary | MBA Business Analytics
--  Database: rapido_analysis | Table: rapido_rides
-- ============================================================
 
USE rapido_analysis;
 
-- Load fresh data (run this first!)
-- ============================================================
TRUNCATE TABLE rapido_rides;
 
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Rapido_Ride_Rejection_Data_v3_1.csv"
INTO TABLE rapido_rides
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(request_id, request_datetime, day_of_week, time_slot, pickup_zone,
 ride_type, distance_km, distance_band, drivers_shown, drivers_rejected,
 rejection_rate_pct, surge_active, estimated_fare_inr, final_status);
 
-- Verify: should return 750
SELECT COUNT(*) AS total_records FROM rapido_rides;
-- CHECK 1: See what final_status values actually exist in your table
SELECT 
    final_status,
    COUNT(*) AS count
FROM rapido_rides
GROUP BY final_status;

-- CHECK 2: See raw data for supposed 'No Driver Found' rows
SELECT 
    request_id,
    final_status,
    estimated_fare_inr,
    LENGTH(final_status) AS char_length,
    HEX(final_status) AS hex_value
FROM rapido_rides
WHERE final_status LIKE '%No%'
LIMIT 10;

-- CHECK 3: Check if there are hidden spaces or special characters
SELECT 
    TRIM(final_status) AS trimmed_status,
    COUNT(*) AS count
FROM rapido_rides
GROUP BY TRIM(final_status);

TRUNCATE TABLE rapido_rides;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Rapido_Ride_Rejection_Data_v3_1.csv"
INTO TABLE rapido_rides
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'    -- ← CHANGED THIS
IGNORE 1 ROWS
(request_id, request_datetime, day_of_week, time_slot, pickup_zone,
 ride_type, distance_km, distance_band, drivers_shown, drivers_rejected,
 rejection_rate_pct, surge_active, estimated_fare_inr, final_status);

-- Verify immediately:
SELECT final_status, COUNT(*) 
FROM rapido_rides 
GROUP BY final_status;
 
 
-- ============================================================
-- QUERY 1: Overall Business Summary
-- Gives you your 4 KPI cards for Power BI
-- ============================================================
SELECT
    COUNT(*)                                                            AS total_requests,
    ROUND(AVG(rejection_rate_pct), 1)                                  AS avg_rejection_rate_pct,
    SUM(CASE WHEN final_status = 'Accepted'        THEN 1 ELSE 0 END)  AS rides_accepted,
    SUM(CASE WHEN final_status = 'No Driver Found' THEN 1 ELSE 0 END)  AS rides_lost,
    SUM(CASE WHEN final_status = 'Cancelled'       THEN 1 ELSE 0 END)  AS rides_cancelled,
    CONCAT('₹', SUM(CASE WHEN final_status = 'No Driver Found'
                    THEN estimated_fare_inr ELSE 0 END))                AS total_revenue_lost
FROM rapido_rides;
 
 
-- ============================================================
-- QUERY 2: Rejection Rate by Time Slot
-- Your HERO chart — bar chart in Power BI
-- Insight: Evening Rush will show the highest rejection rate
-- ============================================================
SELECT
    time_slot,
    COUNT(*)                            AS total_requests,
    ROUND(AVG(rejection_rate_pct), 1)  AS avg_rejection_rate_pct,
    SUM(drivers_rejected)              AS total_rejections,
    SUM(CASE WHEN final_status = 'No Driver Found' THEN 1 ELSE 0 END) AS rides_lost
FROM rapido_rides
GROUP BY time_slot
ORDER BY avg_rejection_rate_pct DESC;
 
 
-- ============================================================
-- QUERY 3: Rejection Rate by Pickup Zone
-- Bar chart or map visual in Power BI
-- Insight: LIG Colony and Rajwada will be the worst zones
-- ============================================================
SELECT
    pickup_zone,
    COUNT(*)                            AS total_requests,
    ROUND(AVG(rejection_rate_pct), 1)  AS avg_rejection_rate_pct,
    SUM(drivers_rejected)              AS total_rejections,
    SUM(CASE WHEN final_status = 'No Driver Found' THEN 1 ELSE 0 END) AS rides_lost
FROM rapido_rides
GROUP BY pickup_zone
ORDER BY avg_rejection_rate_pct DESC;
 
 
-- ============================================================
-- QUERY 4: Distance Band vs Rejection Rate
-- Column chart in Power BI
-- Insight: Short rides (<3km) get rejected the most
-- ============================================================
SELECT
    distance_band,
    COUNT(*)                            AS total_requests,
    ROUND(AVG(rejection_rate_pct), 1)  AS avg_rejection_rate_pct,
    ROUND(AVG(estimated_fare_inr), 0)  AS avg_fare_inr,
    SUM(CASE WHEN final_status = 'No Driver Found' THEN 1 ELSE 0 END) AS rides_lost
FROM rapido_rides
GROUP BY distance_band
ORDER BY avg_rejection_rate_pct DESC;
 
 
-- ============================================================
-- QUERY 5: Does Surge Pricing Actually Reduce Rejections?
-- Clustered bar chart in Power BI
-- Insight: Surge helps slightly but is not enough on its own
-- ============================================================
SELECT
    surge_active,
    COUNT(*)                            AS total_requests,
    ROUND(AVG(rejection_rate_pct), 1)  AS avg_rejection_rate_pct,
    SUM(CASE WHEN final_status = 'Accepted'        THEN 1 ELSE 0 END) AS rides_completed,
    SUM(CASE WHEN final_status = 'No Driver Found' THEN 1 ELSE 0 END) AS rides_lost
FROM rapido_rides
GROUP BY surge_active;
 
 
-- ============================================================
-- QUERY 6: Revenue Lost to Rejections
-- KPI card in Power BI — most impactful business number
-- ============================================================
SELECT
    CONCAT('₹', SUM(estimated_fare_inr))                               AS total_potential_revenue,
    CONCAT('₹', SUM(CASE WHEN final_status = 'No Driver Found'
                    THEN estimated_fare_inr ELSE 0 END))                AS revenue_lost,
    CONCAT(ROUND(
        SUM(CASE WHEN final_status = 'No Driver Found'
            THEN estimated_fare_inr ELSE 0 END)
        * 100.0 / SUM(estimated_fare_inr), 1), '%')                    AS revenue_loss_pct
FROM rapido_rides;
 
 
-- ============================================================
-- QUERY 7: Rejection Rate by Day of Week
-- Line chart in Power BI
-- Insight: Weekends will show higher rejection rates
-- ============================================================
SELECT
    day_of_week,
    COUNT(*)                            AS total_requests,
    ROUND(AVG(rejection_rate_pct), 1)  AS avg_rejection_rate_pct,
    SUM(CASE WHEN final_status = 'No Driver Found' THEN 1 ELSE 0 END) AS rides_lost
FROM rapido_rides
GROUP BY day_of_week
ORDER BY avg_rejection_rate_pct DESC;
 
 
-- ============================================================
-- QUERY 8: Ride Type vs Rejection Rate
-- Donut chart in Power BI
-- Insight: Bikes get rejected more than Autos or Cabs
-- ============================================================
SELECT
    ride_type,
    COUNT(*)                            AS total_requests,
    ROUND(AVG(rejection_rate_pct), 1)  AS avg_rejection_rate_pct,
    SUM(CASE WHEN final_status = 'No Driver Found' THEN 1 ELSE 0 END) AS rides_lost
FROM rapido_rides
GROUP BY ride_type
ORDER BY avg_rejection_rate_pct DESC;
 
 
-- ============================================================
-- QUERY 9: The Perfect Storm — Your Strongest LinkedIn Insight
-- Short ride + Evening Rush + No Surge = Maximum rejection
-- This single finding tells the whole story
-- ============================================================
SELECT
    distance_band,
    surge_active,
    COUNT(*)                            AS total_requests,
    ROUND(AVG(rejection_rate_pct), 1)  AS avg_rejection_rate_pct,
    SUM(CASE WHEN final_status = 'No Driver Found' THEN 1 ELSE 0 END) AS rides_lost
FROM rapido_rides
WHERE time_slot = 'Evening Rush (4-8 PM)'
GROUP BY distance_band, surge_active
ORDER BY avg_rejection_rate_pct DESC;
 
 
-- ============================================================
-- QUERY 10: Zone x Time Slot Heatmap
-- Matrix visual in Power BI — your most impressive visual
-- Shows exactly which zone at which time is the worst
-- ============================================================
SELECT
    pickup_zone,
    time_slot,
    ROUND(AVG(rejection_rate_pct), 1)  AS avg_rejection_rate_pct,
    COUNT(*)                            AS total_requests
FROM rapido_rides
GROUP BY pickup_zone, time_slot
ORDER BY avg_rejection_rate_pct DESC
LIMIT 20;
 
-- ============================================================
-- ALL DONE!
-- Export each result: Right click result grid → Export as CSV
-- Then load all CSVs into Power BI to build your dashboard
-- ============================================================
 

