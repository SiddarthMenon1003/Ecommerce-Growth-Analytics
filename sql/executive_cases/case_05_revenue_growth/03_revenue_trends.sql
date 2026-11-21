/*
===============================================================================
CASE 05 - REVENUE GROWTH

STEP 03 - REVENUE TRENDS

Objective:
Measure the direction and momentum of revenue over time: month-over-month and
year-over-year growth, and whether growth is driven by new or returning customers.
===============================================================================
*/

----------------------------------------------------------------------------
-- SECTION A : MONTHLY REVENUE WITH MOM GROWTH
----------------------------------------------------------------------------

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', fo.order_purchase_timestamp)::date AS revenue_month,
        SUM(oi.price)::numeric AS revenue
    FROM fact_order_items oi
    JOIN fact_orders fo ON oi.order_id = fo.order_id
    WHERE fo.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
)
SELECT
    revenue_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY revenue_month), 2) AS prev_month_revenue,
    ROUND(
        CASE WHEN LAG(revenue) OVER (ORDER BY revenue_month) > 0
             THEN (revenue - LAG(revenue) OVER (ORDER BY revenue_month))
                  / LAG(revenue) OVER (ORDER BY revenue_month) * 100
        END, 1
    ) AS mom_growth_pct
FROM monthly
ORDER BY revenue_month;

----------------------------------------------------------------------------
-- SECTION B : YEAR-OVER-YEAR BY MONTH
----------------------------------------------------------------------------

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', fo.order_purchase_timestamp)::date AS revenue_month,
        SUM(oi.price)::numeric AS revenue
    FROM fact_order_items oi
    JOIN fact_orders fo ON oi.order_id = fo.order_id
    GROUP BY 1
)
SELECT
    revenue_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(LAG(revenue, 12) OVER (ORDER BY revenue_month), 2) AS same_month_prev_year,
    ROUND(
        CASE WHEN LAG(revenue, 12) OVER (ORDER BY revenue_month) > 0
             THEN (revenue - LAG(revenue, 12) OVER (ORDER BY revenue_month))
                  / LAG(revenue, 12) OVER (ORDER BY revenue_month) * 100
        END, 1
    ) AS yoy_growth_pct
FROM monthly
ORDER BY revenue_month;

----------------------------------------------------------------------------
-- SECTION C : NEW vs RETURNING CUSTOMER REVENUE BY MONTH
----------------------------------------------------------------------------
-- Splits monthly revenue into first-ever purchase (new) vs later purchases
-- (returning), to show whether growth is acquisition-led or retention-led.

WITH customer_first AS (
    SELECT
        dc.customer_unique_id,
        MIN(fo.order_purchase_timestamp) AS first_purchase
    FROM fact_orders fo
    JOIN dim_customers dc ON fo.customer_id = dc.customer_id
    GROUP BY dc.customer_unique_id
),
order_revenue AS (
    SELECT
        fo.order_id,
        fo.order_purchase_timestamp,
        dc.customer_unique_id,
        SUM(oi.price) AS order_revenue
    FROM fact_orders fo
    JOIN dim_customers dc ON fo.customer_id = dc.customer_id
    JOIN fact_order_items oi ON fo.order_id = oi.order_id
    GROUP BY fo.order_id, fo.order_purchase_timestamp, dc.customer_unique_id
)
SELECT
    DATE_TRUNC('month', orr.order_purchase_timestamp)::date AS revenue_month,
    ROUND(SUM(orr.order_revenue) FILTER (
        WHERE orr.order_purchase_timestamp = cf.first_purchase)::numeric, 2) AS new_customer_revenue,
    ROUND(SUM(orr.order_revenue) FILTER (
        WHERE orr.order_purchase_timestamp > cf.first_purchase)::numeric, 2) AS returning_customer_revenue
FROM order_revenue orr
JOIN customer_first cf ON orr.customer_unique_id = cf.customer_unique_id
GROUP BY 1
ORDER BY 1;
