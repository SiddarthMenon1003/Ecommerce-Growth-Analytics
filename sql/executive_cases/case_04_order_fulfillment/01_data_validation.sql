-- ==========================================================
-- CASE 04 - ORDER JOURNEY & FULFILLMENT ANALYTICS
-- FILE: 01_data_validation.sql
-- PURPOSE:
-- Validate the Order Fulfillment Funnel Mart before
-- analysis.
-- ==========================================================

------------------------------------------------------------
-- 1. Total Orders
------------------------------------------------------------

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM order_fulfillment_funnel_mart;

------------------------------------------------------------
-- 2. Duplicate Orders
------------------------------------------------------------

SELECT
    COUNT(*) AS duplicate_orders
FROM (
    SELECT order_id
    FROM order_fulfillment_funnel_mart
    GROUP BY order_id
    HAVING COUNT(*) > 1
) d;

------------------------------------------------------------
-- 3. Missing Identity Fields
------------------------------------------------------------

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL)
        AS missing_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL)
        AS missing_customer_id,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL)
        AS missing_customer_unique_id,
    COUNT(*) FILTER (WHERE order_status IS NULL)
        AS missing_order_status
FROM order_fulfillment_funnel_mart;

------------------------------------------------------------
-- 4. Missing Commercial Fields
------------------------------------------------------------

SELECT
    COUNT(*) FILTER (WHERE payment_value IS NULL)
        AS missing_payment_value,
    COUNT(*) FILTER (WHERE order_value IS NULL)
        AS missing_order_value,
    COUNT(*) FILTER (WHERE freight_value IS NULL)
        AS missing_freight_value,
    COUNT(*) FILTER (WHERE items_per_order IS NULL)
        AS missing_items_per_order,
    COUNT(*) FILTER (WHERE primary_payment_type IS NULL)
        AS missing_payment_type
FROM order_fulfillment_funnel_mart;

------------------------------------------------------------
-- 5. Missing Classification Fields
------------------------------------------------------------

SELECT
    COUNT(*) FILTER (WHERE order_size_category IS NULL)
        AS missing_order_size,
    COUNT(*) FILTER (WHERE current_funnel_stage IS NULL)
        AS missing_funnel_stage,
    COUNT(*) FILTER (WHERE delivery_performance IS NULL)
        AS missing_delivery_perf,
    COUNT(*) FILTER (WHERE sla_status IS NULL)
        AS missing_sla_status,
    COUNT(*) FILTER (WHERE delivery_efficiency_score IS NULL)
        AS missing_efficiency_score,
    COUNT(*) FILTER (WHERE order_value_band IS NULL)
        AS missing_value_band
FROM order_fulfillment_funnel_mart;

------------------------------------------------------------
-- 6. Invalid Values
------------------------------------------------------------

SELECT
    COUNT(*) FILTER (WHERE payment_value < 0)
        AS negative_payment_value,
    COUNT(*) FILTER (WHERE order_value < 0)
        AS negative_order_value,
    COUNT(*) FILTER (WHERE freight_value < 0)
        AS negative_freight_value,
    COUNT(*) FILTER (WHERE fulfillment_days < 0)
        AS negative_fulfillment_days,
    COUNT(*) FILTER (WHERE delivery_days < 0)
        AS negative_delivery_days,
    COUNT(*) FILTER (WHERE approval_hours < 0)
        AS negative_approval_hours
FROM order_fulfillment_funnel_mart;

------------------------------------------------------------
-- 7. Funnel Logic Consistency
------------------------------------------------------------

SELECT
    approved_flag,
    shipped_flag,
    delivered_flag,
    reviewed_flag,
    COUNT(*) AS orders
FROM order_fulfillment_funnel_mart
GROUP BY
    approved_flag,
    shipped_flag,
    delivered_flag,
    reviewed_flag
ORDER BY orders DESC;

------------------------------------------------------------
-- 8. Order Status Distribution
------------------------------------------------------------

SELECT
    order_status,
    COUNT(*) AS orders
FROM order_fulfillment_funnel_mart
GROUP BY order_status
ORDER BY orders DESC;

------------------------------------------------------------
-- 9. Funnel Stage Distribution
------------------------------------------------------------

SELECT
    current_funnel_stage,
    COUNT(*) AS orders
FROM order_fulfillment_funnel_mart
GROUP BY current_funnel_stage
ORDER BY orders DESC;

------------------------------------------------------------
-- 10. Delivery Performance Distribution
------------------------------------------------------------

SELECT
    delivery_performance,
    COUNT(*) AS orders
FROM order_fulfillment_funnel_mart
GROUP BY delivery_performance
ORDER BY orders DESC;

------------------------------------------------------------
-- 11. SLA Status Distribution
------------------------------------------------------------

SELECT
    sla_status,
    COUNT(*) AS orders
FROM order_fulfillment_funnel_mart
GROUP BY sla_status
ORDER BY orders DESC;

------------------------------------------------------------
-- 12. Review Score Band Distribution
------------------------------------------------------------

SELECT
    review_score_band,
    COUNT(*) AS orders
FROM order_fulfillment_funnel_mart
GROUP BY review_score_band
ORDER BY orders DESC;

------------------------------------------------------------
-- 13. Order Value Band Distribution
------------------------------------------------------------

SELECT
    order_value_band,
    COUNT(*) AS orders
FROM order_fulfillment_funnel_mart
GROUP BY order_value_band
ORDER BY orders DESC;
