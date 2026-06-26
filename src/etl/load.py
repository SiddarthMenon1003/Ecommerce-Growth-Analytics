from sqlalchemy import create_engine
from pathlib import Path
import pandas as pd

from src.database.connections import engine


BASE_DIR = Path(__file__).resolve().parents[2]
RAW_DATA_PATH = BASE_DIR / "data" / "raw"


def load_data():

    datasets = {
        "customers": "olist_customers_dataset.csv",
        "orders": "olist_orders_dataset.csv",
        "products": "olist_products_dataset.csv",
        "sellers": "olist_sellers_dataset.csv",
        "order_items": "olist_order_items_dataset.csv",
        "order_payments": "olist_order_payments_dataset.csv",
        "order_reviews": "olist_order_reviews_dataset.csv"
    }

    for table, file in datasets.items():

        print(f"Loading {table}...")

        df = pd.read_csv(RAW_DATA_PATH / file)

        df.to_sql(
            table,
            engine,
            if_exists="append",
            index=False
        )

        print(f"{table} loaded")


if __name__ == "__main__":
    load_data()