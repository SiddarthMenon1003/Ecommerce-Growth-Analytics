-- ==========================================================
-- CASE 04 - ORDER JOURNEY & FULFILLMENT ANALYTICS
-- FILE: 05_delivery_experience.sql
-- PURPOSE:
-- Evaluate delivery performance, SLA compliance, and
-- their impact on customer satisfaction and review
-- scores.
-- ==========================================================

------------------------------------------------------------
-- 1. Delivery Performance Summary
------------------------------------------------------------

SELECT
    delivery_performance,
    COUNT(*) AS orders,
    ROUND(
        COUNT(*)::numeric /
        SUM(COUNT(*)) OVER() * 100,
        2
    ) AS order_percentage,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score
FROM order_fulfillment_funnel_mart
GROUP BY delivery_performance
ORDER BY orders DESC;

------------------------------------------------------------
-- 2. Delivery Delay Category Breakdown
------------------------------------------------------------

SELECT
    delivery_delay_category,
    COUNT(*) AS orders,
    ROUND(
        COUNT(*)::numeric /
        SUM(COUNT(*)) OVER() * 100,
        2
    ) AS order_percentage,
    ROUND(AVG(delivery_delay_days)::numeric, 2) AS avg_delay_days,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score
FROM order_fulfillment_funnel_mart
GROUP BY delivery_delay_category
ORDER BY orders DESC;

------------------------------------------------------------
-- 3. SLA Status by State (Top 10)
------------------------------------------------------------

SELECT
    customer_state,
    COUNT(*) AS orders,
    ROUND(
        SUM(CASE WHEN sla_status = 'Met SLA' THEN 1 ELSE 0 END)::numeric /
        GREATEST(SUM(delivered_flag), 1) * 100,
        2
    ) AS sla_compliance_rate,
    ROUND(
        SUM(late_delivery_flag)::numeric /
        GREATEST(COUNT(*), 1) * 100,
        2
    ) AS late_delivery_rate
FROM order_fulfillment_funnel_mart
GROUP BY customer_state
ORDER BY orders DESC
LIMIT 10;

------------------------------------------------------------
-- 4. Review Score by Delivery Performance
------------------------------------------------------------

SELECT
    delivery_performance,
    review_score_band,
    COUNT(*) AS orders,
    ROUND(
        COUNT(*)::numeric /
        SUM(COUNT(*)) OVER(PARTITION BY delivery_performance) * 100,
        2
    ) AS percentage_within_group
FROM order_fulfillment_funnel_mart
WHERE review_score IS NOT NULL
GROUP BY
    delivery_performance,
    review_score_band
ORDER BY
    CASE delivery_performance
        WHEN 'Early'         THEN 1
        WHEN 'On Time'       THEN 2
        WHEN 'Late'          THEN 3
        WHEN 'Not Delivered' THEN 4
    END,
    review_score_band;

------------------------------------------------------------
-- 5. Review Score by Fulfillment Speed
------------------------------------------------------------

SELECT
    fulfillment_speed_band,
    COUNT(*) AS orders,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    ROUND(
        SUM(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END)::numeric /
        GREATEST(COUNT(*), 1) * 100,
        2
    ) AS positive_review_rate
FROM order_fulfillment_funnel_mart
WHERE fulfillment_speed_band IS NOT NULL
AND review_score IS NOT NULL
GROUP BY fulfillment_speed_band
ORDER BY avg_review_score DESC;

------------------------------------------------------------
-- 6. Delivery Efficiency Score Summary
------------------------------------------------------------

SELECT
    delivery_efficiency_score,
    COUNT(*) AS orders,
    ROUND(
        COUNT(*)::numeric /
        SUM(COUNT(*)) OVER() * 100,
        2
    ) AS order_percentage,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days
FROM order_fulfillment_funnel_mart
GROUP BY delivery_efficiency_score
ORDER BY orders DESC;

------------------------------------------------------------
-- 7. Late Delivery Impact on Reviews
------------------------------------------------------------

SELECT
    CASE
        WHEN late_delivery_flag = 1 THEN 'Late'
        ELSE 'On Time / Early'
    END AS delivery_timing,
    COUNT(*) AS orders,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score,
    ROUND(
        SUM(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END)::numeric /
        GREATEST(SUM(CASE WHEN review_score IS NOT NULL THEN 1 ELSE 0 END), 1) * 100,
        2
    ) AS poor_review_rate,
    ROUND(
        SUM(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END)::numeric /
        GREATEST(SUM(CASE WHEN review_score IS NOT NULL THEN 1 ELSE 0 END), 1) * 100,
        2
    ) AS positive_review_rate
FROM order_fulfillment_funnel_mart
WHERE delivered_flag = 1
GROUP BY late_delivery_flag
ORDER BY late_delivery_flag;

------------------------------------------------------------
-- 8. Freight Percentage by Delivery Performance
------------------------------------------------------------

SELECT
    delivery_performance,
    COUNT(*) AS orders,
    ROUND(AVG(freight_percentage)::numeric, 2) AS avg_freight_percent,
    ROUND(AVG(freight_value)::numeric, 2) AS avg_freight_value,
    ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days
FROM order_fulfillment_funnel_mart
WHERE freight_percentage IS NOT NULL
GROUP BY delivery_performance
ORDER BY avg_freight_percent DESC;

------------------------------------------------------------
-- 9. Weekday Delivery Performance
------------------------------------------------------------

SELECT
    purchase_weekday,
    COUNT(*) AS orders,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    ROUND(
        SUM(late_delivery_flag)::numeric /
        GREATEST(COUNT(*), 1) * 100,
        2
    ) AS late_delivery_rate,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score
FROM order_fulfillment_funnel_mart
GROUP BY purchase_weekday
ORDER BY avg_fulfillment_days DESC;

------------------------------------------------------------
-- 10. Customer Experience Executive Summary
------------------------------------------------------------

SELECT
    delivery_performance,
    sla_status,
    COUNT(*) AS orders,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    ROUND(AVG(delivery_delay_days)::numeric, 2) AS avg_delay_days
FROM order_fulfillment_funnel_mart
GROUP BY
    delivery_performance,
    sla_status
ORDER BY
    CASE delivery_performance
        WHEN 'Early'         THEN 1
        WHEN 'On Time'       THEN 2
        WHEN 'Late'          THEN 3
        WHEN 'Not Delivered' THEN 4
    END,
    sla_status;
