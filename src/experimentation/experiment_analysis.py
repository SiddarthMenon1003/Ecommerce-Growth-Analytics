"""
Case 06 - Experimentation: worked analysis
==========================================

Runs two things end to end, printing a report:

1. OBSERVATIONAL TEST (real data): does late delivery lower review scores?
   Pulls review scores by delivery timing from the warehouse and runs a
   Welch t-test (Late vs non-late), with 95% CI and effect size.
   NOTE: this is observational, not a randomized experiment - it quantifies
   an association, strong but not proof of causation.

2. EXPERIMENT DESIGN (framework): sample size / power for two proposed A/B
   tests - a second-purchase nudge (repeat rate) and a fulfillment change
   (review score) - using the reusable ab_toolkit.

Run:  python -m src.experimentation.experiment_analysis
Requires: a .env with DB_* credentials (see .env.example).
"""

import os
import numpy as np
import psycopg2
from dotenv import load_dotenv

from src.experimentation import ab_toolkit as ab

load_dotenv(".env")


def _conn():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"), port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"), user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"))


def observational_delivery_vs_reviews():
    print("=" * 70)
    print("1. OBSERVATIONAL TEST - Late delivery vs review score")
    print("=" * 70)
    with _conn() as c:
        cur = c.cursor()
        cur.execute("""
            SELECT delivery_performance,
                   COUNT(*) FILTER (WHERE review_score IS NOT NULL) AS n,
                   AVG(review_score)        AS mean,
                   STDDEV_SAMP(review_score) AS sd
            FROM order_fulfillment_funnel_mart
            WHERE review_score IS NOT NULL
            GROUP BY delivery_performance""")
        groups = {r[0]: dict(n=int(r[1]), m=float(r[2]), sd=float(r[3]))
                  for r in cur.fetchall()}

    late = groups["Late"]
    # combine the on-schedule groups (Early + On Time) into "non-late"
    on = [groups[k] for k in ("Early", "On Time") if k in groups]
    n2 = sum(g["n"] for g in on)
    m2 = sum(g["n"] * g["m"] for g in on) / n2
    ss = sum((g["n"] - 1) * g["sd"] ** 2 + g["n"] * (g["m"] - m2) ** 2 for g in on)
    sd2 = np.sqrt(ss / (n2 - 1))

    print(f"  Late     : n={late['n']:>6}  mean={late['m']:.3f} stars")
    print(f"  Non-late : n={n2:>6}  mean={m2:.3f} stars")
    res = ab.welch_ttest_summary(late["n"], late["m"], late["sd"], n2, m2, sd2)
    print("  Result   :", res.summary())
    sig = "REJECT H0 (significant)" if res.p_value < 0.05 else "fail to reject H0"
    print(f"  Verdict  : {sig} at alpha=0.05; effect size is "
          f"{'large' if abs(res.cohens_d) >= 0.8 else 'moderate/small'}.")
    print("  Caveat   : observational (not randomized) - association, not proof.\n")


def design_second_purchase_nudge():
    print("=" * 70)
    print("2a. DESIGN - Second-purchase nudge (repeat rate)")
    print("=" * 70)
    baseline = 0.031  # current repeat purchase rate
    print(f"  Baseline repeat rate: {baseline:.1%}")
    for lift in (0.003, 0.005, 0.010):
        n = ab.sample_size_proportions(baseline, baseline + lift)
        print(f"   +{lift*100:.1f}pp (to {baseline+lift:.1%}, rel +{lift/baseline:.0%}): "
              f"{n:>7,} per arm  ({2*n:,} total)")
    # duration example: assume ~330 new eligible customers per day
    eligible_per_day = 330
    n = ab.sample_size_proportions(baseline, baseline + 0.005)
    days = ab.experiment_duration(2 * n, eligible_per_day)
    print(f"  At ~{eligible_per_day}/day eligible, the +0.5pp test needs ~{days} days.\n")


def design_fulfillment_review_test():
    print("=" * 70)
    print("2b. DESIGN - Fulfillment change (review score)")
    print("=" * 70)
    sd = 1.25  # approx review-score std dev
    for mde in (0.05, 0.10, 0.20):
        n = ab.sample_size_means(mde, sd)
        print(f"   MDE {mde:.2f} star: {n:>7,} per arm")
    print()


if __name__ == "__main__":
    observational_delivery_vs_reviews()
    design_second_purchase_nudge()
    design_fulfillment_review_test()
