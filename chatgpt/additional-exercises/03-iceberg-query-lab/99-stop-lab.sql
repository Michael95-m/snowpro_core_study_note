-- Run when finished to stop warehouse compute charges.
USE ROLE SYSADMIN;
ALTER WAREHOUSE ICEBERG_QUERY_WH SUSPEND;

-- Optional cleanup: remove only the objects created for this lab.
-- Uncomment when you no longer need the table or its Time Travel history.
-- DROP DATABASE IF EXISTS ICEBERG_QUERY_LAB;
-- DROP WAREHOUSE IF EXISTS ICEBERG_QUERY_WH;
