DROP TABLE IF EXISTS order_reviews CASCADE;
DROP TABLE IF EXISTS order_payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS fact_reviews CASCADE;
DROP TABLE IF EXISTS fact_payments CASCADE;
DROP TABLE IF EXISTS fact_order_items CASCADE;
DROP TABLE IF EXISTS fact_orders CASCADE;
DROP TABLE IF EXISTS dim_products CASCADE;
DROP TABLE IF EXISTS dim_sellers CASCADE;
DROP TABLE IF EXISTS dim_customers CASCADE;

--------------------------------------------------
-- CUSTOMER DIMENSION
--------------------------------------------------

CREATE TABLE dim_customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INTEGER,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

--------------------------------------------------
-- PRODUCT DIMENSION
--------------------------------------------------

CREATE TABLE dim_products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT
);

--------------------------------------------------
-- SELLER DIMENSION
--------------------------------------------------

CREATE TABLE dim_sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

--------------------------------------------------
-- ORDER FACT
--------------------------------------------------

CREATE TABLE fact_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    FOREIGN KEY (customer_id)
        REFERENCES dim_customers(customer_id)
);

--------------------------------------------------
-- ORDER ITEMS FACT
--------------------------------------------------

CREATE TABLE fact_order_items (
    order_id VARCHAR(50),
    order_item_id INTEGER,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price FLOAT,
    freight_value FLOAT,
    FOREIGN KEY (order_id)
        REFERENCES fact_orders(order_id),
    FOREIGN KEY (product_id)
        REFERENCES dim_products(product_id),
    FOREIGN KEY (seller_id)
        REFERENCES dim_sellers(seller_id)
);

--------------------------------------------------
-- PAYMENTS FACT
--------------------------------------------------

CREATE TABLE fact_payments (
    order_id VARCHAR(50),
    payment_sequential INTEGER,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value FLOAT,
    FOREIGN KEY (order_id)
        REFERENCES fact_orders(order_id)
);

--------------------------------------------------
-- REVIEWS FACT
--------------------------------------------------

CREATE TABLE fact_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    FOREIGN KEY (order_id)
        REFERENCES fact_orders(order_id)
);
