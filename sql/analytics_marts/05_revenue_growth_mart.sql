/*
===============================================================================
ANALYTICS MART 05 - REVENUE GROWTH

Grain: ONE ROW PER (product_category_name, revenue_month).

Purpose:
Powers the Case 05 Revenue Growth analysis and dashboard page. Provides monthly
category-level revenue with month-over-month and year-over-year growth, revenue
rank, and the inputs for a growth-portfolio (revenue x growth) matrix.

Revenue definition:
Category/product revenue = SUM(fact_order_items.price). This is item-level product
revenue and is intentionally separate from order-level payment_value (which also
includes freight and installment effects). Canceled/unavailable orders are excluded.

PBI: relate on product_category_name (to Dim Products) and revenue_month (to Dim Date).
===============================================================================
*/

DROP TABLE IF EXISTS revenue_growth_mart;
CREATE TABLE revenue_growth_mart AS
WITH item_revenue AS (
    SELECT
        fo.order_id,
        DATE_TRUNC('month', fo.order_purchase_timestamp)::date AS revenue_month,
        COALESCE(dp.product_category_name, '(unknown)')        AS product_category_name,
        oi.price
    FROM fact_order_items oi
    JOIN fact_orders fo
        ON oi.order_id = fo.order_id
    LEFT JOIN dim_products dp
        ON oi.product_id = dp.product_id
    WHERE fo.order_status NOT IN ('canceled', 'unavailable')
),
monthly AS (
    SELECT
        product_category_name,
        revenue_month,
        ROUND(SUM(price)::numeric, 2)   AS monthly_revenue,
        COUNT(DISTINCT order_id)        AS monthly_orders,
        COUNT(*)                        AS monthly_items
    FROM item_revenue
    GROUP BY
        product_category_name,
        revenue_month
),
with_growth AS (
    SELECT
        m.*,
        LAG(monthly_revenue) OVER (
            PARTITION BY product_category_name ORDER BY revenue_month
        ) AS prev_month_revenue,
        LAG(monthly_revenue, 12) OVER (
            PARTITION BY product_category_name ORDER BY revenue_month
        ) AS prev_year_revenue
    FROM monthly m
),
category_totals AS (
    SELECT
        product_category_name,
        SUM(monthly_revenue) AS category_total_revenue
    FROM monthly
    GROUP BY product_category_name
)
SELECT
    g.product_category_name,
    g.revenue_month,
    EXTRACT(YEAR  FROM g.revenue_month)::int  AS revenue_year,
    EXTRACT(MONTH FROM g.revenue_month)::int  AS revenue_month_num,
    g.monthly_revenue,
    g.monthly_orders,
    g.monthly_items,
    g.prev_month_revenue,
    ROUND(
        CASE WHEN g.prev_month_revenue > 0
             THEN (g.monthly_revenue - g.prev_month_revenue) / g.prev_month_revenue * 100
        END, 1
    ) AS mom_growth_pct,
    g.prev_year_revenue,
    ROUND(
        CASE WHEN g.prev_year_revenue > 0
             THEN (g.monthly_revenue - g.prev_year_revenue) / g.prev_year_revenue * 100
        END, 1
    ) AS yoy_growth_pct,
    ct.category_total_revenue,
    DENSE_RANK() OVER (ORDER BY ct.category_total_revenue DESC) AS category_revenue_rank
FROM with_growth g
JOIN category_totals ct
    ON g.product_category_name = ct.product_category_name;
