/*
===============================================================================
CASE 01: CUSTOMER RETENTION ANALYSIS
STEP 01: DATA VALIDATION
-------------------------------------------------------------------------------

Objective:
Validate that the analytical warehouse is suitable for customer retention
analysis before performing any business calculations.

A valid dataset should satisfy the following:

1. No duplicate customers
2. No duplicate orders
3. No missing customer IDs
4. Every order belongs to an existing customer
5. No invalid order timestamps
6. Basic warehouse statistics match expectations

===============================================================================
*/

------------------------------------------------------------
-- CHECK 1 : Total Customers
------------------------------------------------------------

SELECT
    COUNT(*) AS total_customers
FROM dim_customers;

------------------------------------------------------------
-- CHECK 2 : Total Orders
------------------------------------------------------------

SELECT
    COUNT(*) AS total_orders
FROM fact_orders;

------------------------------------------------------------
-- CHECK 3 : Duplicate Customers
------------------------------------------------------------

SELECT
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_customers
FROM dim_customers;

------------------------------------------------------------
-- CHECK 4 : Duplicate Orders
------------------------------------------------------------

SELECT
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM fact_orders;

------------------------------------------------------------
-- CHECK 5 : Missing Customer IDs
------------------------------------------------------------

SELECT
    COUNT(*) AS missing_customer_ids
FROM fact_orders
WHERE customer_id IS NULL;

------------------------------------------------------------
-- CHECK 6 : Orders Without Matching Customers
------------------------------------------------------------

SELECT
    COUNT(*) AS orphan_orders
FROM fact_orders fo
LEFT JOIN dim_customers dc
       ON fo.customer_id = dc.customer_id
WHERE dc.customer_id IS NULL;

------------------------------------------------------------
-- CHECK 7 : Missing Purchase Dates
------------------------------------------------------------

SELECT
    COUNT(*) AS missing_purchase_dates
FROM fact_orders
WHERE order_purchase_timestamp IS NULL;

------------------------------------------------------------
-- CHECK 8 : Invalid Delivery Timeline
------------------------------------------------------------

SELECT
    COUNT(*) AS invalid_delivery_dates
FROM fact_orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

------------------------------------------------------------
-- CHECK 9 : Order Status Distribution
------------------------------------------------------------

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM fact_orders
GROUP BY order_status
ORDER BY total_orders DESC;

------------------------------------------------------------
-- CHECK 10 : Monthly Order Volume
------------------------------------------------------------

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders
FROM fact_orders
GROUP BY order_month
ORDER BY order_month;
