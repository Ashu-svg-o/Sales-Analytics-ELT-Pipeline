-- ============================================================
-- 07_TIME_TRAVEL_AND_CLONE.SQL
-- Time Travel + zero-copy cloning
-- ============================================================

USE DATABASE SALES_ANALYTICS_DB;

-- Zero-copy clone for safe testing.
CREATE OR REPLACE TABLE STAGING.FACT_SALES_TEST_CLONE
CLONE PRODUCTION.FACT_SALES;

-- Make an intentional test change on the clone.
UPDATE STAGING.FACT_SALES_TEST_CLONE
SET sales_amount = sales_amount + 1
WHERE order_item_id = 'OI001';

-- Production remains unchanged.
SELECT * FROM PRODUCTION.FACT_SALES WHERE order_item_id = 'OI001';
SELECT * FROM STAGING.FACT_SALES_TEST_CLONE WHERE order_item_id = 'OI001';

-- Time Travel: inspect an earlier version of the production table.
-- Run after making a controlled test change and adjust the timestamp.
SELECT *
FROM PRODUCTION.FACT_SALES
AT (OFFSET => -60*5);

-- Restore a table by creating a replacement from a historical snapshot.
CREATE OR REPLACE TABLE STAGING.FACT_SALES_RECOVERY AS
SELECT *
FROM PRODUCTION.FACT_SALES
AT (OFFSET => -60*5);

-- Clean up test objects when finished.
-- DROP TABLE STAGING.FACT_SALES_TEST_CLONE;
-- DROP TABLE STAGING.FACT_SALES_RECOVERY;
