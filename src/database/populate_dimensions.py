from src.config.settings import SQL_PATH
from src.utils.sql_runner import run_sql_file


def populate_dimensions():
    run_sql_file(
        SQL_PATH / "transform" / "populate_dimensions.sql"
    )

    print("Dimension tables populated successfully.")


if __name__ == "__main__":
    populate_dimensions()