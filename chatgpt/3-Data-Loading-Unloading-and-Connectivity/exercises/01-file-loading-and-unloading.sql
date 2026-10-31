-- Prerequisite: run 00-setup.sql.
-- Run the numbered sections in order. No local upload or cloud bucket is needed.
-- COPY INTO <location> generates the input files, using tiny SQL sample tables.

USE ROLE SYSADMIN;
USE WAREHOUSE D3_STUDY_WH;
USE DATABASE D3_STUDY;
USE SCHEMA LAB;

-- 1. Make source rows as text. One amount is intentionally invalid.
CREATE OR REPLACE TABLE D3_FILE_SOURCE (
  ORDER_ID STRING,
  CUSTOMER_NAME STRING,
  REGION STRING,
  AMOUNT STRING,
  ORDER_DATE STRING
);

INSERT INTO D3_FILE_SOURCE VALUES
  ('1', 'Aye',  'APAC', '120.00',       '2026-01-01'),
  ('2', 'Min',  'APAC', '80.00',        '2026-01-01'),
  ('3', 'Lin',  'EMEA', '200.00',       '2026-01-01'),
  ('4', 'Kay',  'APAC', '50.00',        '2026-01-02'),
  ('5', 'Nora', 'EMEA', 'not_a_number', '2026-01-02'),
  ('6', 'Leo',  'AMER', '70.00',        '2026-01-02');

COPY INTO @D3_FILES/input/good/orders_good.csv
  FROM (
    SELECT *
    FROM D3_FILE_SOURCE
    WHERE ORDER_ID IN ('1', '2', '3')
    ORDER BY ORDER_ID
  )
  FILE_FORMAT = (
    TYPE = CSV
    COMPRESSION = NONE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  )
  HEADER = TRUE
  SINGLE = TRUE
  OVERWRITE = TRUE;

COPY INTO @D3_FILES/input/bad/orders_bad.csv
  FROM (
    SELECT *
    FROM D3_FILE_SOURCE
    WHERE ORDER_ID IN ('4', '5', '6')
    ORDER BY ORDER_ID
  )
  FILE_FORMAT = (
    TYPE = CSV
    COMPRESSION = NONE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  )
  HEADER = TRUE
  SINGLE = TRUE
  OVERWRITE = TRUE;

-- 2. Inspect files before loading. The stage contains files, not table rows.
LIST @D3_FILES/input/;

SELECT
  METADATA$FILENAME AS FILE_NAME,
  METADATA$FILE_ROW_NUMBER AS FILE_ROW,
  f.$1 AS ORDER_ID,
  f.$4 AS AMOUNT_TEXT
FROM @D3_FILES/input/good/
  (FILE_FORMAT => 'D3_CSV_LOAD') f
ORDER BY FILE_ROW;
-- Expected: three data rows; the CSV header is skipped.

-- 3. Validate without inserting any rows.
CREATE OR REPLACE TABLE D3_ORDERS (
  ORDER_ID NUMBER,
  CUSTOMER_NAME STRING,
  REGION STRING,
  AMOUNT NUMBER(12, 2),
  ORDER_DATE DATE
);

COPY INTO D3_ORDERS
  FROM @D3_FILES/input/good/
  FILE_FORMAT = (FORMAT_NAME = 'D3_CSV_LOAD')
  VALIDATION_MODE = RETURN_ERRORS;

SELECT COUNT(*) AS ROWS_AFTER_VALIDATION FROM D3_ORDERS;
-- Expected: 0.

-- 4. Load the good file, then repeat the same COPY.
COPY INTO D3_ORDERS
  FROM @D3_FILES/input/good/
  FILES = ('orders_good.csv')
  FILE_FORMAT = (FORMAT_NAME = 'D3_CSV_LOAD');

COPY INTO D3_ORDERS
  FROM @D3_FILES/input/good/
  FILES = ('orders_good.csv')
  FILE_FORMAT = (FORMAT_NAME = 'D3_CSV_LOAD');

SELECT COUNT(*) AS GOOD_ROWS FROM D3_ORDERS;
-- Expected: 3, not 6. The second COPY skips the already loaded file.
-- Do not add FORCE = TRUE unless you intentionally want to reload it.

-- 5. Find the bad amount, then keep valid rows from that file.
CREATE OR REPLACE TABLE D3_PARTIAL_ORDERS LIKE D3_ORDERS;

COPY INTO D3_PARTIAL_ORDERS
  FROM @D3_FILES/input/bad/
  FILE_FORMAT = (FORMAT_NAME = 'D3_CSV_LOAD')
  VALIDATION_MODE = RETURN_ERRORS;
-- Expected: a numeric-conversion error for not_a_number; no rows loaded.

COPY INTO D3_PARTIAL_ORDERS
  FROM @D3_FILES/input/bad/
  FILE_FORMAT = (FORMAT_NAME = 'D3_CSV_LOAD')
  ON_ERROR = CONTINUE;

-- Capture the COPY query ID immediately, before running another query.
SET d3_partial_copy_id = LAST_QUERY_ID();

SELECT *
FROM TABLE(VALIDATE(
  D3_PARTIAL_ORDERS,
  JOB_ID => $d3_partial_copy_id
));

