"""
Synthetic Targets Generator
Generates monthly regional sales targets based on historical orders.
Includes intentional missing targets to test system edge cases as specified in SRS 3.3.
"""
from pathlib import Path
import sys
import numpy as np
import pandas as pd

from config import RAW_DATA_DIR, SYNTHETIC_TARGETS_CONFIG

# Brazil 5 Macro-Regions mapping by state abbreviation
STATE_TO_REGION = {
    # North
    "AC": "North", "AP": "North", "AM": "North", "PA": "North", "RO": "North", "RR": "North", "TO": "North",
    # Northeast
    "AL": "Northeast", "BA": "Northeast", "CE": "Northeast", "MA": "Northeast", "PB": "Northeast",
    "PE": "Northeast", "PI": "Northeast", "RN": "Northeast", "SE": "Northeast",
    # Central-West
    "DF": "Central-West", "GO": "Central-West", "MT": "Central-West", "MS": "Central-West",
    # Southeast
    "ES": "Southeast", "MG": "Southeast", "RJ": "Southeast", "SP": "Southeast",
    # South
    "PR": "South", "RS": "South", "SC": "South"
}

REGIONS = ["North", "Northeast", "Central-West", "Southeast", "South"]

def generate_targets():
    orders_path = RAW_DATA_DIR / "olist_orders_dataset.csv"
    items_path = RAW_DATA_DIR / "olist_order_items_dataset.csv"
    customers_path = RAW_DATA_DIR / "olist_customers_dataset.csv"

    output_path = RAW_DATA_DIR / "targets_synthetic.csv"
    seed = SYNTHETIC_TARGETS_CONFIG.get("seed", 42)
    growth_rate = SYNTHETIC_TARGETS_CONFIG.get("base_growth_rate", 1.08)
    variation_pct = SYNTHETIC_TARGETS_CONFIG.get("variation_pct", 0.05)
    intentional_missing = SYNTHETIC_TARGETS_CONFIG.get("intentional_missing", [])

    np.random.seed(seed)

    # If raw files exist, calculate baseline from actual monthly regional sales
    if orders_path.exists() and items_path.exists() and customers_path.exists():
        print("[*] Generating synthetic targets based on actual order history...")
        orders = pd.read_csv(orders_path, usecols=["order_id", "customer_id", "order_status", "order_purchase_timestamp"])
        items = pd.read_csv(items_path, usecols=["order_id", "price"])
        customers = pd.read_csv(customers_path, usecols=["customer_id", "customer_state"])

        # Filter valid orders
        valid_orders = orders[~orders["order_status"].isin(["canceled", "unavailable"])].copy()
        valid_orders["purchase_date"] = pd.to_datetime(valid_orders["order_purchase_timestamp"])
        valid_orders["month_start"] = valid_orders["purchase_date"].dt.to_period("M").dt.to_timestamp()

        # Merge with customers and items
        merged = valid_orders.merge(customers, on="customer_id").merge(items, on="order_id")
        merged["region"] = merged["customer_state"].map(STATE_TO_REGION).fillna("Other")

        # Group by month_start and region
        monthly_regional = merged.groupby(["month_start", "region"])["price"].sum().reset_index()
        monthly_regional.rename(columns={"price": "actual_revenue"}, inplace=True)

        target_rows = []
        for _, row in monthly_regional.iterrows():
            month_str = row["month_start"].strftime("%Y-%m")
            region = row["region"]

            # Check if this region-month is intentionally missing for testing
            is_missing = any(im["region"] == region and im["month"] == month_str for im in intentional_missing)
            if is_missing:
                continue

            # Random noise factor between 1 - variation_pct and 1 + variation_pct
            noise = 1.0 + np.random.uniform(-variation_pct, variation_pct)
            target_amount = round(row["actual_revenue"] * growth_rate * noise, 2)

            target_rows.append({
                "region": region,
                "month_start": row["month_start"].strftime("%Y-%m-%d"),
                "month": month_str,
                "target_amount": target_amount,
                "is_synthetic": True
            })

        df_targets = pd.DataFrame(target_rows)
    else:
        # Fallback baseline if raw files are not yet present
        print("[*] Raw data files not found. Creating placeholder baseline targets for 2017-2018...")
        dates = pd.date_range(start="2017-01-01", end="2018-08-01", freq="MS")
        target_rows = []
        base_weights = {"Southeast": 60000.0, "South": 25000.0, "Northeast": 15000.0, "Central-West": 10000.0, "North": 4000.0}

        for dt in dates:
            month_str = dt.strftime("%Y-%m")
            for region in REGIONS:
                is_missing = any(im["region"] == region and im["month"] == month_str for im in intentional_missing)
                if is_missing:
                    continue

                base = base_weights.get(region, 10000.0)
                noise = 1.0 + np.random.uniform(-variation_pct, variation_pct)
                target_amount = round(base * noise, 2)
                target_rows.append({
                    "region": region,
                    "month_start": dt.strftime("%Y-%m-%d"),
                    "month": month_str,
                    "target_amount": target_amount,
                    "is_synthetic": True
                })
        df_targets = pd.DataFrame(target_rows)

    df_targets.to_csv(output_path, index=False)
    print(f"[+] Synthetic targets generated: {len(df_targets)} records written to {output_path}")
    print(f"[+] Intentionally excluded targets for edge-case testing: {intentional_missing}")

if __name__ == "__main__":
    generate_targets()
