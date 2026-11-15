-- =============================================================================
-- Ad-hoc & Strategic Analysis Queries
-- Used for MIS reports, executive insights, and business analysis
-- =============================================================================

-- Query 1: Monthly Trend with MoM Growth & AOV
SELECT
    year_month,
    gross_revenue,
    total_orders,
    aov,
    items_per_order,
    mom_growth_pct,
    cancellation_rate_pct
FROM rpt.v_monthly_kpis
ORDER BY year_month;

-- Query 2: Regional Performance vs Targets (Including Missing Target Handling)
SELECT
    year_month,
    region_name,
    gross_revenue,
    orders_count,
    target_amount,
    target_achievement_pct,
    target_gap,
    regional_contribution_pct
FROM rpt.v_regional_performance
WHERE year_month = '2018-06'
ORDER BY gross_revenue DESC;

-- Query 3: Top 10 Product Categories by Revenue (Pareto Analysis)
SELECT
    category_revenue_rank,
    category_en,
    gross_revenue,
    items_sold,
    category_aov,
    ROUND(gross_revenue / SUM(gross_revenue) OVER () * 100, 2) AS pct_of_total_revenue,
    ROUND(SUM(gross_revenue) OVER (ORDER BY category_revenue_rank) / SUM(gross_revenue) OVER () * 100, 2) AS cumulative_revenue_pct
FROM rpt.v_category_performance
LIMIT 10;

-- Query 4: Cancellation Analysis by Customer Region
SELECT
    r.region_name,
    COUNT(o.order_id) AS total_orders,
    COUNT(CASE WHEN o.order_status IN ('canceled', 'unavailable') THEN 1 END) AS canceled_orders,
    ROUND(COUNT(CASE WHEN o.order_status IN ('canceled', 'unavailable') THEN 1 END)::NUMERIC / NULLIF(COUNT(o.order_id), 0) * 100, 2) AS regional_cancellation_rate_pct
FROM core.fact_order o
JOIN core.dim_customer c ON o.customer_id = c.customer_id
JOIN core.dim_region r ON c.region_id = r.region_id
GROUP BY r.region_name
ORDER BY regional_cancellation_rate_pct DESC;

-- Query 5: Missing Target Audit (Edge Case Check)
SELECT
    r.region_name,
    TO_CHAR(d.calendar_date, 'YYYY-MM') AS year_month,
    'Target missing intentionally for edge-case validation' AS reason
FROM core.dim_region r
CROSS JOIN (
    SELECT DISTINCT calendar_date 
    FROM core.dim_date 
    WHERE day_of_month = 1 AND year_month BETWEEN '2017-01' AND '2018-08'
) d
LEFT JOIN core.fact_target t 
    ON r.region_id = t.region_id AND t.month_start = d.calendar_date
WHERE t.target_amount IS NULL AND r.region_name != 'Other'
ORDER BY year_month, r.region_name;