SELECT ORDER_ID, AMOUNT
FROM D3_PARTIAL_ORDERS
ORDER BY ORDER_ID;
-- Expected: orders 4 and 6 only.

-- 6. Contrast file-level rejection with row-level rejection.
CREATE OR REPLACE TABLE D3_SKIP_FILE_ORDERS LIKE D3_ORDERS;

COPY INTO D3_SKIP_FILE_ORDERS
  FROM @D3_FILES/input/bad/
  FILE_FORMAT = (FORMAT_NAME = 'D3_CSV_LOAD')
  ON_ERROR = SKIP_FILE;

SELECT COUNT(*) AS ROWS_FROM_REJECTED_FILE FROM D3_SKIP_FILE_ORDERS;
-- Expected: 0, because the whole bad file was skipped.

-- 7. Transform at load time. TRY_TO_DECIMAL deliberately keeps the bad
-- amount as SQL NULL instead of rejecting its row.
CREATE OR REPLACE TABLE D3_CLEAN_ORDERS (
  ORDER_ID NUMBER,
  CUSTOMER_NAME STRING,
  REGION STRING,
  AMOUNT NUMBER(12, 2),
  ORDER_DATE DATE,
  SOURCE_FILE STRING
);

COPY INTO D3_CLEAN_ORDERS
  FROM (
    SELECT
      f.$1::NUMBER,
      TRIM(f.$2),
      UPPER(f.$3),
      TRY_TO_DECIMAL(f.$4, 12, 2),
      f.$5::DATE,
      METADATA$FILENAME
    FROM @D3_FILES/input/bad/ f
  )
  FILE_FORMAT = (FORMAT_NAME = 'D3_CSV_LOAD');

SELECT ORDER_ID, AMOUNT
FROM D3_CLEAN_ORDERS
ORDER BY ORDER_ID;
-- Expected: three rows; order 5 has AMOUNT = NULL.
-- This is an intentional data-quality choice, not an automatic fix.

-- 8. Generate JSON files, then load their objects into VARIANT.
CREATE OR REPLACE TABLE D3_JSON_SOURCE (PAYLOAD VARIANT);
INSERT INTO D3_JSON_SOURCE
SELECT PARSE_JSON('{"event_id":101,"region":"APAC","amount":25}')
UNION ALL
SELECT PARSE_JSON('{"event_id":102,"region":"EMEA","amount":40}');

COPY INTO @D3_FILES/input/json/events.json
  FROM D3_JSON_SOURCE
  FILE_FORMAT = (TYPE = JSON COMPRESSION = NONE)
  SINGLE = TRUE
  OVERWRITE = TRUE;

CREATE OR REPLACE TABLE D3_RAW_EVENTS (PAYLOAD VARIANT);
COPY INTO D3_RAW_EVENTS
  FROM @D3_FILES/input/json/
  FILE_FORMAT = (FORMAT_NAME = 'D3_JSON_LOAD');

SELECT
  PAYLOAD:event_id::NUMBER AS EVENT_ID,
  PAYLOAD:region::STRING AS REGION,
  PAYLOAD:amount::NUMBER AS AMOUNT
FROM D3_RAW_EVENTS
ORDER BY EVENT_ID;
-- Expected: events 101 and 102.
-- The generated file is newline-delimited JSON. D3_JSON_LOAD also accepts
-- an outer JSON array because STRIP_OUTER_ARRAY = TRUE.

-- 9. Unload a table and an aggregation.
COPY INTO @D3_FILES/output/orders.csv
  FROM D3_ORDERS
  FILE_FORMAT = (
    TYPE = CSV
    COMPRESSION = NONE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  )
  HEADER = TRUE
  SINGLE = TRUE
  OVERWRITE = TRUE;

COPY INTO @D3_FILES/output/region_totals/
  FROM (
    SELECT REGION, SUM(AMOUNT) AS TOTAL_AMOUNT
    FROM D3_ORDERS
    GROUP BY REGION
  )
  FILE_FORMAT = (TYPE = PARQUET)
  INCLUDE_QUERY_ID = TRUE;

LIST @D3_FILES/output/;
-- The CSV is one named file. The Parquet unload uses generated filenames.
-- APAC total = 200; EMEA total = 200.

-- 10. Directory metadata and an optional short-lived download URL.
ALTER STAGE D3_FILES REFRESH;
SELECT RELATIVE_PATH, SIZE, LAST_MODIFIED
FROM DIRECTORY(@D3_FILES)
ORDER BY RELATIVE_PATH;
-- Expected: file metadata, not the CSV/JSON row contents.

-- Optional: do not share the returned URL.
-- SELECT GET_PRESIGNED_URL(
--   @D3_FILES, 'output/orders.csv', 60
-- ) AS DOWNLOAD_URL;

-- 11. Recent file-load history.
SELECT
  FILE_NAME, STATUS, ROW_COUNT, ERROR_COUNT, FIRST_ERROR_MESSAGE
FROM TABLE(D3_STUDY.INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'D3_STUDY.LAB.D3_PARTIAL_ORDERS',
  START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())
))
ORDER BY LAST_LOAD_TIME DESC;

-- After studying, run 99-stop-lab.sql to stop the lab warehouse.
