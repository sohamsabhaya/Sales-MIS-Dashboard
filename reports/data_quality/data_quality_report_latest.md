# Data Quality & Cleaning Audit Report
**Run Timestamp:** 2026-11-12 22:47:31

## 1. Table Cleaning & Ingestion Summary

| Table | Raw Rows | Cleaned Rows | Quarantined | Notes |
|---|---|---|---|---|
| `orders` | 99,441 | 99,441 | 0 | DQ-003 flagged: 0 delivery anomaly orders (flagged in is_delivery_anomaly) |
| `customers` | 99,441 | 99,441 | 0 | Standardized state abbreviations |
| `products` | 32,951 | 32,951 | 0 | Mapped translations, imputed missing categories as 'unknown' |
| `order_items` | 112,650 | 112,650 | 0 | DQ-007 review: 105 items > 99.9th percentile (R$2110.00) |
| `payments` | 103,886 | 103,886 | 0 | Verified sequence and payment types |
| `sellers` | 3,095 | 3,095 | 0 | Cleaned seller postal regions |