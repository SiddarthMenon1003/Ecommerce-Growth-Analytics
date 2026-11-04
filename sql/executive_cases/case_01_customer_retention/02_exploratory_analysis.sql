/*
===============================================================================
CASE 01 – CUSTOMER RETENTION STRATEGY

STEP 02 – EXPLORATORY ANALYSIS

Objective:
Develop a high-level understanding of the marketplace, customer behaviour,
revenue, operations, and growth trends before investigating customer
retention.

===============================================================================
*/

----------------------------------------------------------------------------
-- SECTION A : BUSINESS SCALE
----------------------------------------------------------------------------

-- 1. Total Customers

SELECT
    COUNT(*) AS total_customers
FROM dim_customers;

-- 2. Total Orders

SELECT
    COUNT(*) AS total_orders
FROM fact_orders;

-- 3. Total Revenue

SELECT
    ROUND(SUM(payment_value)::numeric, 2) AS total_revenue
FROM fact_payments;

-- 4. Average Order Value

SELECT
    ROUND(AVG(payment_value)::numeric, 2) AS average_order_value
FROM fact_payments;

----------------------------------------------------------------------------
-- SECTION B : CUSTOMER BEHAVIOUR
----------------------------------------------------------------------------

-- 5. Average Orders per Customer

SELECT
    ROUND(
        COUNT(order_id)::NUMERIC /
        COUNT(DISTINCT customer_id),
        2
    ) AS average_orders_per_customer
FROM fact_orders;

-- 6. Customers by Number of Orders

SELECT
    order_count,
    COUNT(*) AS customers
FROM (
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM fact_orders
    GROUP BY customer_id
) customer_orders
GROUP BY order_count
ORDER BY order_count;

----------------------------------------------------------------------------
-- SECTION C : GEOGRAPHIC DISTRIBUTION
----------------------------------------------------------------------------

-- 7. Top 10 States by Customers

SELECT
    customer_state,
    COUNT(*) AS total_customers
FROM dim_customers
GROUP BY customer_state
ORDER BY total_customers DESC
LIMIT 10;

-- 8. Top 10 Cities by Customers

SELECT
    customer_city,
    COUNT(*) AS total_customers
FROM dim_customers
GROUP BY customer_city
ORDER BY total_customers DESC
LIMIT 10;

----------------------------------------------------------------------------
-- SECTION D : GROWTH TRENDS
----------------------------------------------------------------------------

-- 9. Monthly Customer Acquisition

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(DISTINCT customer_id) AS new_customers
FROM fact_orders
GROUP BY month
ORDER BY month;

-- 10. Monthly Orders

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    COUNT(*) AS total_orders
FROM fact_orders
GROUP BY month
ORDER BY month;

-- 11. Monthly Revenue

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value)::numeric,2)
FROM fact_orders o
JOIN fact_payments p
ON o.order_id = p.order_id
GROUP BY month
ORDER BY month;

----------------------------------------------------------------------------
-- SECTION E : ORDER OPERATIONS
----------------------------------------------------------------------------

-- 12. Order Status Distribution

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM fact_orders
GROUP BY order_status
ORDER BY total_orders DESC;

----------------------------------------------------------------------------
-- SECTION F : PAYMENT BEHAVIOUR
----------------------------------------------------------------------------

------------------------------------------------------------
-- 13. Payment Method Distribution
------------------------------------------------------------

SELECT
    payment_type,
    COUNT(*) AS total_payments,
    ROUND(SUM(payment_value)::NUMERIC, 2) AS total_revenue
FROM fact_payments
GROUP BY payment_type
ORDER BY ROUND(SUM(payment_value)::NUMERIC, 2) DESC;

-- 14. Payment Installment Distribution

SELECT
    payment_installments,
    COUNT(*) AS total_orders
FROM fact_payments
GROUP BY payment_installments
ORDER BY payment_installments;

----------------------------------------------------------------------------
-- SECTION G : PRODUCT PERFORMANCE
----------------------------------------------------------------------------

-- 15. Top 10 Product Categories by Revenue

SELECT
    dp.product_category_name,
    ROUND(SUM(foi.price)::NUMERIC,2) AS revenue,
    COUNT(*) AS items_sold
FROM fact_order_items foi
JOIN dim_products dp
ON foi.product_id = dp.product_id
GROUP BY dp.product_category_name
ORDER BY revenue DESC
LIMIT 10;

----------------------------------------------------------------------------
-- SECTION H : SELLER PERFORMANCE
----------------------------------------------------------------------------

-- 16. Top 10 Sellers by Revenue

SELECT
    seller_id,
    ROUND(SUM(price)::NUMERIC,2) AS revenue,
    COUNT(*) AS items_sold
FROM fact_order_items
GROUP BY seller_id
ORDER BY revenue DESC
LIMIT 10;
