-- ============================================================
-- 02_INGESTION.SQL
-- COPY INTO examples for CSV and JSON
-- ============================================================

USE WAREHOUSE SALES_ANALYTICS_WH;
USE DATABASE SALES_ANALYTICS_DB;

-- After uploading data/customers.csv, products.csv, orders.csv,
-- order_items.csv and customer_events.json to @RAW.SALES_STAGE:

COPY INTO RAW.RAW_CUSTOMERS
  (customer_id, customer_name, email, city, state, signup_date)
FROM @RAW.SALES_STAGE/customers.csv
FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FORMAT)
ON_ERROR = 'CONTINUE';

COPY INTO RAW.RAW_PRODUCTS
  (product_id, product_name, category, unit_price)
FROM @RAW.SALES_STAGE/products.csv
FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FORMAT)
ON_ERROR = 'CONTINUE';

COPY INTO RAW.RAW_ORDERS
  (order_id, customer_id, order_date, status, region)
FROM @RAW.SALES_STAGE/orders.csv
FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FORMAT)
ON_ERROR = 'CONTINUE';

COPY INTO RAW.RAW_ORDER_ITEMS
  (order_item_id, order_id, product_id, quantity, unit_price)
FROM @RAW.SALES_STAGE/order_items.csv
FILE_FORMAT = (FORMAT_NAME = RAW.CSV_FORMAT)
ON_ERROR = 'CONTINUE';

-- JSON is landed as VARIANT and can be flattened later.
COPY INTO RAW.RAW_CUSTOMER_EVENTS (event_data)
FROM @RAW.SALES_STAGE/customer_events.json
FILE_FORMAT = (FORMAT_NAME = RAW.JSON_FORMAT)
ON_ERROR = 'CONTINUE';

-- Basic ingestion validation
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM RAW.RAW_CUSTOMERS
UNION ALL
SELECT 'products', COUNT(*) FROM RAW.RAW_PRODUCTS
UNION ALL
SELECT 'orders', COUNT(*) FROM RAW.RAW_ORDERS
UNION ALL
SELECT 'order_items', COUNT(*) FROM RAW.RAW_ORDER_ITEMS
UNION ALL
SELECT 'customer_events', COUNT(*) FROM RAW.RAW_CUSTOMER_EVENTS;
