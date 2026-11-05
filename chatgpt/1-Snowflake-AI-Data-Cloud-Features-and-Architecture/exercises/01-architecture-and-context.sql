-- Objectives 1.1 and 1.2. Run 00-setup.sql first.
USE ROLE SYSADMIN;
USE DATABASE D1_STUDY;
USE SCHEMA LAB;
USE WAREHOUSE D1_STUDY_WH;
SELECT SUM(AMOUNT) AS TOTAL_AMOUNT FROM D1_STUDY.LAB.ORDERS;
-- Expected: 750.

CREATE WAREHOUSE IF NOT EXISTS D1_STUDY_BI_WH
  WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE INITIALLY_SUSPENDED = TRUE
  ENABLE_QUERY_ACCELERATION = FALSE;
USE WAREHOUSE D1_STUDY_BI_WH;
SELECT SUM(AMOUNT) AS TOTAL_AMOUNT FROM D1_STUDY.LAB.ORDERS;
-- Expected: 750, using different compute and the same persistent table.

-- Check state so this also works after idle auto-suspension.
EXECUTE IMMEDIATE $$
DECLARE
  LAB_WH_STATE STRING;
BEGIN
  SHOW WAREHOUSES LIKE 'D1_STUDY_WH';
  SELECT MAX("state") INTO :LAB_WH_STATE
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
  IF (LAB_WH_STATE = 'STARTED') THEN
    ALTER WAREHOUSE D1_STUDY_WH SUSPEND;
  END IF;
  SHOW WAREHOUSES LIKE 'D1_STUDY_BI_WH';
  SELECT MAX("state") INTO :LAB_WH_STATE
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
  IF (LAB_WH_STATE = 'STARTED') THEN
    ALTER WAREHOUSE D1_STUDY_BI_WH SUSPEND;
  END IF;
END;
$$;
SHOW TABLES LIKE 'ORDERS' IN SCHEMA D1_STUDY.LAB;
-- The table still exists while both lab warehouses are suspended.
-- SHOW is metadata inspection; do not use it as a warehouse benchmark.
USE WAREHOUSE D1_STUDY_WH;
SELECT COUNT(*) FROM D1_STUDY.LAB.ORDERS;
-- Expected: 6. AUTO_RESUME can restart D1_STUDY_WH; this costs credits.

CREATE SCHEMA IF NOT EXISTS D1_STUDY.OTHER_CONTEXT;
USE SCHEMA D1_STUDY.OTHER_CONTEXT;
SELECT CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_WAREHOUSE();
-- ORDERS without qualification now resolves in OTHER_CONTEXT, not LAB.
-- Intentional failure, run separately if desired:
-- SELECT * FROM ORDERS;
SELECT COUNT(*) FROM D1_STUDY.LAB.ORDERS;
-- Expected: 6. Qualification fixes name resolution, not missing privileges.
USE SCHEMA D1_STUDY.LAB;

SELECT CURRENT_ORGANIZATION_NAME(), CURRENT_ACCOUNT_NAME(), CURRENT_ACCOUNT();
-- Names and locator identify your real account. Do not publish that output.
-- Compare the same context query in Snowsight and the connected VS Code editor.
-- The client changes the interface, not Snowflake's authorization checks.
