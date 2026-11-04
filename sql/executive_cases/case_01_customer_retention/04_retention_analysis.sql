/*
===============================================================================
CASE 01 – CUSTOMER RETENTION STRATEGY

STEP 04 – RETENTION ANALYSIS

Business Question:
How effectively does the business retain customers after their first purchase?

Business Value:
Measure customer retention across monthly acquisition cohorts to identify
customer churn patterns and evaluate long-term customer engagement.

Expected Output:
Monthly customer retention percentages for each acquisition cohort.

===============================================================================
*/

----------------------------------------------------------------------------
-- STEP 1 : Identify First Purchase Month
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
-- STEP 2 : Associate Every Order With Cohort
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
-- STEP 3 : Calculate Month Offset
----------------------------------------------------------------------------

cohort_activity AS (
    SELECT
        cohort_month,
        (
            EXTRACT(YEAR FROM AGE(purchase_month, cohort_month)) * 12
            +
            EXTRACT(MONTH FROM AGE(purchase_month, cohort_month))
        )::INTEGER AS month_number,
        customer_unique_id
    FROM customer_orders
),

----------------------------------------------------------------------------
-- STEP 4 : Count Active Customers
----------------------------------------------------------------------------

cohort_counts AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM cohort_activity
    GROUP BY
        cohort_month,
        month_number
),

----------------------------------------------------------------------------
-- STEP 5 : Determine Cohort Size
----------------------------------------------------------------------------

retention AS (
    SELECT
        cohort_month,
        month_number,
        active_customers,
        FIRST_VALUE(active_customers)
        OVER (
            PARTITION BY cohort_month
            ORDER BY month_number
        ) AS cohort_size
    FROM cohort_counts
)

----------------------------------------------------------------------------
-- STEP 6 : Calculate Retention Percentage
----------------------------------------------------------------------------

SELECT
    cohort_month,
    month_number,
    cohort_size,
    active_customers,
    ROUND(
        (
            active_customers::NUMERIC
            /
            cohort_size
        ) * 100,
        2
    ) AS retention_rate
FROM retention
ORDER BY
    cohort_month,
    month_number;
