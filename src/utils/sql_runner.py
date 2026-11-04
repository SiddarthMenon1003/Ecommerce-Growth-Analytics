from pathlib import Path
from sqlalchemy import text

from src.database.connections import engine
from src.utils.logger import log


def run_sql_file(sql_path: Path):
    with open(sql_path, "r", encoding="utf-8") as file:
        script = file.read()
    statements = [
        stmt.strip()
        for stmt in script.split(";")
        if stmt.strip()
    ]
    with engine.begin() as conn:
        for statement in statements:
            conn.execute(text(statement))
    log(f"Executed {sql_path.name}")
