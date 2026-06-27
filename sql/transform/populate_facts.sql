/*
===============================================================================
POPULATE FACT TABLES
===============================================================================
*/

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

--------------------------------------------------
-- FACT ORDER ITEMS
--------------------------------------------------

INSERT INTO fact_order_items (

    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value

)

SELECT

    order_id,

    order_item_id,

    product_id,

    seller_id,

    CAST(shipping_limit_date AS TIMESTAMP),

    price,

    freight_value

FROM stg_order_items;

--------------------------------------------------
-- FACT PAYMENTS
--------------------------------------------------

INSERT INTO fact_payments (

    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value

)

SELECT

    order_id,

    payment_sequential,

    LOWER(TRIM(payment_type)),

    payment_installments,

    payment_value

FROM stg_order_payments;

--------------------------------------------------
-- FACT REVIEWS
--------------------------------------------------

INSERT INTO fact_reviews (

    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp

)

SELECT

    review_id,

    order_id,

    review_score,

    review_comment_title,

    review_comment_message,

    CAST(review_creation_date AS TIMESTAMP),

    CAST(review_answer_timestamp AS TIMESTAMP)

FROM stg_order_reviews;