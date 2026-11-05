USE ROLE SYSADMIN;

-- Guard the SUSPEND command so the script also works after auto-suspension.
EXECUTE IMMEDIATE $$
DECLARE
  LAB_WH_STATE STRING;
BEGIN
  SHOW WAREHOUSES LIKE 'D5_STUDY_WH';
  SELECT MAX("state") INTO :LAB_WH_STATE
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
    WHERE "name" = 'D5_STUDY_WH';
  IF (LAB_WH_STATE = 'STARTED') THEN
    ALTER WAREHOUSE D5_STUDY_WH SUSPEND;
  END IF;
END;
$$;

SHOW WAREHOUSES LIKE 'D5_STUDY_WH';

-- Optional final deletion when the lab data is no longer needed.
-- Clean up any optional share or replication setup separately first.
-- DROP DATABASE IF EXISTS D5_STUDY;
-- DROP WAREHOUSE IF EXISTS D5_STUDY_WH;
