/*
===============================================================================
CASE 06 - EXPERIMENTATION

STEP 01 - OBSERVATIONAL DATA

Olist has no randomized experiment data (no control/treatment assignment, no
test logs), so a true A/B test cannot be run on it. This case therefore
delivers (a) a reusable experiment-design toolkit and (b) a worked statistical
test on the strongest OBSERVATIONAL signal available: the relationship between
delivery timing and review score.

This query pulls the group statistics the Python analysis uses to run a
two-sample Welch t-test (Late vs non-late). See
src/experimentation/experiment_analysis.py and ab_toolkit.py.

NOTE: observational comparison - it quantifies an association, not proof of
causation (late-delivered orders may differ systematically from on-time ones).
===============================================================================
*/

-- Review-score distribution by delivery timing (inputs for the t-test)
SELECT
    delivery_performance,
    COUNT(*) FILTER (WHERE review_score IS NOT NULL)        AS n,
    ROUND(AVG(review_score)::numeric, 3)                    AS mean_review,
    ROUND(STDDEV_SAMP(review_score)::numeric, 3)            AS sd_review
FROM order_fulfillment_funnel_mart
WHERE review_score IS NOT NULL
GROUP BY delivery_performance
ORDER BY mean_review DESC;

-- Late vs non-late (the two groups compared in the worked test)
SELECT
    CASE WHEN delivery_performance = 'Late' THEN 'Late' ELSE 'Non-late' END AS grp,
    COUNT(*) FILTER (WHERE review_score IS NOT NULL)        AS n,
    ROUND(AVG(review_score)::numeric, 3)                    AS mean_review,
    ROUND(STDDEV_SAMP(review_score)::numeric, 3)            AS sd_review
FROM order_fulfillment_funnel_mart
WHERE review_score IS NOT NULL
  AND delivery_performance IN ('Late', 'Early', 'On Time')
GROUP BY 1
ORDER BY mean_review DESC;

-- Baseline repeat rate (input for the second-purchase nudge sample-size design)
SELECT
    COUNT(*)                                                   AS customers,
    COUNT(*) FILTER (WHERE orders > 1)                         AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE orders > 1) / COUNT(*), 2) AS repeat_rate_pct
FROM (
    SELECT dc.customer_unique_id, COUNT(DISTINCT fo.order_id) AS orders
    FROM fact_orders fo
    JOIN dim_customers dc ON fo.customer_id = dc.customer_id
    GROUP BY dc.customer_unique_id
) t;
