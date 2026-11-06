# Lab 02 · Query performance on larger data

[Additional exercises](../../readme.md#additional-exercises) · [Domain 4 exercises](../../4-Performance-Optimization-Querying-and-Transformation/exercises/readme.md)

Use one synthetic sales dataset to practice three exam scenarios. Measure pruning on the same data stored in two orders. Compare warehouse-local data reuse with persisted query results. Then fix a query that doubles revenue by joining every sale to two customer versions.

## Choose a size

Edit the single `GENERATOR(ROWCOUNT => 100000)` value in [00-setup.sql](00-setup.sql). The count is **per sales table**. Setup builds two tables with the same rows.

| Size per table | When to use it |
| ---: | --- |
| 100,000 | First run. Check that the SQL works and the totals match. There may be too few micro-partitions to see a clear pruning difference. |
| 5,000,000 | Main run. Compare partitions scanned, bytes scanned, and cache behavior. |
| 20,000,000 | Optional larger run. Both tables take more time and storage to build. |

- Use a fresh worksheet or SQL connection in your **main account**. The lab uses `SYSADMIN`, the dedicated `PERF_LAB` database, and the X-Small `PERF_LAB_WH` warehouse.
- Setup replaces its two sales tables when rerun. The warehouse auto-suspends after 60 seconds of inactivity. Setup and queries consume warehouse credits, and the stored data incurs storage usage until cleanup.
- The sales rows have a synthetic text column to give the tables more width. The benchmark queries select only the columns they need. Table order comes from `ORDER BY` during creation, so the comparison runs without an Automatic Clustering maintenance job. [Creating a sorted table with CTAS](https://docs.snowflake.com/en/sql-reference/sql/create-table)

## Run the files in order

Keep the same SQL session for exercises 01–04 so the history query can find your earlier runs.

| File | What to check |
| --- | --- |
| [00-setup.sql](00-setup.sql) | `EVENTS_INTERLEAVED` and `EVENTS_BY_DATE` have matching row counts, date ranges, and totals. |
| [01-pruning.sql](01-pruning.sql) | The January 10 queries return the same count and total. Compare the scan nodes in Query Profile. |
| [02-caching.sql](02-caching.sql) | Run each pair back-to-back on the same warehouse. Compare local cache reads with possible final-result reuse. |
| [03-join-correctness.sql](03-join-correctness.sql) | The ID-only join doubles the baseline. The latest-version join fixes the count but puts January sales in `EAST`. The date-aware join puts them in `WEST`. |
| [04-query-history.sql](04-query-history.sql) | Find the query IDs, execution times, and bytes scanned in your current session. Run it before cleanup. |
| [99-stop-lab.sql](99-stop-lab.sql) | Suspend the lab warehouse. Optionally drop the dedicated database and warehouse when finished. |

## 1. Compare pruning

- In `EVENTS_INTERLEAVED`, neighboring event IDs cycle across the year. In `EVENTS_BY_DATE`, rows with similar dates are written together.
- Open **Query Profile → TableScan** for both January 10 queries. Compare **partitions scanned / partitions total** and **bytes scanned**. The date-ordered table should typically scan a smaller fraction at the larger sizes. Snowflake chooses the actual partition layout and query plan. [Micro-partitions and pruning](https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions#query-pruning)
- Use the query IDs returned by exercise 04 to find each run. Compare scan metrics before comparing duration, since cache warmth and warehouse activity can change timing.
- For a SQL report with partition counts and warehouse cache percentages, exercise 04 also has an optional `ACCOUNT_USAGE` query. It requires access to that view, and results can lag by up to 45 minutes. [Query History table function](https://docs.snowflake.com/en/sql-reference/functions/query_history) · [Account Usage Query History](https://docs.snowflake.com/en/sql-reference/account-usage/query_history)

## 2. Identify which cache helped

1. In the first pair, `USE_CACHED_RESULT = FALSE`. Each query executes. The second can read table data that the first left in the running warehouse’s local cache.
2. In the second pair, result reuse is enabled and the July query text repeats exactly. If Snowflake reuses the saved answer, it can return it without a table scan.
3. Compare **bytes scanned**, **warehouse cache %**, and the profile together. Warehouse cache % is the fraction of scanned data read from local cache. Zero bytes alone is insufficient evidence of saved-result reuse. Cache hits and faster runtimes are observations you can check. [Warehouse cache](https://docs.snowflake.com/en/user-guide/performance-query-warehouse-cache) · [Persisted results and reuse conditions](https://docs.snowflake.com/en/user-guide/querying-persisted-results)

## 3. Fix the join and keep the business meaning

Each customer has a `WEST` version through June and an `EAST` version starting July 1. Before reading the corrected query, predict what happens if you join January sales on customer ID alone or keep only the latest customer version.

- **ID only.** Each sale matches two versions, so both the row count and revenue double.
- **Latest version only.** Each January sale matches one version, but it gets assigned to `EAST`.
- **ID and validity dates.** Each sale matches the version valid on the sale date. The query uses `EVENT_DATE >= VALID_FROM` and `EVENT_DATE < VALID_TO`. The January results match the baseline and belong in `WEST`. [Diagnosing exploding joins](https://docs.snowflake.com/en/user-guide/ui-snowsight-activity#exploding-joins)

## Expected results

| Sales rows per table | Jan 10 count | Jan 10 total | Jan 1–7 baseline count | Jan 1–7 baseline total |
| ---: | ---: | ---: | ---: | ---: |
| 100,000 | 274 | 14,405 | 1,918 | 96,327 |
| 5,000,000 | 13,699 | 719,205 | 95,893 | 4,801,577 |
| 20,000,000 | 54,795 | 2,876,725 | 383,565 | 19,205,685 |

Each repeated cache query should return the same count and total as the other query in its pair. For the five-million-row run, the ID-only join returns **191,786** rows and **9,603,154** total. The corrected join returns **95,893** rows and **4,801,577** total, all assigned to `WEST`.

The expected totals were checked locally. The SQL was reviewed against Snowflake documentation. Actual partitions scanned, cache hits, and timings will come from your Snowflake run.
