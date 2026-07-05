-- ============================================================
-- 03_business_analysis_queries.sql
-- Project: Nova Retail - Profitability Optimization
-- Purpose: SQL business analysis queries
-- Database: PostgreSQL
-- ============================================================

-- 1. Overall KPI Summary
SELECT
    COUNT(*) AS order_lines,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0), 4) AS profit_margin,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_making_rows,
    ROUND(
        SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)::NUMERIC / NULLIF(COUNT(*), 0),
        4
    ) AS loss_making_row_share
FROM nova_retail.fact_sales;


-- 2. Yearly Sales and Profit Growth
WITH yearly_performance AS (
    SELECT
        order_year,
        SUM(sales) AS sales,
        SUM(profit) AS profit,
        SUM(profit) / NULLIF(SUM(sales), 0) AS profit_margin
    FROM nova_retail.fact_sales
    GROUP BY order_year
),
yearly_with_lag AS (
    SELECT
        order_year,
        sales,
        profit,
        profit_margin,
        LAG(sales) OVER (ORDER BY order_year) AS previous_year_sales,
        LAG(profit) OVER (ORDER BY order_year) AS previous_year_profit
    FROM yearly_performance
)
SELECT
    order_year,
    ROUND(sales, 2) AS sales,
    ROUND(profit, 2) AS profit,
    ROUND(profit_margin, 4) AS profit_margin,
    ROUND((sales - previous_year_sales) / NULLIF(previous_year_sales, 0), 4) AS sales_growth,
    ROUND((profit - previous_year_profit) / NULLIF(previous_year_profit, 0), 4) AS profit_growth
FROM yearly_with_lag
ORDER BY order_year;


-- 3. Monthly Running Totals
WITH monthly_performance AS (
    SELECT
        order_year_month,
        SUM(sales) AS sales,
        SUM(profit) AS profit
    FROM nova_retail.fact_sales
    GROUP BY order_year_month
)
SELECT
    order_year_month,
    ROUND(sales, 2) AS sales,
    ROUND(profit, 2) AS profit,
    ROUND(SUM(sales) OVER (ORDER BY order_year_month), 2) AS running_sales,
    ROUND(SUM(profit) OVER (ORDER BY order_year_month), 2) AS running_profit
FROM monthly_performance
ORDER BY order_year_month;


-- 4. Category Performance
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
GROUP BY p.category
ORDER BY profit DESC;


-- 5. Sub-Category Performance with Ranking
SELECT
    p.category,
    p.sub_category,
    ROUND(SUM(f.sales), 2) AS sales,
    ROUND(SUM(f.profit), 2) AS profit,
    ROUND(SUM(f.profit) / NULLIF(SUM(f.sales), 0), 4) AS profit_margin,
    SUM(f.quantity) AS quantity,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(CASE WHEN f.profit < 0 THEN 1 ELSE 0 END) AS loss_making_rows,
    RANK() OVER (ORDER BY SUM(f.profit) DESC) AS profit_rank
FROM nova_retail.fact_sales f
JOIN nova_retail.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category, p.sub_category
ORDER BY profit ASC;


-- 6. Top Products by Profit
WITH product_performance AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.sub_category,
        SUM(f.sales) AS sales,
        SUM(f.profit) AS profit,
        SUM(f.profit) / NULLIF(SUM(f.sales), 0) AS profit_margin,
        COUNT(DISTINCT f.order_id) AS orders
    FROM nova_retail.fact_sales f
    JOIN nova_retail.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.product_id, p.product_name, p.category, p.sub_category
),
ranked_products AS (
    SELECT
        *,
        RANK() OVER (ORDER BY profit DESC) AS profit_rank,
        RANK() OVER (ORDER BY sales DESC) AS sales_rank
    FROM product_performance
)
SELECT *
FROM ranked_products
WHERE profit_rank <= 10
ORDER BY profit_rank;


-- 7. Loss-Making Products
WITH product_performance AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.sub_category,
        SUM(f.sales) AS sales,
        SUM(f.profit) AS profit,
        SUM(f.profit) / NULLIF(SUM(f.sales), 0) AS profit_margin,
        COUNT(DISTINCT f.order_id) AS orders
    FROM nova_retail.fact_sales f
    JOIN nova_retail.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.product_id, p.product_name, p.category, p.sub_category
)
SELECT *
FROM product_performance
ORDER BY profit ASC
LIMIT 20;


-- 8. High Sales but Low Margin Products
WITH product_performance AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.sub_category,
        SUM(f.sales) AS sales,
        SUM(f.profit) AS profit,
        SUM(f.profit) / NULLIF(SUM(f.sales), 0) AS profit_margin,
        COUNT(DISTINCT f.order_id) AS orders
    FROM nova_retail.fact_sales f
    JOIN nova_retail.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.product_id, p.product_name, p.category, p.sub_category
),
overall_margin AS (
    SELECT
        SUM(profit) / NULLIF(SUM(sales), 0) AS company_profit_margin
    FROM nova_retail.fact_sales
),
average_product_sales AS (
    SELECT
        AVG(sales) AS avg_product_sales
    FROM product_performance
)
SELECT
    pp.*
FROM product_performance pp
CROSS JOIN overall_margin om
CROSS JOIN average_product_sales aps
WHERE pp.sales > aps.avg_product_sales
  AND pp.profit_margin < om.company_profit_margin
ORDER BY pp.sales DESC
LIMIT 20;


-- 9. Customer Segment Performance
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
GROUP BY c.segment
ORDER BY profit DESC;


-- 10. Market Performance
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
GROUP BY g.market
ORDER BY profit DESC;


-- 11. Discount Impact
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
    ROUND(SUM(sales), 2) AS sales,
    ROUND(SUM(profit), 2) AS profit,
    ROUND(SUM(profit) / NULLIF(SUM(sales), 0), 4) AS profit_margin,
    COUNT(*) AS order_lines,
    COUNT(DISTINCT order_id) AS orders,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_making_rows,
    ROUND(SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)::NUMERIC / NULLIF(COUNT(*), 0), 4) AS loss_rate
FROM discount_analysis
GROUP BY discount_band, discount_band_order
ORDER BY discount_band_order;


-- 12. Shipping Performance
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
GROUP BY ship_mode
ORDER BY profit DESC;


-- 13. Pareto Analysis: Products that Generate Around 80% of Positive Profit
WITH product_profit AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.sub_category,
        SUM(f.profit) AS profit
    FROM nova_retail.fact_sales f
    JOIN nova_retail.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.product_id, p.product_name, p.category, p.sub_category
    HAVING SUM(f.profit) > 0
),
ranked_products AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY profit DESC) AS product_rank,
        COUNT(*) OVER () AS total_profitable_products,
        SUM(profit) OVER (ORDER BY profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
        SUM(profit) OVER () AS total_positive_profit
    FROM product_profit
)
SELECT
    product_id,
    product_name,
    category,
    sub_category,
    ROUND(profit, 2) AS profit,
    product_rank,
    total_profitable_products,
    ROUND(cumulative_profit, 2) AS cumulative_profit,
    ROUND(cumulative_profit / NULLIF(total_positive_profit, 0), 4) AS cumulative_profit_share,
    ROUND(product_rank::NUMERIC / total_profitable_products, 4) AS product_share
FROM ranked_products
WHERE cumulative_profit / NULLIF(total_positive_profit, 0) <= 0.80
ORDER BY product_rank;