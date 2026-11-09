-- Complete Tasks 6–10 after Tasks 1–5.
-- Run each change separately and save its query ID from the result/history.
-- Run this file only once per setup. Rerun 00-setup.sql to reset the lab.
USE ROLE SYSADMIN;
USE WAREHOUSE ICEBERG_QUERY_WH;
USE DATABASE ICEBERG_QUERY_LAB;
USE SCHEMA LAB;

-- Create a zero-copy Iceberg clone BEFORE changing ORDERS.
-- Cloning Iceberg tables with Snowflake storage is an open preview feature.
CREATE OR REPLACE ICEBERG TABLE ORDERS_BASELINE CLONE ORDERS;

-- Run this UPDATE alone. Copy its query ID as UPDATE_ID.
UPDATE ORDERS SET AMOUNT = 225.00 WHERE ORDER_ID = 103;

-- Run this DELETE alone. Copy its query ID as DELETE_ID.
DELETE FROM ORDERS WHERE ORDER_ID = 108;

-- Task 6. Query current ORDERS. Return ROW_COUNT and ALL_ORDER_AMOUNT.
-- Your SQL:


-- Task 7. Use Time Travel to show ORDER_ID 103 immediately before UPDATE_ID.
-- Then show ORDER_ID 108 immediately before DELETE_ID.
-- Hint: BEFORE (STATEMENT => '<query_id>') goes directly after the table name.
-- Your SQL:


-- Task 8. Restore ONLY ORDER_ID 108 from the table state before DELETE_ID.
-- Then check that it appears once and that ORDERS has 8 rows.
-- Hint: INSERT INTO ... SELECT ... FROM ORDERS BEFORE (...).
-- Your SQL:


-- Task 9. Compare ORDERS_BASELINE with current ORDERS for ORDER_ID 103.
-- Why does the clone still show the old amount?
-- Your SQL:


-- Task 10 (optional, open preview). List the Iceberg snapshots for ORDERS.
-- Pick the VERSION_ID created by the original INSERT in 00-setup.sql.
-- Query ORDERS at that version and check ORDER_ID 103 and 108.
-- Hint: INFORMATION_SCHEMA.GET_TABLE_VERSIONS and AT (VERSION => <snapshot_id>).
-- Your SQL:
