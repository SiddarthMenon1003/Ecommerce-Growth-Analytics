/*
=========================================================
CASE 02 — MARKETING ROI
Data Validation
=========================================================
Purpose:
Validate the marketing ROI mart before analysis.
=========================================================
*/

-- Total Customers

SELECT
    COUNT(*) AS total_customers
FROM marketing_roi_mart;


-- Missing Customer IDs

SELECT
    COUNT(*) AS missing_customer_ids
FROM marketing_roi_mart
WHERE customer_id IS NULL;


-- Missing Revenue

SELECT
    COUNT(*) AS missing_revenue
FROM marketing_roi_mart
WHERE total_revenue IS NULL;


-- Customer Types

SELECT
    customer_type,
    COUNT(*) AS customers
FROM marketing_roi_mart
GROUP BY customer_type;


-- Marketing Priorities

SELECT
    marketing_priority,
    COUNT(*) AS customers
FROM marketing_roi_mart
GROUP BY marketing_priority;


-- Customer Value Segments

SELECT
    customer_value_segment,
    COUNT(*) AS customers
FROM marketing_roi_mart
GROUP BY customer_value_segment;


-- Duplicate Customers

SELECT
    customer_id,
    COUNT(*)
FROM marketing_roi_mart
GROUP BY customer_id
HAVING COUNT(*) > 1;