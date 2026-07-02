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
Monthly customer cohorts with active customer counts, cohort sizes,
and retention rates across subsequent months.

===============================================================================
*/

----------------------------------------------------------------------------
-- Remove Existing Analytics Table
----------------------------------------------------------------------------

DROP TABLE IF EXISTS customer_cohorts;

----------------------------------------------------------------------------
-- Create Customer Cohort Analytics Table
----------------------------------------------------------------------------

CREATE TABLE customer_cohorts AS

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

),

----------------------------------------------------------------------------
-- STEP 4 : Calculate Cohort Size
----------------------------------------------------------------------------

cohort_sizes AS (

    SELECT

        cohort_month,

        COUNT(DISTINCT customer_unique_id) AS cohort_size

    FROM first_purchase

    GROUP BY

        cohort_month

)

----------------------------------------------------------------------------
-- STEP 5 : Build Cohort Analytics Table
----------------------------------------------------------------------------

SELECT

    ca.cohort_month,

    ca.month_number,

    COUNT(DISTINCT ca.customer_unique_id) AS active_customers,

    cs.cohort_size,

    ROUND(
        COUNT(DISTINCT ca.customer_unique_id)::NUMERIC
        /
        cs.cohort_size,
        4
    ) AS retention_rate

FROM cohort_activity ca

JOIN cohort_sizes cs

    ON ca.cohort_month = cs.cohort_month

GROUP BY

    ca.cohort_month,

    ca.month_number,

    cs.cohort_size

ORDER BY

    ca.cohort_month,

    ca.month_number;