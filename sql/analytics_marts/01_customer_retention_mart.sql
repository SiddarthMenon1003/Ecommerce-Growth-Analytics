DROP TABLE IF EXISTS customer_retention_mart;
CREATE TABLE customer_retention_mart AS
WITH dataset_max_date AS (
    SELECT
        MAX(order_purchase_timestamp)::date AS max_purchase_date
    FROM fact_orders
),
customer_orders AS (
    SELECT
        dc.customer_id,
        dc.customer_unique_id,
        fo.order_id,
        fo.order_purchase_timestamp,
        fp.payment_value
    FROM dim_customers dc
    JOIN fact_orders fo
        ON dc.customer_id = fo.customer_id
    JOIN fact_payments fp
        ON fo.order_id = fp.order_id
),
customer_metrics AS (
    SELECT
        customer_id,
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(SUM(payment_value)::numeric,2) AS total_revenue,
        ROUND(AVG(payment_value)::numeric,2) AS avg_order_value,
        MIN(order_purchase_timestamp) AS first_purchase_date,
        MAX(order_purchase_timestamp) AS last_purchase_date
    FROM customer_orders
    GROUP BY
        customer_id,
        customer_unique_id
),
customer_enriched AS (
    SELECT
        cm.*,
        (last_purchase_date::date - first_purchase_date::date)
            AS customer_lifetime_days,
        (
            SELECT max_purchase_date
            FROM dataset_max_date
        ) - last_purchase_date::date
            AS days_since_last_purchase,
        ROUND(
            total_orders::numeric /
            GREATEST(
                (last_purchase_date::date - first_purchase_date::date) + 1,
                1
            ),
            4
        ) AS purchase_frequency,
        RANK() OVER(
            ORDER BY total_revenue DESC
        ) AS revenue_rank,
        NTILE(100) OVER(
            ORDER BY total_revenue DESC
        ) AS revenue_percentile
    FROM customer_metrics cm
)
SELECT

    *,

    CASE
        WHEN revenue_percentile <= 20 THEN 'High Value'
        WHEN revenue_percentile <= 60 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM customer_enriched;
