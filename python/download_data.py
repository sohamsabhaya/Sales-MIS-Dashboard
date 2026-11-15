"""
Data Download and Verification Helper Script
Checks if the Olist dataset files are present in data/raw/.
If Kaggle credentials exist, attempts to download automatically.
Otherwise, displays step-by-step instructions.
"""
from pathlib import Path
import sys
import zipfile

from config import RAW_DATA_DIR, EXPECTED_RAW_FILES

KAGGLE_DATASET = "olistbr/brazilian-ecommerce"

def check_existing_files() -> tuple[list[str], list[str]]:
    """Return lists of present and missing files."""
    present = []
    missing = []
    for key, filename in EXPECTED_RAW_FILES.items():
        file_path = RAW_DATA_DIR / filename
        if file_path.exists() and file_path.stat().st_size > 0:
            present.append(filename)
        else:
            missing.append(filename)
    return present, missing

def download_via_kaggle_api() -> bool:
    """Attempt download using kaggle package or CLI."""
    try:
        from kaggle.api.kaggle_api_extended import KaggleApi
        api = KaggleApi()
        api.authenticate()
        print(f"[*] Authenticated with Kaggle API. Downloading '{KAGGLE_DATASET}' into {RAW_DATA_DIR}...")
        api.dataset_download_files(KAGGLE_DATASET, path=str(RAW_DATA_DIR), unzip=True)
        print("[+] Download and extraction complete!")
        return True
    except Exception as e:
        print(f"[-] Kaggle API automated download could not proceed: {e}")
        return False

def check_for_zips_to_extract():
    """Extract any .zip file found in data/raw/."""
    for zip_path in RAW_DATA_DIR.glob("*.zip"):
        print(f"[*] Found zip archive: {zip_path.name}. Extracting...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(RAW_DATA_DIR)
        print(f"[+] Extracted {zip_path.name}")

def main():
    print("=" * 60)
    print("Olist Brazilian E-Commerce Dataset Verification")
    print("=" * 60)

    # Check if a zip was manually dropped into data/raw
    check_for_zips_to_extract()

    present, missing = check_existing_files()

    if not missing:
        print(f"[SUCCESS] All {len(present)} required raw CSV files are present in {RAW_DATA_DIR}:")
        for f in present:
            print(f"  [OK] {f}")
        return 0

    print(f"[*] Currently found {len(present)} of {len(EXPECTED_RAW_FILES)} files.")
    if present:
        for f in present:
            print(f"  [OK] {f}")
    print(f"\n[-] Missing {len(missing)} files:")
    for f in missing:
        print(f"  [MISSING] {f}")

    print("\nAttempting automated Kaggle download...")
    if download_via_kaggle_api():
        check_for_zips_to_extract()
        present, missing = check_existing_files()
        if not missing:
            print("\n[SUCCESS] All dataset files acquired successfully!")
            return 0

    print("\n" + "=" * 60)
    print("MANUAL DOWNLOAD INSTRUCTIONS:")
    print("=" * 60)
    print("1. Go to: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce")
    print("2. Click 'Download' (archive.zip, ~15MB compressed).")
    print(f"3. Unzip the contents directly into:")
    print(f"   {RAW_DATA_DIR.resolve()}")
    print("4. Re-run this script to verify: python python/download_data.py")
    print("=" * 60)
    return 1

if __name__ == "__main__":
    sys.exit(main())
