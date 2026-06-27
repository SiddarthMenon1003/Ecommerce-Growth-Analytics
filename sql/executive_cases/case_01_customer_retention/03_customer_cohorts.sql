/*
===============================================================================
CASE 01 – CUSTOMER RETENTION STRATEGY

STEP 03 – CUSTOMER COHORT ANALYSIS

Business Question:
How well does the company retain customers after their first purchase?

Business Value:
Identify customer retention patterns by grouping customers according to
their first purchase month and tracking repeat purchases over time.

Expected Output:
Monthly customer cohorts with active customer counts across subsequent months.

===============================================================================
*/

----------------------------------------------------------------------------
-- STEP 1 : Identify Each Customer's First Purchase Month
----------------------------------------------------------------------------

WITH first_purchase AS (

    SELECT

        dc.customer_unique_id,

        DATE_TRUNC(
            'month',
            MIN(fo.order_purchase_timestamp)
        ) AS cohort_month

    FROM fact_orders fo

    JOIN dim_customers dc

        ON fo.customer_id = dc.customer_id

    GROUP BY

        dc.customer_unique_id

),

----------------------------------------------------------------------------
-- STEP 2 : Associate Every Order With Its Customer Cohort
----------------------------------------------------------------------------

customer_orders AS (

    SELECT

        dc.customer_unique_id,

        fp.cohort_month,

        DATE_TRUNC(
            'month',
            fo.order_purchase_timestamp
        ) AS purchase_month

    FROM fact_orders fo

    JOIN dim_customers dc

        ON fo.customer_id = dc.customer_id

    JOIN first_purchase fp

        ON dc.customer_unique_id = fp.customer_unique_id

),

----------------------------------------------------------------------------
-- STEP 3 : Calculate Months Since First Purchase
----------------------------------------------------------------------------

cohort_activity AS (

    SELECT

        cohort_month,

        purchase_month,

        (
            EXTRACT(YEAR FROM AGE(purchase_month, cohort_month)) * 12
            +
            EXTRACT(MONTH FROM AGE(purchase_month, cohort_month))
        )::INTEGER AS month_number,

        customer_unique_id

    FROM customer_orders

)

----------------------------------------------------------------------------
-- STEP 4 : Aggregate Customers Per Cohort
----------------------------------------------------------------------------

SELECT

    cohort_month,

    month_number,

    COUNT(DISTINCT customer_unique_id) AS active_customers

FROM cohort_activity

GROUP BY

    cohort_month,

    month_number

ORDER BY

    cohort_month,

    month_number;