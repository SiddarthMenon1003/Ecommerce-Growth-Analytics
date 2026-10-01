    -- ==========================================================
    -- CASE 04 - ORDER JOURNEY & FULFILLMENT ANALYTICS
    -- FILE: 06_business_impact.sql
    -- PURPOSE:
    -- Quantify the business value of fulfillment improvements
    -- by estimating revenue impact, operational priorities,
    -- and strategic investment opportunities.
    -- ==========================================================

    ------------------------------------------------------------
    -- 1. Executive KPI Summary
    ------------------------------------------------------------

    SELECT

        COUNT(*) AS total_orders,

        ROUND(SUM(payment_value)::numeric, 2) AS total_revenue,

        ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,

        ROUND(
            SUM(delivered_flag)::numeric /
            COUNT(*) * 100,
            2
        ) AS delivery_completion_rate,

        ROUND(
            SUM(CASE WHEN sla_status = 'Met SLA' THEN 1 ELSE 0 END)::numeric /
            GREATEST(SUM(delivered_flag), 1) * 100,
            2
        ) AS sla_compliance_rate,

        ROUND(
            SUM(late_delivery_flag)::numeric /
            GREATEST(COUNT(*), 1) * 100,
            2
        ) AS late_delivery_rate,

        ROUND(AVG(review_score)::numeric, 2) AS avg_review_score

    FROM order_fulfillment_funnel_mart;

    ------------------------------------------------------------
    -- 2. Revenue by Delivery Performance
    ------------------------------------------------------------

    SELECT

        delivery_performance,

        COUNT(*) AS orders,

        ROUND(SUM(payment_value)::numeric, 2) AS revenue,

        ROUND(
            SUM(payment_value)::numeric /
            SUM(SUM(payment_value)) OVER() * 100,
            2
        ) AS revenue_share_percent,

        ROUND(AVG(review_score)::numeric, 2) AS avg_review_score

    FROM order_fulfillment_funnel_mart

    GROUP BY delivery_performance

    ORDER BY

        CASE delivery_performance
            WHEN 'Early'         THEN 1
            WHEN 'On Time'       THEN 2
            WHEN 'Late'          THEN 3
            WHEN 'Not Delivered' THEN 4
        END;

    ------------------------------------------------------------
    -- 3. Revenue by SLA Status
    ------------------------------------------------------------

    SELECT

        sla_status,

        COUNT(*) AS orders,

        ROUND(SUM(payment_value)::numeric, 2) AS revenue,

        ROUND(
            SUM(payment_value)::numeric /
            SUM(SUM(payment_value)) OVER() * 100,
            2
        ) AS revenue_share_percent

    FROM order_fulfillment_funnel_mart

    GROUP BY sla_status

    ORDER BY revenue DESC;

    ------------------------------------------------------------
    -- 4. Revenue at Risk (Late / Missed SLA)
    ------------------------------------------------------------

    SELECT

        delivery_delay_category,

        COUNT(*) AS orders,

        ROUND(SUM(payment_value)::numeric, 2) AS revenue_at_risk,

        ROUND(AVG(delivery_delay_days)::numeric, 2) AS avg_delay_days,

        ROUND(AVG(review_score)::numeric, 2) AS avg_review_score

    FROM order_fulfillment_funnel_mart

    WHERE delivery_delay_days > 0

    GROUP BY delivery_delay_category

    ORDER BY revenue_at_risk DESC;

    ------------------------------------------------------------
    -- 5. Revenue by Fulfillment Speed
    ------------------------------------------------------------

    SELECT

        fulfillment_speed_band,

        COUNT(*) AS orders,

        ROUND(SUM(payment_value)::numeric, 2) AS revenue,

        ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,

        ROUND(AVG(review_score)::numeric, 2) AS avg_review_score

    FROM order_fulfillment_funnel_mart

    WHERE fulfillment_speed_band IS NOT NULL

    GROUP BY fulfillment_speed_band

    ORDER BY revenue DESC;

    ------------------------------------------------------------
    -- 6. Revenue by Order Value Band
    ------------------------------------------------------------

    SELECT

        order_value_band,

        COUNT(*) AS orders,

        ROUND(SUM(payment_value)::numeric, 2) AS revenue,

        ROUND(
            SUM(payment_value)::numeric /
            SUM(SUM(payment_value)) OVER() * 100,
            2
        ) AS revenue_share_percent,

        ROUND(
            SUM(late_delivery_flag)::numeric /
            GREATEST(COUNT(*), 1) * 100,
            2
        ) AS late_delivery_rate

    FROM order_fulfillment_funnel_mart

    GROUP BY order_value_band

    ORDER BY

        CASE order_value_band
            WHEN 'High Value'   THEN 1
            WHEN 'Medium Value' THEN 2
            WHEN 'Low Value'    THEN 3
        END;

    ------------------------------------------------------------
    -- 7. Scenario: Revenue Impact of Late Delivery Reduction
    ------------------------------------------------------------

    SELECT

        delivery_performance,

        COUNT(*) AS orders,

        ROUND(SUM(payment_value)::numeric, 2) AS current_revenue,

        ROUND(SUM(payment_value)::numeric * 0.05, 2) AS uplift_5_percent,

        ROUND(SUM(payment_value)::numeric * 0.10, 2) AS uplift_10_percent,

        ROUND(SUM(payment_value)::numeric * 0.20, 2) AS uplift_20_percent

    FROM order_fulfillment_funnel_mart

    WHERE delivery_performance = 'Late'

    GROUP BY delivery_performance;

    ------------------------------------------------------------
    -- 8. Highest Priority Operational Fixes
    ------------------------------------------------------------

    SELECT

        customer_state,

        COUNT(*) AS orders,

        ROUND(SUM(payment_value)::numeric, 2) AS revenue,

        ROUND(
            SUM(late_delivery_flag)::numeric /
            GREATEST(COUNT(*), 1) * 100,
            2
        ) AS late_delivery_rate,

        ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,

        ROUND(AVG(review_score)::numeric, 2) AS avg_review_score

    FROM order_fulfillment_funnel_mart

    GROUP BY customer_state

    HAVING SUM(late_delivery_flag) > 0

    ORDER BY late_delivery_rate DESC

    LIMIT 10;

    ------------------------------------------------------------
    -- 9. Strategic Investment Matrix
    ------------------------------------------------------------

    SELECT

        delivery_efficiency_score,

        order_value_band,

        COUNT(*) AS orders,

        ROUND(SUM(payment_value)::numeric, 2) AS revenue,

        ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,

        ROUND(AVG(review_score)::numeric, 2) AS avg_review_score

    FROM order_fulfillment_funnel_mart

    GROUP BY
        delivery_efficiency_score,
        order_value_band

    ORDER BY revenue DESC;

    ------------------------------------------------------------
    -- 10. Executive Business Summary
    ------------------------------------------------------------

    SELECT

        delivery_performance,

        COUNT(*) AS orders,

        ROUND(SUM(payment_value)::numeric, 2) AS revenue,

        ROUND(AVG(fulfillment_days)::numeric, 2) AS avg_fulfillment_days,

        ROUND(AVG(approval_hours)::numeric, 2) AS avg_approval_hours,

        ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days,

        ROUND(AVG(review_score)::numeric, 2) AS avg_review_score,

        ROUND(
            SUM(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END)::numeric /
            GREATEST(SUM(CASE WHEN review_score IS NOT NULL THEN 1 ELSE 0 END), 1) * 100,
            2
        ) AS positive_review_rate

    FROM order_fulfillment_funnel_mart

    GROUP BY delivery_performance

    ORDER BY

        CASE delivery_performance
            WHEN 'Early'         THEN 1
            WHEN 'On Time'       THEN 2
            WHEN 'Late'          THEN 3
            WHEN 'Not Delivered' THEN 4
        END;
