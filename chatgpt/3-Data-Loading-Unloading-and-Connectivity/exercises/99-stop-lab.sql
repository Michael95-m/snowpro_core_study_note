-- Run after whichever exercises you completed.
-- Stops lab scheduling and warehouse compute; preserves tables/files for review.
-- Inspect task history if you submitted a task run: suspending a task
-- prevents future automatic runs but does not cancel an already-running run.

USE ROLE SYSADMIN;

ALTER TASK IF EXISTS D3_STUDY.LAB.D3_PROCESS_NEW_ORDERS SUSPEND;
ALTER TASK IF EXISTS D3_STUDY.LAB.D3_SERVERLESS_AUDIT SUSPEND;
ALTER DYNAMIC TABLE IF EXISTS D3_STUDY.LAB.D3_REGION_TOTALS SUSPEND;
-- If it already auto-suspended, an "already suspended" response also means
-- the intended stopped state has been reached.
ALTER WAREHOUSE D3_STUDY_WH SUSPEND;

SHOW WAREHOUSES LIKE 'D3_STUDY_WH';
SHOW TASKS IN SCHEMA D3_STUDY.LAB;
SHOW DYNAMIC TABLES IN SCHEMA D3_STUDY.LAB;

-- If you enabled any OPTIONAL cloud Snowpipe or Openflow examples from the
-- note, manage those services separately. Suspending this warehouse does not
-- stop independent serverless or compute-pool workloads.
--
-- Optional permanent cleanup, only after you no longer want these lab objects:
-- DROP DATABASE D3_STUDY;
-- DROP WAREHOUSE D3_STUDY_WH;
-- Dropping the database also removes files from its named internal stage.
-- Account-level storage/API integrations, if you created any, are separate.
