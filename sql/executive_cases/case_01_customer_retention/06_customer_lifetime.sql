/*
===============================================================================
CASE 01 – CUSTOMER RETENTION STRATEGY

STEP 06 – CUSTOMER LIFETIME VALUE ANALYSIS

Objective:
Identify the most valuable customers by analyzing lifetime revenue,
purchase behaviour, customer lifespan, and spending patterns.

===============================================================================
*/

----------------------------------------------------------------------------
-- SECTION A : CUSTOMER LIFETIME REVENUE
----------------------------------------------------------------------------

-- QUERY 1 : Lifetime Revenue by Customer

WITH customer_metrics AS (

    SELECT

        dc.customer_unique_id,

        SUM(fp.payment_value) AS lifetime_revenue,

        COUNT(DISTINCT fo.order_id) AS total_orders

    FROM fact_orders fo

    JOIN dim_customers dc

        ON fo.customer_id = dc.customer_id

    JOIN fact_payments fp

        ON fo.order_id = fp.order_id

    GROUP BY

        dc.customer_unique_id

)

SELECT

    customer_unique_id,

    ROUND(lifetime_revenue::NUMERIC,2) AS lifetime_revenue,

    total_orders

FROM customer_metrics

ORDER BY lifetime_revenue DESC

LIMIT 20;

----------------------------------------------------------------------------
-- SECTION B : CUSTOMER LIFESPAN
----------------------------------------------------------------------------

-- QUERY 2 : Customer Lifespan

SELECT

    dc.customer_unique_id,

    MIN(fo.order_purchase_timestamp) AS first_purchase,

    MAX(fo.order_purchase_timestamp) AS last_purchase,

    MAX(fo.order_purchase_timestamp)::DATE
        -
    MIN(fo.order_purchase_timestamp)::DATE
        AS customer_lifespan_days

FROM fact_orders fo

JOIN dim_customers dc

ON fo.customer_id = dc.customer_id

GROUP BY

    dc.customer_unique_id

ORDER BY customer_lifespan_days DESC

LIMIT 20;

----------------------------------------------------------------------------
-- SECTION C : AVERAGE ORDER VALUE
----------------------------------------------------------------------------

-- QUERY 3 : Average Order Value per Customer

SELECT

    dc.customer_unique_id,

    ROUND(

        SUM(fp.payment_value)::NUMERIC

        /

        COUNT(DISTINCT fo.order_id),

        2

    ) AS average_order_value,

    COUNT(DISTINCT fo.order_id) AS total_orders

FROM fact_orders fo

JOIN dim_customers dc

ON fo.customer_id = dc.customer_id

JOIN fact_payments fp

ON fo.order_id = fp.order_id

GROUP BY

    dc.customer_unique_id

ORDER BY average_order_value DESC

LIMIT 20;

----------------------------------------------------------------------------
-- SECTION D : CUSTOMER VALUE SEGMENTATION
----------------------------------------------------------------------------

-- QUERY 4 : Customer Value Segments

WITH customer_revenue AS (

    SELECT

        dc.customer_unique_id,

        SUM(fp.payment_value) AS lifetime_revenue

    FROM fact_orders fo

    JOIN dim_customers dc

        ON fo.customer_id = dc.customer_id

    JOIN fact_payments fp

        ON fo.order_id = fp.order_id

    GROUP BY

        dc.customer_unique_id

)

SELECT

    CASE

        WHEN lifetime_revenue >= 5000 THEN 'Platinum'

        WHEN lifetime_revenue >= 2000 THEN 'Gold'

        WHEN lifetime_revenue >= 500 THEN 'Silver'

        ELSE 'Bronze'

    END AS customer_segment,

    COUNT(*) AS customers,

    ROUND(

        AVG(lifetime_revenue)::NUMERIC,

        2

    ) AS average_customer_value

FROM customer_revenue

GROUP BY customer_segment

ORDER BY average_customer_value DESC;

----------------------------------------------------------------------------
-- SECTION E : CUSTOMER VALUE DISTRIBUTION
----------------------------------------------------------------------------

-- QUERY 5 : Revenue Statistics

WITH customer_revenue AS (

    SELECT

        dc.customer_unique_id,

        SUM(fp.payment_value) AS lifetime_revenue

    FROM fact_orders fo

    JOIN dim_customers dc

        ON fo.customer_id = dc.customer_id

    JOIN fact_payments fp

        ON fo.order_id = fp.order_id

    GROUP BY

        dc.customer_unique_id

)

SELECT

    ROUND(MIN(lifetime_revenue)::NUMERIC,2) AS minimum_value,

    ROUND(MAX(lifetime_revenue)::NUMERIC,2) AS maximum_value,

    ROUND(AVG(lifetime_revenue)::NUMERIC,2) AS average_value,

    ROUND(

        PERCENTILE_CONT(0.5)

        WITHIN GROUP (

            ORDER BY lifetime_revenue

        )::NUMERIC,

        2

    ) AS median_value

FROM customer_revenue;

----------------------------------------------------------------------------
-- SECTION F : EXECUTIVE SUMMARY
----------------------------------------------------------------------------

-- QUERY 6 : Overall Customer Value Metrics

WITH customer_summary AS (

    SELECT

        dc.customer_unique_id,

        SUM(fp.payment_value) AS lifetime_revenue,

        COUNT(DISTINCT fo.order_id) AS total_orders

    FROM fact_orders fo

    JOIN dim_customers dc

        ON fo.customer_id = dc.customer_id

    JOIN fact_payments fp

        ON fo.order_id = fp.order_id

    GROUP BY

        dc.customer_unique_id

)

SELECT

    COUNT(*) AS total_customers,

    ROUND(AVG(lifetime_revenue)::NUMERIC,2) AS average_customer_value,

    ROUND(AVG(total_orders)::NUMERIC,2) AS average_orders,

    ROUND(

        SUM(lifetime_revenue)::NUMERIC,

        2

    ) AS total_revenue

FROM customer_summary;