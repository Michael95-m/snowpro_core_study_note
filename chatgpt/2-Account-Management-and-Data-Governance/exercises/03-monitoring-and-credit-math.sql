-- Objective 2.3. Basic path: arithmetic, current session history, inventory.
USE ROLE SYSADMIN;
USE WAREHOUSE D2_STUDY_WH;
USE DATABASE D2_STUDY;
USE SCHEMA LAB;
ALTER SESSION SET QUERY_TAG = 'D2_COST_LAB';

-- Explicitly assumed rates; use your actual edition/generation/region rates.
SELECT 4.0 * (15.0 / 60) * 3 AS CREDITS;
-- Expected: 3 credits (4 credits/hour, 15 minutes, 3 active clusters).
SELECT 4.0 * (60.0 / 3600) * 2 AS TWO_SHORT_RESUMES_CREDITS;
-- Expected: approximately 0.133333 (each separate resume billed >= 60 seconds).
SELECT 2.0 * (30.0 / 60) AS SMALLER_WH_CREDITS,
       4.0 * (10.0 / 60) AS LARGER_WH_CREDITS;
-- Expected: 1 versus approximately 0.666667; faster can be cheaper.

-- Daily cloud-services billing illustration. Serverless credits are separate
-- and do not increase the warehouse-compute base for the 10% adjustment.
WITH EXAMPLES (SCENARIO, WH_CREDITS, CLOUD_CREDITS, OTHER_CREDITS) AS (
  SELECT * FROM VALUES (1,100,15,0),(2,100,8,0),(3,200,30,0),(4,100,25,200)
)
SELECT *, GREATEST(CLOUD_CREDITS - WH_CREDITS * 0.10, 0) AS BILLABLE_CLOUD,
  WH_CREDITS + GREATEST(CLOUD_CREDITS - WH_CREDITS * 0.10, 0)
    + OTHER_CREDITS AS TOTAL_CREDITS
FROM EXAMPLES ORDER BY SCENARIO;
-- Corresponding totals: 105, 100, 210, 315 for the four input scenarios.
-- Resource monitor usage includes supporting cloud services BEFORE adjustment.

SELECT QUERY_ID, QUERY_TAG, EXECUTION_STATUS,
  TOTAL_ELAPSED_TIME / 1000.0 AS ELAPSED_SECONDS,
  EXECUTION_TIME / 1000.0 AS EXECUTION_SECONDS,
  QUEUED_OVERLOAD_TIME / 1000.0 AS OVERLOAD_SECONDS,
  QUEUED_PROVISIONING_TIME / 1000.0 AS PROVISIONING_SECONDS
FROM TABLE(D2_STUDY.INFORMATION_SCHEMA.QUERY_HISTORY_BY_SESSION(RESULT_LIMIT => 100))
ORDER BY START_TIME DESC;
-- Observe your actual values; a small lab does not force queueing or spilling.
SHOW WAREHOUSES;
SHOW COMPUTE POOLS;
-- Visibility depends on privileges. A historical credit row does not prove a
-- resource is still running. SHOW gives current visible resource state.

-- OPTIONAL historical reporting. Requires access to SNOWFLAKE.ACCOUNT_USAGE;
-- history can lag, so an empty result immediately after practice is possible.
-- SELECT USAGE_DATE, SERVICE_TYPE, SUM(CREDITS_BILLED) AS BILLED_CREDITS
-- FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY
-- WHERE USAGE_DATE >= DATEADD('day',-7,CURRENT_DATE())
-- GROUP BY USAGE_DATE, SERVICE_TYPE ORDER BY USAGE_DATE, SERVICE_TYPE;
-- SELECT COMPUTE_POOL_NAME, SUM(CREDITS_USED) AS POOL_CREDITS
-- FROM SNOWFLAKE.ACCOUNT_USAGE.SNOWPARK_CONTAINER_SERVICES_HISTORY
-- WHERE START_TIME >= DATEADD('day',-7,CURRENT_TIMESTAMP())
-- GROUP BY COMPUTE_POOL_NAME;
ALTER SESSION UNSET QUERY_TAG;
