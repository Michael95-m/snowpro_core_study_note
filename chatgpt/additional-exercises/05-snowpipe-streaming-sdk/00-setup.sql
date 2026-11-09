-- Optional live Snowpipe Streaming lab. Run only when you are ready for
-- serverless ingestion charges and have set up key-pair authentication.
-- This creates a separate lab database and does not change any existing lab.
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS D3_STREAMING_LAB;
CREATE SCHEMA IF NOT EXISTS D3_STREAMING_LAB.LAB;

CREATE TABLE IF NOT EXISTS D3_STREAMING_LAB.LAB.EVENTS (
  SEQ NUMBER,
  EVENT_ID STRING,
  AMOUNT NUMBER(10, 2),
  STATUS STRING
);

-- The Python SDK's from_table() mode uses the system-managed default pipe.
-- It appears on demand as EVENTS-STREAMING after the channel is opened.
-- No stage, uploaded file, or user-managed warehouse is used for ingestion.
