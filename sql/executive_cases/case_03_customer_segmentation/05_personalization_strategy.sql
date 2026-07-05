-- ==========================================================
-- CASE 03 - CUSTOMER SEGMENTATION
-- FILE: 05_personalization_strategy.sql
-- PURPOSE:
-- Recommend personalized engagement strategies for every
-- customer segment based on value, spending behavior,
-- purchase frequency, and engagement.
-- ==========================================================

------------------------------------------------------------
-- 1. Strategy by Customer Value Segment
------------------------------------------------------------

SELECT

    customer_value_segment,

    COUNT(*) AS customers,

    ROUND(SUM(total_revenue),2) AS total_revenue,

    ROUND(AVG(estimated_ltv),2) AS avg_estimated_ltv,

    CASE

        WHEN customer_value_segment='High Value'
            THEN 'VIP Loyalty & Retention'

        WHEN customer_value_segment='Medium Value'
            THEN 'Upsell & Cross-Sell'

        ELSE 'Customer Activation'

    END AS recommended_strategy

FROM customer_segmentation_mart

GROUP BY customer_value_segment

ORDER BY total_revenue DESC;

------------------------------------------------------------
-- 2. Strategy by Engagement Status
------------------------------------------------------------

SELECT

    engagement_status,

    COUNT(*) AS customers,

    ROUND(SUM(total_revenue),2) AS total_revenue,

    CASE

        WHEN engagement_status='Active'
            THEN 'Reward Loyalty'

        WHEN engagement_status='At Risk'
            THEN 'Retention Campaign'

        ELSE 'Win-Back Campaign'

    END AS recommended_action

FROM customer_segmentation_mart

GROUP BY engagement_status

ORDER BY total_revenue DESC;

------------------------------------------------------------
-- 3. Strategy by Spending Band
------------------------------------------------------------

SELECT

    spending_band,

    COUNT(*) AS customers,

    ROUND(AVG(avg_order_value),2) AS avg_order_value,

    ROUND(AVG(estimated_ltv),2) AS avg_ltv,

    CASE

        WHEN spending_band='Premium'
            THEN 'Premium Experience'

        WHEN spending_band='Standard'
            THEN 'Bundle Offers'

        ELSE 'Discount Campaigns'

    END AS recommended_offer

FROM customer_segmentation_mart

GROUP BY spending_band

ORDER BY avg_ltv DESC;

------------------------------------------------------------
-- 4. Strategy by Purchase Frequency
------------------------------------------------------------

SELECT

    purchase_frequency_band,

    COUNT(*) AS customers,

    ROUND(AVG(total_orders),2) AS avg_orders,

    ROUND(AVG(estimated_ltv),2) AS avg_ltv,

    CASE

        WHEN purchase_frequency_band='High Frequency'
            THEN 'Exclusive Membership'

        WHEN purchase_frequency_band='Medium Frequency'
            THEN 'Personalized Promotions'

        ELSE 'Reactivation Incentives'

    END AS recommended_strategy

FROM customer_segmentation_mart

GROUP BY purchase_frequency_band

ORDER BY avg_ltv DESC;

------------------------------------------------------------
-- 5. High Value Dormant Customers
------------------------------------------------------------

SELECT

    customer_unique_id,

    total_revenue,

    estimated_ltv,

    days_since_last_purchase,

    'Immediate Win-Back Campaign' AS recommendation

FROM customer_segmentation_mart

WHERE customer_value_segment='High Value'
AND engagement_status='Dormant'

ORDER BY estimated_ltv DESC

LIMIT 20;

------------------------------------------------------------
-- 6. Premium Active Customers
------------------------------------------------------------

SELECT

    customer_unique_id,

    total_revenue,

    estimated_ltv,

    avg_order_value,

    'VIP Rewards Program' AS recommendation

FROM customer_segmentation_mart

WHERE spending_band='Premium'
AND engagement_status='Active'

ORDER BY estimated_ltv DESC

LIMIT 20;

------------------------------------------------------------
-- 7. Budget Customers with High Frequency
------------------------------------------------------------

SELECT

    customer_unique_id,

    total_orders,

    total_revenue,

    purchase_frequency,

    'Cross-Sell Low Cost Products' AS recommendation

FROM customer_segmentation_mart

WHERE spending_band='Budget'
AND purchase_frequency_band='High Frequency'

ORDER BY total_orders DESC

LIMIT 20;

------------------------------------------------------------
-- 8. Segment Opportunity Ranking
------------------------------------------------------------

SELECT

    customer_value_segment,

    engagement_status,

    ROUND(AVG(estimated_ltv),2) AS avg_ltv,

    ROUND(SUM(total_revenue),2) AS revenue,

    COUNT(*) AS customers

FROM customer_segmentation_mart

GROUP BY

    customer_value_segment,
    engagement_status

ORDER BY avg_ltv DESC;

------------------------------------------------------------
-- 9. Recommended Budget Allocation
------------------------------------------------------------

SELECT

    customer_value_segment,

    ROUND(
        SUM(total_revenue) /
        SUM(SUM(total_revenue)) OVER()*100,
        2
    ) AS suggested_budget_percent

FROM customer_segmentation_mart

GROUP BY customer_value_segment

ORDER BY suggested_budget_percent DESC;

------------------------------------------------------------
-- 10. Executive Personalization Summary
------------------------------------------------------------

SELECT

    customer_value_segment,

    spending_band,

    purchase_frequency_band,

    engagement_status,

    COUNT(*) AS customers,

    ROUND(AVG(estimated_ltv),2) AS avg_ltv,

    ROUND(SUM(total_revenue),2) AS revenue

FROM customer_segmentation_mart

GROUP BY

    customer_value_segment,
    spending_band,
    purchase_frequency_band,
    engagement_status

ORDER BY revenue DESC;