# Model Remediation Checklist (Desktop — do while watching for broken visuals)

The items below were **not** applied live because each can silently break report visuals
that bind to a table/measure/column by name, and the model connection cannot see the
report canvas. Do them in Power BI Desktop where breakage is visible, one at a time,
checking each page after each change.

Already applied live (safe, done):
- Deleted the empty default `Measure` on `Customer Type`.
- Fixed `Delivery Completion Rate` DAX (removed stray backticks; denominator aligned to the other funnel rates).
- Renamed hierarchy `Calender` → `Calendar` on `Dim Date`.
- Added descriptions + correct format strings (R$ / % / #,0) to the headline KPIs.
- Set % format on `Late Delivery Rate`, `Approval Rate`, `Shipping Rate`.

---

## P0 — Customer grain bug (CORRECTNESS) — SQL FIXED, deployment pending

Cause: marts `GROUP BY customer_id` (Olist `customer_id` is unique per order) instead of
`customer_unique_id`, so every customer was one-time by construction and `estimated_ltv`
collapsed to revenue.

**Fixed 2026-11-04** in `sql/analytics_marts/01_customer_retention_mart.sql`,
`02_marketing_roi_mart.sql`, `03_customer_segmentation_mart.sql` (now group on
`customer_unique_id`; `customer_id` dropped from output). Dependent case queries repointed:
`case_02/01_data_validation.sql`, `case_02/04_ltv_analysis.sql`. Cohort SQL already used
`customer_unique_id` (no change). Base-table EDA still uses `customer_id` legitimately.

Old vs new (measured from the model, customer_unique_id grain):

| Metric | Old (customer_id) | New (customer_unique_id) |
|---|---:|---:|
| Customers | 99,440 | 96,096 |
| One-time | 100% | 96.9% (93,099) |
| Repeat | 0 | 3.1% (2,997) |
| Max orders | 1 | 17 |
| Avg rev / repeat vs one-time | n/a | R$315 vs R$162 |
| Repeat revenue share | 0% | 5.9% |
| Total revenue | R$16.0M | R$16.0M (conserved) |

Remaining to deploy (owner action — changes published numbers):
1. Re-run the ETL to rematerialise the mart tables in PostgreSQL.
2. Refresh the Power BI dataset.
3. Repoint the `public *_mart` → `Dim Customers` relationships to `customer_unique_id`
   (the old `customer_id` key is gone from the marts).
4. Re-validate KPI cards; optionally replace the `estimated_ltv` proxy with a defensible LTV.

---

## P1 — Kill auto date/time bloat (biggest cleanup, ~26 hidden tables)

The model carries ~26 auto-generated `LocalDateTable_*` + `DateTableTemplate_*` tables
(one per date column) plus their auto `Date Hierarchy`. They bloat the model and
duplicate the real `Dim Date`.

1. **File → Options and settings → Options → Current File → Data Load**.
2. Uncheck **Auto date/time**. Click OK. All `LocalDateTable_*` vanish.
3. Wherever a visual used an auto `Date Hierarchy` off a fact date column, repoint it to
   `Dim Date` → `Calendar` hierarchy. Check each page's time visuals.
4. Confirm `Dim Date` is marked as date table: Table tools → **Mark as date table** → `Date`.

Expect model size to drop sharply and the field list to get much cleaner.

---

## P2 — Clean the leaked `public ` table names

Five tables keep the raw PostgreSQL schema prefix: `public customer_cohorts`,
`public customer_value_mart`, `public marketing_roi_mart`,
`public customer_segmentation_mart`, `public order_fulfillment_funnel_mart`.

Rename in Desktop (double-click table in Model view) to business names:
- `public customer_cohorts` → `Customer Cohorts`
- `public customer_value_mart` → `Customer Value`
- `public marketing_roi_mart` → `Customer LTV` (see P4 — it is not marketing ROI)
- `public customer_segmentation_mart` → `Customer Segments`
- `public order_fulfillment_funnel_mart` → `Fulfillment Funnel`

Renaming through Desktop auto-updates visuals and measure references in the same file
(external renames do not — that is why this is a Desktop step). After each rename, open
every page and confirm no visual shows "can't find field".

---

## P3 — Decide: star vs marts (remove redundancy)

The model runs two paradigms at once: a clean star (Dim/Fact) **and** 5 denormalized
marts that re-import customer_id + first/last purchase dates already present in the dims.
This is the biggest structural redundancy.

Pick one per subject area and drop the other's duplicate tables:
- For report pages driven by measures over the star → the marts are only needed where a
  visual binds directly to a mart column. Audit each mart: if no visual uses it, delete it.
- Keep `Fulfillment Funnel` (the Case-4 notes declare it the single denormalized source
  for that dashboard) and `Customer Cohorts` (cohort matrix needs the pre-pivoted grain).
- `Customer Value`, `Customer LTV`, `Customer Segments` overlap heavily — consolidate to
  one customer-attribute table related to `Dim Customers`, or compute via measures.

Do this last, after P1/P2, and only after confirming which marts visuals actually use.

---

## P4 — Reframe Case 2 (credibility fix)

`sql/analytics_marts/02_marketing_roi_mart.sql` contains **no** CAC, ROAS, ad-spend or
channel data — the Olist dataset has none. It is a customer LTV / priority-matrix mart
mislabeled as "Marketing ROI", and `estimated_ltv = revenue × purchase_frequency` is a
weak proxy (money × orders/day).

Fix one of two ways:
- **Honest reframe (recommended):** rename case + mart to "Customer Value & Marketing
  Prioritisation". Drop CAC/ROAS/channel claims from the README Case 2 section. Keep the
  Retain/Convert/Upsell/Nurture priority matrix — that part is sound.
- **Or** source real spend/channel data and actually compute CAC/ROAS.
- Replace `estimated_ltv` with a defensible definition (e.g. `avg_order_value ×
  predicted_orders`, or historical `total_revenue` as observed value) and state the assumption.

---

## P5 — Customer grain (deeper, optional core redesign)

The `Fact Orders ↔ Dim Customers` relationship is **1:1** on `customer_id`, which forces
bidirectional cross-filter (the engine rejected one-direction — expected for 1:1). Root
cause: Olist `customer_id` is unique per order; the real customer key is
`customer_unique_id`. `Dim Customers` is therefore at order grain, not customer grain.

If you want a true customer dimension:
1. Build `Dim Customers` deduplicated on `customer_unique_id`.
2. Relate `Fact Orders[customer_unique_id]` → `Dim Customers[customer_unique_id]` (Many-to-One, single direction).
3. Re-validate every customer count measure (they already use `DISTINCTCOUNT(customer_unique_id)`, so most will hold).

This changes core modeling — do it deliberately, on a copy, and diff the KPIs before/after.

---

## P6 — Fill the empty deliverables

These are tracked but empty, which undercuts the "done" checkboxes in the README:
- `docs/warehouse_design.md` — **filled** in this pass (star schema reference).
- `sql/executive_cases/case_02_marketing_roi/07_business_findings.md` — empty.
- `.../case_02_marketing_roi/08_recommendations.md` — empty.
- `.../case_02_marketing_roi/09_dashboard_notes.md` — empty.

Case-02 docs should be written against the reframed Case 2 (P4), not the fictional
CAC/ROAS version. Also level up Case-03 writeups (~1 KB vs Case-01's 6 KB).

Then correct the README project-status checkboxes to match reality (Case 4 artifacts
exist but it is marked incomplete; Marketing is marked done but has empty docs).
