"""
Database connection.

Credentials are read from environment variables (loaded from a local .env file
that is git-ignored). Copy .env.example to .env and fill in your values.
"""

import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine

# Load variables from a .env file at the project root, if present.
PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "growth_lab")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD")

if not DB_PASSWORD:
    raise RuntimeError(
        "DB_PASSWORD is not set. Copy .env.example to .env and set your "
        "database credentials (the .env file is git-ignored)."
    )

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

if __name__ == "__main__":
    try:
        connection = engine.connect()
        print(f"Connected to {DB_NAME}")
        connection.close()
    except Exception as e:
        print("Connection Failed")
        print(e)
