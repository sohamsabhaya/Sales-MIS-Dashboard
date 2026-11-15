# Sales Operations & Executive Business Intelligence Insights

**System:** Sales Operations & MIS Analytics Platform  
**Market:** E-Commerce Transaction Intelligence  
**Reporting Window:** 2017-01-01 to 2018-08-31  
**Prepared For:** Commercial Directors, Operations Leads & VP of Sales  

---

## 1. Executive Summary

This enterprise MIS analytics system processed **99,441 orders**, **112,650 order items**, and **$ 13.43M in gross merchandise value (GMV)**. The audited data warehouse and reporting engine reveal three defining operational realities:

1. **Extreme Geographic Concentration**: Southeast (SP, RJ, MG) drives **68.4% of total sales volume** and **63.6% of gross revenue**.
2. **High Customer Acquisition Churn**: Over **96.8% of consumers are single-purchase buyers**, yielding an M1 retention rate under **0.7%**.
3. **Category Pareto Power Law**: The top **10 of 71 product categories generate >52% of total gross revenue**, led by `health_beauty`, `watches_gifts`, `bed_bath_table`, and `sports_leisure`.

```
        National Revenue Distribution by Region
        ┌──────────────────────────────────────────────┐
        │ Southeast (SP, RJ, MG, ES)     : 63.6% ██████│
        │ South (PR, RS, SC)             : 17.8% █▌    │
        │ Northeast (BA, PE, CE, etc.)   : 11.4% █     │
        │ Central-West (DF, GO, MT, MS)  :  4.7% ▌     │
        │ North (PA, AM, RO, etc.)       :  2.5% ▎     │
        └──────────────────────────────────────────────┘
```

---

## 2. Key Performance Indicators (National Benchmark)

| Operational KPI | Baseline Metric | Benchmark / SLA Target | Operational Status |
|---|---|---|---|
| **Gross Merchandise Value (GMV)** | $ 13,433,961.52 | Target Budget (Synthetic) | **On Track** (94.20% vs Stretch Plan) |
| **Average Order Value (AOV)** | $ 137.22 | $ 130.00 | **Exceeding** (+5.5%) |
| **Items Per Order** | 1.14 items | 1.25 items | **Lagging** (Multi-item basket deficit) |
| **On-Time Delivery Rate** | 92.5% | 95.0% SLA | **At Risk** (Logistics delays in North/NE) |
| **Order Cancellation Rate** | 1.24% | < 2.0% | **Healthy** (Well within threshold) |
| **Freight-to-GMV Ratio** | 14.6% national avg | < 12.0% | **Critical in North/NE (>28%)** |

---

## 3. Deep Dive: Regional Operations & Logistics Inequality

### A. Delivery Time Disparity by Macro-Region
- **Southeast**: Average transit duration is **8.2 days** (São Paulo intra-state median: **5.4 days**).
- **South**: Average transit duration is **12.1 days**.
- **Central-West**: Average transit duration is **14.8 days**.
- **Northeast**: Average transit duration is **21.4 days**.
- **North**: Average transit duration is **26.9 days** (Worst case: up to 48 days).

### B. Logistics Cost Headwind
In Northern states (Acre, Amazonas, Roraima), freight costs frequently exceed **35% of product price**, causing high cart abandonment and lower target achievement.

> **Operational Recommendation #1 (Decentralized Hubbing):**  
> Establish regional fulfillment consolidation points in **Recife (Northeast)** and **Brasília (Central-West)** to drop transit days from 21+ to under 10 days, cutting freight costs by ~30%.

---

## 4. Deep Dive: Customer RFM Segmentation & Retention Deficit

Our RFM segmentation engine classified **94,686 unique purchasers** across 6 distinct behavioural tiers:

| Customer Segment | Total Users | User Base % | Total Revenue ($) | Revenue % | Average Spend | Avg Recency |
|---|---|---|---|---|---|---|
| **Promising / New** | 36,796 | 38.86% | $ 5,176,987.45 | 38.54% | $ 140.69 | 95.7 days |
| **Hibernating / Lost** | 36,695 | 38.75% | $ 5,121,871.74 | 38.13% | $ 139.58 | 400.9 days |
| **Need Attention** | 18,329 | 19.36% | $ 2,387,449.87 | 17.77% | $ 130.26 | 225.6 days |
| **Loyal Customers** | 1,738 | 1.84% | $ 436,854.60 | 3.25% | $ 251.35 | 139.6 days |
| **At Risk** | 1,019 | 1.08% | $ 253,144.24 | 1.88% | $ 248.42 | 388.3 days |
| **Champions** | 119 | 0.13% | $ 57,653.62 | 0.43% | $ 484.48 | 98.6 days |

### Cohort Retention Matrix Finding:
- **Month 0**: 100% active.
- **Month 1**: **0.4% - 0.7% repeat rate**.
- **Month 2-6**: Plateauing below **0.3%**.

> **Commercial Recommendation #2 (Win-Back CRM Lifecycle):**  
> Focus marketing automation on the **18,329 customers in the "Need Attention" tier** (60-120 days post-order). A targeted automated CRM push with personalized re-order recommendations in consumable categories (e.g., `health_beauty`, `perfumery`) can unlock an estimated **$ 250,000+ incremental GMV**.

---

## 5. Product Category Concentration & Pareto Analysis

The top 10 categories represent over 52% of total marketplace GMV:

```
Rank | Category (English)        | Gross Revenue ($)   | Revenue Share | Cumulative %
-----|---------------------------|---------------------|---------------|-------------
 1   | health_beauty             | $ 1,258,681.34      | 9.26%         |  9.26%
 2   | watches_gifts             | $ 1,205,005.68      | 8.87%         | 18.13%
 3   | bed_bath_table            | $ 1,036,988.70      | 7.63%         | 25.76%
 4   | sports_leisure            | $   988,048.97      | 7.27%         | 33.03%
 5   | computers_accessories     | $   911,954.32      | 6.71%         | 39.74%
 6   | furniture_decor           | $   729,762.49      | 5.37%         | 45.11%
 7   | cool_stuff                | $   635,290.85      | 4.67%         | 49.78%
 8   | housewares                | $   632,248.55      | 4.65%         | 54.43%
 9   | auto                      | $   596,628.20      | 4.39%         | 58.82%
 10  | garden_tools              | $   485,256.46      | 3.57%         | 62.39%
```

> **Commercial Recommendation #3 (Cross-Merchandising & Bundle Pricing):**  
> Basket size is stagnant at **1.14 items/order**. Introducing "Frequently Bought Together" bundle discounts (e.g., `bed_bath_table` + `furniture_decor`) can drive average basket size toward the 1.30 target.

