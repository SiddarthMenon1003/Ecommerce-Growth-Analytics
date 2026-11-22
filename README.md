# Product Growth Analytics Lab

## Data-Driven Growth Strategy & Decision Intelligence

An end-to-end analytics engineering project that takes the Brazilian **Olist**
e-commerce dataset (~99K orders, ~96K customers, R$16M revenue) from raw CSVs to a
modeled PostgreSQL warehouse, a library of business-focused SQL analyses, and a
consulting-grade Power BI report — framed around the growth questions a CEO would
actually ask.

The goal is not to produce queries and charts. It is to **turn data into decisions**:
identify growth bottlenecks, quantify impact, and recommend action.

---

# Project Status

This is an **actively built** project. The sections below separate what is **done** from
what is **planned** — nothing here is claimed as finished unless it ships in the repo.

| Area | Status |
|---|---|
| Environment, PostgreSQL warehouse, ETL pipeline | ✅ Built |
| Dimensional model (star schema) + data validation | ✅ Built |
| 5 analytics marts | ✅ Built |
| **Case 1 — Customer Retention** | ✅ Built (SQL + dashboard) |
| **Case 2 — Customer Value & Marketing Prioritisation** | ✅ Built (SQL + dashboard) |
| **Case 3 — Customer Segmentation (value-tier, rule-based)** | ✅ Built (SQL + dashboard) |
| **Case 4 — Order Fulfillment Funnel** | ✅ Built (SQL + dashboard) |
| **Case 5 — Revenue Growth Analysis** | ✅ Built (SQL + mart + dashboard page) |
| **Case 6 — Experimentation / A/B Testing** | ✅ Built (toolkit + worked test) |
| Power BI report (7 pages, 43 tables, 120 measures) | ✅ Built |
| Case 3 upgrade — RFM + K-Means segmentation | 🔜 Planned |
| Churn prediction model (classification + SHAP) | 🔜 Planned |
| Executive Growth Strategy Report | 🔜 Planned |

> **Honesty note.** The Python ML layer (`src/ml`) and the experimentation work are
> scaffolded but **not yet implemented**. Where the README describes RFM, K-Means,
> churn modeling, or A/B testing, treat it as the **roadmap**, not delivered work.

---

# What's Built (the real deliverables)

### Data engineering
- **PostgreSQL data warehouse** built from the Olist CSVs via a Python ETL pipeline
  (`src/etl`, `src/database`): extract → stage → transform → load, with a warehouse
  validation step.
- **Dimensional model (star schema):** `Dim Customers`, `Dim Date`, `Dim Products`,
  `Dim Sellers` around `Fact Orders`, `Fact Order Items`, `Fact Payments`, `Fact Reviews`.

### SQL analytics
- **40+ SQL files**: 5 analytics marts, executive Cases 1–5 with 6 analyses each
  (Case 6 adds observational-data SQL), plus setup / transform / validation scripts.
- Each case ships `07_business_findings.md`, `08_recommendations.md`, and
  `09_dashboard_notes.md` — analysis tied to **decisions**, not just query output.
- SQL depth: CTEs, window & ranking functions (`ROW_NUMBER`, `RANK`, `NTILE`, `LAG`/`LEAD`),
  subqueries, multi-table joins.

### Business intelligence
- **Power BI report (PBIP format)** with a semantic model of **42 tables and 112 DAX
  measures**, and a **6-page narrative**: Overview · Retention · CLV · Segmentation ·
  Marketing · Fulfillment — styled on the Microsoft Fluent2 design system.

---

# Business Context

A mid-sized e-commerce company has grown fast but is now slowing: retention is declining,
repeat purchasing is weak, acquisition is getting more expensive, and marketing ROI is
deteriorating. Leadership needs a **data-driven growth strategy**, not another report.

This project is the analytical foundation for that strategy, worked case by case.

---

# The Cases

### Case 1 — Why is customer retention declining? ✅ Built
Cohort analysis, retention curves, repeat-purchase and customer-lifetime SQL feed a
**Retention** dashboard page. **Headline finding:** the marketplace is acquisition-led —
**96.9% of customers buy only once**, and repeat buyers (worth ~2× a one-time buyer:
R$315 vs R$162) are only **5.9% of revenue**.

### Case 2 — Which customers should marketing prioritise? ✅ Built
Value-based prioritisation (Convert / Nurture / Low Priority tiers), value concentration
(Pareto), and segment profitability feed a **Marketing** page. **Headline finding:** the
**top 20% of customers drive 53% of revenue** (R$8.56M, ~R$430 each).

> **Data limitation (stated honestly):** Olist has no marketing spend, channel, or
> attribution data, so true **CAC / ROAS / payback cannot be computed**. This case is
> scoped to *value-based prioritisation*. See
> `sql/executive_cases/case_02_marketing_roi/07_business_findings.md` for the framing and
> the instrumentation needed to measure real marketing ROI later.

### Case 3 — Which customers matter most? ✅ Built (rule-based) · 🔜 ML upgrade planned
**What's built:** a **rule-based High / Medium / Low value segmentation** with behavioural
profiling and a personalization strategy, feeding a **Segmentation** page (customer value
map, per-segment order value and frequency, top customers).
**Planned:** upgrade to **RFM + K-Means clustering** with named segments (Champions, Loyal,
At-Risk, Lost). *Not yet built.*

