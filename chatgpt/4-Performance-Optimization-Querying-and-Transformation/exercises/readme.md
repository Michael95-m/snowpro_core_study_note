# Domain 4 SQL exercises

- **Objectives:** 4.1 diagnosis, 4.2 optimization, 4.3 caching, 4.4 transformations.
- **Status:** reviewed against official SQL references; not executed in your account.
- **Data:** six business orders, four customers, five customer versions, and 100,000 small synthetic events.
- **Basic requirements:** a role such as `SYSADMIN` that can create a lab database/warehouse; use a fresh session.
- **Basic compute:** one X-Small warehouse with 60-second auto-suspend. Queries consume credits.

## Run order and checkpoints

| Order | File | Expected observation |
| --- | --- | --- |
| 0 | [00-setup.sql](00-setup.sql) | `D4_STUDY.LAB`; 6 orders totaling 750; 100,000 inspection events. |
| 1 | [01-query-diagnosis.sql](01-query-diagnosis.sql) | Cross join: 24 rows; duplicate-key join: 8 rows/900 total; correct join: 6 rows/750 total. |
| 2 | [02-sql-and-optimization-choices.sql](02-sql-and-optimization-choices.sql) | Both date predicates return 3334 rows; UNION gives 1 APAC row, UNION ALL gives 3. |
| 3 | [03-caching.sql](03-caching.sql) | Inspect final-result reuse separately from warehouse scan-cache metrics; timing/cache hits are observations, not guaranteed outcomes. |
| 4 | [04-structured-and-semi-structured.sql](04-structured-and-semi-structured.sql) | 3 aggregate rows versus 6 window rows; latest IDs 2/4/5/6; FLATTEN 2 rows versus OUTER 3 rows. |
| 5 | [05-file-metadata-and-urls.sql](05-file-metadata-and-urls.sql) | One generated CSV inventory row and file-reference URLs; no document parsing. |
| 99 | [99-stop-lab.sql](99-stop-lab.sql) | Warehouse suspended; session benchmark settings cleared. |

## A small lab is not a performance benchmark

1. Correctness checkpoints have known answers; compare those directly.
2. Runtime, cache hits, spill, partitions scanned, and acceleration depend on the real plan and environment.
3. The fixture may fit in very few micro-partitions, so weak/strong pruning differences may be too small to measure.
4. Do not enlarge a warehouse or enable a paid service merely to force an observation.
5. Capture the actual query ID and use its Query Profile. Editor background queries can change the most recent ID.
6. `GET_QUERY_OPERATOR_STATS` requires a completed query with available statistics and suitable warehouse monitoring privileges.
7. `PERCENTAGE_SCANNED_FROM_CACHE` describes warehouse-local scans, not final-result reuse.

## Optional optimization services

- QAS, Search Optimization, Automatic Clustering, and materialized-view templates are commented in exercise 02.
- Check edition, account support, query eligibility, and ongoing cost before enabling one.
- Search optimization and materialized views add storage and maintenance costs.
- Defining a clustering key can start background maintenance; a tiny table rarely justifies it.
- Warehouse suspension does not stop independent serverless maintenance.
- If you activate a template, run its paired cleanup and the optional cleanup lines in `99-stop-lab.sql`.
- Core exercises do not provision these services.

## Explain after running

1. Why did the wrong join produce 900 instead of 750?
2. How does filtering unnecessary data differ from changing the required business result?
3. Why can two equivalent predicates have similar plans even when one uses a function?
4. Why is zero bytes scanned alone insufficient proof of a final-result cache hit?
5. Why do RANGE totals include both same-date rows at once?
6. Why does OUTER FLATTEN retain the empty-array parent?
7. Why is a directory row not a parsed document or a table's business row?

References: [operator statistics](https://docs.snowflake.com/en/sql-reference/functions/get_query_operator_stats), [clustering information](https://docs.snowflake.com/en/sql-reference/functions/system_clustering_information), [persisted results](https://docs.snowflake.com/en/user-guide/querying-persisted-results), [window frames](https://docs.snowflake.com/en/sql-reference/functions-window-syntax), [FLATTEN](https://docs.snowflake.com/en/sql-reference/functions/flatten).

[Back to Domain 4](../readme.md)
