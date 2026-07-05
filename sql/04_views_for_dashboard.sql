-- ============================================================
-- 04_views_for_dashboard.sql
-- Project: Nova Retail - Profitability Optimization
-- Purpose: Create reusable views for dashboards and reporting
-- Database: PostgreSQL
-- ============================================================

CREATE OR REPLACE VIEW nova_retail.view_kpi_summary AS
SELECT
    COUNT(*) AS order_lines,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0), 4) AS profit_margin,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_making_rows,
    ROUND(SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)::NUMERIC / NULLIF(COUNT(*), 0), 4) AS loss_making_row_share
FROM nova_retail.fact_sales;


CREATE OR REPLACE VIEW nova_retail.view_yearly_performance AS
SELECT
    order_year,
    ROUND(SUM(sales), 2) AS sales,
    ROUND(SUM(profit), 2) AS profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0), 4) AS profit_margin,
    COUNT(DISTINCT order_id) AS orders
FROM nova_retail.fact_sales
GROUP BY order_year;


CREATE OR REPLACE VIEW nova_retail.view_monthly_performance AS
SELECT
    order_year_month,
    ROUND(SUM(sales), 2) AS sales,
    ROUND(SUM(profit), 2) AS profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0), 4) AS profit_margin,
    COUNT(DISTINCT order_id) AS orders
FROM nova_retail.fact_sales
GROUP BY order_year_month;


CREATE OR REPLACE VIEW nova_retail.view_category_performance AS
SELECT
    p.category,
    ROUND(SUM(f.sales), 2) AS sales,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0), 4) AS profit_margin,
    SUM(f.quantity) AS quantity,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(CASE WHEN f.profit < 0 THEN 1 ELSE 0 END) AS loss_making_rows
FROM nova_retail.fact_sales f
JOIN nova_retail.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category;


CREATE OR REPLACE VIEW nova_retail.view_sub_category_performance AS
SELECT
    p.category,
    p.sub_category,
    ROUND(SUM(f.sales), 2) AS sales,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0), 4) AS profit_margin,
    SUM(f.quantity) AS quantity,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(CASE WHEN f.profit < 0 THEN 1 ELSE 0 END) AS loss_making_rows
FROM nova_retail.fact_sales f
JOIN nova_retail.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category, p.sub_category;


CREATE OR REPLACE VIEW nova_retail.view_segment_performance AS
SELECT
    c.segment,
    ROUND(SUM(f.sales), 2) AS sales,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0), 4) AS profit_margin,
    COUNT(DISTINCT f.order_id) AS orders,
    COUNT(DISTINCT f.customer_id) AS customers
FROM nova_retail.fact_sales f
JOIN nova_retail.dim_customers c
    ON f.customer_id = c.customer_id
GROUP BY c.segment;


CREATE OR REPLACE VIEW nova_retail.view_market_performance AS
SELECT
    g.market,
    ROUND(SUM(f.sales), 2) AS sales,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0), 4) AS profit_margin,
    COUNT(DISTINCT f.order_id) AS orders,
    COUNT(DISTINCT f.customer_id) AS customers
FROM nova_retail.fact_sales f
JOIN nova_retail.dim_geography g
    ON f.geography_key = g.geography_key
GROUP BY g.market;


CREATE OR REPLACE VIEW nova_retail.view_discount_performance AS
WITH discount_analysis AS (
    SELECT
        CASE
            WHEN discount = 0 THEN 'No discount'
            WHEN discount > 0 AND discount <= 0.10 THEN 'Low discount'
            WHEN discount > 0.10 AND discount <= 0.20 THEN 'Moderate discount'
            WHEN discount > 0.20 AND discount <= 0.30 THEN 'High discount'
            WHEN discount > 0.30 AND discount <= 0.50 THEN 'Very high discount'
            WHEN discount > 0.50 THEN 'Extreme discount'
            ELSE 'Unknown'
        END AS discount_band,
        CASE
            WHEN discount = 0 THEN 1
            WHEN discount > 0 AND discount <= 0.10 THEN 2
            WHEN discount > 0.10 AND discount <= 0.20 THEN 3
            WHEN discount > 0.20 AND discount <= 0.30 THEN 4
            WHEN discount > 0.30 AND discount <= 0.50 THEN 5
            WHEN discount > 0.50 THEN 6
            ELSE 7
        END AS discount_band_order,
        sales,
        profit,
        order_id
    FROM nova_retail.fact_sales
)
SELECT
    discount_band,
    discount_band_order,
    ROUND(SUM(sales), 2) AS sales,
    ROUND(SUM(profit), 2) AS profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0), 4) AS profit_margin,
    COUNT(*) AS order_lines,
    COUNT(DISTINCT order_id) AS orders,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_making_rows,
    ROUND(SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)::NUMERIC / NULLIF(COUNT(*), 0), 4) AS loss_rate
FROM discount_analysis
GROUP BY discount_band, discount_band_order;


CREATE OR REPLACE VIEW nova_retail.view_shipping_performance AS
SELECT
    ship_mode,
    ROUND(SUM(sales), 2) AS sales,
    ROUND(SUM(profit), 2) AS profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0), 4) AS profit_margin,
    ROUND(SUM(shipping_cost), 2) AS shipping_cost,
    ROUND(SUM(shipping_cost) / NULLIF(SUM(sales), 0), 4) AS shipping_cost_ratio,
    ROUND(AVG(shipping_delay_days), 2) AS avg_shipping_delay_days,
    COUNT(DISTINCT order_id) AS orders
FROM nova_retail.fact_sales
GROUP BY ship_mode;