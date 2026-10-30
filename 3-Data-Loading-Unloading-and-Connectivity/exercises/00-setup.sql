-- Domain 3 lab setup. Run this first, using a role authorized to create
-- a warehouse and a database. SYSADMIN is used for these study objects.
-- These scripts are examples to run yourself; they have not run in your account.
-- Use D3_STUDY only for this lab: later scripts replace tables inside it.

USE ROLE SYSADMIN;

CREATE WAREHOUSE IF NOT EXISTS D3_STUDY_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

CREATE TRANSIENT DATABASE IF NOT EXISTS D3_STUDY;
CREATE SCHEMA IF NOT EXISTS D3_STUDY.LAB;

USE DATABASE D3_STUDY;
USE SCHEMA LAB;
USE WAREHOUSE D3_STUDY_WH;

-- SSE is chosen for the optional pre-signed URL exercise.
-- An internal stage normally defaults to SNOWFLAKE_FULL encryption.
CREATE STAGE IF NOT EXISTS D3_FILES
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
  DIRECTORY = (ENABLE = TRUE);

CREATE OR REPLACE FILE FORMAT D3_CSV_LOAD
  TYPE = CSV
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  EMPTY_FIELD_AS_NULL = TRUE
  NULL_IF = ('NULL', '\\N');

CREATE OR REPLACE FILE FORMAT D3_JSON_LOAD
  TYPE = JSON
  STRIP_OUTER_ARRAY = TRUE;

-- This separate format reads column names from a CSV header.
-- Do not combine PARSE_HEADER = TRUE with SKIP_HEADER.
CREATE OR REPLACE FILE FORMAT D3_CSV_BY_NAME
  TYPE = CSV
  PARSE_HEADER = TRUE
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

SELECT
  CURRENT_ROLE(),
  CURRENT_WAREHOUSE(),
  CURRENT_DATABASE(),
  CURRENT_SCHEMA();

-- Task lab only: an authorized administrator must grant EXECUTE TASK
-- to the role that owns the task. These optional grants are not executed here.
-- USE ROLE ACCOUNTADMIN;
-- GRANT EXECUTE TASK ON ACCOUNT TO ROLE SYSADMIN;
-- GRANT EXECUTE MANAGED TASK ON ACCOUNT TO ROLE SYSADMIN;
-- USE ROLE SYSADMIN;
-- EXECUTE MANAGED TASK is needed only for the optional serverless task.
-- A production setup should grant these privileges to a dedicated task role.
