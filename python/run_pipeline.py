"""
Master Pipeline Orchestrator (FR-701, FR-702, FR-703)
Executes the end-to-end Sales Operations & MIS Analytics pipeline:
Inspection -> Synthetic Targets -> Cleaning & Quarantine -> Warehouse Load -> MIS Report.
Logs every run to logs/pipeline_<timestamp>.log.
"""
from datetime import datetime
import logging
from pathlib import Path
import sys

from config import LOGS_DIR
import clean_data
import generate_mis_report
import generate_targets
import inspect_data
import load_database
import rfm_analytics

def setup_logging() -> tuple[logging.Logger, Path]:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_path = LOGS_DIR / f"pipeline_{timestamp}.log"

    logger = logging.getLogger("SalesMISPipeline")
    logger.setLevel(logging.INFO)

    file_handler = logging.FileHandler(log_path, encoding="utf-8")
    file_handler.setLevel(logging.INFO)

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)

    formatter = logging.Formatter("[%(asctime)s] [%(levelname)s] %(message)s", datefmt="%Y-%m-%d %H:%M:%S")
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)

    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

    return logger, log_path

def main():
    logger, log_path = setup_logging()
    logger.info("============================================================")
    logger.info("Starting Sales Operations & MIS Analytics Master Pipeline")
    logger.info(f"Log Output: {log_path}")
    logger.info("============================================================")

    # Stage 1: Data Discovery & Profiling
    logger.info(">>> Stage 1: Inspecting & Profiling Raw Data...")
    try:
        profile_exit = inspect_data.main()
        if profile_exit != 0:
            logger.warning("Stage 1 completed with warnings (some raw files might be pending download).")
    except Exception as e:
        logger.error(f"Stage 1 failed: {e}", exc_info=True)

    # Stage 2: Synthetic Targets Generation
    logger.info(">>> Stage 2: Generating Synthetic Targets (Reproducible Seed=42)...")
    try:
        generate_targets.generate_targets()
        logger.info("[SUCCESS] Synthetic targets generated successfully.")
    except Exception as e:
        logger.error(f"Stage 2 failed: {e}", exc_info=True)

    # Stage 3: Cleaning & Quarantine
    logger.info(">>> Stage 3: Cleaning Datasets, Enforcing DQ Rules & Routing Quarantine...")
    try:
        clean_success = clean_data.run_cleaning_pipeline()
        if clean_success:
            logger.info("[SUCCESS] Data cleaning & quarantine complete.")
        else:
            logger.warning("Data cleaning skipped due to missing raw files. Download dataset to proceed.")
    except Exception as e:
        logger.error(f"Stage 3 failed: {e}", exc_info=True)

    # Stage 4: Database Warehouse Loading
    logger.info(">>> Stage 4: Loading PostgreSQL Analytical Warehouse...")
    try:
        db_success = load_database.run_db_pipeline()
        if db_success:
            logger.info("[SUCCESS] PostgreSQL staging, core star schema, and KPI views loaded.")
        else:
            logger.warning("PostgreSQL loading skipped (Docker/PostgreSQL container may not be started yet).")
    except Exception as e:
        logger.warning(f"Database stage encountered notice: {e}")

    # Stage 5: Executive Monthly MIS Excel Pack Generation
    logger.info(">>> Stage 5: Generating Executive MIS Report (Period: 2018-06)...")
    try:
        # Generate for standard reference period
        try:
            df_m, df_r, df_c = generate_mis_report.load_data_from_db()
            source_used = "PostgreSQL Warehouse"
        except Exception:
            logger.info("Database views unavailable; generating from processed CSV datasets.")
            df_m, df_r, df_c = generate_mis_report.load_data_from_csv()
            source_used = "Processed CSVs (Fallback Engine)"

        out_path = generate_mis_report.create_report_workbook("2018-06", df_m, df_r, df_c)
        logger.info(f"[SUCCESS] Executive MIS workbook created ({source_used}): {out_path.name}")
    except Exception as e:
        logger.error(f"Stage 5 failed: {e}", exc_info=True)

    # Stage 6: Strategic Customer RFM Segmentation & Cohort Retention
    logger.info(">>> Stage 6: Computing RFM Customer Segmentation & Cohort Retention...")
    try:
        seg_summary, retention_matrix = rfm_analytics.compute_rfm_from_csv()
        rfm_path = rfm_analytics.generate_rfm_markdown_report(seg_summary, retention_matrix)
        logger.info(f"[SUCCESS] RFM & Cohort analytics published: {rfm_path.name}")
    except Exception as e:
        logger.error(f"Stage 6 failed: {e}", exc_info=True)

    logger.info("============================================================")
    logger.info("Pipeline Execution Finished.")
    logger.info(f"Log persisted at: {log_path}")
    logger.info("============================================================")
    return 0

if __name__ == "__main__":
    sys.exit(main())
