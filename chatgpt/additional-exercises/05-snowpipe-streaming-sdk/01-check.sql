-- Run after the Python producer exits. Select a warehouse in the worksheet
-- first; it is used for these SELECT queries, not for SDK ingestion.
USE ROLE SYSADMIN;
SELECT SEQ, EVENT_ID, AMOUNT, STATUS
FROM D3_STREAMING_LAB.LAB.EVENTS
ORDER BY SEQ;

SELECT COUNT(*) AS ROW_COUNT, COUNT(DISTINCT SEQ) AS DISTINCT_OFFSETS
FROM D3_STREAMING_LAB.LAB.EVENTS;
-- After --max-seq 2: 2 rows. After --max-seq 5: 5 rows.
-- Repeating the 5-row command should leave 5 rows because the script starts
-- after the Named Channel's latest committed offset.

SHOW PIPES LIKE 'EVENTS-STREAMING' IN SCHEMA D3_STREAMING_LAB.LAB;
-- The default pipe appears only after the SDK opens its channel.
