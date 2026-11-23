# Product Growth Analytics Lab — Full Project Overview

A complete, head-to-toe reference for the project: what it is, how it's built, every
analysis in it, the models, the dashboard, the findings, and the decisions behind them.
Built on the Brazilian Olist e-commerce dataset, it carries raw order data through a
PostgreSQL warehouse, a SQL analytics layer, a Python ML + statistics layer, an eight-page
Power BI report, and a capstone growth strategy.

> **One line:** find where growth stalls, size the impact, and say what to do next —
> warehouse → analysis → ML → BI → strategy, with the scope kept honest throughout.

---

## 1. At a glance

| | |
|---|---|
| **Dataset** | Olist Brazilian e-commerce (public), ~Sep 2016 – Oct 2018 |
| **Scale** | 96,096 customers · R$16.0M revenue · R$161 average order value |
| **Warehouse** | PostgreSQL star schema (4 dims + 4 facts) + 5 analytics marts |
| **Analysis** | 6 executive cases, each: 6 SQL analyses → findings → recommendations → dashboard notes |
| **ML** | RFM + K-Means segmentation; second-purchase (churn) propensity + SHAP |
| **Statistics** | A/B toolkit (power, sample size, MDE) + a worked observational test |
| **BI** | Power BI PBIP, 8 pages, ~130 DAX measures, Microsoft Fluent 2 styling |
| **Capstone** | Executive growth strategy synthesising all of the above |
| **Repo** | ~270 tracked files; password rotated + git history scrubbed |

---

## 2. Business context & the growth problem

A mid-sized marketplace that grew fast and is now slowing. The leadership questions:
who stays, who's worth most, where marketing should point, whether fulfillment helps or
hurts, where revenue grows, and how to test a change before betting on it.

**The core finding that frames everything:** the business is **acquisition-led and
retention-weak**. 96.9% of customers buy exactly once, so revenue is rebuilt from new
acquisition every month rather than compounded through repeat purchase. The single largest
growth lever is converting first orders into second orders — and the cheapest way to move
it is fixing the first-delivery experience.

**Two honest scope limits** (stated, not hidden):
- No marketing spend / channel / attribution data → no true CAC, ROAS, or payback.
- No clickstream → no visit-to-purchase conversion funnel (fulfillment funnel instead).

---

## 3. Architecture

```
Olist CSVs
   │  (Python ETL: extract → stage → transform → load)
   ▼
PostgreSQL warehouse  ──  star schema (4 dims + 4 facts)
   │  (SQL)
   ▼
5 analytics marts  ──  one per business question
   │
   ├──► Python ML   (RFM + K-Means, churn propensity + SHAP)  ──► result tables back in Postgres
   │
   ▼
Power BI (PBIP)  ──  semantic model + DAX + 8-page report
   │
   ▼
Executive Growth Strategy  (synthesis + 90-day plan)
```

---

## 4. Data & warehouse

**Star schema** (built by `src/etl` + `src/database`, DDL in `sql/setup`, population in
`sql/transform`, checks in `sql/validation`):

- **Dimensions:** `dim_customers`, `dim_date`, `dim_products`, `dim_sellers`
- **Facts:** `fact_orders`, `fact_order_items`, `fact_payments`, `fact_reviews`

**Grain caveat (handled explicitly):** Olist's `customer_id` is unique *per order*; the
stable customer key is `customer_unique_id`. So `dim_customers` is effectively order-grain.
Customer-level metrics use `DISTINCTCOUNT(customer_unique_id)`, and the ML layer rebuilds
customer-grain features directly on `customer_unique_id` (which is why the RFM/churn code
does not trust the order-grain marts for frequency).

Details: [`docs/warehouse_design.md`](warehouse_design.md),
[`docs/data_dictionary.md`](data_dictionary.md).

---

## 5. SQL analytics layer

**5 marts** (`sql/analytics_marts/`), each shaped for one question:
`customer_retention`, `marketing_roi`, `customer_segmentation`, `order_fulfillment_funnel`,
`revenue_growth`.

**6 executive cases** (`sql/executive_cases/`), each a folder of 6 SQL analyses plus
`07_business_findings.md`, `08_recommendations.md`, `09_dashboard_notes.md` — analysis tied
to decisions, not just query output. SQL depth: CTEs, window & ranking functions
(`ROW_NUMBER`, `RANK`, `NTILE`, `LAG`/`LEAD`), subqueries, multi-table joins.

