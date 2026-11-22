# RFM + K-Means Segmentation (ML upgrade)

This upgrades Case 3 from the rule-based High/Med/Low value tiers to a **behavioural
segmentation** learned with K-Means on RFM features. Code: `src/ml/rfm_segmentation.py`
(run: `python -m src.ml.rfm_segmentation`). Output table: `customer_rfm_segments`.

## Method
- **RFM at the true customer grain** (`customer_unique_id`): Recency = days since last
  purchase, Frequency = distinct orders, Monetary = total payment value. (Note: the
  earlier `customer_value_mart` is order-grain, so its frequency is always 1 — RFM is
  rebuilt from the fact tables to get real frequency.)
- Skewed **F & M log-transformed**, all features standardised.
- **K-Means, k = 4**, chosen via elbow + silhouette. (k=2 scores highest on silhouette but
  only separates repeat vs one-time; k=4 is the interpretable optimum.)
- Clusters profiled and named from their RFM centroids.

## Segments (96,095 customers)

| Segment | Customers | Recency (d) | Frequency | Avg Monetary | Revenue share |
|---|---|---|---|---|---|
| **Big Spenders** | 28,469 | 226 | 1.0 | R$323 | **57.4%** |
| **Hibernating** | 27,798 | 476 | 1.0 | R$119 | 20.6% |
| **Recent** | 36,831 | 196 | 1.0 | R$70 | 16.1% |
| **Champions** | 2,997 | 269 | 2.1 | R$315 | 5.9% |

## What it reveals
- **Big Spenders (~30% of customers) drive 57% of revenue — yet they buy only once.**
  This is the single biggest opportunity: a high-value first purchase that never repeats.
- **Champions** (the only repeat segment, freq 2.1) are tiny — 3.1% of customers, 5.9% of
  revenue — confirming the acquisition-led, low-loyalty pattern from Cases 1–2.
- **Hibernating** (lapsed ~16 months) and **Recent** (new, low-value) are large but
  low-yield pools — win-back and nurture targets respectively.

## How it differs from the rule-based tiers
The rule-based High/Med/Low split purely on value. RFM/K-Means adds the **recency and
frequency behaviour**, which separates *high-value-but-one-time* (Big Spenders) from
*repeat* (Champions) and *lapsed* (Hibernating) — a far more actionable view for
retention and targeting.

## Caveat
K-Means on a 97%-one-time base is dominated by Recency and Monetary (Frequency is ~1 for
all but Champions). The segments are still business-meaningful, but "Frequency" does little
work here — a richer frequency signal would need a longer observation window.
