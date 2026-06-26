DROP TABLE IF EXISTS stg_customers;
DROP TABLE IF EXISTS stg_orders;
DROP TABLE IF EXISTS stg_order_items;
DROP TABLE IF EXISTS stg_order_payments;
DROP TABLE IF EXISTS stg_order_reviews;
DROP TABLE IF EXISTS stg_products;
DROP TABLE IF EXISTS stg_sellers;
DROP TABLE IF EXISTS stg_geolocation;

CREATE TABLE stg_customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state TEXT
);

CREATE TABLE stg_orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

CREATE TABLE stg_order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price FLOAT,
    freight_value FLOAT
);

CREATE TABLE stg_order_payments (
    order_id TEXT,
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value FLOAT
);

CREATE TABLE stg_order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);

CREATE TABLE stg_products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_length FLOAT,
    product_description_length FLOAT,
    product_photos_qty FLOAT,
    product_weight_g FLOAT,
    product_length_cm FLOAT,
    product_height_cm FLOAT,
    product_width_cm FLOAT
);

CREATE TABLE stg_sellers (
    seller_id TEXT,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state TEXT
);

CREATE TABLE stg_geolocation (
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat FLOAT,
    geolocation_lng FLOAT,
    geolocation_city TEXT,
    geolocation_state TEXT
);