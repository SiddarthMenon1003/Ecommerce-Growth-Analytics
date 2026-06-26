from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]

RAW_DATA_PATH = PROJECT_ROOT / "data" / "raw"
CLEANED_DATA_PATH = PROJECT_ROOT / "data" / "cleaned"
WAREHOUSE_DATA_PATH = PROJECT_ROOT / "data" / "warehouse"

SQL_PATH = PROJECT_ROOT / "sql"
REPORT_PATH = PROJECT_ROOT / "reports"