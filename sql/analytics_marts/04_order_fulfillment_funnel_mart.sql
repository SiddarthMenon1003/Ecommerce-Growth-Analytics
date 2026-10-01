DROP TABLE IF EXISTS order_fulfillment_funnel_mart;

CREATE TABLE order_fulfillment_funnel_mart AS

/* ==========================================================
   CASE 04 - ORDER FULFILLMENT FUNNEL MART
   Grain: One Row = One Order
   Purpose:
       Order Journey & Fulfillment Analytics
       Operational Bottleneck Identification
       Customer Experience Measurement
       Executive KPI Reporting
   ========================================================== */

WITH dataset_metrics AS (

    SELECT

        MAX(order_purchase_timestamp)::date AS dataset_refresh_date

    FROM fact_orders

),

/* ==========================================================
   Order Item Metrics
   ========================================================== */

order_item_metrics AS (

    SELECT

        order_id,

        COUNT(*) AS items_per_order,

        ROUND(
            SUM(price)::numeric,
            2
        ) AS order_value,

        ROUND(
            SUM(freight_value)::numeric,
            2
        ) AS freight_value

    FROM fact_order_items

    GROUP BY order_id

),

/* ==========================================================
   Payment Aggregates
   ========================================================== */

payment_aggregates AS (

    SELECT

        order_id,

        ROUND(
            SUM(payment_value)::numeric,
            2
        ) AS payment_value,

        COUNT(*) AS payment_transactions,

        MAX(payment_installments) AS payment_installments

    FROM fact_payments

    GROUP BY order_id

),

/* ==========================================================
   Primary Payment Type Per Order
   ========================================================== */

payment_primary AS (

    SELECT

        order_id,

        payment_type AS primary_payment_type,

        ROW_NUMBER() OVER (

            PARTITION BY order_id

            ORDER BY
                payment_value DESC,
                payment_sequential ASC,
                payment_type ASC

        ) AS payment_rank

    FROM fact_payments

),

/* ==========================================================
   Combined Payment Metrics
   ========================================================== */

payment_metrics AS (

    SELECT

        pa.order_id,

        pa.payment_value,

        pa.payment_transactions,

        pa.payment_installments,

        pp.primary_payment_type

    FROM payment_aggregates pa

    LEFT JOIN payment_primary pp

        ON pa.order_id = pp.order_id
       AND pp.payment_rank = 1

),

/* ==========================================================
   Latest Review Per Order
   ========================================================== */

review_metrics AS (

    SELECT

        order_id,

        review_score,

        review_creation_date,

        review_answer_timestamp,

        ROW_NUMBER() OVER (

            PARTITION BY order_id

            ORDER BY
                review_creation_date DESC,
                review_answer_timestamp DESC NULLS LAST

        ) AS review_rank

    FROM fact_reviews

),

/* ==========================================================
   Base Order Dataset
   ========================================================== */

order_base AS (

    SELECT

        fo.order_id,

        fo.customer_id,

        dc.customer_unique_id,

        dc.customer_city,

        dc.customer_state,

        fo.order_status,

        fo.order_purchase_timestamp,

        fo.order_approved_at,

        fo.order_delivered_carrier_date,

        fo.order_delivered_customer_date,

        fo.order_estimated_delivery_date,

        dm.dataset_refresh_date,

        COALESCE(pm.payment_value, 0) AS payment_value,

        COALESCE(oim.order_value, 0) AS order_value,

        COALESCE(oim.freight_value, 0) AS freight_value,

        COALESCE(oim.items_per_order, 0) AS items_per_order,

        COALESCE(pm.payment_transactions, 0) AS payment_transactions,

        pm.payment_installments,

        pm.primary_payment_type,

        rm.review_score,

        rm.review_creation_date,

        rm.review_answer_timestamp

    FROM fact_orders fo

    INNER JOIN dim_customers dc

        ON fo.customer_id = dc.customer_id

    CROSS JOIN dataset_metrics dm

    LEFT JOIN order_item_metrics oim

        ON fo.order_id = oim.order_id

    LEFT JOIN payment_metrics pm

        ON fo.order_id = pm.order_id

    LEFT JOIN review_metrics rm

        ON fo.order_id = rm.order_id
       AND rm.review_rank = 1

),

