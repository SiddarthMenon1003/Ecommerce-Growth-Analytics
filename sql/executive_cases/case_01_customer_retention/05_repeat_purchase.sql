/*
===============================================================================
CASE 01 – CUSTOMER RETENTION STRATEGY

STEP 05 – REPEAT PURCHASE ANALYSIS

Objective:
Measure repeat purchasing behaviour to understand customer loyalty and identify
opportunities to improve customer retention.

===============================================================================
*/

----------------------------------------------------------------------------
-- SECTION A : PURCHASE FREQUENCY DISTRIBUTION
----------------------------------------------------------------------------

-- QUERY 1 : Number of Purchases per Customer

WITH customer_purchase_counts AS (
    SELECT
        dc.customer_unique_id,
        COUNT(fo.order_id) AS purchase_count
    FROM fact_orders fo
    JOIN dim_customers dc
        ON fo.customer_id = dc.customer_id
    GROUP BY
        dc.customer_unique_id
)
SELECT
    purchase_count,
    COUNT(*) AS customers,
    ROUND(
        (COUNT(*)::NUMERIC /
        SUM(COUNT(*)) OVER()) * 100,
        2
    ) AS customer_percentage
FROM customer_purchase_counts
GROUP BY purchase_count
ORDER BY purchase_count;

----------------------------------------------------------------------------
-- SECTION B : CUSTOMER SEGMENTATION
----------------------------------------------------------------------------

-- QUERY 2 : One-Time vs Repeat Customers

WITH customer_purchase_counts AS (
    SELECT
        dc.customer_unique_id,
        COUNT(fo.order_id) AS purchase_count
    FROM fact_orders fo
    JOIN dim_customers dc
        ON fo.customer_id = dc.customer_id
    GROUP BY
        dc.customer_unique_id
)
SELECT
    CASE
        WHEN purchase_count = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*)::NUMERIC /
        SUM(COUNT(*)) OVER() * 100,
        2
    ) AS percentage
FROM customer_purchase_counts
GROUP BY customer_type
ORDER BY total_customers DESC;

----------------------------------------------------------------------------
-- SECTION C : PURCHASE FREQUENCY METRICS
----------------------------------------------------------------------------

-- QUERY 3 : Average Purchases per Customer

SELECT
    ROUND(
        AVG(purchase_count)::NUMERIC,
        2
    ) AS average_purchases
FROM (
    SELECT
        dc.customer_unique_id,
        COUNT(fo.order_id) AS purchase_count
    FROM fact_orders fo
    JOIN dim_customers dc
        ON fo.customer_id = dc.customer_id
    GROUP BY
        dc.customer_unique_id
) customer_orders;

----------------------------------------------------------------------------
-- SECTION D : HIGH VALUE CUSTOMERS
----------------------------------------------------------------------------

-- QUERY 4 : Customers with 5 or More Purchases

WITH customer_purchase_counts AS (
    SELECT
        dc.customer_unique_id,
        COUNT(fo.order_id) AS purchase_count
    FROM fact_orders fo
    JOIN dim_customers dc
        ON fo.customer_id = dc.customer_id
    GROUP BY
        dc.customer_unique_id
)
SELECT
    COUNT(*) AS customers_with_five_plus_orders
FROM customer_purchase_counts
WHERE purchase_count >= 5;

----------------------------------------------------------------------------
-- SECTION E : PURCHASE FREQUENCY SUMMARY
----------------------------------------------------------------------------

-- QUERY 5 : Purchase Statistics

WITH customer_purchase_counts AS (
    SELECT
        dc.customer_unique_id,
        COUNT(fo.order_id) AS purchase_count
    FROM fact_orders fo
    JOIN dim_customers dc
        ON fo.customer_id = dc.customer_id
    GROUP BY
        dc.customer_unique_id
)
SELECT
    MIN(purchase_count) AS minimum_orders,
    MAX(purchase_count) AS maximum_orders,
    ROUND(AVG(purchase_count)::NUMERIC,2) AS average_orders,
    PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY purchase_count)
        AS median_orders
FROM customer_purchase_counts;

----------------------------------------------------------------------------
-- SECTION F : TOP REPEAT CUSTOMERS
----------------------------------------------------------------------------

-- QUERY 6 : Customers with the Highest Purchase Frequency

SELECT
    dc.customer_unique_id,
    COUNT(fo.order_id) AS total_orders
FROM fact_orders fo
JOIN dim_customers dc
    ON fo.customer_id = dc.customer_id
GROUP BY
    dc.customer_unique_id
ORDER BY total_orders DESC
LIMIT 20;
