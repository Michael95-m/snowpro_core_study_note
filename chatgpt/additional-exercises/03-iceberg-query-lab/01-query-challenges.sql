-- Complete Tasks 1–5 before opening solutions.md.
-- Run 00-setup.sql first.
USE ROLE SYSADMIN;
USE WAREHOUSE ICEBERG_QUERY_WH;
USE DATABASE ICEBERG_QUERY_LAB;
USE SCHEMA LAB;

-- Task 1. Show only the Iceberg tables in ICEBERG_QUERY_LAB.LAB.
-- Find ORDERS in the output. What do catalog_name and external_volume_name say?
-- Your SQL:


-- Task 2. From the SHOW result, return just the table name, catalog name,
-- and external volume name as three columns. Run this immediately after Task 1.
-- Hint: TABLE(RESULT_SCAN(LAST_QUERY_ID())) and double-quoted output column names.
-- Your SQL:


-- Task 3. For COMPLETE orders only, return one row per region with:
-- REGION, ORDER_COUNT, TOTAL_AMOUNT. Order by TOTAL_AMOUNT descending.
-- Your SQL:


-- Task 4. Return customers with at least two orders, including cancelled or
-- refunded orders. Show CUSTOMER_ID and ORDER_COUNT, ordered by CUSTOMER_ID.
-- Your SQL:


-- Task 5. Return ORDER_ID, ORDER_DATE, and AMOUNT for APAC's COMPLETE orders
-- in February 2026. Use a date range, not a string pattern.
-- Your SQL:
