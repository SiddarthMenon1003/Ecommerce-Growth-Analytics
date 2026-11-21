/*
===============================================================================
CASE 05 - REVENUE GROWTH

STEP 04 - CATEGORY PERFORMANCE

Objective:
Identify which product categories carry the business, how concentrated revenue
is across the catalogue, and which categories are gaining or losing momentum.
===============================================================================
*/

----------------------------------------------------------------------------
-- SECTION A : CATEGORY REVENUE + PARETO CONCENTRATION
----------------------------------------------------------------------------

WITH category_rev AS (
    SELECT
        COALESCE(dp.product_category_name, '(unknown)') AS product_category_name,
        SUM(oi.price)::numeric AS category_revenue,
        COUNT(DISTINCT oi.order_id) AS orders
    FROM fact_order_items oi
    LEFT JOIN dim_products dp ON oi.product_id = dp.product_id
    GROUP BY 1
),
ranked AS (
    SELECT
        product_category_name,
        ROUND(category_revenue, 2) AS category_revenue,
        orders,
        DENSE_RANK() OVER (ORDER BY category_revenue DESC) AS revenue_rank,
        ROUND(category_revenue / SUM(category_revenue) OVER () * 100, 2) AS pct_of_revenue,
        ROUND(
            SUM(category_revenue) OVER (ORDER BY category_revenue DESC)
            / SUM(category_revenue) OVER () * 100, 2
        ) AS cumulative_pct
    FROM category_rev
)
SELECT *
FROM ranked
ORDER BY revenue_rank;

----------------------------------------------------------------------------
-- SECTION B : HOW MANY CATEGORIES MAKE 80% OF REVENUE
----------------------------------------------------------------------------

WITH category_rev AS (
    SELECT
        COALESCE(dp.product_category_name, '(unknown)') AS product_category_name,
        SUM(oi.price)::numeric AS category_revenue
    FROM fact_order_items oi
    LEFT JOIN dim_products dp ON oi.product_id = dp.product_id
    GROUP BY 1
),
cumulative AS (
    SELECT
        product_category_name,
        SUM(category_revenue) OVER (ORDER BY category_revenue DESC)
            / SUM(category_revenue) OVER () AS cumulative_share
    FROM category_rev
)
SELECT
    COUNT(*) FILTER (WHERE cumulative_share <= 0.80) + 1 AS categories_for_80pct,
    COUNT(*)                                             AS total_categories
FROM cumulative;

----------------------------------------------------------------------------
-- SECTION C : CATEGORY MOMENTUM (same-period year-over-year)
----------------------------------------------------------------------------
-- Compares each category's current-year revenue to the prior year over the
-- SAME calendar months, ending at the last COMPLETE month in the data. This
-- avoids two traps that distort a naive trailing-6-month view: seasonality
-- (the Nov Black Friday peak) and the partial final month of the dataset.

WITH cur_year AS (
    SELECT MAX(EXTRACT(YEAR FROM order_purchase_timestamp))::int AS yr
    FROM fact_orders
),
cutoff AS (
    -- last complete month of the current year = max month present minus 1
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
)
SELECT
    ir.product_category_name,
    ROUND(SUM(ir.price) FILTER (
        WHERE ir.yr = cy.yr     AND ir.mo <= co.mo)::numeric, 2) AS current_ytd_revenue,
    ROUND(SUM(ir.price) FILTER (
        WHERE ir.yr = cy.yr - 1 AND ir.mo <= co.mo)::numeric, 2) AS prior_ytd_revenue,
    ROUND((
        100.0 * (SUM(ir.price) FILTER (WHERE ir.yr = cy.yr     AND ir.mo <= co.mo)
               - SUM(ir.price) FILTER (WHERE ir.yr = cy.yr - 1 AND ir.mo <= co.mo))
        / NULLIF(SUM(ir.price) FILTER (WHERE ir.yr = cy.yr - 1 AND ir.mo <= co.mo), 0)
    )::numeric, 1) AS yoy_growth_pct
FROM item_rev ir
CROSS JOIN cur_year cy
CROSS JOIN cutoff co
GROUP BY ir.product_category_name, cy.yr, co.mo
HAVING SUM(ir.price) FILTER (WHERE ir.yr = cy.yr - 1 AND ir.mo <= co.mo) > 30000
ORDER BY yoy_growth_pct DESC NULLS LAST;
