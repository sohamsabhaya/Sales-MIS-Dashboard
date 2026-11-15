-- =============================================================================
-- Advanced Analytics: RFM Customer Segmentation & Cohort Retention (Milestone 7)
-- Codifies strategic customer analytics directly into analytical views.
-- =============================================================================

-- View 1: Customer RFM Metrics and Segmentation
CREATE OR REPLACE VIEW rpt.v_customer_rfm_segments AS
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        MAX(o.purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(i.price) AS total_spend
    FROM core.dim_customer c
    JOIN core.fact_order o ON c.customer_id = o.customer_id
    JOIN core.fact_order_item i ON o.order_id = i.order_id
    WHERE o.is_revenue_bearing = TRUE
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        total_orders,
        total_spend,
        last_purchase_date,
        -- Reference date: 2018-09-01 (end of active reporting window)
        DATE_PART('day', '2018-09-01'::TIMESTAMP - last_purchase_date) AS recency_days,
        NTILE(5) OVER (ORDER BY DATE_PART('day', '2018-09-01'::TIMESTAMP - last_purchase_date) DESC) AS r_score,
        NTILE(5) OVER (ORDER BY total_orders ASC) AS f_score,
        NTILE(5) OVER (ORDER BY total_spend ASC) AS m_score
    FROM customer_orders
)
SELECT
    customer_unique_id,
    recency_days,
    total_orders,
    ROUND(total_spend, 2) AS total_spend,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Promising / New'
        WHEN r_score = 3 AND f_score <= 2 THEN 'Need Attention'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating / Lost'
        ELSE 'General Customers'
    END AS customer_segment
FROM rfm_scores;

-- View 2: Monthly Customer Acquisition Cohort Retention
CREATE OR REPLACE VIEW rpt.v_cohort_retention AS
WITH customer_first_purchase AS (
    SELECT
        c.customer_unique_id,
        MIN(d.calendar_date) AS first_order_date,
        TO_CHAR(MIN(d.calendar_date), 'YYYY-MM') AS cohort_month
    FROM core.dim_customer c
    JOIN core.fact_order o ON c.customer_id = o.customer_id
    JOIN core.dim_date d ON o.purchase_date_key = d.date_key
    WHERE o.is_revenue_bearing = TRUE
    GROUP BY c.customer_unique_id
),
customer_activity AS (
    SELECT
        c.customer_unique_id,
        fp.cohort_month,
        d.year_month AS activity_month,
        (EXTRACT(YEAR FROM d.calendar_date) - EXTRACT(YEAR FROM fp.first_order_date)) * 12 +
        (EXTRACT(MONTH FROM d.calendar_date) - EXTRACT(MONTH FROM fp.first_order_date)) AS period_number
    FROM core.dim_customer c
    JOIN customer_first_purchase fp ON c.customer_unique_id = fp.customer_unique_id
    JOIN core.fact_order o ON c.customer_id = o.customer_id
    JOIN core.dim_date d ON o.purchase_date_key = d.date_key
    WHERE o.is_revenue_bearing = TRUE
    GROUP BY c.customer_unique_id, fp.cohort_month, d.year_month, fp.first_order_date, d.calendar_date
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM customer_first_purchase
    GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    cs.cohort_size,
    ca.period_number,
    COUNT(DISTINCT ca.customer_unique_id) AS active_customers,
    ROUND(COUNT(DISTINCT ca.customer_unique_id)::NUMERIC / NULLIF(cs.cohort_size, 0) * 100, 2) AS retention_rate_pct
FROM customer_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
GROUP BY ca.cohort_month, cs.cohort_size, ca.period_number
ORDER BY ca.cohort_month, ca.period_number;

