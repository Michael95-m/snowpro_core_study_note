-- Objective 4.3. Run with a fresh lab session after setup.
USE ROLE SYSADMIN;
USE WAREHOUSE D4_STUDY_WH;
USE DATABASE D4_STUDY;
USE SCHEMA LAB;
ALTER SESSION SET QUERY_TAG = 'D4_CACHE_LAB';

-- A. Disable persisted result reuse; local warehouse caching can still occur.
ALTER SESSION SET USE_CACHED_RESULT = FALSE;
SELECT EVENT_DATE, SUM(AMOUNT) AS TOTAL FROM PERF_EVENTS
GROUP BY EVENT_DATE ORDER BY EVENT_DATE;
SET D4_FIRST_RUN = LAST_QUERY_ID();
SELECT EVENT_DATE, SUM(AMOUNT) AS TOTAL FROM PERF_EVENTS
GROUP BY EVENT_DATE ORDER BY EVENT_DATE;
SET D4_SECOND_RUN = LAST_QUERY_ID();
-- Both execute. Compare scan/cache metrics; do not promise run 2 is faster.

-- B. Enable final-result reuse and repeat exactly the same deterministic SELECT.
-- Use a different alias to separate this pair from the earlier queries.
ALTER SESSION SET USE_CACHED_RESULT = TRUE;
SELECT EVENT_DATE, SUM(AMOUNT) AS SAVED_TOTAL FROM PERF_EVENTS
GROUP BY EVENT_DATE ORDER BY EVENT_DATE;
SET D4_RESULT_RUN_1 = LAST_QUERY_ID();
SELECT EVENT_DATE, SUM(AMOUNT) AS SAVED_TOTAL FROM PERF_EVENTS
GROUP BY EVENT_DATE ORDER BY EVENT_DATE;
SET D4_RESULT_RUN_2 = LAST_QUERY_ID();
-- Data/privileges/settings must allow reuse; eligible does not guarantee a hit.
-- Check the actual SELECT/query IDs when the client submits background SQL.

SELECT QUERY_ID, QUERY_TEXT, EXECUTION_TIME, BYTES_SCANNED
FROM TABLE(D4_STUDY.INFORMATION_SCHEMA.QUERY_HISTORY_BY_SESSION(RESULT_LIMIT => 100))
WHERE QUERY_ID IN ($D4_FIRST_RUN,$D4_SECOND_RUN,$D4_RESULT_RUN_1,$D4_RESULT_RUN_2)
ORDER BY START_TIME;
-- Open Query Profile for those query IDs to inspect scan partitions and cache percentage.
-- The local-cache percentage describes the data read by a warehouse scan.
-- A metadata-only query can also scan zero bytes, so that alone is not proof.

-- OPTIONAL cold-warehouse experiment (another resume has minimum billing):
-- If it is STARTED: ALTER WAREHOUSE D4_STUDY_WH SUSPEND;
-- ALTER SESSION SET USE_CACHED_RESULT = FALSE;
-- Rerun the SELECT, inspect its profile, then compare a second warm run.
-- Suspension clears local table cache, not persisted query results.
ALTER SESSION UNSET QUERY_TAG;
ALTER SESSION UNSET USE_CACHED_RESULT;
UNSET (D4_FIRST_RUN,D4_SECOND_RUN,D4_RESULT_RUN_1,D4_RESULT_RUN_2);