| Case | Question | Headline finding |
|---|---|---|
| **1 — Retention** | Who comes back? | 96.9% buy once; repeat buyers worth ~2× (R$315 vs R$162) but only 5.9% of revenue |
| **2 — Marketing prioritisation** | Where should budget point? | Top 20% of customers = 53% of revenue (R$8.56M, ~R$430 each); long tail yields little |
| **3 — Segmentation** | Which customers matter most? | Rule-based tiers **+ ML**: Big Spenders ~30% of customers, 57% of revenue — and buy once |
| **4 — Fulfillment** | Does delivery help or hurt? | 8.1% late; late orders score 2.57 vs 4.29 stars (−1.73); carrier handoff (~2.8d) is the controllable delay |
| **5 — Revenue growth** | Where does revenue grow? | R$6.16M (2017) → R$7.39M (2018 through Oct); top 10 categories = 62%; biggest categories also fastest-growing |
| **6 — Experimentation** | How to test a change? | Reusable A/B toolkit + worked test: late delivery ≈ 2 stars lower (Welch t ≈ −101, d ≈ −1.71) |

---

## 6. Machine learning layer (`src/ml/`)

### 6.1 RFM + K-Means segmentation (`rfm_segmentation.py`)
Upgrades the rule-based tiers to behavioural clusters. RFM built at the true
`customer_unique_id` grain; frequency & monetary log-transformed, all features standardised;
**k = 4** chosen via elbow + silhouette. Clusters profiled and named from their centroids,
written back to Postgres as `customer_rfm_segments`.

| Segment | Customers | Recency | Frequency | Avg monetary | Revenue share |
|---|---|---|---|---|---|
| **Big Spenders** | 28,469 | 226d | 1.0 | R$323 | **57.4%** |
| **Hibernating** | 27,798 | 476d | 1.0 | R$119 | 20.6% |
| **Recent** | 36,831 | 196d | 1.0 | R$70 | 16.1% |
| **Champions** | 2,997 | 269d | 2.1 | R$315 | 5.9% |

**Insight:** Big Spenders drive 57% of revenue but buy once — the biggest opportunity.
Champions (the only repeat segment) are tiny, confirming the acquisition-led pattern.

### 6.2 Second-purchase (churn) propensity (`churn_model.py`)
Olist has no subscription/cancellation event, so "churn" is defined as the actionable
inverse: **P(a first-time buyer places a 2nd order within 180 days)**; churn risk = 1 − that.

- **Features** computed *as of the first order* (no leakage): order economics, basket,
  delivery experience, satisfaction, geography, temporal.
- **Time-aware split** (train earlier cohorts, test most-recent 30%); right-censored tail
  (first order after 2018-04-20) excluded from training but still scored.
- **Models:** Logistic vs XGBoost; **Logistic wins** on held-out PR-AUC and is deployed.
- **Honest result — a ranker, not a classifier** (ROC-AUC ≈ 0.58 on a 97%-one-time base):

| Risk band | Customers | Repeat rate |
|---|---|---|
| High | 13,818 | **4.91%** |
| Medium | 20,277 | 3.32% |
| Low | 34,893 | 2.15% |

High band returns at **2.3×** Low (base 3.04%). **SHAP drivers** (persisted to
`churn_feature_importance`, charted on the Churn page): delivery-vs-estimate gap, payment
installments, first-order value, purchase month, product category. Outputs:
`customer_churn_scores`, `churn_feature_importance`, `reports/churn_shap_summary.png`.

---

## 7. Statistics & experimentation (`src/experimentation/`)

- **`ab_toolkit.py`** — reusable: `sample_size_proportions` / `_means`, `mde_proportions`,
  `experiment_duration`, `welch_ttest_summary`, `two_proportion_ztest` (scipy + statsmodels).
- **`experiment_analysis.py`** — worked observational test: late vs on-time review scores,
  diff ≈ −2.0, Welch t ≈ −101, Cohen's d ≈ −1.71; plus design tables (a review-lift test
  needs ~2,500/arm for 0.1 star; a second-purchase nudge ~20,000/arm for +0.5pp on a 3.1%
  base).

This is what makes the recommendations testable rather than asserted.

---

## 8. Business intelligence (`dashboards/`)

Power BI **PBIP** (text-based) project: a star-schema semantic model (~130 DAX measures,
M/Power Query partitions from Postgres) and an **8-page narrative** styled on the Microsoft
**Fluent 2** design system.

**Pages, in narrative order:** Overview → Retention → CLV → Segmentation → Marketing →
Fulfillment → Revenue Growth → Churn.

Each page: KPI cards (several with sparklines), the main analysis, and a short read of what
the numbers mean. **Chart variety used where it adds value** — scatter/bubble segment map,
Pareto combo, area trend, monthly revenue-bridge waterfall, horizontal SHAP driver bar,
band columns, funnel — with Top-N filters where a full category axis would be unreadable.
Consistent colour system (muted gold / navy / slate), aligned headers, and a styled action
banner on the Churn page.

