from sqlalchemy import text

from src.database.connections import engine


def row_count(table):

    with engine.connect() as conn:

        result = conn.execute(
            text(f"SELECT COUNT(*) FROM {table}")
        )

        return result.scalar()