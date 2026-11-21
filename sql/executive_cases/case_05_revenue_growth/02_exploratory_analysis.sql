/*
===============================================================================
CASE 05 - REVENUE GROWTH

STEP 02 - EXPLORATORY ANALYSIS

Objective:
Establish the shape of revenue - its scale, how it splits across categories and
geography, and how it has moved over time - before diagnosing where future
growth will come from.
===============================================================================
*/

----------------------------------------------------------------------------
-- SECTION A : REVENUE SCALE
----------------------------------------------------------------------------

-- 1. Total product revenue (item-level)
SELECT ROUND(SUM(price)::numeric, 2) AS total_product_revenue
FROM fact_order_items;

-- 2. Total order payment revenue (order-level, incl. freight/installments)
SELECT ROUND(SUM(payment_value)::numeric, 2) AS total_payment_revenue
FROM fact_payments;

-- 3. Average item price and items per order
SELECT
    ROUND(AVG(price)::numeric, 2) AS avg_item_price,
    ROUND(COUNT(*)::numeric / COUNT(DISTINCT order_id), 2) AS avg_items_per_order
FROM fact_order_items;

----------------------------------------------------------------------------
-- SECTION B : REVENUE OVER TIME
----------------------------------------------------------------------------

-- 4. Monthly product revenue
SELECT
    DATE_TRUNC('month', fo.order_purchase_timestamp)::date AS revenue_month,
    ROUND(SUM(oi.price)::numeric, 2)                       AS monthly_revenue,
    COUNT(DISTINCT fo.order_id)                            AS orders
FROM fact_order_items oi
JOIN fact_orders fo ON oi.order_id = fo.order_id
GROUP BY 1
ORDER BY 1;

-- 5. Annual revenue (note: 2016 and 2018 are partial years)
SELECT
    EXTRACT(YEAR FROM fo.order_purchase_timestamp)::int AS revenue_year,
    ROUND(SUM(oi.price)::numeric, 2)                    AS annual_revenue
FROM fact_order_items oi
JOIN fact_orders fo ON oi.order_id = fo.order_id
GROUP BY 1
ORDER BY 1;

----------------------------------------------------------------------------
-- SECTION C : REVENUE BY CATEGORY
----------------------------------------------------------------------------

-- 6. Revenue by product category (top 20)
SELECT
    COALESCE(dp.product_category_name, '(unknown)') AS product_category_name,
    ROUND(SUM(oi.price)::numeric, 2)                AS category_revenue,
    COUNT(DISTINCT oi.order_id)                     AS orders
FROM fact_order_items oi
LEFT JOIN dim_products dp ON oi.product_id = dp.product_id
GROUP BY 1
ORDER BY category_revenue DESC
LIMIT 20;

----------------------------------------------------------------------------
-- SECTION D : REVENUE BY GEOGRAPHY
----------------------------------------------------------------------------

-- 7. Revenue by customer state (top 10)
SELECT
    dc.customer_state,
    ROUND(SUM(oi.price)::numeric, 2) AS state_revenue
FROM fact_order_items oi
JOIN fact_orders fo ON oi.order_id = fo.order_id
JOIN dim_customers dc ON fo.customer_id = dc.customer_id
GROUP BY 1
ORDER BY state_revenue DESC
LIMIT 10;
