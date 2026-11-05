-- Objective 4.4 file access. Creates a real tiny CSV, not a pretend PDF/image.
-- URL/file inventory concepts also apply to unstructured files uploaded later.
USE ROLE SYSADMIN;
USE WAREHOUSE D4_STUDY_WH;
USE DATABASE D4_STUDY;
USE SCHEMA LAB;
COPY INTO @LAB_FILES/samples/orders.csv
FROM (SELECT ORDER_ID, AMOUNT FROM ORDERS ORDER BY ORDER_ID)
FILE_FORMAT = (TYPE = CSV COMPRESSION = NONE)
HEADER = TRUE SINGLE = TRUE OVERWRITE = TRUE;
ALTER STAGE LAB_FILES REFRESH;
SELECT RELATIVE_PATH, SIZE, LAST_MODIFIED, FILE_URL
FROM DIRECTORY(@LAB_FILES)
WHERE RELATIVE_PATH = 'samples/orders.csv';
-- Expected: one file metadata row, not the six order rows or parsed content.
SELECT BUILD_SCOPED_FILE_URL(@LAB_FILES,'samples/orders.csv') AS SCOPED_URL;
SELECT BUILD_STAGE_FILE_URL(@LAB_FILES,'samples/orders.csv') AS STAGE_URL;
-- Optional bearer URL, short lifetime for this exercise. Keep generated tokens
-- private and do not paste the result into public notes/screenshots.
-- SELECT GET_PRESIGNED_URL(@LAB_FILES,'samples/orders.csv',60) AS PRESIGNED_URL;
-- Internal stage was created with SNOWFLAKE_SSE for readable URL downloads.
-- FILE_URL/BUILD_STAGE_FILE_URL are not authorization bypasses.
-- These statements do not extract text from a PDF or analyze an image.
-- Domain 3 covers uploading/downloading actual files and stage permissions.
