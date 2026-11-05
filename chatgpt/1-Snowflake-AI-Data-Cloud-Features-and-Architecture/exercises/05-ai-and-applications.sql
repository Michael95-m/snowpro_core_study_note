-- Objective 1.6. Basic SQL prepares a tiny, synthetic dataset only.
USE ROLE SYSADMIN;
USE WAREHOUSE D1_STUDY_WH;
USE DATABASE D1_STUDY;
USE SCHEMA LAB;
CREATE OR REPLACE TABLE SUPPORT_ARTICLES (ARTICLE_ID NUMBER, BODY STRING);
INSERT INTO SUPPORT_ARTICLES VALUES
  (1,'A warehouse supplies compute for SQL queries.'),
  (2,'A named stage stores or references files.'),
  (3,'A masking policy controls returned column values.');
SELECT * FROM SUPPORT_ARTICLES ORDER BY ARTICLE_ID;
-- This creates source content. It does not create a Cortex Search service.
SELECT REGION, SUM(AMOUNT) AS TOTAL FROM ORDERS GROUP BY REGION ORDER BY REGION;
-- Three summary rows can feed a notebook/Streamlit chart without downloading
-- the entire source. Try the companion 06-snowpark.py in a Snowflake notebook.

-- OPTIONAL paid inference template. Replace the model with an available one
-- and use a role with the required Cortex/model privileges. Not run by default.
-- SELECT AI_COMPLETE('supported-model-name',
--   'Explain why warehouse suspension does not delete table data.');

-- Account inventory only; output visibility depends on privileges.
SHOW WAREHOUSES;
SHOW COMPUTE POOLS;
-- Notebook runtime compute can be independent from its SQL warehouse.
-- Stop the notebook service/runtime through its supported control when done.
-- Suspending D1_STUDY_WH alone does not stop an unrelated compute pool.
-- Cortex Search, Analyst, Model Registry, and Feature Store are explained in
-- topic 1.6 with prerequisites. They are not provisioned by this small script.
