-- =============================================================================
-- Production KPI Views (rpt schema)
-- Implements single source of truth for KPIs (K1 - K13)
-- =============================================================================

-- View 1: Monthly National KPI Summary (K1, K2, K3, K4, K5, K8, K10)
CREATE OR REPLACE VIEW rpt.v_monthly_kpis AS
WITH monthly_orders AS (
    SELECT
        d.year,
        d.month,
        d.year_month,
        COUNT(DISTINCT o.order_id) AS total_orders_all,
        COUNT(DISTINCT CASE WHEN o.is_revenue_bearing THEN o.order_id END) AS total_orders,
        COUNT(DISTINCT CASE WHEN o.order_status IN ('canceled', 'unavailable') THEN o.order_id END) AS canceled_orders,
        COUNT(CASE WHEN o.is_delivered_on_time = TRUE THEN 1 END) AS on_time_orders,
        COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) AS delivered_orders
    FROM core.fact_order o
    JOIN core.dim_date d ON o.purchase_date_key = d.date_key
    GROUP BY d.year, d.month, d.year_month
),
monthly_items AS (
    SELECT
        d.year_month,
        SUM(i.price) AS gross_revenue,
        SUM(i.freight_value) AS freight_revenue,
        COUNT(i.order_item_id) AS total_items
    FROM core.fact_order_item i
    JOIN core.fact_order o ON i.order_id = o.order_id
    JOIN core.dim_date d ON o.purchase_date_key = d.date_key
    WHERE o.is_revenue_bearing = TRUE
    GROUP BY d.year_month
)
SELECT
    mo.year,
    mo.month,
    mo.year_month,
    COALESCE(mi.gross_revenue, 0) AS gross_revenue,
    COALESCE(mi.freight_revenue, 0) AS freight_revenue,
    mo.total_orders,
    ROUND(COALESCE(mi.gross_revenue, 0) / NULLIF(mo.total_orders, 0), 2) AS aov,
    ROUND(CAST(mi.total_items AS NUMERIC) / NULLIF(mo.total_orders, 0), 2) AS items_per_order,
    ROUND((COALESCE(mi.gross_revenue, 0) - LAG(mi.gross_revenue) OVER (ORDER BY mo.year_month)) 
          / NULLIF(LAG(mi.gross_revenue) OVER (ORDER BY mo.year_month), 0) * 100, 2) AS mom_growth_pct,
    ROUND(CAST(mo.canceled_orders AS NUMERIC) / NULLIF(mo.total_orders_all, 0) * 100, 2) AS cancellation_rate_pct,
    ROUND(CAST(mo.on_time_orders AS NUMERIC) / NULLIF(mo.delivered_orders, 0) * 100, 2) AS on_time_delivery_pct
FROM monthly_orders mo
LEFT JOIN monthly_items mi ON mo.year_month = mi.year_month
ORDER BY mo.year_month;

-- View 2: Regional Performance vs Targets (K6, K7, K11)
CREATE OR REPLACE VIEW rpt.v_regional_performance AS
WITH regional_revenue AS (
    SELECT
        d.year_month,
        r.region_id,
        r.region_name,
        SUM(i.price) AS gross_revenue,
        COUNT(DISTINCT o.order_id) AS orders_count
    FROM core.fact_order_item i
    JOIN core.fact_order o ON i.order_id = o.order_id
    JOIN core.dim_customer c ON o.customer_id = c.customer_id
    JOIN core.dim_region r ON c.region_id = r.region_id
    JOIN core.dim_date d ON o.purchase_date_key = d.date_key
    WHERE o.is_revenue_bearing = TRUE
    GROUP BY d.year_month, r.region_id, r.region_name
),
national_totals AS (
    SELECT year_month, SUM(gross_revenue) AS national_revenue
    FROM regional_revenue
    GROUP BY year_month
)
SELECT
    rr.year_month,
    rr.region_name,
    rr.gross_revenue,
    rr.orders_count,
    t.target_amount,
    -- Target Achievement % (NULL if no target exists, never 0)
    ROUND(rr.gross_revenue / NULLIF(t.target_amount, 0) * 100, 2) AS target_achievement_pct,
    -- Target Gap (Actual - Target)
    ROUND(rr.gross_revenue - t.target_amount, 2) AS target_gap,
    -- Regional Contribution %
    ROUND(rr.gross_revenue / NULLIF(nat.national_revenue, 0) * 100, 2) AS regional_contribution_pct,
    COALESCE(t.is_synthetic, TRUE) AS is_synthetic
FROM regional_revenue rr
JOIN national_totals nat ON rr.year_month = nat.year_month
LEFT JOIN core.fact_target t 
    ON rr.region_id = t.region_id 
    AND t.month_start = TO_DATE(rr.year_month || '-01', 'YYYY-MM-DD')
ORDER BY rr.year_month, rr.gross_revenue DESC;

-- View 3: Product Category Ranking (K12)
CREATE OR REPLACE VIEW rpt.v_category_performance AS
SELECT
    p.category_en,
    SUM(i.price) AS gross_revenue,
    COUNT(i.order_item_id) AS items_sold,
    COUNT(DISTINCT o.order_id) AS orders_count,
    ROUND(SUM(i.price) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS category_aov,
    RANK() OVER (ORDER BY SUM(i.price) DESC) AS category_revenue_rank
FROM core.fact_order_item i
JOIN core.fact_order o ON i.order_id = o.order_id
JOIN core.dim_product p ON i.product_id = p.product_id
WHERE o.is_revenue_bearing = TRUE
GROUP BY p.category_en
ORDER BY gross_revenue DESC;

-- View 4: Reconciliation Totals (Single Source of Truth)
CREATE OR REPLACE VIEW rpt.v_reconciliation_totals AS
SELECT
    COUNT(DISTINCT CASE WHEN o.is_revenue_bearing THEN o.order_id END) AS total_valid_orders,
    COUNT(DISTINCT o.order_id) AS total_orders_all,
    SUM(i.price) AS total_gross_revenue,
    SUM(i.freight_value) AS total_freight_revenue,
    ROUND(SUM(i.price) / NULLIF(COUNT(DISTINCT CASE WHEN o.is_revenue_bearing THEN o.order_id END), 0), 2) AS national_aov
FROM core.fact_order o
JOIN core.fact_order_item i ON o.order_id = i.order_id
WHERE o.is_revenue_bearing = TRUE;
