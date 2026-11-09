# Lab 03 solutions

[Return to the exercises](readme.md)

Try each task first. The sample answers use the small dataset from [00-setup.sql](00-setup.sql). Do **not** rerun setup between the change tasks; it resets the table history.

## Tasks 1–2 · Inspect catalog and storage

```sql
SHOW ICEBERG TABLES IN SCHEMA ICEBERG_QUERY_LAB.LAB;

-- Run immediately after SHOW, before another SQL statement.
SELECT "name", "catalog_name", "external_volume_name"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
```

For `ORDERS`, expect catalog `SNOWFLAKE` and storage `SNOWFLAKE_MANAGED`. The clone also appears after you create it in the second exercise. `SHOW` reports the catalog and storage separately. [SHOW ICEBERG TABLES](https://docs.snowflake.com/en/sql-reference/sql/show-iceberg-tables)

## Task 3 · Completed revenue by region

```sql
SELECT REGION, COUNT(*) AS ORDER_COUNT, SUM(AMOUNT) AS TOTAL_AMOUNT
FROM ICEBERG_QUERY_LAB.LAB.ORDERS
WHERE STATUS = 'COMPLETE'
GROUP BY REGION
ORDER BY TOTAL_AMOUNT DESC;
```

Before the change exercise, expect EMEA **275.00**, APAC **260.00**, and AMER **150.00**.

## Task 4 · Customers with multiple orders

```sql
SELECT CUSTOMER_ID, COUNT(*) AS ORDER_COUNT
FROM ICEBERG_QUERY_LAB.LAB.ORDERS
GROUP BY CUSTOMER_ID
HAVING COUNT(*) >= 2
ORDER BY CUSTOMER_ID;
```

Before the changes, customers **1, 2, and 4** each have two orders.

## Task 5 · APAC's completed February orders

```sql
SELECT ORDER_ID, ORDER_DATE, AMOUNT
FROM ICEBERG_QUERY_LAB.LAB.ORDERS
WHERE REGION = 'APAC'
  AND STATUS = 'COMPLETE'
  AND ORDER_DATE >= DATE '2026-02-01'
  AND ORDER_DATE < DATE '2026-03-01'
ORDER BY ORDER_DATE, ORDER_ID;
```

Before the changes, expect orders **104** and **108**, totaling **140.00**.

## Task 6 · Current table after the UPDATE and DELETE

```sql
SELECT COUNT(*) AS ROW_COUNT, SUM(AMOUNT) AS ALL_ORDER_AMOUNT
FROM ICEBERG_QUERY_LAB.LAB.ORDERS;
```

Before restoring order 108, expect **7 rows** and **740.00**. Order 103 rose from 200.00 to 225.00; order 108's 90.00 was removed.

## Task 7 · Read old data with Time Travel

Replace the placeholders with the **actual query IDs** you saved after the UPDATE and DELETE. Run within the table's Time Travel retention period.

```sql
SELECT ORDER_ID, AMOUNT
FROM ICEBERG_QUERY_LAB.LAB.ORDERS
  BEFORE (STATEMENT => '<UPDATE_ID>')
WHERE ORDER_ID = 103;

SELECT ORDER_ID, AMOUNT
FROM ICEBERG_QUERY_LAB.LAB.ORDERS
  BEFORE (STATEMENT => '<DELETE_ID>')
WHERE ORDER_ID = 108;
```

Expect **200.00** for order 103 and **90.00** for order 108. `BEFORE` reads an earlier version; it does not change the current table. [AT and BEFORE](https://docs.snowflake.com/en/sql-reference/constructs/at-before)

## Task 8 · Restore one deleted row

Only run this once. Running it a second time inserts a duplicate because the lab table has no enforced primary key.

```sql
INSERT INTO ICEBERG_QUERY_LAB.LAB.ORDERS
  (ORDER_ID, CUSTOMER_ID, REGION, ORDER_DATE, STATUS, AMOUNT)
SELECT ORDER_ID, CUSTOMER_ID, REGION, ORDER_DATE, STATUS, AMOUNT
FROM ICEBERG_QUERY_LAB.LAB.ORDERS
  BEFORE (STATEMENT => '<DELETE_ID>')
WHERE ORDER_ID = 108;

SELECT ORDER_ID, COUNT(*) AS COPIES
FROM ICEBERG_QUERY_LAB.LAB.ORDERS
WHERE ORDER_ID = 108
GROUP BY ORDER_ID;
```

Expect one copy of order 108 and **8 rows** in ORDERS. Restoring one row this way keeps the later update to order 103.

## Task 9 · Compare the clone

```sql
SELECT 'BASELINE' AS TABLE_VERSION, ORDER_ID, AMOUNT
FROM ICEBERG_QUERY_LAB.LAB.ORDERS_BASELINE
WHERE ORDER_ID = 103
UNION ALL
SELECT 'CURRENT', ORDER_ID, AMOUNT
FROM ICEBERG_QUERY_LAB.LAB.ORDERS
WHERE ORDER_ID = 103;
```

Expect **200.00** in the clone and **225.00** in the current table. Clones share existing storage at creation; subsequent changes are independent. Cloning an Iceberg table with Snowflake storage is currently open preview. [Snowflake cloning considerations](https://docs.snowflake.com/en/user-guide/object-clone#cloning-and-apache-iceberg-tables)

## Task 10 · Query an Iceberg snapshot ID (optional preview)

```sql
SELECT VERSION_ID, VERSION_CREATED_AT, QUERY_ID
FROM TABLE(ICEBERG_QUERY_LAB.INFORMATION_SCHEMA.GET_TABLE_VERSIONS(
  'ICEBERG_QUERY_LAB.LAB.ORDERS'
));

-- Replace the number with the VERSION_ID for the setup INSERT.
SELECT ORDER_ID, AMOUNT
FROM ICEBERG_QUERY_LAB.LAB.ORDERS AT (VERSION => 123456789)
WHERE ORDER_ID IN (103, 108)
ORDER BY ORDER_ID;
```

Expect **103 = 200.00** and **108 = 90.00** at the original INSERT snapshot. `VERSION_ID` is an Iceberg snapshot ID, while `QUERY_ID` identifies the SQL statement that produced it. The table function and snapshot query are currently open preview features, so treat this task as extra practice rather than a core exam requirement. [GET_TABLE_VERSIONS](https://docs.snowflake.com/en/sql-reference/functions/get_table_versions) · [Iceberg Time Travel](https://docs.snowflake.com/en/user-guide/tables-iceberg-time-travel)
