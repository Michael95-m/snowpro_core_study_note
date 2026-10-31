# 1.5 Storage, Table Types, and Views

[Domain 1 index](readme.md)

## Micro-partitions and natural clustering

- For standard Snowflake tables, Snowflake automatically organizes rows into **micro-partitions**.
- These are:
  - Immutable.
  - Compressed.
  - Columnar.
- You do not define and maintain traditional table partitions yourself.
- Specialized table types do not necessarily use the same storage mechanism.

- A micro-partition represents approximately 50 MB to 500 MB of uncompressed data; physical storage is compressed.
- Snowflake records metadata such as per-column value ranges and distinct-value information.
- A selective predicate can use metadata to skip partitions that cannot match. This is **micro-partition pruning**.
- Updates/deletes produce new micro-partitions rather than modifying the old ones in place. Historical versions can remain for applicable protection periods.

<p align="center"><img src="../../img/domain1-partition-pruning.png" alt="A March date filter skips January-only and February-only partitions, while scanning partitions whose metadata ranges overlap March." width="760"></p>

- The ranges in the image are illustrative.
- A candidate partition can contain rows outside the filter.
- **Pruning** selects which partitions must be scanned.
- The query still checks which rows match.

- **Natural clustering** comes from the order in which data is loaded or inserted.
- Pruning can become less effective when frequently filtered values are scattered across many overlapping micro-partitions.
- An optional **clustering key** guides maintenance of a better organization for a suitable large-table workload.
- A clustering key is not mandatory for every table.

- These fundamentals were moved from the storage course chapter.
- Use [Domain 4](../4-Performance-Optimization-Querying-and-Transformation/readme.md) for:
  - Scan metrics.
  - Clustering-key choices.
  - Maintenance costs.
  - SQL tuning.

## Table lifetimes and data protection

| Standard table type | Lifetime | Time Travel | Fail-safe | Common use |
| --- | --- | --- | --- | --- |
| Permanent | Until dropped. | Standard: 0 or 1 day; Enterprise or higher: up to 90 days. | Seven days after retained history leaves Time Travel. | Persistent business data requiring recovery protection. |
| Temporary | Current session only, unless dropped sooner. | Up to one day while available; do not rely on recovery after the session ends. | None. | Session-local intermediate work. |
| Transient | Until dropped; survives sessions. | 0 or 1 day. | None. | Rebuildable staging or derived data. |

- **Temporary tables** are scoped to a session.
- They are not shared across every connection owned by the same user.
- A temporary table can hide a permanent table with the same name in that session.
- **Transient** does not mean “automatically deleted soon.”

```sql
-- Run in an existing writable study schema.
CREATE TABLE study_permanent (id NUMBER, amount NUMBER(12,2));
CREATE TEMPORARY TABLE study_session_work (id NUMBER);
CREATE TRANSIENT TABLE study_rebuildable (id NUMBER)
  DATA_RETENTION_TIME_IN_DAYS = 1;
```

## External, Iceberg, and dynamic tables

- External, Iceberg, and Dynamic Tables describe:
  - Data access.
  - Data format.
  - Refresh behavior.
- They are not simply alternative lifetimes for every table type listed above.

| Table | What it does | Key distinction |
| --- | --- | --- |
| External | Exposes files in external storage as a read-only table abstraction. | Files remain outside managed table storage; metadata refresh tracks file changes. |
| Apache Iceberg | Uses the open Iceberg table format with catalog metadata and data files. | Catalog ownership and storage location affect management and supported operations. |
| Dynamic | Stores the result of a query and refreshes it to pursue a target freshness. | Declare the query and target lag instead of writing every pipeline step manually. |

- For **Iceberg**, check the catalog and storage choices separately.
- **Catalog:**
  - Snowflake-managed catalog.
  - External catalog.
- **Storage:**
  - Snowflake-provided storage is supported in appropriate configurations.
  - External-volume storage is also supported in appropriate configurations.
  - An external catalog requires an appropriate external storage configuration.
- Do not assume that every Iceberg table:
  - Is read-only.
  - Is externally stored.
  - Follows standard-table Fail-safe rules.
- Check the actual catalog and storage setup.

```sql
-- Existing source table and refresh warehouse required.
CREATE DYNAMIC TABLE study_daily_sales
  TARGET_LAG = '10 minutes'
  WAREHOUSE = study_wh
  REFRESH_MODE = AUTO
AS
  SELECT order_date, SUM(amount) AS daily_sales
  FROM analytics.mart.orders
  GROUP BY order_date;
```

- **Target lag** is a freshness target relative to source data.
- It is not a fixed refresh interval or guaranteed SLA.
- Snowflake schedules refresh work to pursue the target.
- Incremental/full refresh support depends on the query and mode.
- Refreshing the stored result consumes compute.
- Ordinary direct DML is not how you maintain Dynamic Table results.

## View types

| View | Stores query result? | Purpose and trade-off |
| --- | --- | --- |
| Standard | No. | Reusable SQL abstraction; executes against underlying data. |
| Materialized | Yes, maintained automatically. | Speeds eligible repeated work; adds storage and maintenance cost and has definition restrictions. Requires Enterprise or higher. |
| Secure | Secure behavior can apply to standard or materialized views. | Protects definition/details and restricts optimizations that could expose underlying data; may cost performance. |

```sql
CREATE VIEW study_sales_summary AS
  SELECT order_date, SUM(amount) AS sales
  FROM analytics.mart.orders
  GROUP BY order_date;

CREATE SECURE VIEW study_public_customers AS
  SELECT customer_id, customer_name
  FROM analytics.mart.customer;
```

- `SECURE` does not automatically grant access.
- It does not replace row access or masking policies.
- **Dynamic Tables:**
  - Support pipeline definitions with broader transformation patterns.
- **Materialized views:**
  - Focus on eligible query acceleration.
  - Can be selected by the optimizer.
- Use [Domain 4](../4-Performance-Optimization-Querying-and-Transformation/readme.md) for materialized-view restrictions and tuning.

## What to recall

1. What makes micro-partitions immutable, and what metadata supports pruning?
2. How does natural clustering differ from an explicitly maintained clustering key?
3. Which table disappears at session end? Which survives but has no Fail-safe?
4. Which permanent-table retention requires Enterprise or higher?
5. How do external tables and Iceberg tables differ?
6. What are the separate Iceberg catalog and storage decisions?
7. Why does a ten-minute target lag not mean a refresh exactly every ten minutes?
8. How do secure, materialized, and standard views differ?

## Official references

- [Micro-partitions and clustering](https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions)
- [Temporary and transient tables](https://docs.snowflake.com/en/user-guide/tables-temp-transient)
- [External tables](https://docs.snowflake.com/en/user-guide/tables-external-intro)
- [Iceberg storage choices](https://docs.snowflake.com/en/user-guide/tables-iceberg-storage)
- [Dynamic-table target lag](https://docs.snowflake.com/en/user-guide/dynamic-tables/target-lag)
- [Materialized views](https://docs.snowflake.com/en/user-guide/views-materialized)
- [Secure views](https://docs.snowflake.com/en/user-guide/views-secure)
