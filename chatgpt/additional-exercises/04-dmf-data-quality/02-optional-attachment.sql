-- Optional: attach a DMF and test an expectation. Run after Tasks 1-5.
-- This attachment can schedule serverless data quality monitoring.
-- Finish by running the cleanup statements at the bottom of this file.

-- Before adding a DMF, explicitly set a schedule for this lab table.
-- This is a 60-minute schedule, not an immediate run. Scheduled evaluations
-- can consume credits. The manual expectation test below checks it now.
ALTER TABLE D2_DMF_LAB.LAB.CUSTOMERS
  SET DATA_METRIC_SCHEDULE = '60 MINUTE';

ALTER TABLE D2_DMF_LAB.LAB.CUSTOMERS
  ADD DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT ON (EMAIL)
  EXPECTATION no_missing_email (VALUE = 0);

-- Predict: one EMAIL is still NULL, so does this expectation pass?
SELECT *
FROM TABLE(SYSTEM$EVALUATE_DATA_QUALITY_EXPECTATIONS(
  REF_ENTITY_NAME => 'D2_DMF_LAB.LAB.CUSTOMERS'
));

-- Repair the final missing EMAIL, then rerun the SELECT above.
UPDATE D2_DMF_LAB.LAB.CUSTOMERS
SET EMAIL = 'e@example.com'
WHERE CUSTOMER_ID = 5;

SELECT *
FROM TABLE(SYSTEM$EVALUATE_DATA_QUALITY_EXPECTATIONS(
  REF_ENTITY_NAME => 'D2_DMF_LAB.LAB.CUSTOMERS'
));

-- Stop recurring work even if you keep the lab table for review.
ALTER TABLE D2_DMF_LAB.LAB.CUSTOMERS
  SET DATA_METRIC_SCHEDULE = '';

ALTER TABLE D2_DMF_LAB.LAB.CUSTOMERS
  DROP DATA METRIC FUNCTION SNOWFLAKE.CORE.NULL_COUNT ON (EMAIL);
