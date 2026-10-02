-- ============================================================
-- 03_TRANSFORM.SQL
-- Raw -> Staging -> Production star schema
-- ============================================================

USE DATABASE SALES_ANALYTICS_DB;

CREATE OR REPLACE TABLE STAGING.STG_CUSTOMERS AS
SELECT
  TRIM(customer_id) AS customer_id,
  INITCAP(TRIM(customer_name)) AS customer_name,
  LOWER(TRIM(email)) AS email,
  INITCAP(TRIM(city)) AS city,
  INITCAP(TRIM(state)) AS state,
  signup_date
FROM RAW.RAW_CUSTOMERS
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY loaded_at DESC) = 1;

CREATE OR REPLACE TABLE STAGING.STG_PRODUCTS AS
SELECT
  TRIM(product_id) AS product_id,
  TRIM(product_name) AS product_name,
  INITCAP(TRIM(category)) AS category,
  unit_price
FROM RAW.RAW_PRODUCTS
QUALIFY ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY loaded_at DESC) = 1;

CREATE OR REPLACE TABLE STAGING.STG_ORDERS AS
SELECT
  TRIM(order_id) AS order_id,
  TRIM(customer_id) AS customer_id,
  order_date,
  UPPER(TRIM(status)) AS status,
  INITCAP(TRIM(region)) AS region
FROM RAW.RAW_ORDERS
QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY loaded_at DESC) = 1;

CREATE OR REPLACE TABLE STAGING.STG_ORDER_ITEMS AS
SELECT
  TRIM(order_item_id) AS order_item_id,
  TRIM(order_id) AS order_id,
  TRIM(product_id) AS product_id,
  quantity,
  unit_price,
  quantity * unit_price AS line_amount
FROM RAW.RAW_ORDER_ITEMS
QUALIFY ROW_NUMBER() OVER (PARTITION BY order_item_id ORDER BY loaded_at DESC) = 1;

-- Flatten nested JSON attributes.
CREATE OR REPLACE VIEW STAGING.VW_CUSTOMER_EVENTS AS
SELECT
  event_data:event_id::STRING AS event_id,
  event_data:customer_id::STRING AS customer_id,
  event_data:event_type::STRING AS event_type,
  event_data:event_ts::TIMESTAMP_NTZ AS event_ts,
  event_data:device.type::STRING AS device_type,
  event_data:device.os::STRING AS device_os,
  tag.value::STRING AS tag
FROM RAW.RAW_CUSTOMER_EVENTS,
LATERAL FLATTEN(INPUT => event_data:tags) tag;

-- Dimension tables
CREATE OR REPLACE TABLE PRODUCTION.DIM_CUSTOMER AS
SELECT
  customer_id,
  customer_name,
  email,
  city,
  state,
  signup_date
FROM STAGING.STG_CUSTOMERS;

CREATE OR REPLACE TABLE PRODUCTION.DIM_PRODUCT AS
SELECT
  product_id,
  product_name,
  category,
  unit_price
FROM STAGING.STG_PRODUCTS;

CREATE OR REPLACE TABLE PRODUCTION.DIM_DATE AS
WITH dates AS (
  SELECT DATEADD(
    DAY,
    SEQ4(),
    '2025-01-01'::DATE
  ) AS date_day
  FROM TABLE(GENERATOR(ROWCOUNT => 365))
)
SELECT
  date_day,
  YEAR(date_day) AS year,
  MONTH(date_day) AS month,
  MONTHNAME(date_day) AS month_name,
  QUARTER(date_day) AS quarter,
  DAY(date_day) AS day_of_month,
  DAYOFWEEK(date_day) AS day_of_week
FROM dates;

-- Fact table
CREATE OR REPLACE TABLE PRODUCTION.FACT_SALES AS
SELECT
  o.order_id,
  oi.order_item_id,
  o.order_date,
  o.customer_id,
  oi.product_id,
  o.region,
  o.status,
  oi.quantity,
  oi.unit_price,
  oi.line_amount AS sales_amount
FROM STAGING.STG_ORDERS o
JOIN STAGING.STG_ORDER_ITEMS oi
  ON o.order_id = oi.order_id
WHERE o.status <> 'CANCELLED';

-- Analytical view
CREATE OR REPLACE VIEW PRODUCTION.VW_SALES_DETAIL AS
SELECT
  f.order_id,
  f.order_date,
  c.customer_name,
  c.city,
  c.state,
  p.product_name,
  p.category,
  f.region,
  f.quantity,
  f.sales_amount
FROM PRODUCTION.FACT_SALES f
JOIN PRODUCTION.DIM_CUSTOMER c
  ON f.customer_id = c.customer_id
JOIN PRODUCTION.DIM_PRODUCT p
  ON f.product_id = p.product_id;
