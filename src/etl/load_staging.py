from pathlib import Path
import pandas as pd
from sqlalchemy import text

from src.database.connections import engine

BASE_DIR = Path(__file__).resolve().parents[2]
RAW_DATA_PATH = BASE_DIR / "data" / "raw"

DATASETS = {
    "stg_customers": "olist_customers_dataset.csv",
    "stg_orders": "olist_orders_dataset.csv",
    "stg_order_items": "olist_order_items_dataset.csv",
    "stg_order_payments": "olist_order_payments_dataset.csv",
    "stg_order_reviews": "olist_order_reviews_dataset.csv",
    "stg_products": "olist_products_dataset.csv",
    "stg_sellers": "olist_sellers_dataset.csv",
    "stg_geolocation": "olist_geolocation_dataset.csv",
}


def load_staging():
    for table, csv_file in DATASETS.items():
        print(f"\nLoading {table}...")
        try:
            df = pd.read_csv(RAW_DATA_PATH / csv_file)
            if table == "stg_products":
                df = df.rename(columns={
                    "product_name_lenght": "product_name_length",
                    "product_description_lenght": "product_description_length"
                })
            with engine.begin() as conn:
                conn.execute(text(f"TRUNCATE TABLE {table};"))
            df.to_sql(
                table,
                engine,
                if_exists="append",
                index=False,
                method="multi",
                chunksize=500
            )
            print(f"✓ {table}: {len(df):,} rows loaded")
        except Exception as e:
            print(f"\n❌ FAILED: {table}")
            print(e)
            break


if __name__ == "__main__":
    load_staging()
