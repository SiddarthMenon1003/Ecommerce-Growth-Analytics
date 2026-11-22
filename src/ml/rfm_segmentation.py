"""
Case 03 (ML upgrade) - RFM + K-Means customer segmentation
==========================================================

Replaces the rule-based High/Med/Low value tiers with behavioural clusters:

  1. Build RFM at the true customer grain (customer_unique_id):
       Recency   = days since last purchase
       Frequency = distinct orders
       Monetary  = total payment value
  2. Log-transform the skewed F & M, standardise, and run K-Means (k=4).
  3. Profile each cluster and assign a business name
       (Champions / Loyal / At-Risk / Hibernating).
  4. Write the labelled result back to Postgres as `customer_rfm_segments`
       (so it can be imported into the semantic model and charted).

Run:  python -m src.ml.rfm_segmentation
Requires a .env with DB_* credentials. k chosen via elbow + silhouette
(k=4 is the interpretable optimum; see choose_k()).
"""

import os
import numpy as np
import pandas as pd
import psycopg2
from dotenv import load_dotenv
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

load_dotenv(".env")
RANDOM_STATE = 42
K = 4

RFM_SQL = """
WITH mx AS (SELECT MAX(order_purchase_timestamp)::date AS md FROM fact_orders)
SELECT
    dc.customer_unique_id                                   AS customer_unique_id,
    (SELECT md FROM mx) - MAX(fo.order_purchase_timestamp)::date AS recency,
    COUNT(DISTINCT fo.order_id)                             AS frequency,
    SUM(fp.payment_value)                                   AS monetary
FROM fact_orders fo
JOIN dim_customers dc ON fo.customer_id = dc.customer_id
JOIN fact_payments fp ON fo.order_id = fp.order_id
GROUP BY dc.customer_unique_id
HAVING SUM(fp.payment_value) IS NOT NULL
"""


def _conn():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"), port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"), user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"))


def load_rfm(conn):
    return pd.read_sql(RFM_SQL, conn)


def _features(df):
    """Log-transform skewed F & M, then standardise all three."""
    X = df[["recency", "frequency", "monetary"]].astype(float).copy()
    X["frequency"] = np.log1p(X["frequency"])
    X["monetary"] = np.log1p(X["monetary"])
    return StandardScaler().fit_transform(X)


def choose_k(df, ks=range(2, 8), sample=12000):
    """Return a DataFrame of inertia + silhouette for a range of k (diagnostic)."""
    Xs = _features(df)
    rng = np.random.default_rng(RANDOM_STATE)
    idx = rng.choice(len(Xs), size=min(sample, len(Xs)), replace=False)
    out = []
    for k in ks:
        km = KMeans(n_clusters=k, random_state=RANDOM_STATE, n_init=10).fit(Xs)
        out.append((k, km.inertia_, silhouette_score(Xs[idx], km.labels_[idx])))
    return pd.DataFrame(out, columns=["k", "inertia", "silhouette"])


def fit_segments(df, k=K):
    Xs = _features(df)
    km = KMeans(n_clusters=k, random_state=RANDOM_STATE, n_init=10).fit(Xs)
    df = df.copy()
    df["cluster"] = km.labels_
    return df


def profile(df):
    """Per-cluster means + size + revenue share."""
    g = df.groupby("cluster").agg(
        customers=("customer_unique_id", "size"),
        recency=("recency", "mean"),
        frequency=("frequency", "mean"),
        monetary=("monetary", "mean"),
        revenue=("monetary", "sum"),
    )
    g["revenue_share_%"] = (100 * g["revenue"] / g["revenue"].sum()).round(1)
    g["recency"] = g["recency"].round(0)
    g["frequency"] = g["frequency"].round(2)
    g["monetary"] = g["monetary"].round(2)
    return g


def name_segments(prof):
    """
    Map each cluster to a business name from its RFM profile. The base is
    heavily one-time (97% frequency == 1), so beyond the repeat cluster the
    segments separate on Monetary and Recency rather than Frequency.

      Champions    - the repeat / most-engaged core (highest frequency)
      Big Spenders - high-value one-time buyers (highest monetary of the rest)
      Recent       - recent but low-value (lowest recency of what remains)
      Hibernating  - lapsed (highest recency)
    """
    names = {}
    champ = prof["frequency"].idxmax()
    names[champ] = "Champions"
    rest = [c for c in prof.index if c != champ]
    big = max(rest, key=lambda c: prof.loc[c, "monetary"])
    names[big] = "Big Spenders"
    last_two = sorted([c for c in rest if c != big],
                      key=lambda c: prof.loc[c, "recency"])
    names[last_two[0]] = "Recent"
    names[last_two[-1]] = "Hibernating"
    return names


def write_back(conn, df):
    """Write customer_unique_id + RFM + cluster + segment to Postgres."""
    cur = conn.cursor()
    cur.execute("DROP TABLE IF EXISTS customer_rfm_segments")
    cur.execute("""
        CREATE TABLE customer_rfm_segments (
            customer_unique_id text,
            recency integer, frequency integer, monetary numeric,
            cluster integer, segment_name text)""")
    rows = list(df[["customer_unique_id", "recency", "frequency",
                    "monetary", "cluster", "segment_name"]].itertuples(index=False, name=None))
    cur.executemany(
        "INSERT INTO customer_rfm_segments VALUES (%s,%s,%s,%s,%s,%s)", rows)
    conn.commit()
    cur.close()


def main():
    with _conn() as conn:
        df = load_rfm(conn)
        print(f"Loaded {len(df):,} customers.\n")
        print("k selection (elbow + silhouette):")
        print(choose_k(df).to_string(index=False), "\n")

        df = fit_segments(df, K)
        prof = profile(df)
        names = name_segments(prof)
        df["segment_name"] = df["cluster"].map(names)
        prof["segment"] = prof.index.map(names)

        print(f"Segments (k={K}):")
        print(prof[["segment", "customers", "recency", "frequency",
                    "monetary", "revenue_share_%"]].to_string(index=False), "\n")

        write_back(conn, df)
        print("Wrote table: customer_rfm_segments "
              f"({len(df):,} rows, {df['segment_name'].nunique()} segments).")


if __name__ == "__main__":
    main()