/* ==========================================================
   Time Metrics
   ========================================================== */

time_metrics AS (

    SELECT

        *,

        CASE
            WHEN payment_value > 0 THEN
                ROUND(
                    (freight_value / payment_value * 100)::numeric,
                    2
                )
            ELSE NULL
        END AS freight_percentage,

        CASE
            WHEN items_per_order = 1 THEN 'Single Item'
            WHEN items_per_order BETWEEN 2 AND 3 THEN 'Small Basket'
            WHEN items_per_order >= 4 THEN 'Large Basket'
            ELSE 'Unknown'
        END AS order_size_category,

        ROUND(
            EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp))
            / 3600.0,
            2
        ) AS approval_hours,

        (order_delivered_carrier_date::date - order_approved_at::date)
            AS fulfillment_processing_days,

        (order_delivered_customer_date::date - order_delivered_carrier_date::date)
            AS delivery_days,

        (order_delivered_customer_date::date - order_purchase_timestamp::date)
            AS fulfillment_days,

        (review_creation_date::date - order_delivered_customer_date::date)
            AS review_delay_days,

        (order_delivered_customer_date::date - order_estimated_delivery_date::date)
            AS delivery_delay_days,

        CASE WHEN order_approved_at IS NOT NULL THEN 1 ELSE 0 END
            AS approved_flag,

        CASE WHEN order_delivered_carrier_date IS NOT NULL THEN 1 ELSE 0 END
            AS shipped_flag,

        CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END
            AS delivered_flag,

        CASE WHEN review_score IS NOT NULL THEN 1 ELSE 0 END
            AS reviewed_flag

    FROM order_base

),

/* ==========================================================
   Calendar Metrics
   ========================================================== */

calendar_metrics AS (

    SELECT

        *,

        CASE
            WHEN delivery_delay_days > 0 THEN 1
            ELSE 0
        END AS late_delivery_flag,

        CASE
            WHEN reviewed_flag = 1 THEN 'Reviewed'
            WHEN delivered_flag = 1 THEN 'Delivered'
            WHEN shipped_flag = 1 THEN 'Shipped'
            WHEN approved_flag = 1 THEN 'Payment Approved'
            ELSE 'Order Created'
        END AS current_funnel_stage,

        EXTRACT(YEAR FROM order_purchase_timestamp)::integer
            AS purchase_year,

        EXTRACT(QUARTER FROM order_purchase_timestamp)::integer
            AS purchase_quarter,

        EXTRACT(MONTH FROM order_purchase_timestamp)::integer
            AS purchase_month,

        TO_CHAR(order_purchase_timestamp, 'FMMonth')
            AS purchase_month_name,

        EXTRACT(WEEK FROM order_purchase_timestamp)::integer
            AS purchase_week,

        TO_CHAR(order_purchase_timestamp, 'FMDay')
            AS purchase_weekday

    FROM time_metrics

),

/* ==========================================================
   Operational Metrics
   ========================================================== */

