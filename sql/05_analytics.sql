-- ============================================================
-- 05_ANALYTICS.SQL
-- Reporting queries using joins, CTEs, aggregates and windows
-- ============================================================

USE DATABASE SALES_ANALYTICS_DB;

-- Monthly revenue
SELECT
  DATE_TRUNC('MONTH', order_date) AS sales_month,
  SUM(sales_amount) AS revenue,
  SUM(quantity) AS units_sold,
  COUNT(DISTINCT order_id) AS orders
FROM PRODUCTION.FACT_SALES
GROUP BY 1
ORDER BY 1;

-- Product performance
SELECT
  p.product_name,
  p.category,
  SUM(f.quantity) AS units_sold,
  SUM(f.sales_amount) AS revenue
FROM PRODUCTION.FACT_SALES f
JOIN PRODUCTION.DIM_PRODUCT p
  ON f.product_id = p.product_id
GROUP BY 1, 2
ORDER BY revenue DESC;

-- Customer revenue ranking
WITH customer_sales AS (
  SELECT
    customer_id,
    SUM(sales_amount) AS revenue
  FROM PRODUCTION.FACT_SALES
  GROUP BY customer_id
)
SELECT
  c.customer_name,
  c.city,
  c.state,
  cs.revenue,
  RANK() OVER (ORDER BY cs.revenue DESC) AS revenue_rank
FROM customer_sales cs
JOIN PRODUCTION.DIM_CUSTOMER c
  ON cs.customer_id = c.customer_id
ORDER BY revenue_rank;

-- Regional performance
SELECT
  region,
  COUNT(DISTINCT order_id) AS orders,
  SUM(sales_amount) AS revenue,
  ROUND(SUM(sales_amount) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_order_value
FROM PRODUCTION.FACT_SALES
GROUP BY region
ORDER BY revenue DESC;

-- Running monthly revenue
WITH monthly AS (
  SELECT
    DATE_TRUNC('MONTH', order_date) AS sales_month,
    SUM(sales_amount) AS revenue
  FROM PRODUCTION.FACT_SALES
  GROUP BY 1
)
SELECT
  sales_month,
  revenue,
  SUM(revenue) OVER (ORDER BY sales_month) AS cumulative_revenue
FROM monthly
ORDER BY sales_month;
