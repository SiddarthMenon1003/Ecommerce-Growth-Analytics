/*
===============================================================================
CASE 05 - REVENUE GROWTH

STEP 05 - GROWTH PORTFOLIO MATRIX

Objective:
Place each material category on a revenue (size) x growth (momentum) grid and
assign a portfolio role, to guide where to invest, defend, or divest.

Momentum = same-period year-over-year (current year vs prior year over the same
calendar months, ending at the last complete month) - this avoids seasonality
and partial-month distortion from a naive trailing-window comparison.

Quadrants (growth-share style):
  STAR         - high revenue, high growth   -> invest / scale
  CASH COW     - high revenue, low growth    -> defend / harvest
  QUESTION     - low revenue,  high growth   -> test / selective bets
  LOW PRIORITY - low revenue,  low growth    -> maintain / divest
===============================================================================
*/

WITH cur_year AS (
    SELECT MAX(EXTRACT(YEAR FROM order_purchase_timestamp))::int AS yr
    FROM fact_orders
),
cutoff AS (
    SELECT MAX(EXTRACT(MONTH FROM fo.order_purchase_timestamp))::int - 1 AS mo
    FROM fact_orders fo
    CROSS JOIN cur_year cy
    WHERE EXTRACT(YEAR FROM fo.order_purchase_timestamp) = cy.yr
),
item_rev AS (
    SELECT
        COALESCE(dp.product_category_name, '(unknown)') AS product_category_name,
        EXTRACT(YEAR  FROM fo.order_purchase_timestamp)::int AS yr,
        EXTRACT(MONTH FROM fo.order_purchase_timestamp)::int AS mo,
        oi.price
    FROM fact_order_items oi
    JOIN fact_orders fo ON oi.order_id = fo.order_id
    LEFT JOIN dim_products dp ON oi.product_id = dp.product_id
),
cat AS (
    SELECT
        ir.product_category_name,
        SUM(ir.price) AS total_revenue,
        SUM(ir.price) FILTER (WHERE ir.yr = cy.yr     AND ir.mo <= co.mo) AS current_ytd,
        SUM(ir.price) FILTER (WHERE ir.yr = cy.yr - 1 AND ir.mo <= co.mo) AS prior_ytd
    FROM item_rev ir
    CROSS JOIN cur_year cy
    CROSS JOIN cutoff co
    GROUP BY ir.product_category_name
),
scored AS (
    SELECT
        product_category_name,
        ROUND(total_revenue::numeric, 2) AS total_revenue,
        ROUND((
            CASE WHEN prior_ytd > 0
                 THEN (current_ytd - prior_ytd) / prior_ytd * 100 END
        )::numeric, 1) AS yoy_growth_pct,
        PERCENT_RANK() OVER (ORDER BY total_revenue) AS revenue_pctile,
        PERCENT_RANK() OVER (ORDER BY
            CASE WHEN prior_ytd > 0 THEN (current_ytd - prior_ytd) / prior_ytd END
        ) AS growth_pctile
    FROM cat
    WHERE total_revenue > 50000
      AND prior_ytd > 0           -- need a prior-year base to score momentum
)
SELECT
    product_category_name,
    total_revenue,
    yoy_growth_pct,
    CASE
        WHEN revenue_pctile >= 0.5 AND growth_pctile >= 0.5 THEN 'STAR'
        WHEN revenue_pctile >= 0.5 AND growth_pctile <  0.5 THEN 'CASH COW'
        WHEN revenue_pctile <  0.5 AND growth_pctile >= 0.5 THEN 'QUESTION'
        ELSE 'LOW PRIORITY'
    END AS portfolio_role
FROM scored
ORDER BY total_revenue DESC;
