from pathlib import Path
from sqlalchemy import text

from connections import engine


def create_tables():

    base_dir = Path(__file__).resolve().parents[2]

    sql_file = base_dir / "sql" / "setup" / "create_tables.sql"

    with open(sql_file, "r", encoding="utf-8") as f:
        sql_script = f.read()

    with engine.begin() as conn:
        conn.execute(text(sql_script))

    print("Tables created successfully")


if __name__ == "__main__":
    create_tables()