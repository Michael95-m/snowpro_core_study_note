# Lab 04 · Answers

[Back to the lab](readme.md)

## Task 1: missing emails

```sql
SELECT SNOWFLAKE.CORE.NULL_COUNT(
  SELECT EMAIL FROM D2_DMF_LAB.LAB.CUSTOMERS
) AS missing_emails;
```

**Initial result: 2.** Customers 2 and 5 have `NULL` emails. `NULL_COUNT` measures the data; it does not decide whether two is acceptable.

## Task 2: duplicate IDs

```sql
SELECT SNOWFLAKE.CORE.DUPLICATE_COUNT(
  SELECT CUSTOMER_ID FROM D2_DMF_LAB.LAB.CUSTOMERS
) AS duplicated_id_values;
```

**Initial result: 2.** Both rows with ID 3 belong to the duplicate group. You need to change only one row to make IDs unique, but the DMF counts both duplicate values. [DUPLICATE_COUNT semantics](https://docs.snowflake.com/en/sql-reference/functions/dmf_duplicate_count)

## Task 3: ROW_COUNT

`SNOWFLAKE.CORE.ROW_COUNT` **cannot be called directly**. It must be attached to a supported table or view. Ordinary `SELECT COUNT(*)` is fine when you simply want the row total in an ad hoc query. [ROW_COUNT reference](https://docs.snowflake.com/en/sql-reference/functions/dmf_row_count)

## Task 4: repair and measure again

```sql
UPDATE D2_DMF_LAB.LAB.CUSTOMERS
SET EMAIL = 'b@example.com'
WHERE CUSTOMER_ID = 2;

UPDATE D2_DMF_LAB.LAB.CUSTOMERS
SET CUSTOMER_ID = 4
WHERE CUSTOMER_ID = 3 AND EMAIL = 'd@example.com';

SELECT SNOWFLAKE.CORE.NULL_COUNT(
  SELECT EMAIL FROM D2_DMF_LAB.LAB.CUSTOMERS
) AS missing_emails;

SELECT SNOWFLAKE.CORE.DUPLICATE_COUNT(
  SELECT CUSTOMER_ID FROM D2_DMF_LAB.LAB.CUSTOMERS
) AS duplicated_id_values;
```

**New results: 1 missing email, 0 duplicated ID values.** Customer 5 still has a missing email.

## Task 5: expectation

`EXPECTATION no_missing_email (VALUE = 0)` passes only when `NULL_COUNT` returns zero. After Task 4, it **fails** because the measured value is one. After the optional step updates customer 5's email, it **passes**. An expectation reports the quality state; it does not repair the row. [Expectation behavior](https://docs.snowflake.com/en/user-guide/data-quality-expectations)
