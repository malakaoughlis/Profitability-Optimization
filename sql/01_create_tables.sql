-- ============================================================
-- 01_create_tables.sql
-- Project: Nova Retail - Profitability Optimization
-- Purpose: Create a simple relational model for SQL analysis
-- Database: PostgreSQL
-- ============================================================

CREATE SCHEMA IF NOT EXISTS nova_retail;

DROP TABLE IF EXISTS nova_retail.fact_sales CASCADE;
DROP TABLE IF EXISTS nova_retail.dim_customers CASCADE;
DROP TABLE IF EXISTS nova_retail.dim_products CASCADE;
DROP TABLE IF EXISTS nova_retail.dim_geography CASCADE;
DROP TABLE IF EXISTS nova_retail.stg_cleaned_superstore CASCADE;

-- Staging table matching the cleaned CSV structure.
-- This table is used only to load the cleaned dataset before splitting it into dimensions and facts.

CREATE TABLE nova_retail.stg_cleaned_superstore (
    category TEXT,
    city TEXT,
    country TEXT,
    customer_id TEXT,
    customer_name TEXT,
    discount NUMERIC,
    market TEXT,
    order_date DATE,
    order_id TEXT,
    order_priority TEXT,
    product_id TEXT,
    product_name TEXT,
    profit NUMERIC,
    quantity INTEGER,
    region TEXT,
    row_id INTEGER,
    sales NUMERIC,
    segment TEXT,
    ship_date DATE,
    ship_mode TEXT,
    shipping_cost NUMERIC,
    state TEXT,
    sub_category TEXT,
    order_year INTEGER,
    market_group TEXT,
    order_week INTEGER,
    order_month INTEGER,
    order_month_name TEXT,
    order_quarter TEXT,
    order_year_month TEXT,
    shipping_delay_days INTEGER,
    profit_margin NUMERIC,
    profit_status TEXT,
    discount_band TEXT,
    shipping_cost_ratio NUMERIC,
    order_size TEXT
);

CREATE TABLE nova_retail.dim_customers (
    customer_id TEXT PRIMARY KEY,
    customer_name TEXT,
    segment TEXT
);

CREATE TABLE nova_retail.dim_products (
    product_key TEXT PRIMARY KEY,
    product_id TEXT,
    product_name TEXT,
    category TEXT,
    sub_category TEXT
);

CREATE TABLE nova_retail.dim_geography (
    geography_key TEXT PRIMARY KEY,
    market TEXT,
    market_group TEXT,
    region TEXT,
    country TEXT,
    state TEXT,
    city TEXT
);

CREATE TABLE nova_retail.fact_sales (
    row_id INTEGER PRIMARY KEY,
    order_id TEXT,
    order_date DATE,
    ship_date DATE,
    customer_id TEXT REFERENCES nova_retail.dim_customers(customer_id),
    product_key TEXT REFERENCES nova_retail.dim_products(product_key),
    geography_key TEXT REFERENCES nova_retail.dim_geography(geography_key),
    sales NUMERIC,
    profit NUMERIC,
    quantity INTEGER,
    discount NUMERIC,
    shipping_cost NUMERIC,
    ship_mode TEXT,
    order_priority TEXT,
    order_year INTEGER,
    order_month INTEGER,
    order_month_name TEXT,
    order_quarter TEXT,
    order_year_month TEXT,
    order_week INTEGER,
    shipping_delay_days INTEGER,
    profit_margin NUMERIC,
    profit_status TEXT,
    discount_band TEXT,
    shipping_cost_ratio NUMERIC,
    order_size TEXT
);