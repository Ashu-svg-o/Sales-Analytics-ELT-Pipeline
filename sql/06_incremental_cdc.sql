-- ============================================================
-- 06_INCREMENTAL_CDC.SQL
-- Streams + Tasks + MERGE
-- ============================================================

USE DATABASE SALES_ANALYTICS_DB;

-- Source table used to demonstrate incremental change capture.
CREATE OR REPLACE TABLE STAGING.CUSTOMER_SOURCE AS
SELECT * FROM STAGING.STG_CUSTOMERS;

CREATE OR REPLACE TABLE STAGING.CUSTOMER_TARGET AS
SELECT * FROM STAGING.STG_CUSTOMERS;

CREATE OR REPLACE STREAM STAGING.CUSTOMER_STREAM
  ON TABLE STAGING.CUSTOMER_SOURCE
  APPEND_ONLY = FALSE;

-- Example source changes.
UPDATE STAGING.CUSTOMER_SOURCE
SET city = 'Pune'
WHERE customer_id = 'C001';

INSERT INTO STAGING.CUSTOMER_SOURCE
(customer_id, customer_name, email, city, state, signup_date)
VALUES
('C009', 'Neha Mehta', 'neha@example.com', 'Bhopal', 'Madhya Pradesh', '2025-07-25');

-- Inspect captured INSERT/UPDATE/DELETE records.
SELECT * FROM STAGING.CUSTOMER_STREAM;

-- MERGE stream changes into the target.
MERGE INTO STAGING.CUSTOMER_TARGET t
USING (
  SELECT
    customer_id,
    customer_name,
    email,
    city,
    state,
    signup_date,
    METADATA$ACTION AS change_action,
    METADATA$ISUPDATE AS is_update
  FROM STAGING.CUSTOMER_STREAM
  WHERE METADATA$ACTION = 'INSERT'
) s
ON t.customer_id = s.customer_id
WHEN MATCHED THEN UPDATE SET
  t.customer_name = s.customer_name,
  t.email = s.email,
  t.city = s.city,
  t.state = s.state,
  t.signup_date = s.signup_date
WHEN NOT MATCHED THEN INSERT
  (customer_id, customer_name, email, city, state, signup_date)
VALUES
  (s.customer_id, s.customer_name, s.email, s.city, s.state, s.signup_date);

-- Scheduled task example. Enable after reviewing your warehouse and schedule.
CREATE OR REPLACE TASK STAGING.PROCESS_CUSTOMER_STREAM_TASK
  WAREHOUSE = SALES_ANALYTICS_WH
  SCHEDULE = 'USING CRON 0 * * * * UTC'
AS
  MERGE INTO STAGING.CUSTOMER_TARGET t
  USING (
    SELECT
      customer_id, customer_name, email, city, state, signup_date
    FROM STAGING.CUSTOMER_STREAM
    WHERE METADATA$ACTION = 'INSERT'
  ) s
  ON t.customer_id = s.customer_id
  WHEN MATCHED THEN UPDATE SET
    t.customer_name = s.customer_name,
    t.email = s.email,
    t.city = s.city,
    t.state = s.state,
    t.signup_date = s.signup_date
  WHEN NOT MATCHED THEN INSERT
    (customer_id, customer_name, email, city, state, signup_date)
  VALUES
    (s.customer_id, s.customer_name, s.email, s.city, s.state, s.signup_date);

-- ALTER TASK STAGING.PROCESS_CUSTOMER_STREAM_TASK RESUME;
