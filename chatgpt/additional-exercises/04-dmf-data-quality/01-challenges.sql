-- Run 00-setup.sql first. Write each answer below its task.

-- Task 1: Without querying, predict the result of NULL_COUNT on EMAIL.
-- Then call SNOWFLAKE.CORE.NULL_COUNT directly on that one column.


-- Task 2: Predict the result of DUPLICATE_COUNT on CUSTOMER_ID.
-- Then call SNOWFLAKE.CORE.DUPLICATE_COUNT directly on that one column.
-- Explain why its result is not the number of extra rows needed to fix the IDs.


-- Task 3: Can you call SNOWFLAKE.CORE.ROW_COUNT directly in SELECT?
-- Look at its reference before trying an unsupported call. Explain the
-- difference between a direct call and attaching a DMF to a table.


-- Task 4: Improve both measurements without deleting rows:
--   a. Give customer 2 a non-NULL email.
--   b. Change the row with EMAIL = 'd@example.com' to CUSTOMER_ID = 4.
-- Rerun your DMF queries. Predict the new values first.


-- Task 5: One EMAIL is still NULL. Write an expectation for NULL_COUNT
-- that would PASS only when there are no missing emails. Would it pass now?
-- For the optional step of attaching/testing it, open 02-optional-attachment.sql.
