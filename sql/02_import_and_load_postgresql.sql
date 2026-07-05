-- ============================================================
-- 02_import_and_load_postgresql.sql
-- Project: Nova Retail - Profitability Optimization
-- Purpose: Load cleaned CSV data and populate the relational model
-- Database: PostgreSQL
-- ============================================================

-- Step 1: Import the cleaned CSV into the staging table.
-- Adjust the file path depending on your local machine or database environment.
-- Run this command in psql.
--
-- Example:
-- \copy nova_retail.stg_cleaned_superstore FROM 'data/cleaned/cleaned_superstore.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- Step 2: Populate dimension tables.

INSERT INTO nova_retail.dim_customers (
    customer_id,
    customer_name,
    segment
)
SELECT DISTINCT
    customer_id,
    customer_name,
    segment
FROM nova_retail.stg_cleaned_superstore
ON CONFLICT (customer_id) DO NOTHING;

INSERT INTO nova_retail.dim_products (
    product_key,
    product_id,
    product_name,
    category,
    sub_category
)
SELECT DISTINCT
    md5(concat_ws('|', product_id, product_name, category, sub_category)) AS product_key,
    product_id,
    product_name,
    category,
    sub_category
FROM nova_retail.stg_cleaned_superstore
ON CONFLICT (product_key) DO NOTHING;

INSERT INTO nova_retail.dim_geography (
    geography_key,
    market,
    market_group,
    region,
    country,
    state,
    city
)
SELECT DISTINCT
    md5(concat_ws('|', market, region, country, state, city)) AS geography_key,
    market,
    market_group,
    region,
    country,
    state,
    city
FROM nova_retail.stg_cleaned_superstore
ON CONFLICT (geography_key) DO NOTHING;

-- Step 3: Populate fact table.

INSERT INTO nova_retail.fact_sales (
    row_id,
    order_id,
    order_date,
    ship_date,
    customer_id,
    product_key,
    geography_key,
    sales,
    profit,
    quantity,
    discount,
    shipping_cost,
    ship_mode,
    order_priority,
    order_year,
    order_month,
    order_month_name,
    order_quarter,
    order_year_month,
    order_week,
    shipping_delay_days,
    profit_margin,
    profit_status,
    discount_band,
    shipping_cost_ratio,
    order_size
)
SELECT
    row_id,
    order_id,
    order_date,
    ship_date,
    customer_id,
    md5(concat_ws('|', product_id, product_name, category, sub_category)) AS product_key,
    md5(concat_ws('|', market, region, country, state, city)) AS geography_key,
    sales,
    profit,
    quantity,
    discount,
    shipping_cost,
    ship_mode,
    order_priority,
    order_year,
    order_month,
    order_month_name,
    order_quarter,
    order_year_month,
    order_week,
    shipping_delay_days,
    profit_margin,
    profit_status,
    discount_band,
    shipping_cost_ratio,
    order_size
FROM nova_retail.stg_cleaned_superstore
ON CONFLICT (row_id) DO NOTHING;

-- Step 4: Basic load checks.

SELECT 'dim_customers' AS table_name, COUNT(*) AS rows FROM nova_retail.dim_customers
UNION ALL
SELECT 'dim_products', COUNT(*) FROM nova_retail.dim_products
UNION ALL
SELECT 'dim_geography', COUNT(*) FROM nova_retail.dim_geography
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM nova_retail.fact_sales;