# Case 1 (ML extension) — Churn / second-purchase propensity

An ML layer on top of the retention case. Code: `src/ml/churn_model.py`
(`python -m src.ml.churn_model`). It scores every customer on how likely they
are to come back, and writes the result to Postgres as `customer_churn_scores`.

## Why this is framed as second-purchase propensity

Olist has no subscription, no cancellation, and no account-closed event, so
there is no classic churn signal (an active customer going inactive). On top of
that, 96.9% of customers buy exactly once, so there is almost no repeat base to
lapse in the first place.

So "churn" is defined as the actionable inverse:

> For each customer's **first order**, predict the probability they place a
> **second order within 180 days**. Churn risk = 1 − P(repeat).

This targets the project's biggest growth lever directly: converting one-time
buyers into repeat buyers.

## Target and cohort

- **Grain:** `customer_unique_id` (true customer), same as the RFM work.
- **Label:** `repeat_180 = 1` if a second distinct order lands within 180 days
  of the first, else `0`.
- **Right-censoring:** customers whose first order is close to the data cutoff
  (2018-10-17) have not had a full 180 days to return, so labelling them `0`
  would be wrong. Only customers with a first order on or before
  **2018-04-20** (cutoff − 180 days) are used to train and evaluate. Everyone
  is still scored for the dashboard.

| Quantity | Value |
|---|---|
| First-order customers (scored) | 96,096 |
| Eligible cohort (full 180-day window) | 68,988 (71.8%) |
| Base repeat rate (eligible) | 3.04% |

## Features

Everything is computed **as of the first order** — no lifetime aggregates, no
recency measured at the dataset end, nothing that encodes the future.

- Order economics: first-order value, item count, freight, freight-to-value
  ratio, installments, payment type.
- Basket: top product category (long tail collapsed to top 12 + "other"),
  seller count, category count.
- Delivery experience: delivered flag, late flag, delivery days, estimated-vs-
  actual gap, approval time.
- Satisfaction: first-order review score. *(Caveat: a review posts after
  delivery, so for a very fast second purchase it can arrive slightly late;
  the effect is minor and the feature is kept.)*
- Geography: customer state. Temporal: purchase month, day of week.

## Models and evaluation

Split is **time-aware** — train on earlier cohorts (48,291), test on the most
recent 30% (20,697) — to mimic real forward prediction. Accuracy is not
reported: at a 3% base rate, predicting "never returns" for everyone scores
97%. The metrics that matter are PR-AUC and top-decile lift.

| Model | ROC-AUC | PR-AUC | Top-decile lift |
|---|---|---|---|
| Logistic regression | **0.577** | **0.041** | **1.84×** |
| XGBoost | 0.548 | 0.036 | 1.42× |

The logistic baseline wins on the held-out recent cohort, so it is the
deployed scorer. The signal is faint and close to linear, which is why
gradient boosting — with aggressive class weighting on a rare positive — adds
noise rather than lift. That is the expected outcome for a one-purchase
marketplace, and it is reported as it landed rather than tuned until the tree
model looks better.

### The model is a ranker, not a classifier

AUC near 0.58 is weak as a classifier, but the scores rank customers usefully.
Repeat rate by risk band, on the labelled cohort:

| Risk band | Customers | Repeat rate |
|---|---|---|
| High | 13,818 | 4.91% |
| Medium | 20,277 | 3.32% |
| Low | 34,893 | 2.15% |

The High band returns at **2.3× the Low band** (4.9% vs 2.2%) and about 1.6× the
overall base. That separation is the business output: retention effort aimed at
the High band reaches buyers roughly twice as likely to come back.

## What drives the score (SHAP)

Global mean|SHAP| on the gradient-boosted model (`reports/churn_shap_summary.png`).
Top contributors: estimated-vs-actual delivery gap, payment installments,
first-order value, purchase month, delivery days, and freight-to-value ratio.
Read directionally, not causally: first-order experience and basket economics
carry what little signal exists; a smoother, better-priced, well-delivered first
order is associated with a modestly higher chance of a second.

## Limitations (stated plainly)

- No true attrition signal exists; this is second-purchase propensity, not
  churn in the subscription sense.
- Single-purchase dominance caps the achievable signal — expect ranking value,
  not a high-AUC classifier.
- The label depends on a 180-day window; a different horizon shifts the base
  rate and the scores.

## Recommendations

1. **Target the High band for the second-purchase nudge.** It returns at ~4.9%
   vs ~2.2% in the Low band, so the same retention spend works roughly twice as
   hard here.
2. **Protect the first-order experience.** Delivery-gap and delivery-day
   features carry the most signal, which lines up with Case 4 (late delivery
   costs ~1.7 stars) and Case 6 (late delivery ≈ 2 stars lower). A smoother
   first delivery is the cheapest lever that also moves repeat propensity.
3. **Do not over-invest in model complexity.** The data does not support a
   strong classifier. Spend on instrumentation (channel, marketing touch,
   post-purchase engagement) would raise the ceiling more than algorithm tuning.

## Artifacts

- `src/ml/churn_model.py` — pipeline (load → engineer → train → evaluate →
  score → write back).
- `customer_churn_scores` (Postgres) — `customer_unique_id`,
  `repeat_probability`, `churn_risk`, `risk_band`, `cohort_eligible`,
  `repeat_label` (96,096 rows).
- `churn_feature_importance` (Postgres) — aggregated mean|SHAP| driver ranking
  (one-hot dummies folded back to base feature + readable labels), charted as
  the "Top Drivers" bar on the Churn page.
- `reports/churn_shap_summary.png` — SHAP global summary.
