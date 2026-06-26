--------------------------------------------------
-- Clear Existing Data
--------------------------------------------------

TRUNCATE TABLE dim_customers CASCADE;
TRUNCATE TABLE dim_products CASCADE;
TRUNCATE TABLE dim_sellers CASCADE;

--------------------------------------------------
-- Customers
--------------------------------------------------

INSERT INTO dim_customers

SELECT DISTINCT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM stg_customers;

--------------------------------------------------
-- Products
--------------------------------------------------

INSERT INTO dim_products

SELECT DISTINCT
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM stg_products;

--------------------------------------------------
-- Sellers
--------------------------------------------------

INSERT INTO dim_sellers

SELECT DISTINCT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM stg_sellers;