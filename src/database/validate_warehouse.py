from sqlalchemy import text

from src.database.connections import engine


def validate_table(table, expected_rows):
    with engine.connect() as conn:
        rows = conn.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar()
    if rows == expected_rows:
        print(f"✓ {table:<20} {rows:,}")
    else:
        print(f"✗ {table:<20} Expected {expected_rows:,} | Found {rows:,}")


def validate_warehouse():
    print("\n========== WAREHOUSE VALIDATION ==========\n")
    validate_table("dim_customers", 99441)
    validate_table("dim_products", 32951)
    validate_table("dim_sellers", 3095)

    validate_table("fact_orders", 99441)
    validate_table("fact_order_items", 112650)
    validate_table("fact_payments", 103886)
    validate_table("fact_reviews", 99224)
    print("\nValidation complete.\n")


if __name__ == "__main__":
    validate_warehouse()
