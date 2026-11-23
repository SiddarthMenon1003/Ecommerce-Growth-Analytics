"""
Churn model - second-purchase (repeat) propensity
==================================================

Olist has no subscription or cancellation event, and 96.9% of customers buy
exactly once, so there is no classic "active customer went inactive" churn
signal. We model the actionable inverse instead:

    For each customer's FIRST order, predict the probability they place a
    SECOND order within 180 days. Churn risk = 1 - P(repeat).

This points straight at the project's biggest growth lever: converting
one-time buyers into repeat buyers.

Method
------
  1. Build one row per customer_unique_id from their FIRST order only
     (features computed as of that order - no future information).
  2. Label repeat_180 = 1 if a second distinct order lands within 180 days.
  3. Right-censoring: only customers whose first order is on/before
     (max purchase date - 180 days) have a full window, so only they train
     and evaluate. Everyone is still SCORED for the dashboard.
  4. Time-aware split (train on earlier cohorts, test on later) to mimic
     forward prediction and avoid leakage.
  5. Logistic-regression baseline, then XGBoost with class weighting.
  6. Evaluate with PR-AUC / ROC-AUC / top-decile lift (accuracy is useless
     at a ~3% base rate). SHAP for global + per-customer explainability.
  7. Write customer_unique_id + repeat_probability + risk_band back to
     Postgres as `customer_churn_scores`.

Honest expectation: a single-purchase marketplace carries limited signal,
so the win is RANKING (surface the first-time buyers most likely to
return), not a high-AUC classifier. Numbers are reported as they land.

Run:  python -m src.ml.churn_model
Requires a .env with DB_* credentials.
"""

import os
import warnings

import numpy as np
import pandas as pd
import psycopg2
from dotenv import load_dotenv
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import roc_auc_score, average_precision_score
from xgboost import XGBClassifier

load_dotenv(".env")
warnings.filterwarnings("ignore")

RANDOM_STATE = 42
HORIZON_DAYS = 180          # repeat window
TEST_FRACTION = 0.30        # most-recent cohorts held out (time-aware)
TOP_CATEGORIES = 12         # keep top-N product categories, rest -> "other"
REPORTS_DIR = "reports"

# One row per customer_unique_id, built from their first order only.
FEATURE_SQL = f"""
WITH mx AS (
    SELECT MAX(order_purchase_timestamp)::date AS md FROM fact_orders
),
co AS (
    SELECT dc.customer_unique_id                      AS cuid,
           fo.customer_id,
           fo.order_id,
           fo.order_purchase_timestamp                AS ts,
           fo.order_approved_at,
           fo.order_delivered_customer_date,
           fo.order_estimated_delivery_date
    FROM fact_orders fo
    JOIN dim_customers dc ON fo.customer_id = dc.customer_id
),
ranked AS (
    SELECT co.*,
           ROW_NUMBER() OVER (PARTITION BY cuid ORDER BY ts, order_id) AS rn,
           MIN(ts)      OVER (PARTITION BY cuid)                       AS first_ts
    FROM co
),
firsts AS (
    SELECT * FROM ranked WHERE rn = 1
),
repeat_flag AS (
    SELECT cuid,
           MAX(CASE WHEN rn > 1
                     AND ts <= first_ts + INTERVAL '{HORIZON_DAYS} days'
                    THEN 1 ELSE 0 END) AS repeat_180
    FROM ranked
    GROUP BY cuid
),
items AS (
    SELECT f.cuid,
           COUNT(*)                                             AS items_count,
           SUM(oi.price)                                        AS total_price,
           SUM(oi.freight_value)                                AS total_freight,
           COUNT(DISTINCT oi.seller_id)                         AS n_sellers,
           COUNT(DISTINCT p.product_category_name)              AS n_categories,
           MODE() WITHIN GROUP (ORDER BY p.product_category_name) AS top_category
    FROM firsts f
    JOIN fact_order_items oi ON oi.order_id = f.order_id
    LEFT JOIN dim_products  p ON p.product_id = oi.product_id
    GROUP BY f.cuid
),
pay AS (
    SELECT f.cuid,
           SUM(pm.payment_value)                               AS payment_value,
           MAX(pm.payment_installments)                        AS installments,
           MODE() WITHIN GROUP (ORDER BY pm.payment_type)      AS payment_type
    FROM firsts f
    JOIN fact_payments pm ON pm.order_id = f.order_id
    GROUP BY f.cuid
),
rev AS (
    SELECT f.cuid, AVG(rv.review_score)::numeric AS review_score
    FROM firsts f
    JOIN fact_reviews rv ON rv.order_id = f.order_id
    GROUP BY f.cuid
)
SELECT
    f.cuid                                                      AS customer_unique_id,
    f.first_ts::date                                           AS first_order_date,
    (f.first_ts::date <= (SELECT md FROM mx) - {HORIZON_DAYS}) AS cohort_eligible,
    rf.repeat_180,
    CASE WHEN f.order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END AS delivered,
    CASE WHEN f.order_delivered_customer_date IS NOT NULL
              AND f.order_delivered_customer_date > f.order_estimated_delivery_date
         THEN 1 ELSE 0 END                                     AS late,
    EXTRACT(EPOCH FROM (f.order_delivered_customer_date - f.ts)) / 86400.0 AS delivery_days,
    EXTRACT(EPOCH FROM (f.order_estimated_delivery_date
                        - f.order_delivered_customer_date)) / 86400.0      AS estimated_gap_days,
    EXTRACT(EPOCH FROM (f.order_approved_at - f.ts)) / 3600.0  AS approval_hours,
    EXTRACT(MONTH FROM f.ts)                                   AS purchase_month,
    EXTRACT(DOW   FROM f.ts)                                   AS purchase_dow,
    dcf.customer_state,
    it.items_count, it.total_price, it.total_freight,
    it.n_sellers, it.n_categories, it.top_category,
    pay.payment_value, pay.installments, pay.payment_type,
    rev.review_score
FROM firsts f
JOIN repeat_flag rf   ON rf.cuid = f.cuid
JOIN dim_customers dcf ON dcf.customer_id = f.customer_id
LEFT JOIN items it     ON it.cuid = f.cuid
LEFT JOIN pay          ON pay.cuid = f.cuid
LEFT JOIN rev          ON rev.cuid = f.cuid
"""

