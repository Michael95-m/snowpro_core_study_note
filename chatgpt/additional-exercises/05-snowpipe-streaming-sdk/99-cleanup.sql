-- Run only when you have finished checking the rows and channel behavior.
-- This removes only the dedicated D3_STREAMING_LAB database.
USE ROLE SYSADMIN;
DROP DATABASE IF EXISTS D3_STREAMING_LAB;
