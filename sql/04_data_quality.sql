-- ============================================================
-- 04_DATA_QUALITY.SQL
-- NULL checks, duplicate checks and record-count validation
-- ============================================================

USE DATABASE SALES_ANALYTICS_DB;

-- NULL checks
SELECT 'RAW_CUSTOMERS.customer_id' AS check_name, COUNT(*) AS failures
FROM RAW.RAW_CUSTOMERS WHERE customer_id IS NULL
UNION ALL
SELECT 'RAW_ORDERS.order_id', COUNT(*) FROM RAW.RAW_ORDERS WHERE order_id IS NULL
UNION ALL
SELECT 'RAW_ORDER_ITEMS.product_id', COUNT(*) FROM RAW.RAW_ORDER_ITEMS WHERE product_id IS NULL
UNION ALL
SELECT 'RAW_ORDER_ITEMS.quantity', COUNT(*) FROM RAW.RAW_ORDER_ITEMS WHERE quantity IS NULL;

-- Duplicate checks
SELECT customer_id, COUNT(*) AS duplicate_count
FROM RAW.RAW_CUSTOMERS
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*) AS duplicate_count
FROM RAW.RAW_ORDERS
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT order_item_id, COUNT(*) AS duplicate_count
FROM RAW.RAW_ORDER_ITEMS
GROUP BY order_item_id
HAVING COUNT(*) > 1;

-- Record-count validation
SELECT
  (SELECT COUNT(*) FROM RAW.RAW_ORDERS) AS raw_orders,
  (SELECT COUNT(*) FROM STAGING.STG_ORDERS) AS staged_orders;

-- Reusable data-quality stored procedure.
CREATE OR REPLACE PROCEDURE PRODUCTION.RUN_DATA_QUALITY_CHECKS()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
  null_failures NUMBER;
  duplicate_failures NUMBER;
  result STRING;
BEGIN
  SELECT
    (SELECT COUNT(*) FROM RAW.RAW_ORDERS WHERE order_id IS NULL)
    +
    (SELECT COUNT(*) FROM RAW.RAW_ORDER_ITEMS WHERE product_id IS NULL)
  INTO :null_failures;

  SELECT
    (SELECT COUNT(*) FROM (
      SELECT order_id FROM RAW.RAW_ORDERS GROUP BY order_id HAVING COUNT(*) > 1
    ))
    +
    (SELECT COUNT(*) FROM (
      SELECT order_item_id FROM RAW.RAW_ORDER_ITEMS GROUP BY order_item_id HAVING COUNT(*) > 1
    ))
  INTO :duplicate_failures;

  result := 'NULL failures=' || null_failures ||
            ', duplicate groups=' || duplicate_failures;

  RETURN result;
END;
$$;

CALL PRODUCTION.RUN_DATA_QUALITY_CHECKS();
