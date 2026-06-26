from pathlib import Path
from sqlalchemy import text

from connections import engine


def create_staging_tables():

    base_dir = Path(__file__).resolve().parents[2]

    sql_file = base_dir / "sql" / "setup" / "create_staging_tables.sql"

    with open(sql_file, "r", encoding="utf-8") as f:
        sql_script = f.read()

    with engine.begin() as conn:
        conn.execute(text(sql_script))

    print("Staging tables created successfully")


if __name__ == "__main__":
    create_staging_tables()