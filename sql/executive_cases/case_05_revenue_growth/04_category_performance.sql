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
-- SECTION C : CATEGORY MOMENTUM (recent half vs prior half)
----------------------------------------------------------------------------
-- Compares each category's revenue in the most recent 6 months of data against
-- the prior 6 months, to flag accelerating vs declining categories.

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
)
SELECT
    ir.product_category_name,
    ROUND(SUM(ir.price) FILTER (
        WHERE ir.d > b.max_date - INTERVAL '6 months')::numeric, 2) AS recent_6m_revenue,
    ROUND(SUM(ir.price) FILTER (
        WHERE ir.d <= b.max_date - INTERVAL '6 months'
          AND ir.d >  b.max_date - INTERVAL '12 months')::numeric, 2) AS prior_6m_revenue,
    ROUND(
        CASE WHEN SUM(ir.price) FILTER (
                WHERE ir.d <= b.max_date - INTERVAL '6 months'
                  AND ir.d >  b.max_date - INTERVAL '12 months') > 0
             THEN (SUM(ir.price) FILTER (WHERE ir.d > b.max_date - INTERVAL '6 months')
                 - SUM(ir.price) FILTER (WHERE ir.d <= b.max_date - INTERVAL '6 months'
                                           AND ir.d >  b.max_date - INTERVAL '12 months'))
                 / SUM(ir.price) FILTER (WHERE ir.d <= b.max_date - INTERVAL '6 months'
                                           AND ir.d >  b.max_date - INTERVAL '12 months') * 100
        END, 1
    ) AS growth_pct
FROM item_rev ir
CROSS JOIN bounds b
GROUP BY ir.product_category_name
HAVING SUM(ir.price) > 50000          -- focus on material categories
ORDER BY growth_pct DESC NULLS LAST;
