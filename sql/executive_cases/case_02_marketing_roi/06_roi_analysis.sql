/*
=========================================================
Marketing ROI Executive Summary
=========================================================
*/

SELECT
    customer_type,
    customer_value_segment,
    marketing_priority,
    COUNT(*) AS customers,
    ROUND(
        SUM(total_revenue),
        2
    ) AS revenue,
    ROUND(
        AVG(total_revenue),
        2
    ) AS avg_revenue,
    ROUND(
        AVG(estimated_ltv),
        2
    ) AS avg_ltv
FROM marketing_roi_mart
GROUP BY
    customer_type,
    customer_value_segment,
    marketing_priority
ORDER BY revenue DESC;
