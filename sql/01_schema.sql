-- =============================================================================
-- Sales Operations & MIS Analytics Warehouse Schema
-- Schemas: stg (Staging), core (Star Schema), rpt (Reporting), audit (Run Logs)
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS rpt;
CREATE SCHEMA IF NOT EXISTS audit;

-- -----------------------------------------------------------------------------
-- Audit Layer
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit.run_log (
    run_id SERIAL PRIMARY KEY,
    run_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    pipeline_stage VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    rows_processed INT DEFAULT 0,
    rows_quarantined INT DEFAULT 0,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS audit.reconciliation_log (
    check_id SERIAL PRIMARY KEY,
    check_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metric_name VARCHAR(100) NOT NULL,
    python_value NUMERIC(14, 2),
    sql_value NUMERIC(14, 2),
    variance NUMERIC(14, 2),
    match_status VARCHAR(20) NOT NULL
);

-- -----------------------------------------------------------------------------
-- Staging Layer (Truncated & Reloaded per Run)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS stg.orders CASCADE;
CREATE TABLE stg.orders (
    order_id VARCHAR(100),
    customer_id VARCHAR(100),
    order_status VARCHAR(50),
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

DROP TABLE IF EXISTS stg.order_items CASCADE;
CREATE TABLE stg.order_items (
    order_id VARCHAR(100),
    order_item_id INT,
    product_id VARCHAR(100),
    seller_id VARCHAR(100),
    shipping_limit_date TEXT,
    price NUMERIC(10, 2),
    freight_value NUMERIC(10, 2)
);

DROP TABLE IF EXISTS stg.customers CASCADE;
CREATE TABLE stg.customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

DROP TABLE IF EXISTS stg.products CASCADE;
CREATE TABLE stg.products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100),
    product_name_lenght NUMERIC(10, 2),
    product_description_lenght NUMERIC(10, 2),
    product_photos_qty NUMERIC(10, 2),
    product_weight_g NUMERIC(10, 2),
    product_length_cm NUMERIC(10, 2),
    product_height_cm NUMERIC(10, 2),
    product_width_cm NUMERIC(10, 2)
);

DROP TABLE IF EXISTS stg.sellers CASCADE;
CREATE TABLE stg.sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

DROP TABLE IF EXISTS stg.payments CASCADE;
CREATE TABLE stg.payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value NUMERIC(10, 2)
);

DROP TABLE IF EXISTS stg.targets CASCADE;
CREATE TABLE stg.targets (
    region VARCHAR(50),
    month_start TEXT,
    month VARCHAR(20),
    target_amount NUMERIC(12, 2),
    is_synthetic BOOLEAN
);

-- -----------------------------------------------------------------------------
-- Core Star Schema Dimensions
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.dim_region (
    region_id SERIAL PRIMARY KEY,
    region_name VARCHAR(30) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS core.dim_date (
    date_key INT PRIMARY KEY, -- YYYYMMDD
    calendar_date DATE UNIQUE NOT NULL,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    year_month VARCHAR(7) NOT NULL, -- YYYY-MM
    day_of_month INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(15) NOT NULL,
    is_month_end BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS core.dim_customer (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    city VARCHAR(100),
    state VARCHAR(5) NOT NULL,
    region_id INT REFERENCES core.dim_region(region_id)
);

CREATE TABLE IF NOT EXISTS core.dim_product (
    product_id VARCHAR(50) PRIMARY KEY,
    category_pt VARCHAR(100),
    category_en VARCHAR(100) NOT NULL DEFAULT 'unknown',
    weight_g NUMERIC(10, 2),
    length_cm NUMERIC(10, 2),
    height_cm NUMERIC(10, 2),
    width_cm NUMERIC(10, 2)
);

CREATE TABLE IF NOT EXISTS core.dim_seller (
    seller_id VARCHAR(50) PRIMARY KEY,
    city VARCHAR(100),
    state VARCHAR(5) NOT NULL,
    region_id INT REFERENCES core.dim_region(region_id)
);

-- -----------------------------------------------------------------------------
-- Core Star Schema Facts
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS core.fact_order (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL REFERENCES core.dim_customer(customer_id),
    order_status VARCHAR(30) NOT NULL,
    purchase_date_key INT REFERENCES core.dim_date(date_key),
    purchase_timestamp TIMESTAMP NOT NULL,
    approved_at TIMESTAMP,
    delivered_carrier_date TIMESTAMP,
    delivered_customer_date TIMESTAMP,
    estimated_delivery_date TIMESTAMP,
    is_revenue_bearing BOOLEAN NOT NULL DEFAULT FALSE,
    is_delivered_on_time BOOLEAN
);

CREATE TABLE IF NOT EXISTS core.fact_order_item (
    order_id VARCHAR(50) NOT NULL REFERENCES core.fact_order(order_id),
    order_item_id INT NOT NULL,
    product_id VARCHAR(50) NOT NULL REFERENCES core.dim_product(product_id),
    seller_id VARCHAR(50) NOT NULL REFERENCES core.dim_seller(seller_id),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    freight_value NUMERIC(10, 2) NOT NULL CHECK (freight_value >= 0),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE IF NOT EXISTS core.fact_payment (
    order_id VARCHAR(50) NOT NULL REFERENCES core.fact_order(order_id),
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(30) NOT NULL,
    payment_installments INT,
    payment_value NUMERIC(10, 2) NOT NULL CHECK (payment_value >= 0),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE IF NOT EXISTS core.fact_target (
    region_id INT NOT NULL REFERENCES core.dim_region(region_id),
    month_start DATE NOT NULL,
    target_amount NUMERIC(12, 2) NOT NULL CHECK (target_amount >= 0),
    is_synthetic BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (region_id, month_start)
);

-- Indexes for FKs and Date keys
CREATE INDEX IF NOT EXISTS idx_order_customer ON core.fact_order(customer_id);
CREATE INDEX IF NOT EXISTS idx_order_date_key ON core.fact_order(purchase_date_key);
CREATE INDEX IF NOT EXISTS idx_item_product ON core.fact_order_item(product_id);
CREATE INDEX IF NOT EXISTS idx_item_seller ON core.fact_order_item(seller_id);

-- -----------------------------------------------------------------------------
-- Read-Only Reporting User (NFR-05 Security: For Power BI & Excel MIS access)
-- -----------------------------------------------------------------------------
DO $do$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'reporting_user') THEN
    CREATE ROLE reporting_user WITH LOGIN PASSWORD 'reporting_pass';
  END IF;
END
$do$;

GRANT CONNECT ON DATABASE sales_ops_db TO reporting_user;
GRANT USAGE ON SCHEMA rpt TO reporting_user;
GRANT SELECT ON ALL TABLES IN SCHEMA rpt TO reporting_user;
GRANT USAGE ON SCHEMA core TO reporting_user;
GRANT SELECT ON ALL TABLES IN SCHEMA core TO reporting_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA rpt GRANT SELECT ON TABLES TO reporting_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT SELECT ON TABLES TO reporting_user;
