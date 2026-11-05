-- Objective 1.4. The basic path does not resize or add active clusters.
USE ROLE SYSADMIN;
USE WAREHOUSE D1_STUDY_WH;
USE DATABASE D1_STUDY;
USE SCHEMA LAB;
SHOW WAREHOUSES LIKE 'D1_STUDY%';
ALTER WAREHOUSE D1_STUDY_WH SET AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
SELECT REGION, SUM(AMOUNT) FROM ORDERS GROUP BY REGION ORDER BY REGION;
-- Expected: AMER 300, APAC 175, EMEA 275.

-- Paper calculation with an assumed rate, not a price quote for your account.
SELECT
  1.0 * (15.0 / 60) AS ONE_CLUSTER_15_MIN_CREDITS,
  1.0 * (15.0 / 60) * 3 AS THREE_CLUSTERS_15_MIN_CREDITS,
  1.0 * (60.0 / 3600) * 2 AS TWO_SHORT_RESUMES_MINIMUM_CREDITS;
-- Expected: 0.25, 0.75, approximately 0.033333.
-- Last case: two separate resumes, each query lasting under 60 seconds.

-- OPTIONAL configuration templates: execute separately with the right edition.
-- Scaling up adds resources per cluster and may increase the credit rate:
-- ALTER WAREHOUSE D1_STUDY_WH SET WAREHOUSE_SIZE = SMALL;
-- ALTER WAREHOUSE D1_STUDY_WH SET WAREHOUSE_SIZE = XSMALL;

-- Enterprise+: scale out for concurrency, not one query's memory requirement.
-- ALTER WAREHOUSE D1_STUDY_WH SET
--   MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 3 SCALING_POLICY = 'STANDARD';
-- Fixed capacity while running (maximized mode):
-- ALTER WAREHOUSE D1_STUDY_WH SET MIN_CLUSTER_COUNT = 3 MAX_CLUSTER_COUNT = 3;
-- Restore a single-cluster lab before resuming ordinary practice:
-- ALTER WAREHOUSE D1_STUDY_WH SET MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 1;

-- A Standard generation setting is separate from size, type, and cluster count.
-- Where Gen2 is supported: ALTER WAREHOUSE D1_STUDY_WH SET GENERATION = '2';
-- Do not run configuration templates to manufacture performance observations.
-- Explain: large spill -> inspect SQL/memory; overload queue -> concurrency.
