/*
===============================================================================
CASE 05 - REVENUE GROWTH

STEP 06 - BUSINESS IMPACT

Objective:
Quantify where future revenue can realistically come from and size the upside of
two levers: (1) lifting repeat revenue, and (2) concentration risk in the
category portfolio.
===============================================================================
*/

----------------------------------------------------------------------------
-- SECTION A : NEW vs RETURNING REVENUE SPLIT (whole period)
----------------------------------------------------------------------------
-- How dependent is total revenue on first-time purchases?

WITH customer_first AS (
    SELECT dc.customer_unique_id, MIN(fo.order_purchase_timestamp) AS first_purchase
    FROM fact_orders fo
    JOIN dim_customers dc ON fo.customer_id = dc.customer_id
    GROUP BY dc.customer_unique_id
),
order_revenue AS (
    SELECT
        fo.order_id, fo.order_purchase_timestamp, dc.customer_unique_id,
        SUM(oi.price) AS order_revenue
    FROM fact_orders fo
    JOIN dim_customers dc ON fo.customer_id = dc.customer_id
    JOIN fact_order_items oi ON fo.order_id = oi.order_id
    GROUP BY fo.order_id, fo.order_purchase_timestamp, dc.customer_unique_id
)
SELECT
    ROUND(SUM(order_revenue) FILTER (
        WHERE orr.order_purchase_timestamp = cf.first_purchase)::numeric, 2) AS new_revenue,
    ROUND(SUM(order_revenue) FILTER (
        WHERE orr.order_purchase_timestamp > cf.first_purchase)::numeric, 2) AS returning_revenue,
    ROUND(100.0 * SUM(order_revenue) FILTER (
        WHERE orr.order_purchase_timestamp > cf.first_purchase)
        / SUM(order_revenue), 1) AS returning_share_pct
FROM order_revenue orr
JOIN customer_first cf ON orr.customer_unique_id = cf.customer_unique_id;

----------------------------------------------------------------------------
-- SECTION B : REPEAT-REVENUE UPSIDE (scenario sizing)
----------------------------------------------------------------------------
-- If the share of customers who make a 2nd purchase rose from its current level
-- to a target, how much incremental revenue could that add? Uses current average
-- revenue per repeat vs one-time customer as the value gap.

WITH customer_value AS (
    SELECT
        dc.customer_unique_id,
        COUNT(DISTINCT fo.order_id) AS orders,
        SUM(oi.price)               AS revenue
    FROM fact_orders fo
    JOIN dim_customers dc ON fo.customer_id = dc.customer_id
    JOIN fact_order_items oi ON fo.order_id = oi.order_id
    GROUP BY dc.customer_unique_id
),
base AS (
    SELECT
        COUNT(*)                                             AS customers,
        COUNT(*) FILTER (WHERE orders > 1)                   AS repeat_customers,
        AVG(revenue) FILTER (WHERE orders > 1)               AS avg_repeat_rev,
        AVG(revenue) FILTER (WHERE orders = 1)               AS avg_onetime_rev
    FROM customer_value
)
SELECT
    customers,
    repeat_customers,
    ROUND(100.0 * repeat_customers / customers, 2)           AS current_repeat_pct,
    ROUND(avg_repeat_rev::numeric, 2)                        AS avg_repeat_revenue,
    ROUND(avg_onetime_rev::numeric, 2)                       AS avg_onetime_revenue,
    -- upside if repeat rate reaches 10%: extra repeaters x value gap
    ROUND(
        GREATEST(ROUND(0.10 * customers) - repeat_customers, 0)
        * (avg_repeat_rev - avg_onetime_rev)::numeric, 2
    ) AS upside_if_repeat_rate_10pct
FROM base;

----------------------------------------------------------------------------
-- SECTION C : CATEGORY CONCENTRATION RISK
----------------------------------------------------------------------------
-- Share of revenue held by the top 5 and top 10 categories.

WITH category_rev AS (
    SELECT
        COALESCE(dp.product_category_name, '(unknown)') AS product_category_name,
        SUM(oi.price) AS category_revenue
    FROM fact_order_items oi
    LEFT JOIN dim_products dp ON oi.product_id = dp.product_id
    GROUP BY 1
),
ranked AS (
    SELECT category_revenue,
           ROW_NUMBER() OVER (ORDER BY category_revenue DESC) AS rn,
           SUM(category_revenue) OVER () AS total
    FROM category_rev
)
SELECT
    ROUND(100.0 * SUM(category_revenue) FILTER (WHERE rn <= 5)  / MAX(total), 1) AS top5_share_pct,
    ROUND(100.0 * SUM(category_revenue) FILTER (WHERE rn <= 10) / MAX(total), 1) AS top10_share_pct
FROM ranked;
