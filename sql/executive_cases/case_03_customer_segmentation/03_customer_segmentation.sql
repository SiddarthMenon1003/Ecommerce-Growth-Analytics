-- ==========================================================
-- CASE 03 - CUSTOMER SEGMENTATION
-- FILE: 03_customer_segmentation.sql
-- PURPOSE:
-- Build actionable customer segments and compare
-- their business performance.
-- ==========================================================

------------------------------------------------------------
-- 1. Customer Segment Performance
------------------------------------------------------------

SELECT
    customer_value_segment,
    COUNT(*) AS customers,
    ROUND(SUM(total_revenue),2) AS total_revenue,
    ROUND(AVG(total_revenue),2) AS avg_customer_revenue,
    ROUND(AVG(estimated_ltv),2) AS avg_estimated_ltv,
    ROUND(AVG(avg_order_value),2) AS avg_order_value,
    ROUND(AVG(total_orders),2) AS avg_orders
FROM customer_segmentation_mart
GROUP BY customer_value_segment
ORDER BY total_revenue DESC;

------------------------------------------------------------
-- 2. Segment Revenue Contribution
------------------------------------------------------------

SELECT
    customer_value_segment,
    ROUND(
        SUM(total_revenue),
        2
    ) AS revenue,
    ROUND(
        SUM(total_revenue) /
        SUM(SUM(total_revenue)) OVER() * 100,
        2
    ) AS revenue_share_percent
FROM customer_segmentation_mart
GROUP BY customer_value_segment
ORDER BY revenue DESC;

------------------------------------------------------------
-- 3. Customer Type within Segments
------------------------------------------------------------

SELECT
    customer_value_segment,
    customer_type,
    COUNT(*) AS customers,
    ROUND(AVG(total_orders),2) AS avg_orders,
    ROUND(AVG(total_revenue),2) AS avg_revenue
FROM customer_segmentation_mart
GROUP BY
    customer_value_segment,
    customer_type
ORDER BY
    customer_value_segment,
    customer_type;

------------------------------------------------------------
-- 4. Purchase Frequency Distribution
------------------------------------------------------------

SELECT
    purchase_frequency_band,
    customer_value_segment,
    COUNT(*) AS customers,
    ROUND(AVG(total_orders),2) AS avg_orders
FROM customer_segmentation_mart
GROUP BY
    purchase_frequency_band,
    customer_value_segment
ORDER BY
    purchase_frequency_band,
    customer_value_segment;

------------------------------------------------------------
-- 5. Spending Distribution
------------------------------------------------------------

SELECT
    spending_band,
    customer_value_segment,
    COUNT(*) AS customers,
    ROUND(AVG(avg_order_value),2) AS avg_order_value,
    ROUND(SUM(total_revenue),2) AS revenue
FROM customer_segmentation_mart
GROUP BY
    spending_band,
    customer_value_segment
ORDER BY
    spending_band,
    customer_value_segment;

------------------------------------------------------------
-- 6. Engagement by Segment
------------------------------------------------------------

SELECT
    customer_value_segment,
    engagement_status,
    COUNT(*) AS customers,
    ROUND(SUM(total_revenue),2) AS revenue,
    ROUND(AVG(days_since_last_purchase),2) AS avg_days_since_last_purchase
FROM customer_segmentation_mart
GROUP BY
    customer_value_segment,
    engagement_status
ORDER BY
    customer_value_segment,
    engagement_status;

------------------------------------------------------------
-- 7. Estimated LTV by Segment
------------------------------------------------------------

SELECT
    customer_value_segment,
    ROUND(AVG(estimated_ltv),2) AS avg_estimated_ltv,
    ROUND(MAX(estimated_ltv),2) AS max_estimated_ltv,
    ROUND(MIN(estimated_ltv),2) AS min_estimated_ltv
FROM customer_segmentation_mart
GROUP BY customer_value_segment
ORDER BY avg_estimated_ltv DESC;

------------------------------------------------------------
-- 8. Top 10 Premium Customers
------------------------------------------------------------

SELECT
    customer_unique_id,
    total_revenue,
    estimated_ltv,
    avg_order_value,
    purchase_frequency,
    engagement_status
FROM customer_segmentation_mart
WHERE spending_band='Premium'
ORDER BY estimated_ltv DESC
LIMIT 10;

------------------------------------------------------------
-- 9. High Value Dormant Customers
------------------------------------------------------------

SELECT
    customer_unique_id,
    total_revenue,
    estimated_ltv,
    days_since_last_purchase,
    engagement_status
FROM customer_segmentation_mart
WHERE customer_value_segment='High Value'
AND engagement_status='Dormant'
ORDER BY estimated_ltv DESC
LIMIT 20;

------------------------------------------------------------
-- 10. Segment Opportunity Matrix
------------------------------------------------------------

SELECT
    customer_value_segment,
    purchase_frequency_band,
    spending_band,
    COUNT(*) AS customers,
    ROUND(SUM(total_revenue),2) AS revenue,
    ROUND(AVG(estimated_ltv),2) AS avg_ltv
FROM customer_segmentation_mart
GROUP BY
    customer_value_segment,
    purchase_frequency_band,
    spending_band
ORDER BY
    customer_value_segment,
    purchase_frequency_band,
    spending_band;
