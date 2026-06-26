--------------------------------------------------
-- CLEAR FACT TABLES
--------------------------------------------------

TRUNCATE TABLE fact_reviews CASCADE;
TRUNCATE TABLE fact_payments CASCADE;
TRUNCATE TABLE fact_order_items CASCADE;
TRUNCATE TABLE fact_orders CASCADE;

--------------------------------------------------
-- FACT ORDERS
--------------------------------------------------

INSERT INTO fact_orders (

    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date

)

SELECT DISTINCT

    order_id,

    customer_id,

    LOWER(TRIM(order_status)),

    CAST(order_purchase_timestamp AS TIMESTAMP),

    CAST(order_approved_at AS TIMESTAMP),

    CAST(order_delivered_carrier_date AS TIMESTAMP),

    CAST(order_delivered_customer_date AS TIMESTAMP),

    CAST(order_estimated_delivery_date AS TIMESTAMP)

FROM stg_orders

WHERE customer_id IS NOT NULL;