"""
Milestone 1: Data Discovery and Profiling Script
Inspects raw CSV files in data/raw/, computes SHA-256 checksums,
profiles row counts, column types, null percentages, distinct counts,
and timestamp ranges. Outputs reports/data_quality/raw_data_profile.md.
"""
from datetime import datetime
import hashlib
from pathlib import Path
import sys
import pandas as pd

from config import RAW_DATA_DIR, REPORTS_DQ_DIR, EXPECTED_RAW_FILES

def compute_sha256(filepath: Path) -> str:
    """Compute SHA-256 checksum of a file to ensure provenance and integrity."""
    hasher = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest()

def profile_file(filename: str, filepath: Path) -> dict:
    """Read a CSV file and generate comprehensive profiling statistics."""
    stats = {
        "filename": filename,
        "path": str(filepath),
        "size_bytes": filepath.stat().st_size,
        "sha256": compute_sha256(filepath),
        "row_count": 0,
        "col_count": 0,
        "columns": [],
        "date_ranges": {},
    }

    df = pd.read_csv(filepath, low_memory=False)
    stats["row_count"] = len(df)
    stats["col_count"] = len(df.columns)

    for col in df.columns:
        null_count = int(df[col].isnull().sum())
        null_pct = round((null_count / len(df)) * 100, 2) if len(df) > 0 else 0.0
        n_unique = int(df[col].nunique(dropna=True))
        dtype_str = str(df[col].dtype)

        col_info = {
            "name": col,
            "dtype": dtype_str,
            "null_count": null_count,
            "null_pct": null_pct,
            "n_unique": n_unique,
            "sample_values": df[col].dropna().head(3).tolist(),
        }
        stats["columns"].append(col_info)

        # Inspect date ranges if column name suggests timestamp
        if "timestamp" in col.lower() or "date" in col.lower():
            try:
                date_series = pd.to_datetime(df[col], errors="coerce").dropna()
                if not date_series.empty:
                    stats["date_ranges"][col] = {
                        "min": date_series.min().strftime("%Y-%m-%d %H:%M:%S"),
                        "max": date_series.max().strftime("%Y-%m-%d %H:%M:%S"),
                    }
            except Exception:
                pass

    return stats

def generate_markdown_report(profiles: list[dict], output_path: Path):
    """Write the full profiling report to a Markdown artifact."""
    lines = [
        "# Raw Data Discovery & Profile Report",
        f"**Generated at:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Source Directory:** `{RAW_DATA_DIR}`",
        "",
        "## 1. File Integrity & Provenance (SHA-256)",
        "",
        "| File | Size (MB) | Rows | Columns | SHA-256 Checksum |",
        "|---|---|---|---|---|",
    ]

    for p in profiles:
        size_mb = round(p["size_bytes"] / (1024 * 1024), 2)
        lines.append(
            f"| `{p['filename']}` | {size_mb} MB | {p['row_count']:,} | {p['col_count']} | `{p['sha256'][:16]}...` |"
        )

    lines.append("")
    lines.append("## 2. Table Profiles")

    for p in profiles:
        lines.append(f"### `{p['filename']}` ({p['row_count']:,} rows, {p['col_count']} cols)")
        if p["date_ranges"]:
            lines.append("**Date Ranges Identified:**")
            for col, dr in p["date_ranges"].items():
                lines.append(f"- `{col}`: `{dr['min']}` to `{dr['max']}`")
            lines.append("")

        lines.append("| Column Name | Inferred Dtype | Null Count | Null % | Distinct Values | Sample Values |")
        lines.append("|---|---|---|---|---|---|")
        for col in p["columns"]:
            samples = ", ".join(str(v) for v in col["sample_values"][:3])
            # truncate long sample strings
            if len(samples) > 35:
                samples = samples[:32] + "..."
            lines.append(
                f"| `{col['name']}` | {col['dtype']} | {col['null_count']:,} | {col['null_pct']}% | {col['n_unique']:,} | {samples} |"
            )
        lines.append("")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"\n[+] Profile report successfully written to: {output_path}")

def main():
    print("=" * 60)
    print("Running Raw Data Profiler (Milestone 1)")
    print("=" * 60)

    profiles = []
    missing_files = []

    for key, filename in EXPECTED_RAW_FILES.items():
        filepath = RAW_DATA_DIR / filename
        if not filepath.exists():
            missing_files.append(filename)
            continue
        print(f"[*] Profiling {filename}...")
        profiles.append(profile_file(filename, filepath))

    if missing_files:
        print(f"\n[-] Warning: {len(missing_files)} expected raw files are missing from {RAW_DATA_DIR}:")
        for f in missing_files:
            print(f"    [MISSING] {f}")
        print("\nPlease run `python python/download_data.py` or download the dataset first.")
        if not profiles:
            return 1

    report_path = REPORTS_DQ_DIR / "raw_data_profile.md"
    generate_markdown_report(profiles, report_path)
    print("\n[SUCCESS] Milestone 1 Discovery & Profiling complete.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
