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

-- OPTIONAL feature templates; QAS, Search Optimization, and MVs need Enterprise+.
-- Clustering is available across editions. Maintenance can cost credits even
-- after a query finishes. These are commented; the tiny lab proves syntax only.
-- QAS (Enterprise+): eligible large scans, not bad joins or overloaded query queues.
-- ALTER WAREHOUSE D4_STUDY_WH SET ENABLE_QUERY_ACCELERATION = TRUE
--   QUERY_ACCELERATION_MAX_SCALE_FACTOR = 2;
-- Inspect an actual eligible query with SYSTEM$ESTIMATE_QUERY_ACCELERATION.
-- ALTER WAREHOUSE D4_STUDY_WH SET ENABLE_QUERY_ACCELERATION = FALSE;

-- Search optimization (Enterprise+): a selective lookup; initial build takes time.
-- ALTER TABLE PERF_EVENTS ADD SEARCH OPTIMIZATION ON EQUALITY(EVENT_ID);
-- SHOW TABLES LIKE 'PERF_EVENTS' IN SCHEMA D4_STUDY.LAB;
-- SELECT * FROM PERF_EVENTS WHERE EVENT_ID = 4242;
-- ALTER TABLE PERF_EVENTS DROP SEARCH OPTIMIZATION;

-- Clustering: only enable after justifying repeated large-table access patterns.
-- ALTER TABLE PERF_EVENTS CLUSTER BY (EVENT_DATE);
-- ALTER TABLE PERF_EVENTS SUSPEND RECLUSTER;
-- ALTER TABLE PERF_EVENTS DROP CLUSTERING KEY;

-- Materialized view (Enterprise+): supported repeated single-base-table aggregation.
-- CREATE MATERIALIZED VIEW REGIONAL_TOTAL_MV AS
--   SELECT REGION, SUM(AMOUNT) AS TOTAL FROM ORDERS GROUP BY REGION;
-- SELECT * FROM REGIONAL_TOTAL_MV ORDER BY REGION;
-- Expected: AMER 300, APAC 175, EMEA 275; no measurable speedup is promised.
-- DROP MATERIALIZED VIEW REGIONAL_TOTAL_MV;
ALTER SESSION UNSET USE_CACHED_RESULT;