NUMERIC = [
    "delivered", "late", "delivery_days", "estimated_gap_days", "approval_hours",
    "purchase_month", "purchase_dow", "items_count", "total_price", "total_freight",
    "n_sellers", "n_categories", "payment_value", "installments", "review_score",
    "freight_ratio",
]
CATEGORICAL = ["customer_state", "payment_type", "top_category"]


def _conn():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"), port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"), user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"))


def load(conn):
    """Fetch via cursor (avoids pandas 3.x read_sql DBAPI warnings)."""
    cur = conn.cursor()
    cur.execute(FEATURE_SQL)
    cols = [d[0] for d in cur.description]
    df = pd.DataFrame(cur.fetchall(), columns=cols)
    cur.close()
    return df


def engineer(df):
    """Derived features + categorical tidy-up. No target leakage."""
    df = df.copy()
    for c in ["total_price", "total_freight", "payment_value", "delivery_days",
              "estimated_gap_days", "approval_hours", "review_score",
              "installments", "items_count", "n_sellers", "n_categories"]:
        df[c] = pd.to_numeric(df[c], errors="coerce")

    # freight burden relative to basket value (0 when price missing/zero)
    df["freight_ratio"] = np.where(
        df["total_price"].fillna(0) > 0,
        df["total_freight"] / df["total_price"], np.nan)

    # collapse the long tail of product categories to the top-N + "other"
    keep = df["top_category"].value_counts().nlargest(TOP_CATEGORIES).index
    df["top_category"] = df["top_category"].where(
        df["top_category"].isin(keep), "other").fillna("other")
    df["customer_state"] = df["customer_state"].fillna("unknown")
    df["payment_type"] = df["payment_type"].fillna("unknown")
    return df


def build_matrix(df):
    """One-hot the categoricals; return X (float, NaNs kept for XGBoost) + names."""
    X = df[NUMERIC].astype(float).copy()
    dummies = pd.get_dummies(df[CATEGORICAL], prefix=CATEGORICAL, dummy_na=False)
    X = pd.concat([X, dummies.astype(float)], axis=1)
    return X


def time_split(df, X, y):
    """Earlier cohorts train, most-recent TEST_FRACTION held out."""
    order = df["first_order_date"].values.argsort(kind="stable")
    cut = int(len(order) * (1 - TEST_FRACTION))
    tr, te = order[:cut], order[cut:]
    return X.iloc[tr], X.iloc[te], y.iloc[tr], y.iloc[te]


