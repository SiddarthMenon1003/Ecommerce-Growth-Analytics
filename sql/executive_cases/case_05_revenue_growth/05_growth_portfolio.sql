/*
===============================================================================
CASE 05 - REVENUE GROWTH

STEP 05 - GROWTH PORTFOLIO MATRIX

Objective:
Place each material category on a revenue (size) x growth (momentum) grid and
assign a portfolio role, to guide where to invest, defend, or divest.

Quadrants (growth-share style):
  STAR         - high revenue, high growth   -> invest / scale
  CASH COW     - high revenue, low growth    -> defend / harvest
  QUESTION     - low revenue,  high growth   -> test / selective bets
  LOW PRIORITY - low revenue,  low growth    -> maintain / divest
===============================================================================
*/

WITH bounds AS (
    SELECT MAX(order_purchase_timestamp)::date AS max_date FROM fact_orders
),
item_rev AS (
    SELECT
        COALESCE(dp.product_category_name, '(unknown)') AS product_category_name,
        fo.order_purchase_timestamp::date AS d,
        oi.price
    FROM fact_order_items oi
    JOIN fact_orders fo ON oi.order_id = fo.order_id
    LEFT JOIN dim_products dp ON oi.product_id = dp.product_id
),
cat AS (
    SELECT
        ir.product_category_name,
        SUM(ir.price) AS total_revenue,
        SUM(ir.price) FILTER (
            WHERE ir.d > b.max_date - INTERVAL '6 months') AS recent_6m,
        SUM(ir.price) FILTER (
            WHERE ir.d <= b.max_date - INTERVAL '6 months'
              AND ir.d >  b.max_date - INTERVAL '12 months') AS prior_6m
    FROM item_rev ir
    CROSS JOIN bounds b
    GROUP BY ir.product_category_name
),
scored AS (
    SELECT
        product_category_name,
        ROUND(total_revenue::numeric, 2) AS total_revenue,
        ROUND(
            CASE WHEN prior_6m > 0
                 THEN (recent_6m - prior_6m) / prior_6m * 100 END, 1
        ) AS growth_pct,
        PERCENT_RANK() OVER (ORDER BY total_revenue) AS revenue_pctile,
        PERCENT_RANK() OVER (ORDER BY
            CASE WHEN prior_6m > 0 THEN (recent_6m - prior_6m) / prior_6m END
        ) AS growth_pctile
    FROM cat
    WHERE total_revenue > 50000
)
SELECT
    product_category_name,
    total_revenue,
    growth_pct,
    CASE
        WHEN revenue_pctile >= 0.5 AND growth_pctile >= 0.5 THEN 'STAR'
        WHEN revenue_pctile >= 0.5 AND growth_pctile <  0.5 THEN 'CASH COW'
        WHEN revenue_pctile <  0.5 AND growth_pctile >= 0.5 THEN 'QUESTION'
        ELSE 'LOW PRIORITY'
    END AS portfolio_role
FROM scored
ORDER BY total_revenue DESC;
