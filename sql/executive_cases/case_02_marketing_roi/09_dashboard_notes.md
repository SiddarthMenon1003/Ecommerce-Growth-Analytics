# Dashboard Design Specification — Customer Value & Marketing Prioritisation

## Objective

Give leadership a view of **where customer value concentrates** and **which customers to
prioritise** for spend. This is a value-prioritisation dashboard, not a marketing-ROI
dashboard — CAC/ROAS are out of scope until spend/channel data exists (see findings).

## Target Audience
CMO · VP Growth · VP Marketing · Head of CRM · Business Analysts.

## Business Questions
- Where does revenue concentrate across customer value tiers?
- Which customers should receive priority spend?
- How much revenue sits in the high-value tier vs the long tail?
- What would it take to measure true marketing ROI? (gap view)

---

## Data Model

Primary source: `marketing_roi_mart` (rename to **Customer LTV / Prioritisation** per
remediation P2), related to `Dim Customers` and `Dim Date`.

> Grain: the mart SQL is fixed to `customer_unique_id` grain (repeat customers now appear;
> 96.9% one-time / 3.1% repeat). Until the ETL is re-run and the dataset refreshed, the
> live import still shows the old order-grain — refresh before relying on repeat/LTV visuals.

Theme: apply [`powerbi/product_growth_executive_theme.json`](../../../powerbi/product_growth_executive_theme.json).
Follow the shell in [`docs/dashboard_ui_overhaul.md`](../../../docs/dashboard_ui_overhaul.md).

---

## Page structure

### Page 1 — Value Overview
KPIs (cards): Total Customers · Total Revenue · Avg Revenue per Customer · % Revenue from Top Tier
Visuals:
- **Revenue concentration (hero)** — Pareto: customers sorted into tiers on X, cumulative
  % revenue line. Shows "20% → 53%". Blue bars + orange cumulative line.
- **Revenue by priority** — bar: Convert / Nurture / Low Priority (blue / orange / grey).
- **Customers by priority** — bar, same colour roles, data labels on.
Business question: Where does value concentrate?

### Page 2 — Priority Segments
KPIs: Convert customers · Convert revenue · Avg revenue (Convert vs Low) · Revenue share top tier
Visuals:
- **Segment value matrix** — matrix of value segment × customer type, shaded by revenue
  (blue sequential ramp). Highlights that repeat tiers are empty (grain caveat).
- **Avg revenue per customer by priority** — bar.
- **Revenue vs customer count by priority** — scatter (bubble = revenue).
Business question: Who do we prioritise?

### Page 3 — Marketing Measurement Gap
A deliberately honest page (consulting move): states what cannot be measured and why.
Visuals:
- Text panel: metrics unavailable (CAC, ROAS, payback) and the data needed to unlock them.
- Checklist visual: instrumentation required (channel, spend, attribution).
- Target-state mock: what the ROI view will look like once data exists.
Business question: What must we instrument to measure true ROI?

### Page 4 — Executive Insights
Key findings (value concentration) + recommendations (reallocate by value) + priority
matrix. No raw visuals — the screenshot page for leadership.

---

## Global Filters
Customer State · Product Category · Payment Type · Customer Value Segment · Marketing Priority.

## Design Principles
Minimal clutter · consistent palette (blue primary, orange secondary, grey tail) ·
value-first storytelling · honesty about the measurement gap · ≤4 visuals per page.

## Colour roles
Convert = `#2a78d6` · Nurture = `#eb6834` · Low Priority = `#898781` ·
sequential revenue shading = blue ramp `#cde2fb` → `#0d366b`.
