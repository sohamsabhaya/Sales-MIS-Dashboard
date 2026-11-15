-- =============================================================================
-- Core Star Schema Population (from stg to core)
-- Idempotent UPSERT/INSERT logic to prevent duplication on reruns
-- =============================================================================

-- 1. Dim Region
INSERT INTO core.dim_region (region_name)
VALUES 
    ('North'),
    ('Northeast'),
    ('Central-West'),
    ('Southeast'),
    ('South'),
    ('Other')
ON CONFLICT (region_name) DO NOTHING;

-- 2. Dim Date (Calendar generation for 2016-01-01 to 2018-12-31)
INSERT INTO core.dim_date (
    date_key, calendar_date, year, quarter, month, month_name, 
    year_month, day_of_month, day_of_week, day_name, is_month_end
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT AS date_key,
    d::DATE AS calendar_date,
    EXTRACT(YEAR FROM d)::INT AS year,
    EXTRACT(QUARTER FROM d)::INT AS quarter,
    EXTRACT(MONTH FROM d)::INT AS month,
    TO_CHAR(d, 'Month') AS month_name,
    TO_CHAR(d, 'YYYY-MM') AS year_month,
    EXTRACT(DAY FROM d)::INT AS day_of_month,
    EXTRACT(DOW FROM d)::INT AS day_of_week,
    TO_CHAR(d, 'Day') AS day_name,
    (d::DATE = (DATE_TRUNC('MONTH', d) + INTERVAL '1 MONTH - 1 day')::DATE) AS is_month_end
FROM GENERATE_SERIES('2016-01-01'::DATE, '2018-12-31'::DATE, '1 day'::INTERVAL) d
ON CONFLICT (date_key) DO NOTHING;

-- 3. Dim Product
INSERT INTO core.dim_product (
    product_id, category_pt, category_en, weight_g, length_cm, height_cm, width_cm
)
SELECT
    p.product_id,
    COALESCE(p.product_category_name, 'unknown'),
    COALESCE(p.product_category_name_english, 'unknown'),
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM stg.products p
ON CONFLICT (product_id) DO UPDATE SET
    category_en = EXCLUDED.category_en,
    weight_g = EXCLUDED.weight_g;

-- 4. Dim Customer
INSERT INTO core.dim_customer (customer_id, customer_unique_id, city, state, region_id)
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    r.region_id
FROM stg.customers c
LEFT JOIN (
    SELECT 
        state_code,
        CASE 
            WHEN state_code IN ('AC', 'AP', 'AM', 'PA', 'RO', 'RR', 'TO') THEN 'North'
            WHEN state_code IN ('AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE') THEN 'Northeast'
            WHEN state_code IN ('DF', 'GO', 'MT', 'MS') THEN 'Central-West'
            WHEN state_code IN ('ES', 'MG', 'RJ', 'SP') THEN 'Southeast'
            WHEN state_code IN ('PR', 'RS', 'SC') THEN 'South'
            ELSE 'Other'
        END AS region_name
    FROM (SELECT DISTINCT customer_state AS state_code FROM stg.customers) s
) sm ON c.customer_state = sm.state_code
LEFT JOIN core.dim_region r ON sm.region_name = r.region_name
ON CONFLICT (customer_id) DO NOTHING;

-- 5. Dim Seller
INSERT INTO core.dim_seller (seller_id, city, state, region_id)
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    r.region_id
FROM stg.sellers s
LEFT JOIN (
    SELECT 
        state_code,
        CASE 
            WHEN state_code IN ('AC', 'AP', 'AM', 'PA', 'RO', 'RR', 'TO') THEN 'North'
            WHEN state_code IN ('AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE') THEN 'Northeast'
            WHEN state_code IN ('DF', 'GO', 'MT', 'MS') THEN 'Central-West'
            WHEN state_code IN ('ES', 'MG', 'RJ', 'SP') THEN 'Southeast'
            WHEN state_code IN ('PR', 'RS', 'SC') THEN 'South'
            ELSE 'Other'
        END AS region_name
    FROM (SELECT DISTINCT seller_state AS state_code FROM stg.sellers) sl
) sm ON s.seller_state = sm.state_code
LEFT JOIN core.dim_region r ON sm.region_name = r.region_name
ON CONFLICT (seller_id) DO NOTHING;

-- 6. Fact Order
INSERT INTO core.fact_order (
    order_id, customer_id, order_status, purchase_date_key, purchase_timestamp,
    approved_at, delivered_carrier_date, delivered_customer_date, estimated_delivery_date,
    is_revenue_bearing, is_delivered_on_time
)
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    TO_CHAR(o.order_purchase_timestamp::TIMESTAMP, 'YYYYMMDD')::INT AS purchase_date_key,
    o.order_purchase_timestamp::TIMESTAMP,
    NULLIF(o.order_approved_at, '')::TIMESTAMP,
    NULLIF(o.order_delivered_carrier_date, '')::TIMESTAMP,
    NULLIF(o.order_delivered_customer_date, '')::TIMESTAMP,
    NULLIF(o.order_estimated_delivery_date, '')::TIMESTAMP,
    (o.order_status IN ('delivered', 'shipped', 'invoiced', 'approved')) AS is_revenue_bearing,
    CASE 
        WHEN NULLIF(o.order_delivered_customer_date, '') IS NOT NULL AND NULLIF(o.order_estimated_delivery_date, '') IS NOT NULL 
        THEN (NULLIF(o.order_delivered_customer_date, '')::TIMESTAMP <= NULLIF(o.order_estimated_delivery_date, '')::TIMESTAMP)
        ELSE NULL
    END AS is_delivered_on_time
FROM stg.orders o
ON CONFLICT (order_id) DO UPDATE SET
    order_status = EXCLUDED.order_status,
    is_revenue_bearing = EXCLUDED.is_revenue_bearing,
    delivered_customer_date = EXCLUDED.delivered_customer_date;

-- 7. Fact Order Item
INSERT INTO core.fact_order_item (
    order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value
)
SELECT
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    NULLIF(i.shipping_limit_date, '')::TIMESTAMP,
    i.price,
    i.freight_value
FROM stg.order_items i
JOIN core.fact_order o ON i.order_id = o.order_id
ON CONFLICT (order_id, order_item_id) DO UPDATE SET
    price = EXCLUDED.price,
    freight_value = EXCLUDED.freight_value;

-- 8. Fact Payment
INSERT INTO core.fact_payment (
    order_id, payment_sequential, payment_type, payment_installments, payment_value
)
SELECT
    p.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value
FROM stg.payments p
JOIN core.fact_order o ON p.order_id = o.order_id
ON CONFLICT (order_id, payment_sequential) DO NOTHING;

-- 9. Fact Target
INSERT INTO core.fact_target (
    region_id, month_start, target_amount, is_synthetic
)
SELECT
    r.region_id,
    t.month_start::DATE,
    t.target_amount,
    COALESCE(t.is_synthetic, TRUE)
FROM stg.targets t
JOIN core.dim_region r ON t.region = r.region_name
ON CONFLICT (region_id, month_start) DO UPDATE SET
    target_amount = EXCLUDED.target_amount;
