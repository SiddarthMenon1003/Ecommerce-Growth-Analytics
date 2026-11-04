/*
=========================================================
Customer Segmentation
=========================================================
*/

SELECT
    customer_value_segment,
    COUNT(*) AS customers,
    ROUND(
        AVG(total_revenue),
        2
    ) AS avg_revenue,
    ROUND(
        SUM(total_revenue),
        2
    ) AS total_revenue,
    ROUND(
        AVG(estimated_ltv),
        2
    ) AS avg_ltv,
    ROUND(
        AVG(purchase_frequency),
        4
    ) AS avg_purchase_frequency
FROM marketing_roi_mart
GROUP BY customer_value_segment
ORDER BY total_revenue DESC;