---

## 9. Capstone — executive growth strategy

[`docs/executive_growth_strategy.md`](executive_growth_strategy.md) synthesises everything
into a decision document: performance snapshot, root cause, recommendations prioritised by
**impact × effort**, a 90-day plan, and a transparent (assumption-stated) financial estimate.

**Top moves:** (R1) a second-purchase program aimed at the High-propensity band (~2.3× the
return of blanket spend); (R2) protect the first-order delivery experience (moves both
satisfaction *and* repeat propensity — one fix, two payoffs); (R3) focus marketing on
high-value customers and winning categories.

---

## 10. Consolidated headline numbers

- **96.9%** one-time buyers · repeat buyer worth **~2×** (R$315 vs R$162)
- **Big Spenders:** ~30% of customers, **57%** of revenue, buy once
- **8.1%** late delivery · late order = **−1.73 to −2.0** review stars
- **Churn High band** repeats at **4.9% vs 2.1%** (2.3×); base 3.04%; model ROC-AUC ≈ 0.58
- **Revenue** R$6.16M (2017) → R$7.39M (2018, Jan–Oct); top 10 categories = **62%**

---

## 11. Engineering & hygiene

- **Secrets:** DB credentials moved to a gitignored `.env` (`python-dotenv`); the hardcoded
  password was **rotated** and **scrubbed from git history** (`git-filter-repo`), verified
  gone via pickaxe. A bloated `.pbix` was removed from history (git ~92MB → ~1.8MB).
- **Repo trimmed** to portfolio-worthy content: editor config and Power BI local view state
  gitignored; internal process docs and an empty package removed; no `venv`, cache, or
  secrets tracked.
- **Honest README** — "Built vs Planned" kept accurate throughout; no over-claiming.

---

## 12. Repository map

```
data/           Raw Olist CSVs (gitignored) + processed output
src/
  config/       Settings
  database/     Warehouse build (DDL, dimension/fact population, validation)
  etl/          Extract → stage → transform → load
  ml/           rfm_segmentation.py, churn_model.py
  experimentation/  ab_toolkit.py, experiment_analysis.py
  utils/        Logger, SQL runner, validators
sql/
  setup/ transform/ validation/   Warehouse build + checks
  analytics_marts/                5 marts
  executive_cases/                Cases 01–06 (SQL + findings + recs + notes)
dashboards/     Power BI PBIP (Report + SemanticModel) + screenshot guide
docs/           Data dictionary, warehouse design, executive strategy, this overview
powerbi/        Theme files
notebooks/      Data-understanding EDA
reports/        SHAP summary PNG
```

---

## 13. How to run

Requires Python 3 and local PostgreSQL. Copy `.env.example` → `.env` and fill DB creds.

```bash
pip install -r requirements.txt
# 1. Build the warehouse (DDL → dimensions → facts → validation)
python -m src.database.build_warehouse
# 2. Build the ML segments + scores
python -m src.ml.rfm_segmentation
python -m src.ml.churn_model
# 3. Run the worked experiment analysis
python -m src.experimentation.experiment_analysis
# 4. Open the dashboard
#    dashboards/product_growth_analytics_lab.pbip in Power BI Desktop → Refresh
```

---

## 14. Skills demonstrated

Data engineering (warehouse, ETL, star schema, validation) · SQL (marts, window/ranking
functions, CTEs, joins) · Power BI modelling + 130 DAX measures + dashboard design · ML
(RFM/K-Means, propensity modelling, time-aware validation, SHAP) · Statistics (power,
sample size, MDE, Welch's t-test, two-proportion z-test, effect size) · business analysis
(bottleneck identification, impact sizing, prioritised recommendations) · engineering
hygiene (secrets management, history rewriting, honest documentation).

---

## 15. Honest limitations

- **No marketing/channel data** → value-based prioritisation, not true marketing ROI.
- **One-purchase dominance** caps the churn model's achievable signal → ranking value, not a
  high-AUC classifier. Reported as it landed, not tuned to look better.
- **Observational delivery effect** — strong and consistent, but the Case 6 experiment design
  exists to confirm causality before large spend.
- **180-day window** defines "repeat"; a different horizon shifts the base rate and scores.

---

## 16. Possible extensions

- A randomised second-purchase experiment (the toolkit and design already exist).
- Delivery-risk scoring at the shipment level to pre-empt late deliveries.
- Richer frequency signal with a longer observation window.
- A hosted interactive dashboard (currently PBIP-in-repo; Publish-to-web is tenant-gated).

---

*Backing code and analysis live in `sql/`, `src/`, `dashboards/`, and `docs/`. Start with the
[README](../README.md), then the [Executive Growth Strategy](executive_growth_strategy.md).*
