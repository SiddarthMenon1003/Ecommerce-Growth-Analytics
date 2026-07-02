/*
=========================================================
CASE 02 — MARKETING ROI
Exploratory Analysis
=========================================================
*/

-- Customer Type Distribution

SELECT
    customer_type,
    COUNT(*) AS customers,
    ROUND(AVG(total_revenue),2) AS avg_revenue
FROM marketing_roi_mart
GROUP BY customer_type
ORDER BY avg_revenue DESC;


-- Average Purchase Frequency

SELECT
    customer_type,
    ROUND(AVG(purchase_frequency),4) AS avg_frequency
FROM marketing_roi_mart
GROUP BY customer_type;


-- Average Estimated LTV

SELECT
    customer_type,
    ROUND(AVG(estimated_ltv),2) AS avg_ltv
FROM marketing_roi_mart
GROUP BY customer_type;


-- Marketing Priority Distribution

SELECT
    marketing_priority,
    COUNT(*) AS customers,
    ROUND(SUM(total_revenue),2) AS revenue
FROM marketing_roi_mart
GROUP BY marketing_priority
ORDER BY revenue DESC;