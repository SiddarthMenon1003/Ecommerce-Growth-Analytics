-- ==========================================================
-- CASE 04 - ORDER JOURNEY & FULFILLMENT ANALYTICS
-- FILE: 02_exploratory_analysis.sql
-- PURPOSE:
-- Explore order journey metrics and develop a high-level
-- understanding of fulfillment performance, timing, and
-- customer experience before deep-dive analysis.
-- ==========================================================

------------------------------------------------------------
-- 1. Overall Order Summary
------------------------------------------------------------

SELECT
    COUNT(*) AS total_orders,
    ROUND(SUM(payment_value)::numeric, 2) AS total_revenue,
    ROUND(AVG(payment_value)::numeric, 2) AS avg_order_revenue,
    ROUND(AVG(order_value)::numeric, 2) AS avg_order_value,
    ROUND(AVG(freight_value)::numeric, 2) AS avg_freight_value,
    ROUND(AVG(items_per_order)::numeric, 2) AS avg_items_per_order
FROM order_fulfillment_funnel_mart;

------------------------------------------------------------
-- 2. Fulfillment Timing Summary
------------------------------------------------------------

SELECT
    ROUND(AVG(approval_hours)::numeric, 2) AS avg_approval_hours,
    ROUND(AVG(fulfillment_processing_days)::numeric, 2) AS avg_processing_days,
    ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    ROUND(AVG(review_delay_days)::numeric, 2) AS avg_review_delay_days,
    ROUND(AVG(delivery_delay_days)::numeric, 2) AS avg_delivery_delay_days
FROM order_fulfillment_funnel_mart;

------------------------------------------------------------
-- 3. Funnel Stage Summary
------------------------------------------------------------

SELECT
    current_funnel_stage,
    COUNT(*) AS orders,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue,
    ROUND(AVG(payment_value)::numeric, 2) AS avg_revenue
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
-- 4. Delivery Performance Summary
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
-- 5. SLA Status Summary
------------------------------------------------------------

SELECT
    sla_status,
    COUNT(*) AS orders,
    ROUND(
        COUNT(*)::numeric /
        SUM(COUNT(*)) OVER() * 100,
        2
    ) AS order_percentage,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days
FROM order_fulfillment_funnel_mart
GROUP BY sla_status
ORDER BY orders DESC;

------------------------------------------------------------
-- 6. Monthly Order Volume
------------------------------------------------------------

SELECT
    purchase_year,
    purchase_month,
    purchase_month_name,
    COUNT(*) AS orders,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue
FROM order_fulfillment_funnel_mart
GROUP BY
    purchase_year,
    purchase_month,
    purchase_month_name
ORDER BY
    purchase_year,
    purchase_month;

------------------------------------------------------------
-- 7. Payment Type Distribution
------------------------------------------------------------

SELECT
    primary_payment_type,
    COUNT(*) AS orders,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue,
    ROUND(AVG(payment_value)::numeric, 2) AS avg_revenue
FROM order_fulfillment_funnel_mart
GROUP BY primary_payment_type
ORDER BY revenue DESC;

------------------------------------------------------------
-- 8. Order Size Distribution
------------------------------------------------------------

SELECT
    order_size_category,
    COUNT(*) AS orders,
    ROUND(
        COUNT(*)::numeric /
        SUM(COUNT(*)) OVER() * 100,
        2
    ) AS order_percentage,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue
FROM order_fulfillment_funnel_mart
GROUP BY order_size_category
ORDER BY orders DESC;

------------------------------------------------------------
-- 9. Top 10 States by Order Volume
------------------------------------------------------------

SELECT
    customer_state,
    COUNT(*) AS orders,
    ROUND(SUM(payment_value)::numeric, 2) AS revenue,
    ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,
    ROUND(AVG(delivery_delay_days)::numeric, 2) AS avg_delivery_delay_days
FROM order_fulfillment_funnel_mart
GROUP BY customer_state
ORDER BY orders DESC
LIMIT 10;

------------------------------------------------------------
-- 10. Review Score Distribution
------------------------------------------------------------

SELECT
    review_score,
    review_score_band,
    COUNT(*) AS orders,
    ROUND(
        COUNT(*)::numeric /
        SUM(COUNT(*)) OVER() * 100,
        2
    ) AS order_percentage,
    ROUND(AVG(payment_value)::numeric, 2) AS avg_payment_value
FROM order_fulfillment_funnel_mart
GROUP BY
    review_score,
    review_score_band
ORDER BY review_score DESC NULLS LAST;
