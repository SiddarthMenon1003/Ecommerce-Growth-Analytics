# Executive Growth Strategy — Olist Marketplace

*Synthesis of Cases 1–6, the ML layer (RFM + churn), and the Power BI deck into a single
decision document: where the business stands, why growth is stalling, what to do about it,
and what it is worth. All figures trace to the SQL marts and models in this repository.*

**Scope of the data:** 96,096 customers · R$16.0M total revenue · R$161 average order
value · order history Sep 2016 – Oct 2018 (Brazilian e-commerce, Olist public dataset).

---

## 1. Executive summary

The business has a **healthy top of funnel and a broken middle**. Acquisition works —
revenue grew year over year — but **96.9% of customers buy exactly once**, so growth is
bought one order at a time rather than compounded through retention. The single largest
lever is not more traffic; it is **converting first orders into second orders**, and the
cheapest way to move that lever is **fixing the first-delivery experience**, which the data
links directly to both satisfaction and repeat propensity.

Three moves, in priority order:

1. **Launch a second-purchase program aimed at the High-propensity band** — buyers the
   churn model ranks ~2.3× more likely to return.
2. **Protect the first-order delivery experience** — late delivery is the biggest driver of
   bad reviews *and* a top feature in repeat propensity. One fix, two payoffs.
3. **Concentrate marketing on high-value customers and winning categories** — a thin tail
   consumes budget for little return.

---

## 2. Where the business stands (performance snapshot)

| Signal | Value | Source |
|---|---|---|
| Total revenue | R$16.0M | Fact Payments |
| Customers | 96,096 | Dim Customers |
| One-time buyers | **96.9%** | Case 1 — Retention |
| Repeat buyers | 3.1% | Case 1 |
| Value of a repeat customer vs one-time | ~**2×** (R$315 vs R$162) | Case 3 — CLV |
| Revenue from "Big Spenders" segment | **57%** of revenue from ~30% of customers | RFM (ML) |
| On-time delivery | 91.9% (8.1% late) | Case 4 — Fulfillment |
| Review-score penalty for a late order | ~**−1.7 to −2.0 stars** | Case 4 / Case 6 |

**Read:** revenue is real and growing, but it rests on a one-purchase base. Value is
concentrated in a small set of high-spend, mostly one-time customers, and the clearest
dissatisfaction signal in the dataset is delivery lateness.

---

## 3. Root cause — why growth is stalling

1. **Acquisition-led, retention-weak.** With 96.9% one-time buyers, customer lifetime value
   is capped at roughly a single order. Every month starts the revenue climb near zero and
   rebuilds it from new acquisition. That is expensive and fragile.

2. **The value is concentrated and unrepeated.** The ML segmentation (RFM + K-Means) shows
   **Big Spenders** — ~30% of customers, **57% of revenue** — but they buy **once**. The
   only genuinely repeat segment (**Champions**, freq ≈ 2.1) is ~3% of customers and ~6% of
   revenue. The business is leaving the most valuable behaviour (a second high-value order)
   on the table.

