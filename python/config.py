"""
Configuration Loader Module
Loads settings from config.yaml and secrets/env vars from .env.
Provides type-safe paths and database connection strings.
"""
from pathlib import Path
import os
import yaml
from dotenv import load_dotenv

# Root directory of the repository
ROOT_DIR = Path(__file__).resolve().parent.parent

# Load environment variables from .env
load_dotenv(ROOT_DIR / ".env")

CONFIG_PATH = ROOT_DIR / "config.yaml"

with open(CONFIG_PATH, "r", encoding="utf-8") as f:
    _raw_config = yaml.safe_load(f)

# Path definitions
RAW_DATA_DIR = ROOT_DIR / _raw_config["paths"]["raw_data_dir"]
PROCESSED_DATA_DIR = ROOT_DIR / _raw_config["paths"]["processed_data_dir"]
QUARANTINE_DIR = ROOT_DIR / _raw_config["paths"]["quarantine_dir"]
REPORTS_DQ_DIR = ROOT_DIR / _raw_config["paths"]["reports_dq_dir"]
REPORTS_MIS_DIR = ROOT_DIR / _raw_config["paths"]["reports_mis_dir"]
LOGS_DIR = ROOT_DIR / _raw_config["paths"]["logs_dir"]

# Ensure directories exist
for directory in [
    RAW_DATA_DIR,
    PROCESSED_DATA_DIR,
    QUARANTINE_DIR,
    REPORTS_DQ_DIR,
    REPORTS_MIS_DIR,
    LOGS_DIR,
]:
    directory.mkdir(parents=True, exist_ok=True)

# Expected raw files map
EXPECTED_RAW_FILES = _raw_config.get("expected_raw_files", {})

# Reporting window
REPORTING_WINDOW = _raw_config.get("reporting_window", {})

# KPI rules
KPI_RULES = _raw_config.get("kpi_rules", {})

# Synthetic targets config
SYNTHETIC_TARGETS_CONFIG = _raw_config.get("synthetic_targets", {})

# Database configuration
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
# If host is localhost, prefer 127.0.0.1 to avoid Windows IPv6 resolution latency
if DB_HOST.lower() == "localhost":
    DB_HOST = "127.0.0.1"
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "sales_mis")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_CONNECT_TIMEOUT = int(os.getenv("DB_CONNECT_TIMEOUT", "3"))

def get_db_connection_url(readonly: bool = False) -> str:
    """Return SQLAlchemy connection URI (supports psycopg 3 and psycopg2)."""
    user = os.getenv("DB_READONLY_USER", DB_USER) if readonly else DB_USER
    password = os.getenv("DB_READONLY_PASSWORD", DB_PASSWORD) if readonly else DB_PASSWORD
    return f"postgresql+psycopg://{user}:{password}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
