# Domain 1 SQL exercises

- **Objectives:** 1.1-1.6 in the supplied C03 guide.
- **Use a fresh lab connection.** Role/context changes affect that session.
- **Status:** reviewed against official SQL references; not executed in your account.
- **Data:** small synthetic fixtures. No external bucket or paid AI service is required for the basic path.
- **Prerequisites:** an authorized role can create a warehouse/database; basic scripts use `SYSADMIN`.
- **Edition gates:** extended retention, multi-cluster, materialized views, and optional AI services have their own prerequisites.

## Run order and checkpoints

| Order | File | Expected observation |
| --- | --- | --- |
| 0 | [00-setup.sql](00-setup.sql) | `D1_STUDY.LAB`; 6 orders totaling 750. |
| 1 | [01-architecture-and-context.sql](01-architecture-and-context.sql) | Both warehouses read the same total; tables survive suspension; qualified names resolve across schema context. |
| 2 | [02-objects-and-parameters.sql](02-objects-and-parameters.sql) | Tax on 100 = 107; procedure writes one log row; APAC IDs = 1, 2, 5. |
| 3 | [03-virtual-warehouses.sql](03-virtual-warehouses.sql) | Inspect configuration; compute examples = 0.25 and 0.75 credits at the supplied rate. |
| 4 | [04-storage-and-views.sql](04-storage-and-views.sql) | Temporary name hides the permanent table; dropping it reveals the permanent data; view totals = 300/175/275. |
| 5 | [05-ai-and-applications.sql](05-ai-and-applications.sql) | Three source articles and three regional summaries; no AI service is provisioned. |
| 6 | [06-snowpark.py](06-snowpark.py) | Optional notebook cells: actions execute a lazy plan; only 3 aggregate rows are collected. |
| 99 | [99-stop-lab.sql](99-stop-lab.sql) | Both lab warehouses and any optional lab Dynamic Table are suspended. |

## Before you run

1. Run setup, then one exercise at a time.
2. Statements marked **intentional failure** are commented so Run All can continue.
3. Run those statements individually when you want to study the error.
4. The scripts replace their own named lab tables; rerunning setup resets their fixtures.
5. Temporary-table tests require the same session. Use a second connection only for the visibility check.
6. The fixtures demonstrate behavior, not production-scale speed or realistic ML quality.

## Compute and stopping

- A warehouse starts suspended and can resume when a query runs; it then consumes credits.
- `AUTO_SUSPEND = 60` is an idle timer, not a query-runtime limit.
- A separate start/resume has minimum billing. The rate used in arithmetic is an exercise assumption.
- Multi-cluster, Gen2, extended retention, AI inference, and Dynamic Table statements are optional templates.
- After notebook practice, stop its runtime/service separately. Warehouse suspension does not stop an independent compute pool.
- Run `99-stop-lab.sql`; optional DROP statements permanently remove only this named lab.

## Explain after running

1. Which observation demonstrates independent compute with shared storage?
2. Why does a file format exist even when its stage contains no files?
3. Why is a generated sequence value not proof of gap-free numbering?
4. Which query result changes with session context, and which is fixed by a qualified name?
5. What stores results: an ordinary view, a materialized view, or a Dynamic Table?
6. What computation ran before Python received the three summary rows?

References: [architecture](https://docs.snowflake.com/en/user-guide/intro-key-concepts), [CREATE WAREHOUSE](https://docs.snowflake.com/en/sql-reference/sql/create-warehouse), [SQL procedures](https://docs.snowflake.com/en/developer-guide/stored-procedure/stored-procedures-snowflake-scripting), [temporary tables](https://docs.snowflake.com/en/user-guide/tables-temp-transient), [Snowpark DataFrames](https://docs.snowflake.com/en/developer-guide/snowpark/python/working-with-dataframes).

[Back to Domain 1](../readme.md)

For hands-on Iceberg SQL, use the separate [Apache Iceberg query lab](../../additional-exercises/03-iceberg-query-lab/readme.md).
