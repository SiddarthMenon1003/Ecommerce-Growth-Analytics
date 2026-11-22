# Strategic Recommendations — Experimentation

### 1. Run a fulfillment-improvement A/B test first 🔴 High
The delivery → review signal is large, continuous, and cheap to power
(~2,450 per arm for a 0.1★ lift). Test an operational change (e.g., priority
carrier routing or a tighter warehouse-to-carrier SLA) on a random subset of
orders and measure the review-score effect.
- **Primary metric:** average review score. **Guardrail:** fulfillment cost.
- **Design:** 80% power, α = 0.05, MDE 0.1★ → ~2,450 orders/arm.

### 2. Design the second-purchase nudge carefully — it is hard to power 🟡 Medium
The repeat rate is only 3.1%, so detecting a modest lift needs a large sample
(~20,300/arm for +0.5pp, ~4 months). Either (a) commit to the duration, (b) aim
for a bigger expected effect, or (c) use a stronger proxy metric (e.g., 30-day
return visit) with a higher base rate to power faster.
- **Primary metric:** repeat purchase rate. **Guardrail:** discount cost / margin.

### 3. Stand up the experimentation plumbing 🔴 High (enabler)
None of this becomes a real test until the platform can **randomly assign**
customers/orders to arms and **log the assignment + outcome**. Minimum viable
instrumentation:
- a stable randomisation unit (customer_unique_id) and an assignment table,
- event logging for the primary + guardrail metrics,
- a pre-registered analysis plan (metric, test, stopping rule).

### 4. Adopt a standard test scorecard 🟡 Medium
For every experiment, report: hypothesis, sample size & power, observed effect,
confidence interval, p-value, and effect size — using `ab_toolkit.py` so results
are consistent and comparable. Avoid peeking / unplanned stopping.

### 5. Build a backlog ranked by Impact × Confidence × Ease 🟢 Low
Prioritise the experiment queue the same way as the growth roadmap, so testing
effort goes where expected value is highest (fulfillment and retention first).
