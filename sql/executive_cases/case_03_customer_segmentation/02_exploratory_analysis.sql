-- ==========================================================
-- CASE 03 - CUSTOMER SEGMENTATION
-- FILE: 02_exploratory_analysis.sql
-- PURPOSE:
-- Explore customer segments and understand behavioral,
-- revenue, and engagement characteristics before building
-- the dashboard.
-- ==========================================================

------------------------------------------------------------
-- 1. Overall Customer Summary
------------------------------------------------------------

SELECT
    COUNT(*) AS total_customers,
    SUM(total_revenue) AS total_revenue,
    ROUND(AVG(total_revenue),2) AS avg_customer_revenue,
    ROUND(AVG(estimated_ltv),2) AS avg_estimated_ltv,
    ROUND(AVG(avg_order_value),2) AS avg_order_value,
    ROUND(AVG(customer_lifetime_days),2) AS avg_customer_lifetime_days,
    ROUND(AVG(purchase_frequency),4) AS avg_purchase_frequency
FROM customer_segmentation_mart;

------------------------------------------------------------
-- 2. Customer Value Segment Summary
------------------------------------------------------------

SELECT
    customer_value_segment,
    COUNT(*) AS customers,
    ROUND(SUM(total_revenue),2) AS revenue,
    ROUND(AVG(total_revenue),2) AS avg_revenue,
    ROUND(AVG(estimated_ltv),2) AS avg_ltv,
    ROUND(AVG(avg_order_value),2) AS avg_order_value
FROM customer_segmentation_mart
GROUP BY customer_value_segment
ORDER BY revenue DESC;

------------------------------------------------------------
-- 3. Customer Type Distribution
------------------------------------------------------------

SELECT
    customer_type,
    COUNT(*) AS customers,
    ROUND(SUM(total_revenue),2) AS revenue,
    ROUND(AVG(total_orders),2) AS avg_orders
FROM customer_segmentation_mart
GROUP BY customer_type
ORDER BY revenue DESC;

------------------------------------------------------------
-- 4. Purchase Frequency Bands
------------------------------------------------------------

SELECT
    purchase_frequency_band,
    COUNT(*) AS customers,
    ROUND(AVG(total_orders),2) AS avg_orders,
    ROUND(AVG(purchase_frequency),4) AS avg_purchase_frequency,
    ROUND(AVG(total_revenue),2) AS avg_revenue
FROM customer_segmentation_mart
GROUP BY purchase_frequency_band
ORDER BY avg_purchase_frequency DESC;

------------------------------------------------------------
-- 5. Spending Bands
------------------------------------------------------------

SELECT
    spending_band,
    COUNT(*) AS customers,
    ROUND(AVG(avg_order_value),2) AS avg_order_value,
    ROUND(SUM(total_revenue),2) AS revenue
FROM customer_segmentation_mart
GROUP BY spending_band
ORDER BY revenue DESC;

------------------------------------------------------------
-- 6. Engagement Status
------------------------------------------------------------

SELECT
    engagement_status,
    COUNT(*) AS customers,
    ROUND(SUM(total_revenue),2) AS revenue,
    ROUND(AVG(days_since_last_purchase),2) AS avg_days_since_purchase
FROM customer_segmentation_mart
GROUP BY engagement_status
ORDER BY revenue DESC;

------------------------------------------------------------
-- 7. Customer Value vs Engagement
------------------------------------------------------------

SELECT
    customer_value_segment,
    engagement_status,
    COUNT(*) AS customers,
    ROUND(SUM(total_revenue),2) AS revenue
FROM customer_segmentation_mart
GROUP BY
    customer_value_segment,
    engagement_status
ORDER BY
    customer_value_segment,
    engagement_status;

------------------------------------------------------------
-- 8. Top 20 Customers by Revenue
------------------------------------------------------------

SELECT
    customer_unique_id,
    total_orders,
    total_revenue,
    estimated_ltv,
    customer_value_segment,
    purchase_frequency_band,
    spending_band
FROM customer_segmentation_mart
ORDER BY total_revenue DESC
LIMIT 20;

------------------------------------------------------------
-- 9. Top 20 Customers by Estimated LTV
------------------------------------------------------------

SELECT
    customer_unique_id,
    estimated_ltv,
    total_revenue,
    total_orders,
    customer_value_segment,
    engagement_status
FROM customer_segmentation_mart
ORDER BY estimated_ltv DESC
LIMIT 20;

------------------------------------------------------------
-- 10. Revenue Contribution by Segment
------------------------------------------------------------

SELECT
    customer_value_segment,
    ROUND(
        SUM(total_revenue) /
        SUM(SUM(total_revenue)) OVER () * 100,
        2
    ) AS revenue_share_percent
FROM customer_segmentation_mart
GROUP BY customer_value_segment
ORDER BY revenue_share_percent DESC;
