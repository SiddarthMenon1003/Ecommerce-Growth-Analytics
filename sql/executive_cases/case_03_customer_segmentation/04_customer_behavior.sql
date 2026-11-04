-- ==========================================================
-- CASE 03 - CUSTOMER SEGMENTATION
-- FILE: 04_behavior_analysis.sql
-- PURPOSE:
-- Analyze customer purchasing behavior, engagement,
-- and lifecycle characteristics across segments.
-- ==========================================================

------------------------------------------------------------
-- 1. Customer Lifetime by Segment
------------------------------------------------------------

SELECT
    customer_value_segment,
    ROUND(AVG(customer_lifetime_days),2) AS avg_lifetime_days,
    ROUND(MIN(customer_lifetime_days),2) AS min_lifetime_days,
    ROUND(MAX(customer_lifetime_days),2) AS max_lifetime_days
FROM customer_segmentation_mart
GROUP BY customer_value_segment
ORDER BY avg_lifetime_days DESC;

------------------------------------------------------------
-- 2. Purchase Frequency by Segment
------------------------------------------------------------

SELECT
    customer_value_segment,
    ROUND(AVG(purchase_frequency),4) AS avg_purchase_frequency,
    ROUND(MAX(purchase_frequency),4) AS max_purchase_frequency,
    ROUND(MIN(purchase_frequency),4) AS min_purchase_frequency
FROM customer_segmentation_mart
GROUP BY customer_value_segment
ORDER BY avg_purchase_frequency DESC;

------------------------------------------------------------
-- 3. Average Order Value by Segment
------------------------------------------------------------

SELECT
    customer_value_segment,
    ROUND(AVG(avg_order_value),2) AS avg_order_value,
    ROUND(MAX(avg_order_value),2) AS max_order_value,
    ROUND(MIN(avg_order_value),2) AS min_order_value
FROM customer_segmentation_mart
GROUP BY customer_value_segment
ORDER BY avg_order_value DESC;

------------------------------------------------------------
-- 4. Engagement Status Performance
------------------------------------------------------------

SELECT
    engagement_status,
    COUNT(*) AS customers,
    ROUND(AVG(total_revenue),2) AS avg_revenue,
    ROUND(AVG(estimated_ltv),2) AS avg_estimated_ltv,
    ROUND(AVG(days_since_last_purchase),2) AS avg_days_since_purchase
FROM customer_segmentation_mart
GROUP BY engagement_status
ORDER BY avg_estimated_ltv DESC;

------------------------------------------------------------
-- 5. Spending Band Performance
------------------------------------------------------------

SELECT
    spending_band,
    COUNT(*) AS customers,
    ROUND(AVG(total_revenue),2) AS avg_revenue,
    ROUND(AVG(estimated_ltv),2) AS avg_estimated_ltv,
    ROUND(AVG(avg_order_value),2) AS avg_order_value
FROM customer_segmentation_mart
GROUP BY spending_band
ORDER BY avg_estimated_ltv DESC;

------------------------------------------------------------
-- 6. Purchase Frequency Band Performance
------------------------------------------------------------

SELECT
    purchase_frequency_band,
    COUNT(*) AS customers,
    ROUND(AVG(total_revenue),2) AS avg_revenue,
    ROUND(AVG(estimated_ltv),2) AS avg_estimated_ltv,
    ROUND(AVG(total_orders),2) AS avg_orders
FROM customer_segmentation_mart
GROUP BY purchase_frequency_band
ORDER BY avg_estimated_ltv DESC;

------------------------------------------------------------
-- 7. Revenue by Engagement Status
------------------------------------------------------------

SELECT
    engagement_status,
    ROUND(SUM(total_revenue),2) AS total_revenue,
    ROUND(
        SUM(total_revenue) /
        SUM(SUM(total_revenue)) OVER() * 100,
        2
    ) AS revenue_share_percent
FROM customer_segmentation_mart
GROUP BY engagement_status
ORDER BY total_revenue DESC;

------------------------------------------------------------
-- 8. Revenue by Spending Band
------------------------------------------------------------

SELECT
    spending_band,
    ROUND(SUM(total_revenue),2) AS total_revenue,
    ROUND(
        SUM(total_revenue) /
        SUM(SUM(total_revenue)) OVER() * 100,
        2
    ) AS revenue_share_percent
FROM customer_segmentation_mart
GROUP BY spending_band
ORDER BY total_revenue DESC;

------------------------------------------------------------
-- 9. Top 20 Longest Lifetime Customers
------------------------------------------------------------

SELECT
    customer_unique_id,
    customer_value_segment,
    customer_lifetime_days,
    total_revenue,
    estimated_ltv,
    engagement_status
FROM customer_segmentation_mart
ORDER BY customer_lifetime_days DESC
LIMIT 20;

------------------------------------------------------------
-- 10. Top 20 Highest Purchase Frequency Customers
------------------------------------------------------------

SELECT
    customer_unique_id,
    purchase_frequency,
    total_orders,
    estimated_ltv,
    customer_value_segment,
    spending_band
FROM customer_segmentation_mart
ORDER BY purchase_frequency DESC
LIMIT 20;
