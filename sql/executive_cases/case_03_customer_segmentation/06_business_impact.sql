-- ==========================================================
-- CASE 03 - CUSTOMER SEGMENTATION
-- FILE: 06_business_impact.sql
-- PURPOSE:
-- Quantify the business value of customer segmentation by
-- estimating revenue opportunities, retention priorities,
-- and strategic investment impact.
-- ==========================================================

------------------------------------------------------------
-- 1. Executive KPI Summary
------------------------------------------------------------

SELECT

    COUNT(*) AS total_customers,

    ROUND(SUM(total_revenue),2) AS total_revenue,

    ROUND(SUM(estimated_ltv),2) AS total_estimated_ltv,

    ROUND(AVG(total_revenue),2) AS avg_customer_revenue,

    ROUND(AVG(estimated_ltv),2) AS avg_customer_ltv

FROM customer_segmentation_mart;

------------------------------------------------------------
-- 2. Revenue Opportunity by Segment
------------------------------------------------------------

SELECT

    customer_value_segment,

    COUNT(*) AS customers,

    ROUND(SUM(total_revenue),2) AS revenue,

    ROUND(SUM(estimated_ltv),2) AS estimated_ltv,

    ROUND(
        SUM(total_revenue) /
        SUM(SUM(total_revenue)) OVER()*100,
        2
    ) AS revenue_share_percent

FROM customer_segmentation_mart

GROUP BY customer_value_segment

ORDER BY revenue DESC;

------------------------------------------------------------
-- 3. Retention Opportunity
------------------------------------------------------------

SELECT

    engagement_status,

    COUNT(*) AS customers,

    ROUND(SUM(total_revenue),2) AS revenue,

    ROUND(SUM(estimated_ltv),2) AS estimated_ltv,

    ROUND(AVG(days_since_last_purchase),2) AS avg_days_since_purchase

FROM customer_segmentation_mart

GROUP BY engagement_status

ORDER BY estimated_ltv DESC;

------------------------------------------------------------
-- 4. Highest Value Recovery Opportunity
------------------------------------------------------------

SELECT

    customer_value_segment,

    engagement_status,

    COUNT(*) AS customers,

    ROUND(SUM(total_revenue),2) AS revenue,

    ROUND(SUM(estimated_ltv),2) AS estimated_ltv

FROM customer_segmentation_mart

GROUP BY

    customer_value_segment,
    engagement_status

ORDER BY estimated_ltv DESC;

------------------------------------------------------------
-- 5. Premium Customer Opportunity
------------------------------------------------------------

SELECT

    spending_band,

    COUNT(*) AS customers,

    ROUND(SUM(total_revenue),2) AS revenue,

    ROUND(AVG(avg_order_value),2) AS avg_order_value,

    ROUND(AVG(estimated_ltv),2) AS avg_ltv

FROM customer_segmentation_mart

GROUP BY spending_band

ORDER BY avg_ltv DESC;

------------------------------------------------------------
-- 6. Estimated Marketing Budget Allocation
------------------------------------------------------------

SELECT

    customer_value_segment,

    ROUND(
        SUM(estimated_ltv) /
        SUM(SUM(estimated_ltv)) OVER()*100,
        2
    ) AS suggested_budget_share

FROM customer_segmentation_mart

GROUP BY customer_value_segment

ORDER BY suggested_budget_share DESC;

------------------------------------------------------------
-- 7. Estimated Revenue Uplift
------------------------------------------------------------

SELECT

    customer_value_segment,

    ROUND(SUM(total_revenue),2) AS current_revenue,

    ROUND(SUM(total_revenue)*1.10,2) AS projected_revenue,

    ROUND(SUM(total_revenue)*0.10,2) AS projected_incremental_revenue

FROM customer_segmentation_mart

GROUP BY customer_value_segment

ORDER BY current_revenue DESC;

------------------------------------------------------------
-- 8. Highest Priority Customers
------------------------------------------------------------

SELECT

    customer_unique_id,

    estimated_ltv,

    total_revenue,

    engagement_status,

    spending_band,

    customer_value_segment

FROM customer_segmentation_mart

ORDER BY estimated_ltv DESC

LIMIT 25;

------------------------------------------------------------
-- 9. Strategic Investment Matrix
------------------------------------------------------------

SELECT

    customer_value_segment,

    spending_band,

    engagement_status,

    COUNT(*) AS customers,

    ROUND(SUM(total_revenue),2) AS revenue,

    ROUND(AVG(estimated_ltv),2) AS avg_ltv

FROM customer_segmentation_mart

GROUP BY

    customer_value_segment,
    spending_band,
    engagement_status

ORDER BY revenue DESC;

------------------------------------------------------------
-- 10. Executive Business Summary
------------------------------------------------------------

SELECT

    customer_value_segment,

    COUNT(*) AS customers,

    ROUND(AVG(total_orders),2) AS avg_orders,

    ROUND(AVG(avg_order_value),2) AS avg_order_value,

    ROUND(AVG(total_revenue),2) AS avg_revenue,

    ROUND(AVG(estimated_ltv),2) AS avg_ltv,

    ROUND(AVG(days_since_last_purchase),2) AS avg_days_since_purchase

FROM customer_segmentation_mart

GROUP BY customer_value_segment

ORDER BY avg_ltv DESC;