-- Objective 4.2. Basic path: explain plans and correctness-preserving rewrites.
USE ROLE SYSADMIN;
USE WAREHOUSE D4_STUDY_WH;
USE DATABASE D4_STUDY;
USE SCHEMA LAB;
ALTER SESSION SET USE_CACHED_RESULT = FALSE;

EXPLAIN USING TEXT
SELECT EVENT_ID, AMOUNT FROM PERF_EVENTS
WHERE EVENT_DATE >= '2026-01-10'::DATE AND EVENT_DATE < '2026-01-11'::DATE;
SELECT COUNT(*) AS MATCHING_ROWS FROM PERF_EVENTS
WHERE EVENT_DATE >= '2026-01-10'::DATE AND EVENT_DATE < '2026-01-11'::DATE;
-- Expected: 3334. Compare actual pruning in Query Profile, not SQL length.
SELECT COUNT(*) AS SAME_MATCHING_ROWS FROM PERF_EVENTS
WHERE TO_VARCHAR(EVENT_DATE,'YYYY-MM-DD') = '2026-01-10';
-- Same 3334. Optimizer behavior can vary; no guaranteed bad plan for the function.
SELECT PARSE_JSON(SYSTEM$CLUSTERING_INFORMATION(
  'D4_STUDY.LAB.PERF_EVENTS','(EVENT_DATE)'
)) AS CLUSTERING_INFO;
-- No key is defined: supply the expression to inspect natural organization.

-- UNION removes duplicates; UNION ALL preserves them. Choose by required result.
SELECT REGION FROM ORDERS WHERE CUSTOMER_ID = 10
UNION
SELECT REGION FROM ORDERS WHERE CUSTOMER_ID = 30;
-- Expected: 1 APAC row.
SELECT REGION FROM ORDERS WHERE CUSTOMER_ID = 10
UNION ALL
SELECT REGION FROM ORDERS WHERE CUSTOMER_ID = 30;
-- Expected: 3 APAC rows. These are different business results.

-- OPTIONAL: Four separate mini-labs below. Run 00-setup.sql first. Choose one
-- mini-lab at a time; remove the leading -- only from statements you intend
-- to run. QAS, Search Optimization, and materialized views need Enterprise+.
-- These features can incur maintenance or serverless credits. The small setup
-- data demonstrates syntax; it does not prove a performance benefit.

-- A. QAS (Enterprise+). Run a representative query first and save its query ID.
-- 1. Check that query's eligibility before changing the warehouse.
-- SELECT SYSTEM$ESTIMATE_QUERY_ACCELERATION('<query_id>');
-- 2. If eligible, enable QAS on this warehouse and rerun the same query.
-- ALTER WAREHOUSE D4_STUDY_WH SET ENABLE_QUERY_ACCELERATION = TRUE
--   QUERY_ACCELERATION_MAX_SCALE_FACTOR = 2;
-- 3. Compare query profile, runtime, and QAS credits. Then restore the prior
--    warehouse setting if you changed it for this experiment.
-- ALTER WAREHOUSE D4_STUDY_WH SET ENABLE_QUERY_ACCELERATION = FALSE;

-- B. Search Optimization (Enterprise+). Run statements 1-4 in order.
-- 1. Add the service to a selective equality lookup column. Build takes time.
-- ALTER TABLE PERF_EVENTS ADD SEARCH OPTIMIZATION ON EQUALITY(EVENT_ID);
-- 2. Check table status and wait for the initial build before measuring.
-- SHOW TABLES LIKE 'PERF_EVENTS' IN SCHEMA D4_STUDY.LAB;
-- 3. Run a lookup and inspect its Query Profile.
-- SELECT * FROM PERF_EVENTS WHERE EVENT_ID = 4242;
-- 4. Remove the service after this experiment.
-- ALTER TABLE PERF_EVENTS DROP SEARCH OPTIMIZATION;

-- C. Clustering. Use only after finding repeated, large-table date filters
--    with poor pruning. This small lab is not a useful cost/benefit test.
-- 1. Define the key, then check SHOW TABLES and query pruning over time.
-- ALTER TABLE PERF_EVENTS CLUSTER BY (EVENT_DATE);
-- 2. Optional: keep the key but stop automatic maintenance.
-- ALTER TABLE PERF_EVENTS SUSPEND RECLUSTER;
-- 3. When finished, remove the key. This is the cleanup action.
-- ALTER TABLE PERF_EVENTS DROP CLUSTERING KEY;

-- D. Materialized view (Enterprise+). Run statements 1-3 in order.
-- 1. Create a maintained result for repeated single-table aggregation.
-- CREATE MATERIALIZED VIEW REGIONAL_TOTAL_MV AS
--   SELECT REGION, SUM(AMOUNT) AS TOTAL FROM ORDERS GROUP BY REGION;
-- 2. Query the view.
-- SELECT * FROM REGIONAL_TOTAL_MV ORDER BY REGION;
-- Expected: AMER 300, APAC 175, EMEA 275; no measurable speedup is promised.
-- 3. Remove the view after this experiment.
-- DROP MATERIALIZED VIEW REGIONAL_TOTAL_MV;
ALTER SESSION UNSET USE_CACHED_RESULT;
