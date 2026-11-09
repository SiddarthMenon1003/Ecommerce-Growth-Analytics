# Strategic Recommendations — Customer Value & Marketing Prioritisation

These recommendations follow directly from the value concentration in the findings: 20%
of customers drive 53% of revenue. The goal is to allocate limited budget by customer
value rather than by raw acquisition volume.

---

## Recommendation 1 — Reallocate budget toward the high-value "Convert" tier

### Priority 🔴 High
### Challenge
The top 20% of customers (19,900) generate 53% of revenue (R$8.56M) at ~R$430 each, yet
budget is spent uniformly across all tiers.
### Recommendation
Shift acquisition and reactivation spend toward look-alikes of the Convert tier and
protect these customers with priority service and targeted offers.
### Expected Impact
Higher revenue per marketing dollar by concentrating spend where value is proven.
### Success Metrics
Revenue from top tier · Avg revenue per customer · Share of spend on high-value look-alikes

---

## Recommendation 2 — Nurture the middle tier selectively, not uniformly

### Priority 🟡 Medium
### Challenge
The Nurture tier is 40% of customers but only 33% of revenue at ~R$133 each.
### Recommendation
Use low-cost, automated touches (email, recommendations) rather than paid media to lift
mid-tier value; promote only those showing high-value signals toward the Convert tier.
### Expected Impact
Incremental value from the middle at low marginal cost.
### Success Metrics
Mid-tier avg revenue · Migration rate Nurture → Convert · Cost per nurtured customer

---

## Recommendation 3 — Minimise paid spend on the low-value tier

### Priority 🟡 Medium
### Challenge
The bottom 40% of customers contribute only 13% of revenue (~R$54 each).
### Recommendation
Cap paid acquisition and retention spend on this tier; serve it through organic and
self-service channels only.
### Expected Impact
Freed budget redirected to Recommendation 1 without material revenue loss.
### Success Metrics
Spend per low-tier customer · Revenue retained after spend cut

---

## Recommendation 4 — Instrument marketing data so ROI becomes measurable

### Priority 🔴 High (enabler)
### Challenge
CAC, ROAS and payback are currently impossible — no spend, channel or attribution data
exists. Any ROI figure from this dataset would be fabricated.
### Recommendation
Capture channel, campaign and spend at the customer level (UTM/attribution + ad-spend
feed). Only then compute CAC by channel, blended ROAS, and payback period.
### Expected Impact
Turns a value-prioritisation exercise into a true marketing-ROI capability.
### Success Metrics
% of customers with channel attribution · CAC by channel · Blended ROAS · Payback period

---

## Recommendation 5 — Finish rolling out the customer-grain fix

### Priority 🔴 High (correctness) — SQL DONE, deployment pending
### Challenge
The marts were built on order-scoped `customer_id`, making every customer appear one-time
and collapsing `estimated_ltv` to revenue.
### Status
The mart SQL (`01`–`03`) now groups on `customer_unique_id` (fixed 2026-11-04). Remaining:
re-run the ETL to rematerialise the tables, refresh the Power BI dataset, and repoint the
mart→`Dim Customers` relationships to `customer_unique_id`. See remediation P0.
### Next step
After deployment, replace the `estimated_ltv` proxy (`revenue × purchase_frequency`) with
a defensible LTV (historical value, or `AOV × predicted orders`) and re-validate segments.
### Success Metrics
Repeat-customer % (true, now 3.1%) · Avg orders per customer · Validated LTV distribution

---

## Prioritisation

Immediate, data-supported moves: Recommendations 1–3 (reallocate by value). In parallel,
Recommendations 4 and 5 are enablers — without marketing instrumentation and a corrected
customer grain, the marketplace can prioritise by value but cannot yet measure true
marketing ROI or lifetime value.
