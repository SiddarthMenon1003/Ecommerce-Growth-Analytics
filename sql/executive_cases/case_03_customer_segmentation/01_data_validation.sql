-- ==========================================================
-- CASE 03 - CUSTOMER SEGMENTATION
-- FILE: 01_data_validation.sql
-- PURPOSE:
-- Validate the Customer Segmentation Mart before analysis.
-- ==========================================================

------------------------------------------------------------
-- 1. Total Customers
------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customer_segmentation_mart;

------------------------------------------------------------
-- 2. Duplicate Customers
------------------------------------------------------------

SELECT
    COUNT(*) AS duplicate_customers
FROM (
    SELECT customer_unique_id
    FROM customer_segmentation_mart
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) d;

------------------------------------------------------------
-- 3. Missing Values
------------------------------------------------------------

SELECT
    COUNT(*) FILTER (WHERE total_revenue IS NULL)
        AS missing_revenue,
    COUNT(*) FILTER (WHERE estimated_ltv IS NULL)
        AS missing_ltv,
    COUNT(*) FILTER (WHERE avg_order_value IS NULL)
        AS missing_avg_order_value,
    COUNT(*) FILTER (WHERE purchase_frequency IS NULL)
        AS missing_purchase_frequency,
    COUNT(*) FILTER (WHERE customer_lifetime_days IS NULL)
        AS missing_lifetime_days,
    COUNT(*) FILTER (WHERE customer_value_segment IS NULL)
        AS missing_customer_segment,
    COUNT(*) FILTER (WHERE purchase_frequency_band IS NULL)
        AS missing_frequency_band,
    COUNT(*) FILTER (WHERE spending_band IS NULL)
        AS missing_spending_band,
    COUNT(*) FILTER (WHERE engagement_status IS NULL)
        AS missing_engagement_status
FROM customer_segmentation_mart;

------------------------------------------------------------
-- 4. Invalid Revenue
------------------------------------------------------------

SELECT *
FROM customer_segmentation_mart
WHERE total_revenue < 0;

------------------------------------------------------------
-- 5. Invalid Estimated LTV
------------------------------------------------------------

SELECT *
FROM customer_segmentation_mart
WHERE estimated_ltv < 0;

------------------------------------------------------------
-- 6. Invalid Average Order Value
------------------------------------------------------------

SELECT *
FROM customer_segmentation_mart
WHERE avg_order_value < 0;

------------------------------------------------------------
-- 7. Invalid Purchase Frequency
------------------------------------------------------------

SELECT *
FROM customer_segmentation_mart
WHERE purchase_frequency < 0;

------------------------------------------------------------
-- 8. Invalid Customer Lifetime
------------------------------------------------------------

SELECT *
FROM customer_segmentation_mart
WHERE customer_lifetime_days < 0;

------------------------------------------------------------
-- 9. Customer Value Segments
------------------------------------------------------------

SELECT
    customer_value_segment,
    COUNT(*) AS customers
FROM customer_segmentation_mart
GROUP BY customer_value_segment
ORDER BY customers DESC;

------------------------------------------------------------
-- 10. Purchase Frequency Bands
------------------------------------------------------------

SELECT
    purchase_frequency_band,
    COUNT(*) AS customers
FROM customer_segmentation_mart
GROUP BY purchase_frequency_band
ORDER BY customers DESC;

------------------------------------------------------------
-- 11. Spending Bands
------------------------------------------------------------

SELECT
    spending_band,
    COUNT(*) AS customers
FROM customer_segmentation_mart
GROUP BY spending_band
ORDER BY customers DESC;

------------------------------------------------------------
-- 12. Engagement Status
------------------------------------------------------------

SELECT
    engagement_status,
    COUNT(*) AS customers
FROM customer_segmentation_mart
GROUP BY engagement_status
ORDER BY customers DESC;
