from src.database.populate_dimensions import populate_dimensions
from src.database.populate_facts import populate_facts


def build_warehouse():
    print("\n========== BUILDING WAREHOUSE ==========\n")
    populate_dimensions()
    populate_facts()
    print("\nWarehouse build complete.\n")


if __name__ == "__main__":
    build_warehouse()
