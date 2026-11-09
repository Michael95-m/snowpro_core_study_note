-- Optional terminal lab. Run 00-setup.sql first, then execute this file with
-- Snowflake CLI as shown in the exercise README. <% min_amount %> is replaced
-- by the CLI before the SQL reaches Snowflake; it is not a Snowflake SQL variable.
USE WAREHOUSE D1_STUDY_WH;

SELECT CURRENT_USER() AS USER_NAME,
       CURRENT_ROLE() AS ROLE_NAME,
       CURRENT_WAREHOUSE() AS WAREHOUSE_NAME;

SELECT COUNT(*) AS MATCHING_ORDERS, SUM(AMOUNT) AS MATCHING_AMOUNT
FROM D1_STUDY.LAB.ORDERS
WHERE AMOUNT >= <% min_amount %>;
-- With min_amount=100, expect 3 rows totaling 600 from the setup fixture.
