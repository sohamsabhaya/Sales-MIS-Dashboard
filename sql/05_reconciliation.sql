-- =============================================================================
-- SQL Automated Reconciliation & Integrity Verification
-- Ensures no revenue duplication, verifies star schema totals vs staging
-- =============================================================================

-- Test 1: Check Gross Revenue Match between Staging and Core Facts
WITH stg_rev AS (
    SELECT SUM(i.price) AS stg_revenue
    FROM stg.order_items i
    JOIN stg.orders o ON i.order_id = o.order_id
    WHERE o.order_status IN ('delivered', 'shipped', 'invoiced', 'approved')
),
core_rev AS (
    SELECT SUM(i.price) AS core_revenue
    FROM core.fact_order_item i
    JOIN core.fact_order o ON i.order_id = o.order_id
    WHERE o.is_revenue_bearing = TRUE
)
SELECT
    'Gross Revenue (Staging vs Core)' AS check_name,
    s.stg_revenue,
    c.core_revenue,
    (c.core_revenue - s.stg_revenue) AS variance,
    CASE WHEN (c.core_revenue - s.stg_revenue) = 0 THEN 'PASSED' ELSE 'FAILED' END AS status
FROM stg_rev s, core_rev c;

-- Test 2: Verify No Join Fanout (Payments Join Test)
WITH base_revenue AS (
    SELECT SUM(price) AS true_rev
    FROM core.fact_order_item i
    JOIN core.fact_order o ON i.order_id = o.order_id
    WHERE o.is_revenue_bearing = TRUE
),
cte_payment_revenue AS (
    SELECT SUM(i.price) AS revenue_with_cte_payment
    FROM core.fact_order_item i
    JOIN core.fact_order o ON i.order_id = o.order_id
    LEFT JOIN (
        SELECT order_id, SUM(payment_value) AS total_paid
        FROM core.fact_payment
        GROUP BY order_id
    ) p ON o.order_id = p.order_id
    WHERE o.is_revenue_bearing = TRUE
)
SELECT
    'Fanout Prevention Test' AS check_name,
    b.true_rev,
    cp.revenue_with_cte_payment,
    (cp.revenue_with_cte_payment - b.true_rev) AS variance,
    CASE WHEN (cp.revenue_with_cte_payment - b.true_rev) = 0 THEN 'PASSED' ELSE 'FAILED' END AS status
FROM base_revenue b, cte_payment_revenue cp;

-- Test 3: Referential Integrity Check (Orphan Items)
SELECT
    'Orphan Items in Core' AS check_name,
    COUNT(*) AS orphan_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASSED' ELSE 'FAILED' END AS status
FROM core.fact_order_item i
LEFT JOIN core.fact_order o ON i.order_id = o.order_id
WHERE o.order_id IS NULL;
