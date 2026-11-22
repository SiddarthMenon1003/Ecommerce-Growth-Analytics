# Dashboard Notes — Experimentation (Case 06)

Case 06 is **code + statistics**, not a data mart, so there is **no Power BI
page** for it (nothing in the report to add). The deliverables are:

- `src/experimentation/ab_toolkit.py` — reusable design/evaluation functions.
- `src/experimentation/experiment_analysis.py` — runnable worked analysis
  (`python -m src.experimentation.experiment_analysis`).
- `01_observational_data.sql` — the warehouse queries behind the worked test.

## If a visual is wanted later
An "Experiment Scorecard" page could be added once real tests run, driven by an
assignment/results table (not present yet):
- KPI tiles: arm sizes, observed lift, p-value, confidence interval.
- A bar/CI chart of metric by arm (control vs treatment) with error bars.
- A power/sample-size reference table from `ab_toolkit.py`.

Until the experimentation plumbing exists (see recommendations), this stays a
framework, and the worked delivery → review result lives in the findings + the
Fulfillment page's existing "review score by delivery timing" chart.