def decile_lift(y_true, proba, frac=0.10):
    """Repeat rate in the top-`frac` by score, divided by the base rate."""
    y_true = np.asarray(y_true)
    k = max(1, int(len(proba) * frac))
    top = np.argsort(proba)[::-1][:k]
    base = y_true.mean()
    return (y_true[top].mean() / base) if base > 0 else np.nan


def evaluate(name, y_true, proba):
    roc = roc_auc_score(y_true, proba)
    pr = average_precision_score(y_true, proba)
    lift = decile_lift(y_true, proba)
    print(f"  {name:<10}  ROC-AUC {roc:.3f}   PR-AUC {pr:.3f}   "
          f"top-decile lift {lift:.2f}x")
    return {"model": name, "roc_auc": roc, "pr_auc": pr, "decile_lift": lift}


def shap_summary(model, X_sample):
    """Global mean|SHAP| ranking; save a beeswarm PNG if possible."""
    try:
        import shap
        expl = shap.TreeExplainer(model)
        sv = expl.shap_values(X_sample)
        imp = (pd.Series(np.abs(sv).mean(axis=0), index=X_sample.columns)
               .sort_values(ascending=False))
        print("\nTop features by mean|SHAP|:")
        print(imp.head(15).round(4).to_string())
        try:
            import matplotlib
            matplotlib.use("Agg")
            import matplotlib.pyplot as plt
            os.makedirs(REPORTS_DIR, exist_ok=True)
            shap.summary_plot(sv, X_sample, show=False, max_display=15)
            path = os.path.join(REPORTS_DIR, "churn_shap_summary.png")
            plt.tight_layout()
            plt.savefig(path, dpi=120, bbox_inches="tight")
            plt.close()
            print(f"Saved SHAP summary -> {path}")
        except Exception as e:
            print(f"(SHAP plot skipped: {e})")
        return imp
    except Exception as e:
        print(f"(SHAP skipped: {e})")
        return None


def risk_bands(proba):
    """Quantile bands on repeat propensity (documented, data-driven)."""
    hi, mid = np.quantile(proba, [0.80, 0.50])
    band = np.where(proba >= hi, "High",
                    np.where(proba >= mid, "Medium", "Low"))
    return band, hi, mid


def write_back(conn, df, proba):
    band, _, _ = risk_bands(proba)
    elig = df["cohort_eligible"].astype(bool).tolist()
    # Actual label only has meaning inside the full window; NULL for the
    # censored tail so dashboard rates average over eligible customers only.
    # Build native Python types (str/float/bool/int/None) so psycopg2 adapts
    # cleanly - routing None through a DataFrame coerces the column to float.
    rows = [
        (str(c), float(p), float(1 - p), str(b), bool(e),
         (int(r) if e else None))
        for c, p, b, e, r in zip(
            df["customer_unique_id"].tolist(),
            np.round(proba, 6).tolist(),
            band.tolist(),
            elig,
            df["repeat_180"].tolist(),
        )
    ]
    cur = conn.cursor()
    cur.execute("DROP TABLE IF EXISTS customer_churn_scores")
    cur.execute("""
        CREATE TABLE customer_churn_scores (
            customer_unique_id text,
            repeat_probability numeric,
            churn_risk numeric,
            risk_band text,
            cohort_eligible boolean,
            repeat_label integer)""")
    cur.executemany(
        "INSERT INTO customer_churn_scores VALUES (%s,%s,%s,%s,%s,%s)", rows)
    conn.commit()
    cur.close()
    out = pd.DataFrame(rows, columns=["customer_unique_id", "repeat_probability",
                                      "churn_risk", "risk_band",
                                      "cohort_eligible", "repeat_label"])
    return out


PRETTY = {
    "estimated_gap_days": "Delivery vs. estimate gap",
    "delivery_days": "Delivery time (days)",
    "late": "Late delivery",
    "delivered": "Order delivered",
    "approval_hours": "Payment approval time",
    "purchase_month": "Purchase month",
    "purchase_dow": "Purchase day of week",
    "items_count": "Items in first order",
    "total_price": "First-order value",
    "total_freight": "Freight paid",
    "freight_ratio": "Freight as % of basket",
    "n_sellers": "Distinct sellers",
    "n_categories": "Distinct categories",
    "payment_value": "Payment value",
    "installments": "Payment installments",
    "review_score": "Review score",
    "customer_state": "Customer state",
    "payment_type": "Payment type",
    "top_category": "Product category",
}


