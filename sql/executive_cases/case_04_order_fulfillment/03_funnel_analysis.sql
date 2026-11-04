-- ==========================================================
-- CASE 04 - ORDER JOURNEY & FULFILLMENT ANALYTICS
-- FILE: 03_funnel_analysis.sql
-- PURPOSE:
-- Analyse the order fulfillment funnel to understand
-- stage progression, drop-off rates, and where orders
-- fail to advance through the journey.
-- ==========================================================

------------------------------------------------------------
-- 1. Funnel Stage Counts
------------------------------------------------------------

SELECT
    'Order Created' AS stage,
    COUNT(*) AS orders
FROM order_fulfillment_funnel_mart
UNION ALL
SELECT
    'Payment Approved',
    SUM(approved_flag)
FROM order_fulfillment_funnel_mart
UNION ALL
SELECT
    'Shipped',
    SUM(shipped_flag)
FROM order_fulfillment_funnel_mart
UNION ALL
SELECT
    'Delivered',
    SUM(delivered_flag)
FROM order_fulfillment_funnel_mart
UNION ALL
SELECT
    'Reviewed',
    SUM(reviewed_flag)
FROM order_fulfillment_funnel_mart;

------------------------------------------------------------
-- 2. Funnel Conversion Rates
------------------------------------------------------------

SELECT
    COUNT(*) AS total_orders,
    ROUND(
        SUM(approved_flag)::numeric /
        COUNT(*) * 100,
        2
    ) AS approval_rate,
    ROUND(
        SUM(shipped_flag)::numeric /
        GREATEST(SUM(approved_flag), 1) * 100,
        2
    ) AS ship_rate,
    ROUND(
        SUM(delivered_flag)::numeric /
        GREATEST(SUM(shipped_flag), 1) * 100,
        2
    ) AS delivery_rate,
    ROUND(
        SUM(reviewed_flag)::numeric /
        COUNT(*) * 100,
        2
    ) AS review_rate,
    ROUND(
        SUM(delivered_flag)::numeric /
        COUNT(*) * 100,
        2
    ) AS end_to_end_rate
FROM order_fulfillment_funnel_mart;

------------------------------------------------------------
-- 3. Orders Stuck at Each Stage
------------------------------------------------------------

SELECT
    current_funnel_stage,
    COUNT(*) AS orders,
    ROUND(
        COUNT(*)::numeric /
        SUM(COUNT(*)) OVER() * 100,
        2
    ) AS percentage,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue_at_risk,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days
FROM order_fulfillment_funnel_mart
WHERE current_funnel_stage != 'Reviewed'
GROUP BY current_funnel_stage
ORDER BY orders DESC;

------------------------------------------------------------
-- 4. Funnel by Order Status
------------------------------------------------------------

SELECT
    order_status,
    COUNT(*) AS orders,
    SUM(approved_flag) AS approved,
    SUM(shipped_flag) AS shipped,
    SUM(delivered_flag) AS delivered,
    SUM(reviewed_flag) AS reviewed
FROM order_fulfillment_funnel_mart
GROUP BY order_status
ORDER BY orders DESC;

------------------------------------------------------------
-- 5. Monthly Funnel Progression
------------------------------------------------------------

SELECT
    purchase_year,
    purchase_month,
    COUNT(*) AS orders,
    ROUND(
        SUM(approved_flag)::numeric /
        COUNT(*) * 100,
        2
    ) AS approval_rate,
    ROUND(
        SUM(delivered_flag)::numeric /
        COUNT(*) * 100,
        2
    ) AS delivery_rate,
    ROUND(
        SUM(reviewed_flag)::numeric /
        COUNT(*) * 100,
        2
    ) AS review_rate
FROM order_fulfillment_funnel_mart
GROUP BY
    purchase_year,
    purchase_month
ORDER BY
    purchase_year,
    purchase_month;

------------------------------------------------------------
-- 6. Funnel by State (Top 10)
------------------------------------------------------------

SELECT
    customer_state,
    COUNT(*) AS orders,
    ROUND(
        SUM(delivered_flag)::numeric /
        COUNT(*) * 100,
        2
    ) AS delivery_rate,
    ROUND(
        SUM(late_delivery_flag)::numeric /
        GREATEST(COUNT(*), 1) * 100,
        2
    ) AS late_delivery_rate,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score
FROM order_fulfillment_funnel_mart
GROUP BY customer_state
ORDER BY orders DESC
LIMIT 10;

------------------------------------------------------------
-- 7. Funnel Stage Revenue Distribution
------------------------------------------------------------

SELECT
    current_funnel_stage,
    COUNT(*) AS orders,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue,
    ROUND(
        SUM(payment_value)::numeric /
        SUM(SUM(payment_value)) OVER() * 100,
        2
    ) AS revenue_share_percent
FROM order_fulfillment_funnel_mart
GROUP BY current_funnel_stage
ORDER BY
    CASE current_funnel_stage
        WHEN 'Order Created'     THEN 1
        WHEN 'Payment Approved'  THEN 2
        WHEN 'Shipped'           THEN 3
        WHEN 'Delivered'         THEN 4
        WHEN 'Reviewed'          THEN 5
    END;

------------------------------------------------------------
-- 8. Funnel by Order Value Band
------------------------------------------------------------

SELECT
    order_value_band,
    COUNT(*) AS orders,
    ROUND(
        SUM(delivered_flag)::numeric /
        COUNT(*) * 100,
        2
    ) AS delivery_rate,
    ROUND(
        SUM(reviewed_flag)::numeric /
        COUNT(*) * 100,
        2
    ) AS review_rate,
    ROUND(
        SUM(late_delivery_flag)::numeric /
        GREATEST(COUNT(*), 1) * 100,
        2
    ) AS late_delivery_rate
FROM order_fulfillment_funnel_mart
GROUP BY order_value_band
ORDER BY
    CASE order_value_band
        WHEN 'High Value'   THEN 1
        WHEN 'Medium Value' THEN 2
        WHEN 'Low Value'    THEN 3
    END;

------------------------------------------------------------
-- 9. Funnel by Order Size Category
------------------------------------------------------------

SELECT
    order_size_category,
    COUNT(*) AS orders,
    ROUND(
        SUM(delivered_flag)::numeric /
        COUNT(*) * 100,
        2
    ) AS delivery_rate,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    ROUND(
        SUM(late_delivery_flag)::numeric /
        GREATEST(COUNT(*), 1) * 100,
        2
    ) AS late_delivery_rate
FROM order_fulfillment_funnel_mart
GROUP BY order_size_category
ORDER BY orders DESC;

------------------------------------------------------------
-- 10. Average Time Between Stages
------------------------------------------------------------

SELECT
    ROUND(AVG(approval_hours)::numeric, 2)
        AS avg_hours_to_approve,
    ROUND(AVG(fulfillment_processing_days)::numeric, 2)
        AS avg_days_to_ship,
    ROUND(AVG(delivery_days)::numeric, 2)
        AS avg_days_in_transit,
    ROUND(AVG(fulfillment_days)::numeric, 2)
        AS avg_days_total,
    ROUND(AVG(review_delay_days)::numeric, 2)
        AS avg_days_to_review
FROM order_fulfillment_funnel_mart
WHERE delivered_flag = 1;