### Case 4 — Order fulfillment: is delivery helping or hurting growth? ✅ Built
> **Scope note:** Olist has **no clickstream** (no page views, carts, or checkout events),
> so a true *conversion* funnel (Visit→View→Cart→Checkout→Purchase) is not possible with
> this data. Case 4 is therefore an **order-fulfillment funnel**: Created → Approved →
> Shipped → Delivered.

The **Fulfillment** page covers delivery completion, late-delivery rate, and the review
impact of timing. **Headline finding:** **8.1% of orders arrive late**, and late orders
score **2.57★ vs 4.29★ on-time** — a 1.73★ hit; the warehouse-to-carrier handoff (~2.8
days) is the main controllable delay, and high-value orders get no priority.

### Case 5 — Where will future revenue come from? ✅ Built (SQL + dashboard page)
Revenue-trend, category-performance, growth-portfolio and business-impact SQL on a
category × month `revenue_growth_mart`. **Headline finding:** revenue is growing
year-on-year (R$6.16M 2017 → R$7.39M 2018-to-Oct, peaking Nov-2017) but **concentrated**
(top 10 categories = 62% of revenue; 18 of 74 categories = 80%) — and the biggest
categories are also the **fastest growing** on a same-period YoY basis
(*relogios* +175%, *beleza_saude* +158%, *informatica* +102%).
Growth remains acquisition-led, so repeat purchasing is the largest untapped lever. A
dedicated **Revenue Growth** page (area trend, category Pareto, growth-portfolio scatter,
waterfall) is wired into the report.

### Case 6 — Which experiment should we run next? ✅ Built (framework + worked test)
> **Scope note:** Olist has **no randomized-experiment data**, so a true A/B test can't be
> run on it. Case 6 delivers a reusable **statistics toolkit** + a **worked test on real
> observational data** + **design templates** — honestly scoped.

A/B design/evaluation toolkit (`src/experimentation/ab_toolkit.py`: sample size, power,
MDE, Welch t-test, two-proportion z-test) and a runnable worked analysis
(`experiment_analysis.py`). **Headline finding:** late delivery is associated with a
**~2-star lower review** (4.29★→2.27★; Welch t≈−101, p≈0, Cohen's d≈−1.71 — large). Design
sizing: a fulfillment review-lift test is cheap (~2.5K/arm for 0.1★); the second-purchase
nudge is expensive (~20K/arm for +0.5pp on a 3.1% base).

---

# Roadmap (planned, not yet built)

- **Case 3 ML upgrade:** RFM scoring + K-Means clustering + segment profiling.
- **Churn prediction:** feature engineering, classification modeling, SHAP explainability,
  churn risk scores.
- **Executive Growth Strategy Report:** current performance → root cause → recommendations
  → 90-day roadmap → financial impact, using an Impact-vs-Effort prioritisation.

---

# Technical Architecture

**Built**
- **PostgreSQL** data warehouse (star schema) with validation.
- **Python ETL** (`src/`): extract / transform / load, staging, warehouse build & validate.
- **Advanced SQL:** CTEs, window functions, ranking functions, subqueries, complex joins.
- **Power BI (DAX):** 120 measures, 7-page report, Fluent2 design system.
- **Statistics (Python):** A/B test design (power, sample size, MDE) + evaluation
  (Welch t-test, two-proportion z-test, confidence intervals, effect size) — scipy/statsmodels.

**Planned**
- **Machine learning (Python):** RFM, K-Means, churn classification, SHAP.
- Additional visualization (Plotly / Streamlit) if needed.

---

# Skills Demonstrated vs Planned

**Demonstrated in this repo today**
- PostgreSQL · advanced SQL (CTEs, window/ranking functions) · ETL pipelines ·
  dimensional data modeling · data validation
- Power BI / DAX · BI data modeling (112 measures) · dashboard design & data storytelling
- Cohort, retention, value-segmentation and fulfillment analysis · executive-style
  findings & recommendations

- Statistics & experimentation: A/B test design (power/sample size/MDE) and evaluation
  (Welch t-test, two-proportion z-test, confidence intervals, effect size)

**Planned (not yet demonstrated)**
- Machine learning: RFM, K-Means, churn prediction, SHAP
- The executive strategy report

---

# Repository Structure

```
data/            Raw Olist CSVs (gitignored) + processed data
src/             Python: config, database build, ETL, utils, experimentation (Case 6)  (ml/ai_advisor scaffolded)
sql/
  setup/         Table + staging DDL
  transform/     Dimension + fact population
  validation/    Warehouse validation
  analytics_marts/   4 analytical marts (retention, marketing, segmentation, fulfillment)
  executive_cases/   Cases 01–05: 6 analyses each + findings/recommendations/dashboard notes
                     Case 06: observational-data SQL + findings (code lives in src/experimentation)
dashboards/      Power BI project (.pbip): report + semantic model
powerbi/         Theme files
docs/            Data dictionary, warehouse design, model/dashboard notes
notebooks/       Data understanding (01)
```

---

# Data Source

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
— ~99K orders (2016–2018), ~96K customers, order items, payments, reviews, geolocation.

**Known limitations** (and why they shape the cases): no marketing spend/attribution (so
no true CAC/ROAS), and no clickstream (so no conversion funnel). The analysis is scoped
honestly around what the data can support.

---

# Project Intent

The aim is to move beyond reporting toward **executive decision support** — identifying
growth bottlenecks, quantifying their impact, and recommending action. The warehouse,
SQL case library, and BI report are the foundation; the ML, experimentation, and strategy
layers are the roadmap being built on top of it.
