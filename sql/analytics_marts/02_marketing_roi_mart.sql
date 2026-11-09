-- Grain: ONE ROW PER customer_unique_id (true customer).
-- Fixed 2026-11-04: previously grouped on order-scoped customer_id (every customer looked
-- one-time; estimated_ltv collapsed to = revenue). Now aggregates across all orders per
-- customer_unique_id, so Repeat/Retain/Upsell tiers are populated.
-- Scope: value prioritisation only — no CAC/ROAS (no spend/channel data in Olist).
-- PBI: relate to Dim Customers on customer_unique_id (not customer_id).
DROP TABLE IF EXISTS marketing_roi_mart;
CREATE TABLE marketing_roi_mart AS
WITH dataset_max_date AS (
    SELECT
        MAX(order_purchase_timestamp)::date AS max_purchase_date
    FROM fact_orders
),
customer_orders AS (
    SELECT
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
        customer_unique_id,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(SUM(payment_value)::numeric,2) AS total_revenue,
        ROUND(AVG(payment_value)::numeric,2) AS avg_order_value,
        MIN(order_purchase_timestamp) AS first_purchase_date,
        MAX(order_purchase_timestamp) AS last_purchase_date
    FROM customer_orders
    GROUP BY
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
        CASE
            WHEN total_orders = 1 THEN 'One-Time'
            ELSE 'Repeat'
        END AS customer_type,
        NTILE(100) OVER(
            ORDER BY total_revenue DESC
        ) AS revenue_percentile
    FROM customer_metrics cm
),
marketing_metrics AS (
    SELECT

        *,

        CASE
            WHEN revenue_percentile <= 20 THEN 'High Value'
            WHEN revenue_percentile <= 60 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment,
        ROUND(
            total_revenue * purchase_frequency,
            2
        ) AS estimated_ltv
    FROM customer_enriched
)
SELECT

    *,

    CASE
        WHEN customer_type = 'Repeat'
             AND customer_value_segment = 'High Value'
            THEN 'Retain'
        WHEN customer_type = 'One-Time'
             AND customer_value_segment = 'High Value'
            THEN 'Convert'
        WHEN customer_type = 'Repeat'
             AND customer_value_segment = 'Medium Value'
            THEN 'Upsell'
        WHEN customer_type = 'One-Time'
             AND customer_value_segment = 'Medium Value'
            THEN 'Nurture'
        ELSE 'Low Priority'
    END AS marketing_priority
FROM marketing_metrics;
