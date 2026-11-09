/*
=========================================================
Estimated Lifetime Value Analysis
=========================================================
*/

-- Overall LTV

SELECT
    ROUND(AVG(estimated_ltv),2) AS average_ltv,
    ROUND(MAX(estimated_ltv),2) AS highest_ltv,
    ROUND(MIN(estimated_ltv),2) AS lowest_ltv
FROM marketing_roi_mart;

-- LTV by Customer Type

SELECT
    customer_type,
    ROUND(AVG(estimated_ltv),2) AS average_ltv,
    ROUND(SUM(estimated_ltv),2) AS total_ltv
FROM marketing_roi_mart
GROUP BY customer_type
ORDER BY total_ltv DESC;

-- Top 20 Customers

SELECT
    customer_unique_id,
    estimated_ltv,
    total_revenue,
    total_orders
FROM marketing_roi_mart
ORDER BY estimated_ltv DESC
LIMIT 20;