3. **Delivery is the satisfaction bottleneck.** 8.1% of delivered orders arrive late, and a
   late order costs ~1.7–2.0 review stars (Case 4 observational; Case 6 Welch t-test,
   Cohen's d ≈ −1.7). The churn model independently surfaces **delivery-vs-estimate gap and
   delivery days** as top repeat-propensity features. Satisfaction and retention fail at the
   same point: the first delivery.

---

## 4. Recommendations (prioritized by impact × effort)

### R1 — Second-purchase program, aimed at the High-propensity band  *(high impact · medium effort)*
Use the churn model's `risk_band` to target the **High** band — buyers returning at **4.9%
vs 2.1%** for Low (2.3×). A post-delivery nudge (reminder, category-relevant offer, light
incentive) spent on this band works roughly twice as hard as a blanket campaign. Measure it
as a proper experiment (Case 6 toolkit): treatment vs holdout, repeat-within-180-days as the
primary metric.

### R2 — Protect the first-order delivery experience  *(high impact · medium effort)*
Late delivery is the one lever that moves **both** satisfaction and repeat propensity. Tighten
delivery-estimate accuracy (under-promise), flag sellers/routes with the worst
estimated-vs-actual gaps, and intervene on at-risk shipments before they go late. Cheapest
high-leverage fix in the dataset.

### R3 — Focus marketing on high-value customers and winning categories  *(medium impact · low effort)*
Case 2 shows budget spread across a long tail that yields little. Direct spend to the
Big-Spenders profile and the top revenue categories (Case 5 Pareto: a handful of categories
carry most revenue). Stop subsidising the tail.

### R4 — Grow the category winners, triage the laggards  *(medium impact · medium effort)*
Revenue is concentrated in a few fast-growing categories (Case 5). Double down on the
compounders; for declining categories, decide deliberately — invest, reprice, or exit — rather
than drift.

---

## 5. 90-day plan

**Days 0–30 — Instrument & baseline**
- Stand up the second-purchase experiment: define treatment/holdout on the High band, lock
  the primary metric (repeat-within-180d) and MDE (Case 6 sample-size math).
- Build the delivery-risk watchlist: sellers/routes by estimated-vs-actual gap.
- Baseline repeat rate, late rate, and segment revenue in the Power BI deck.

**Days 31–60 — Intervene**
- Ship the High-band post-purchase nudge to the treatment group.
- Launch delivery-estimate tightening on the worst-gap lanes; pre-empt at-risk shipments.
- Reallocate a defined slice of marketing spend from tail to high-value profile.

**Days 61–90 — Read & scale**
- Evaluate the experiment (Welch / two-proportion z-test; confidence intervals, not just a
  point estimate).
- If the nudge clears its MDE, scale to Medium band; if delivery fixes move review scores,
  expand the watchlist coverage.
- Review category bets; reallocate for the next quarter.

---

## 6. Expected financial impact (transparent, with assumptions)

These are **illustrative estimates**, stated with their assumptions so they can be argued
with — not headline numbers dressed up as certainty.

**Lever 1 — Second-purchase lift on the High band**
- High band scored ≈ 19,220 customers; base repeat ≈ 4.9%.
- Assume the nudge lifts High-band repeat by **+2 percentage points** (4.9% → 6.9%).
- Incremental second orders ≈ 19,220 × 2% ≈ **384 orders** × R$161 AOV ≈ **~R$62K** per cycle.
- Extend the same +2pp program to the Medium band (≈ 28,800) → another ~R$93K. Combined
  **~R$150K** incremental revenue per cycle, before repeat-of-repeat compounding.

**Lever 2 — Delivery improvement**
- 8.1% late ≈ small five-figure order count per period arriving late. Removing the ~1.7-star
  penalty on even half of them lifts average review score materially and, via the propensity
  model, nudges repeat rate upward — compounding Lever 1 rather than adding to it separately.

**Sensitivity:** at a conservative **+1pp** lift the High+Medium program is ~R$75K/cycle; at
an aggressive **+4pp** it is ~R$300K/cycle. The point is the **shape**: retention spend on the
ranked High band returns multiples of blanket spend, and delivery is the free multiplier.

---

## 7. Impact × effort matrix

```
        high impact
             |
   R2 ●      |   ● R1
 (delivery)  |   (2nd-purchase)
-------------+------------------  effort
   R3 ●      |   ● R4
 (focus mktg)|   (category bets)
             |
         low impact
```

Do **R1 and R2 first** — highest impact, and they reinforce each other (a better first
delivery raises the propensity score the nudge then targets). R3 is a quick reallocation win.
R4 is a deliberate portfolio decision for the following quarter.

---

## 8. How success is measured

Everything above is written to be **tested, not asserted** (Case 6):
- **Second-purchase program:** two-proportion z-test on repeat-within-180d, treatment vs
  holdout; power and sample size fixed in advance; report the confidence interval.
- **Delivery fixes:** difference in mean review score, late vs on-time, before/after
  (Welch's t-test, effect size).
- **Segment/category reallocation:** revenue share and repeat rate by segment, tracked in the
  Power BI deck month over month.

---

## 9. Risks & honest caveats

- **Weak repeat signal.** The churn model is a **ranker, not a classifier** (ROC-AUC ≈ 0.58);
  a one-purchase marketplace caps the achievable signal. Its value is the band ranking, not
  precise per-customer prediction.
- **No channel/marketing instrumentation.** The dataset has no acquisition-source data, so
  marketing ROI is scoped to value-based prioritisation, not true CAC/LTV. Better
  instrumentation would raise the ceiling more than any model tuning.
- **Observational delivery effect.** The late-delivery → review link is strong and consistent
  but observational; the Case 6 experiment design exists precisely to confirm causality before
  large spend.
- **Window dependence.** Repeat is defined on a 180-day horizon; a different window shifts the
  base rate and scores.

---

*Backing analysis: `sql/executive_cases/` (Cases 1–6), `src/ml/` (RFM + churn),
`src/experimentation/` (A/B toolkit), and the 8-page Power BI deck in `dashboards/`.*
