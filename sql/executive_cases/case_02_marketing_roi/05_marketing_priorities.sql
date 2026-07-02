/*
=========================================================
Marketing Priority Analysis
=========================================================
*/

SELECT

    marketing_priority,

    COUNT(*) AS customers,

    ROUND(
        SUM(total_revenue),
        2
    ) AS revenue,

    ROUND(
        AVG(estimated_ltv),
        2
    ) AS avg_ltv,

    ROUND(
        AVG(total_orders),
        2
    ) AS avg_orders

FROM marketing_roi_mart

GROUP BY marketing_priority

ORDER BY revenue DESC;