/*
===============================================================================
CASE 05 - REVENUE GROWTH

STEP 01 - DATA VALIDATION

Objective:
Confirm the revenue, product, and date fields used for growth analysis are
complete and trustworthy before measuring trends and category performance.
===============================================================================
*/

----------------------------------------------------------------------------
-- SECTION A : ROW COUNTS
----------------------------------------------------------------------------

-- 1. Order item rows (grain of product revenue)
SELECT COUNT(*) AS order_item_rows FROM fact_order_items;

-- 2. Orders and payments
SELECT COUNT(*) AS orders FROM fact_orders;
SELECT COUNT(*) AS payments FROM fact_payments;

----------------------------------------------------------------------------
-- SECTION B : REVENUE FIELD QUALITY
----------------------------------------------------------------------------

-- 3. Null or non-positive item prices (should be ~0)
SELECT
    COUNT(*)                                              AS item_rows,
    COUNT(*) FILTER (WHERE price IS NULL)                 AS null_price,
    COUNT(*) FILTER (WHERE price <= 0)                    AS non_positive_price
FROM fact_order_items;

-- 4. Item revenue vs order payment revenue (reconciliation)
SELECT
    ROUND(SUM(oi.price)::numeric, 2)   AS item_price_revenue,
    (SELECT ROUND(SUM(payment_value)::numeric, 2) FROM fact_payments) AS payment_revenue
FROM fact_order_items oi;

----------------------------------------------------------------------------
-- SECTION C : CATEGORY COVERAGE
----------------------------------------------------------------------------

-- 5. Items with missing product category
SELECT
    COUNT(*)                                                       AS item_rows,
    COUNT(*) FILTER (WHERE dp.product_category_name IS NULL)       AS missing_category
FROM fact_order_items oi
LEFT JOIN dim_products dp ON oi.product_id = dp.product_id;

-- 6. Distinct categories
SELECT COUNT(DISTINCT product_category_name) AS distinct_categories
FROM dim_products;

----------------------------------------------------------------------------
-- SECTION D : DATE RANGE
----------------------------------------------------------------------------

-- 7. Purchase date span (note: first/last months are typically partial)
SELECT
    MIN(order_purchase_timestamp)::date AS first_purchase,
    MAX(order_purchase_timestamp)::date AS last_purchase
FROM fact_orders;

-- 8. Orders per month (spot partial months at the edges)
SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::date AS revenue_month,
    COUNT(*) AS orders
FROM fact_orders
GROUP BY 1
ORDER BY 1;