operational_metrics AS (

    SELECT

        *,

        CASE
            WHEN review_score = 5 THEN 'Excellent'
            WHEN review_score = 4 THEN 'Good'
            WHEN review_score = 3 THEN 'Average'
            WHEN review_score IN (1, 2) THEN 'Poor'
            ELSE 'No Review'
        END AS review_score_band,

        CASE
            WHEN order_delivered_customer_date IS NULL THEN 'Not Delivered'
            WHEN delivery_delay_days < 0 THEN 'Early'
            WHEN delivery_delay_days = 0 THEN 'On Time'
            ELSE 'Late'
        END AS delivery_performance,

        CASE
            WHEN order_delivered_customer_date IS NULL THEN 'Not Delivered'
            WHEN delivery_delay_days <= 0 THEN 'On Time / Early'
            WHEN delivery_delay_days BETWEEN 1 AND 3 THEN '1-3 Days Late'
            ELSE '4+ Days Late'
        END AS delivery_delay_category,

        CASE
            WHEN order_delivered_customer_date IS NULL THEN 'Pending'
            WHEN delivery_delay_days <= 0 THEN 'Met SLA'
            ELSE 'Missed SLA'
        END AS sla_status,

        CASE
            WHEN order_delivered_customer_date IS NULL THEN 'Pending'
            WHEN delivery_delay_days <= 0 AND review_score >= 4 THEN 'Excellent'
            WHEN delivery_delay_days <= 0 AND review_score = 3 THEN 'Good'
            WHEN delivery_delay_days <= 0 AND review_score IS NULL THEN 'Good'
            WHEN delivery_delay_days > 0 THEN 'Needs Improvement'
            WHEN review_score <= 2 THEN 'Needs Improvement'
            ELSE 'Good'
        END AS delivery_efficiency_score,

        CASE
            WHEN approval_hours IS NOT NULL THEN
                NTILE(3) OVER (
                    PARTITION BY (approval_hours IS NOT NULL)::integer
                    ORDER BY approval_hours
                )
            ELSE NULL
        END AS approval_speed_ntile,

        CASE
            WHEN fulfillment_processing_days IS NOT NULL THEN
                NTILE(3) OVER (
                    PARTITION BY (fulfillment_processing_days IS NOT NULL)::integer
                    ORDER BY fulfillment_processing_days
                )
            ELSE NULL
        END AS shipping_speed_ntile,

        CASE
            WHEN fulfillment_days IS NOT NULL THEN
                NTILE(3) OVER (
                    PARTITION BY (fulfillment_days IS NOT NULL)::integer
                    ORDER BY fulfillment_days
                )
            ELSE NULL
        END AS fulfillment_speed_ntile,

        NTILE(3) OVER (
            ORDER BY payment_value DESC
        ) AS order_value_ntile

    FROM calendar_metrics

),

/* ==========================================================
   Segmentation Metrics
   ========================================================== */

segmentation_metrics AS (

    SELECT

        *,

        CASE approval_speed_ntile
            WHEN 1 THEN 'Fast'
            WHEN 2 THEN 'Standard'
            WHEN 3 THEN 'Slow'
            ELSE NULL
        END AS approval_speed_band,

        CASE shipping_speed_ntile
            WHEN 1 THEN 'Fast'
            WHEN 2 THEN 'Standard'
            WHEN 3 THEN 'Slow'
            ELSE NULL
        END AS shipping_speed_band,

        CASE fulfillment_speed_ntile
            WHEN 1 THEN 'Fast'
            WHEN 2 THEN 'Standard'
            WHEN 3 THEN 'Slow'
            ELSE NULL
        END AS fulfillment_speed_band,

        CASE order_value_ntile
            WHEN 1 THEN 'High Value'
            WHEN 2 THEN 'Medium Value'
            WHEN 3 THEN 'Low Value'
        END AS order_value_band

    FROM operational_metrics

)

/* ==========================================================
   Final Output
   ========================================================== */

SELECT

    order_id,
    customer_id,
    customer_unique_id,
    order_status,

    customer_city,
    customer_state,

    dataset_refresh_date,

    payment_value,
    order_value,
    freight_value,
    freight_percentage,
    items_per_order,
    order_size_category,
    payment_transactions,
    payment_installments,
    primary_payment_type,

    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    review_creation_date,
    review_answer_timestamp,

    approval_hours,
    fulfillment_processing_days,
    delivery_days,
    fulfillment_days,
    review_delay_days,
    delivery_delay_days,

    approved_flag,
    shipped_flag,
    delivered_flag,
    reviewed_flag,
    late_delivery_flag,
    current_funnel_stage,

    review_score,
    review_score_band,

    delivery_performance,
    delivery_delay_category,
    sla_status,
    approval_speed_band,
    shipping_speed_band,
    fulfillment_speed_band,
    delivery_efficiency_score,

    order_value_band,

    purchase_year,
    purchase_quarter,
    purchase_month,
    purchase_month_name,
    purchase_week,
    purchase_weekday

FROM segmentation_metrics;
