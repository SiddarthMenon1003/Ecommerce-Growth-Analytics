from src.config.settings import SQL_PATH
from src.utils.sql_runner import run_sql_file


def populate_facts():
    run_sql_file(SQL_PATH / "transform" / "populate_facts.sql")
    print("Fact tables populated successfully.")


if __name__ == "__main__":
    populate_facts()
