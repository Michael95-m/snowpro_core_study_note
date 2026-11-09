-- Optional Domain 1 extension. Run 00-setup.sql first.
-- Observe an object parameter inherited from a schema, then overridden on a table.
-- This changes only an isolated D1_STUDY schema and table, not account/user settings.
USE ROLE SYSADMIN;
USE WAREHOUSE D1_STUDY_WH;

CREATE SCHEMA IF NOT EXISTS D1_STUDY.PARAM_DEMO;
ALTER SCHEMA D1_STUDY.PARAM_DEMO SET DATA_RETENTION_TIME_IN_DAYS = 0;

CREATE OR REPLACE TABLE D1_STUDY.PARAM_DEMO.SAMPLE (ID NUMBER);
INSERT INTO D1_STUDY.PARAM_DEMO.SAMPLE VALUES (1);

SHOW PARAMETERS LIKE 'DATA_RETENTION_TIME_IN_DAYS'
  IN TABLE D1_STUDY.PARAM_DEMO.SAMPLE;
-- Expect the table to inherit the schema setting (0), unless an account
-- minimum retention parameter imposes a higher effective floor.

ALTER TABLE D1_STUDY.PARAM_DEMO.SAMPLE
  SET DATA_RETENTION_TIME_IN_DAYS = 1;
SHOW PARAMETERS LIKE 'DATA_RETENTION_TIME_IN_DAYS'
  IN TABLE D1_STUDY.PARAM_DEMO.SAMPLE;
-- The explicit table setting wins over the schema's 0-day setting.

ALTER TABLE D1_STUDY.PARAM_DEMO.SAMPLE
  UNSET DATA_RETENTION_TIME_IN_DAYS;
SHOW PARAMETERS LIKE 'DATA_RETENTION_TIME_IN_DAYS'
  IN TABLE D1_STUDY.PARAM_DEMO.SAMPLE;
-- Removing the table override returns to the schema setting.

-- Check the schema's value and level without changing your account defaults.
SHOW PARAMETERS LIKE 'DATA_RETENTION_TIME_IN_DAYS'
  IN SCHEMA D1_STUDY.PARAM_DEMO;

-- Optional removal of only this extension's schema and table:
-- DROP SCHEMA D1_STUDY.PARAM_DEMO;
