# Lab 03 · Query an Apache Iceberg table

[Additional exercises](../../readme.md#additional-exercises) · [Domain 1 Iceberg notes](../../1-Snowflake-AI-Data-Cloud-Features-and-Architecture/05-storage-tables-and-views.md#iceberg-configuration-pruning-and-exercise-checkpoints)

Practice with a real Iceberg table in Snowflake. The lab keeps its Parquet data and Iceberg metadata in **Snowflake storage**, so you do not need to configure S3 or an external catalog. Snowflake owns the Iceberg catalog in this setup. The catalog choice and storage choice are separate decisions. [Snowflake Iceberg storage options](https://docs.snowflake.com/en/user-guide/tables-iceberg-storage) · [Catalog options](https://docs.snowflake.com/en/user-guide/tables-iceberg#catalog-options)

## Before you start

- Use your **main Snowflake account** and a fresh worksheet or SQL connection. This lab uses `SYSADMIN` and creates only `ICEBERG_QUERY_LAB` and `ICEBERG_QUERY_WH`.
- Snowflake storage for Iceberg tables is available on AWS and Azure accounts outside the documented excluded regions. Your AWS US West 2 account fits that requirement. If the `CREATE ICEBERG TABLE` statement still fails, send me the exact error; account privileges or a changed feature setting may be involved. [Snowflake storage availability](https://docs.snowflake.com/en/user-guide/tables-iceberg-internal-storage)
- The X-Small warehouse resumes when used and suspends after 60 seconds of inactivity. Queries and table storage can incur charges. Run the stop script when finished.
- Run SQL statements **one at a time** for the change exercises so you can see and save each statement's query ID. Rerunning setup replaces the table and removes its earlier history.

## Run in order

1. Run [00-setup.sql](00-setup.sql). Check that `ORDERS` contains **8 rows** and its total amount is **805.00**.
2. Open [01-query-challenges.sql](01-query-challenges.sql). Write and run the SQL for Tasks 1–5. Check your results before opening the answers.
3. Open [02-change-and-snapshot-challenges.sql](02-change-and-snapshot-challenges.sql). Run its setup statements, then the `UPDATE` and `DELETE` one at a time. Save each query ID. Write the SQL for Tasks 6–10.
4. Check [solutions.md](solutions.md) after trying the tasks. Replace the example query IDs and snapshot ID with the values from your account.
5. Run [99-stop-lab.sql](99-stop-lab.sql). It suspends the warehouse. The optional cleanup statements remove the lab objects.

## What the tasks cover

| Tasks | Practice |
| --- | --- |
| 1–2 | Inspect the table's catalog and storage settings. |
| 3–5 | Filter, aggregate, and find customers with multiple orders. |
| 6–7 | Compare current rows with the state before an `UPDATE` or `DELETE`. |
| 8 | Restore one deleted row without replacing the whole table. |
| 9 | See that an Iceberg clone is independent after changes. Cloning this storage type is an open preview feature. |
| 10 | Optional: inspect Iceberg snapshot IDs and query an earlier snapshot. This uses an open preview feature. |

**Key distinction:** `SNOWFLAKE_MANAGED` is a reserved storage value, not an external volume object you create. If you later want the data files in your own S3 bucket, you must configure an actual external volume. If AWS Glue or another supported external catalog owns the table, Snowflake also uses a catalog integration. [Create Iceberg table](https://docs.snowflake.com/en/user-guide/tables-iceberg-create) · [Catalog integration](https://docs.snowflake.com/en/user-guide/tables-iceberg#catalog-integration)

The SQL follows current Snowflake documentation. I could not run it in your account, so the actual Snowflake results remain for you to check.