def write_importance(conn, imp, top_n=12):
    """Fold one-hot dummies back to their base feature, label, and persist the
    mean|SHAP| driver ranking so the dashboard can chart it."""
    def base(name):
        for c in CATEGORICAL:
            if name.startswith(c + "_"):
                return c
        return name
    agg = {}
    for feat, val in imp.items():
        b = base(feat)
        agg[b] = agg.get(b, 0.0) + float(val)
    ranked = sorted(agg.items(), key=lambda kv: kv[1], reverse=True)[:top_n]
    rows = [(f, PRETTY.get(f, f), float(v), i + 1)
            for i, (f, v) in enumerate(ranked)]
    cur = conn.cursor()
    cur.execute("DROP TABLE IF EXISTS churn_feature_importance")
    cur.execute("""
        CREATE TABLE churn_feature_importance (
            feature text, label text, mean_abs_shap numeric, rank integer)""")
    cur.executemany(
        "INSERT INTO churn_feature_importance VALUES (%s,%s,%s,%s)", rows)
    conn.commit()
    cur.close()
    print(f"\nWrote table: churn_feature_importance ({len(rows)} drivers).")


def main():
    with _conn() as conn:
        raw = load(conn)
        df = engineer(raw)
        X_all = build_matrix(df)

        elig = df["cohort_eligible"].astype(bool).values
        y = df["repeat_180"].astype(int)
        base = y[elig].mean()
        print(f"Customers (first orders): {len(df):,}")
        print(f"Cohort with full {HORIZON_DAYS}-day window: {elig.sum():,} "
              f"({100*elig.mean():.1f}%)")
        print(f"Repeat-within-{HORIZON_DAYS}d base rate (eligible): "
              f"{base:.3%}\n")

        Xc, yc, dc = X_all[elig], y[elig], df[elig]
        Xtr, Xte, ytr, yte = time_split(dc, Xc, yc)
        print(f"Train {len(Xtr):,} (earlier)  |  Test {len(Xte):,} (recent)\n")

        results = []

        # Baseline: logistic regression (median-imputed, scaled, balanced)
        logit = make_pipeline(
            SimpleImputer(strategy="median"),
            StandardScaler(),
            LogisticRegression(max_iter=2000, class_weight="balanced",
                               random_state=RANDOM_STATE))
        logit.fit(Xtr, ytr)
        results.append(evaluate("Logistic", yte, logit.predict_proba(Xte)[:, 1]))

        # Challenger: XGBoost (handles NaN natively; weight the rare positive class)
        pos = max(1, int(ytr.sum()))
        spw = (len(ytr) - pos) / pos
        xgb = XGBClassifier(
            n_estimators=400, max_depth=4, learning_rate=0.05,
            subsample=0.8, colsample_bytree=0.8, min_child_weight=5,
            reg_lambda=1.0, scale_pos_weight=spw,
            eval_metric="aucpr", random_state=RANDOM_STATE, n_jobs=-1)
        xgb.fit(Xtr, ytr)
        results.append(evaluate("XGBoost", yte, xgb.predict_proba(Xte)[:, 1]))

        print("\n" + pd.DataFrame(results).round(3).to_string(index=False))

        # Deploy the model that actually wins on the held-out recent cohort.
        models = {"Logistic": logit, "XGBoost": xgb}
        winner = max(results, key=lambda r: r["pr_auc"])["model"]
        print(f"\nDeployed scorer: {winner} (best held-out PR-AUC).")

        # Explainability: read feature signal from the gradient-boosted model.
        samp = Xte.sample(min(4000, len(Xte)), random_state=RANDOM_STATE)
        imp = shap_summary(xgb, samp)
        if imp is not None:
            write_importance(conn, imp)

        # Score EVERYONE (eligible + censored tail) with the winner and persist
        proba_all = models[winner].predict_proba(X_all)[:, 1]
        out = write_back(conn, df, proba_all)
        print(f"\nWrote table: customer_churn_scores ({len(out):,} rows).")
        print(out["risk_band"].value_counts().to_string())


if __name__ == "__main__":
    main()
