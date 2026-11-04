-- ==========================================================
-- CASE 04 - ORDER JOURNEY & FULFILLMENT ANALYTICS
-- FILE: 04_fulfillment_performance.sql
-- PURPOSE:
-- Measure fulfillment timing at each stage of the order
-- journey to identify operational bottlenecks and
-- performance variations.
-- ==========================================================

------------------------------------------------------------
-- 1. Overall Timing Statistics
------------------------------------------------------------

SELECT
    ROUND(MIN(approval_hours)::numeric, 2) AS min_approval_hours,
    ROUND(AVG(approval_hours)::numeric, 2) AS avg_approval_hours,
    ROUND(MAX(approval_hours)::numeric, 2) AS max_approval_hours,
    MIN(fulfillment_processing_days) AS min_processing_days,
    ROUND(AVG(fulfillment_processing_days)::numeric, 2) AS avg_processing_days,
    MAX(fulfillment_processing_days) AS max_processing_days,
    MIN(delivery_days) AS min_delivery_days,
    ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days,
    MAX(delivery_days) AS max_delivery_days,
    MIN(fulfillment_days) AS min_fulfillment_days,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    MAX(fulfillment_days) AS max_fulfillment_days
FROM order_fulfillment_funnel_mart
WHERE delivered_flag = 1;

------------------------------------------------------------
-- 2. Approval Speed Band Performance
------------------------------------------------------------

SELECT
    approval_speed_band,
    COUNT(*) AS orders,
    ROUND(AVG(approval_hours)::numeric, 2) AS avg_approval_hours,
    ROUND(MIN(approval_hours)::numeric, 2) AS min_approval_hours,
    ROUND(MAX(approval_hours)::numeric, 2) AS max_approval_hours
FROM order_fulfillment_funnel_mart
WHERE approval_speed_band IS NOT NULL
GROUP BY approval_speed_band
ORDER BY avg_approval_hours;

------------------------------------------------------------
-- 3. Shipping Speed Band Performance
------------------------------------------------------------

SELECT
    shipping_speed_band,
    COUNT(*) AS orders,
    ROUND(AVG(fulfillment_processing_days)::numeric, 2) AS avg_processing_days,
    MIN(fulfillment_processing_days) AS min_processing_days,
    MAX(fulfillment_processing_days) AS max_processing_days
FROM order_fulfillment_funnel_mart
WHERE shipping_speed_band IS NOT NULL
GROUP BY shipping_speed_band
ORDER BY avg_processing_days;

------------------------------------------------------------
-- 4. Fulfillment Speed Band Performance
------------------------------------------------------------

SELECT
    fulfillment_speed_band,
    COUNT(*) AS orders,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    MIN(fulfillment_days) AS min_fulfillment_days,
    MAX(fulfillment_days) AS max_fulfillment_days,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score
FROM order_fulfillment_funnel_mart
WHERE fulfillment_speed_band IS NOT NULL
GROUP BY fulfillment_speed_band
ORDER BY avg_fulfillment_days;

------------------------------------------------------------
-- 5. Fulfillment Timing by State (Top 10)
------------------------------------------------------------

SELECT
    customer_state,
    COUNT(*) AS orders,
    ROUND(AVG(approval_hours)::numeric, 2) AS avg_approval_hours,
    ROUND(AVG(fulfillment_processing_days)::numeric, 2) AS avg_processing_days,
    ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    ROUND(AVG(delivery_delay_days)::numeric, 2) AS avg_delivery_delay_days
FROM order_fulfillment_funnel_mart
WHERE delivered_flag = 1
GROUP BY customer_state
ORDER BY orders DESC
LIMIT 10;

------------------------------------------------------------
-- 6. Fulfillment Timing by Order Size
------------------------------------------------------------

SELECT
    order_size_category,
    COUNT(*) AS orders,
    ROUND(AVG(approval_hours)::numeric, 2) AS avg_approval_hours,
    ROUND(AVG(fulfillment_processing_days)::numeric, 2) AS avg_processing_days,
    ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days
FROM order_fulfillment_funnel_mart
WHERE delivered_flag = 1
GROUP BY order_size_category
ORDER BY avg_fulfillment_days DESC;

------------------------------------------------------------
-- 7. Fulfillment Timing by Order Value Band
------------------------------------------------------------

SELECT
    order_value_band,
    COUNT(*) AS orders,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days,
    ROUND(
        SUM(late_delivery_flag)::numeric /
        GREATEST(COUNT(*), 1) * 100,
        2
    ) AS late_delivery_rate
FROM order_fulfillment_funnel_mart
WHERE delivered_flag = 1
GROUP BY order_value_band
ORDER BY
    CASE order_value_band
        WHEN 'High Value'   THEN 1
        WHEN 'Medium Value' THEN 2
        WHEN 'Low Value'    THEN 3
    END;

------------------------------------------------------------
-- 8. Monthly Fulfillment Trend
------------------------------------------------------------

SELECT
    purchase_year,
    purchase_month,
    COUNT(*) AS orders,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    ROUND(AVG(approval_hours)::numeric, 2) AS avg_approval_hours,
    ROUND(
        SUM(late_delivery_flag)::numeric /
        GREATEST(COUNT(*), 1) * 100,
        2
    ) AS late_delivery_rate
FROM order_fulfillment_funnel_mart
GROUP BY
    purchase_year,
    purchase_month
ORDER BY
    purchase_year,
    purchase_month;

------------------------------------------------------------
-- 9. Slowest 20 Orders by Fulfillment
------------------------------------------------------------

SELECT
    order_id,
    customer_state,
    fulfillment_days,
    approval_hours,
    fulfillment_processing_days,
    delivery_days,
    delivery_performance,
    review_score
FROM order_fulfillment_funnel_mart
WHERE delivered_flag = 1
ORDER BY fulfillment_days DESC
LIMIT 20;

------------------------------------------------------------
-- 10. Speed Band Cross Analysis
------------------------------------------------------------

SELECT
    approval_speed_band,
    shipping_speed_band,
    fulfillment_speed_band,
    COUNT(*) AS orders,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score,
    ROUND(AVG(payment_value)::numeric, 2) AS avg_payment_value
FROM order_fulfillment_funnel_mart
WHERE fulfillment_speed_band IS NOT NULL
GROUP BY
    approval_speed_band,
    shipping_speed_band,
    fulfillment_speed_band
ORDER BY avg_fulfillment_days DESC;
