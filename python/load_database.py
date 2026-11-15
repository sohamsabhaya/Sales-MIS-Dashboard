"""
Milestone 3: Database Loader & ETL Engine
Applies database schemas, truncates and loads staging tables from data/processed/,
transforms data into core star schema, creates KPI views, and audits run counts.
"""
from pathlib import Path
import sys
import pandas as pd
from sqlalchemy import create_engine, text

from config import (
    DB_CONNECT_TIMEOUT,
    PROCESSED_DATA_DIR,
    RAW_DATA_DIR,
    ROOT_DIR,
    get_db_connection_url,
)

SQL_DIR = ROOT_DIR / "sql"

def execute_sql_file(engine, file_path: Path):
    """Read and execute an entire SQL file inside a transaction."""
    print(f"[*] Executing SQL script: {file_path.name}...")
    with open(file_path, "r", encoding="utf-8") as f:
        sql_content = f.read()

    with engine.begin() as conn:
        conn.execute(text(sql_content))
    print(f"[+] Successfully applied {file_path.name}")

def load_staging_tables(engine):
    """Load cleaned CSVs into stg.* staging tables."""
    print("[*] Loading cleaned CSV datasets into staging (stg) tables...")

    table_file_map = {
        "orders": PROCESSED_DATA_DIR / "orders_cleaned.csv",
        "order_items": PROCESSED_DATA_DIR / "order_items_cleaned.csv",
        "customers": PROCESSED_DATA_DIR / "customers_cleaned.csv",
        "products": PROCESSED_DATA_DIR / "products_cleaned.csv",
        "sellers": PROCESSED_DATA_DIR / "sellers_cleaned.csv",
        "payments": PROCESSED_DATA_DIR / "payments_cleaned.csv",
    }

    # Staging targets from raw/targets_synthetic.csv
    targets_path = RAW_DATA_DIR / "targets_synthetic.csv"
    if targets_path.exists():
        table_file_map["targets"] = targets_path

    total_loaded = 0
    with engine.begin() as conn:
        for table_name, csv_path in table_file_map.items():
            if not csv_path.exists():
                print(f"[-] Skipping staging table stg.{table_name}: file {csv_path.name} not found.")
                continue

            print(f"    Loading {csv_path.name} -> stg.{table_name}...")
            df = pd.read_csv(csv_path)

            # Truncate first to maintain idempotency
            conn.execute(text(f"TRUNCATE TABLE stg.{table_name};"))
            # Bulk append to staging
            df.to_sql(table_name, con=conn, schema="stg", if_exists="append", index=False, chunksize=5000)
            total_loaded += len(df)
            print(f"    [LOADED] stg.{table_name}: {len(df):,} rows loaded.")

    print(f"[+] Staging data load completed: {total_loaded:,} total rows.")

def record_audit_log(engine, stage: str, status: str, notes: str):
    """Log pipeline execution status to audit.run_log."""
    try:
        with engine.begin() as conn:
            conn.execute(
                text("""
                    INSERT INTO audit.run_log (pipeline_stage, status, notes)
                    VALUES (:stage, :status, :notes);
                """),
                {"stage": stage, "status": status, "notes": notes}
            )
    except Exception as e:
        print(f"[-] Could not write to audit log: {e}")

def run_db_pipeline():
    print("=" * 60)
    print("PostgreSQL Database Warehouse Loader (Milestone 3)")
    print("=" * 60)

    url = get_db_connection_url(readonly=False)
    try:
        engine = create_engine(url, pool_pre_ping=True, connect_args={"connect_timeout": DB_CONNECT_TIMEOUT})
        # Test connection
        with engine.connect() as conn:
            conn.execute(text("SELECT 1;"))
        print("[+] Successfully connected to PostgreSQL warehouse.")
    except Exception as e:
        print(f"[-] Database connection failed: {e}")
        print("Please ensure Docker container is running (`docker compose up -d`).")
        return False

    try:
        # Step 1: Create Schemas & Tables
        execute_sql_file(engine, SQL_DIR / "01_schema.sql")

        # Step 2: Load Staging Tables
        load_staging_tables(engine)

        # Step 3: Populate Core Star Schema
        execute_sql_file(engine, SQL_DIR / "02_load_core.sql")

        # Step 4: Create Reporting KPI Views
        execute_sql_file(engine, SQL_DIR / "03_kpi_views.sql")

        # Step 5: Audit Log
        record_audit_log(engine, "database_load", "SUCCESS", "Staging, core, and KPI views loaded successfully.")
        print("\n[SUCCESS] PostgreSQL analytical warehouse is ready!")
        return True

    except Exception as e:
        print(f"[-] Error during database loading: {e}")
        record_audit_log(engine, "database_load", "FAILED", str(e))
        return False

if __name__ == "__main__":
    success = run_db_pipeline()
    sys.exit(0 if success else 1)
