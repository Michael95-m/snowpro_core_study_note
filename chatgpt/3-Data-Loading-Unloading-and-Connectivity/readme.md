# Domain 3.0: Data Loading, Unloading, and Connectivity

The [SnowPro Core C03 study guide](https://learn.snowflake.com/en/certifications/snowpro-core-c03/) assigns **18%** of the exam to Domain 3. This is a short review sheet: learn the decisions and core syntax here, then use the exercises for hands-on practice.

| Objective | Main question |
| --- | --- |
| **3.1 Loading and unloading** | How do files enter or leave a table, and how do you handle errors? |
| **3.2 Automated ingestion** | Which feature ingests data, tracks changes, or runs processing? |
| **3.3 Connectivity** | Which client or integration connects Snowflake to another system? |

## Practice files

Run these in order in a connected SQL editor. They use `D3_STUDY.LAB`, replace their own lab objects when rerun, and can consume credits.

1. [Setup](exercises/00-setup.sql): database, warehouse, stage, and file formats.
2. [File loading and unloading](exercises/01-file-loading-and-unloading.sql): good and bad files, validation, transformations, and export.
3. [Streams and Tasks](exercises/02-streams-and-tasks.sql): offsets, changes, a triggered task, and `MERGE`.
4. [Dynamic Tables](exercises/03-dynamic-tables.sql): create, inspect, and refresh.
5. [Schema detection and evolution](exercises/04-schema-detection-and-evolution.sql): infer columns and add a new column during a load.
6. [Stop the lab](exercises/99-stop-lab.sql): stop scheduling and suspend the warehouse.

The [Snowpipe Streaming SDK lab](../additional-exercises/05-snowpipe-streaming-sdk/readme.md) is optional. The basic SQL labs do not need an external bucket or streaming app.

---

## 3.1 Perform Data Loading and Unloading

### 3.1.1 Understand stages and file formats

| Goal | Flow | Compute |
| --- | --- | --- |
| Load local files | Local file → `PUT` → internal stage → `COPY INTO table` | Warehouse for `COPY` |
| Load cloud files | Cloud storage → external stage → `COPY INTO table` | Warehouse for `COPY` |
| Export rows | Table/query → `COPY INTO @stage` → files | Warehouse for `COPY` |

A **stage** points to files. A **file format** tells Snowflake how to parse or write them. A **table** stores rows. Staging a file does **not** insert its rows into a table.

- Common file types: `CSV`, `JSON`, `PARQUET`, `AVRO`, `ORC`, and `XML`. A named file format is reusable; inline options apply to one command.
- For CSV, `SKIP_HEADER` skips header rows; `PARSE_HEADER = TRUE` reads column names for column matching or schema inference. `FIELD_DELIMITER`, `FIELD_OPTIONALLY_ENCLOSED_BY`, `NULL_IF`, and `EMPTY_FIELD_AS_NULL` control parsing.
- For JSON, you can load each document into `VARIANT` or select typed paths. `STRIP_OUTER_ARRAY = TRUE` splits a top-level array into separate rows.
- **Internal stages** store files in Snowflake-managed storage: user (`@~`), table (`@%table_name`), or named (`@stage_name`). A named stage is easiest to reuse with a team.
- **External stages** point to S3, Azure, or Google Cloud storage. Dropping an external stage removes the Snowflake reference, not the cloud files. A **storage integration** can provide managed cloud access; the stage identifies the location.

For a warehouse-backed load, the active role needs access to the database, schema, stage, target table, file format (if named), and warehouse. An external stage also needs working cloud permissions.

```sql
CREATE FILE FORMAT my_csv TYPE = CSV SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"';
CREATE STAGE my_files FILE_FORMAT = my_csv;
LIST @my_files;
```

`PUT` uploads local files to an internal stage; `GET` downloads them. Run those commands in a supported client, such as Snowflake CLI or SnowSQL. `REMOVE` deletes staged files, but does not delete rows already loaded from them.

### 3.1.2 Encryption and directory tables

- Snowflake encrypts internal staged files. `SNOWFLAKE_FULL` is the usual default; `SNOWFLAKE_SSE` is needed for some direct file-access patterns, including `GET_PRESIGNED_URL` on an internal stage.
- Cloud storage permissions and encryption still matter for an external stage.
- A **directory table** is a file inventory for a stage: path, size, modification time, and other metadata. It does not contain the file's parsed table rows. Refresh or auto-refresh its inventory when files change.

### 3.1.3 Load, validate, and avoid duplicates

```sql
COPY INTO orders
FROM @my_files/incoming/
FILE_FORMAT = (FORMAT_NAME = 'my_csv')
ON_ERROR = SKIP_FILE;
```

- `FILES` selects specific filenames; `PATTERN` matches filenames with a regular expression. A stage path narrows the location.
- `ON_ERROR = ABORT_STATEMENT` stops the load; `CONTINUE` loads valid rows; `SKIP_FILE` skips a bad file. Check for partial rows before retrying.
- `VALIDATION_MODE = RETURN_ERRORS` tests a regular bulk `COPY` without inserting rows. `VALIDATE(table, JOB_ID => ...)` inspects a previous load's errors. Validation mode is not supported with a transforming `COPY`.
- Bulk `COPY` remembers loaded files to prevent accidental repeat loads. `FORCE = TRUE` deliberately overrides that protection; it does **not** remove existing rows. A new filename can also load the same data again. Reconcile old rows before replaying a correction.
- `COPY_HISTORY` shows per-file results. If a file is missing, check the stage path, file format, permissions, error message, and history.
- For large file loads, several suitably sized files allow parallel loading. Snowflake's general target is roughly **100–250 MB compressed** per file, rather than one huge file or thousands of tiny files.

### 3.1.4 Transform data and adapt the table

A `COPY INTO table` can select staged columns (`$1`, `$2`, and so on), cast them, and use supported expressions. For joins, aggregates, and complex logic, load first and transform later with SQL. `METADATA$FILENAME` can preserve the source filename.

```sql
COPY INTO clean_orders (order_id, region, source_file)
FROM (
  SELECT $1::NUMBER, TRIM($2), METADATA$FILENAME
  FROM @my_files/incoming/
)
FILE_FORMAT = (FORMAT_NAME = 'my_csv');
```

**Schema detection** (`INFER_SCHEMA`) discovers possible columns; it does not alter a table. **Schema evolution** lets a supported `COPY` or Snowpipe load adapt an existing table. Enable `ENABLE_SCHEMA_EVOLUTION`, grant `EVOLVE SCHEMA`, and use `MATCH_BY_COLUMN_NAME`. For evolving CSV files, use `PARSE_HEADER = TRUE` and `ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE`. Column-name matching and a transforming `COPY` cannot be combined.

### 3.1.5 Unload a query result

```sql
COPY INTO @my_files/export/orders.csv
FROM (SELECT order_id, amount FROM orders)
FILE_FORMAT = (TYPE = CSV COMPRESSION = NONE)
HEADER = TRUE
SINGLE = TRUE;
```

`COPY INTO <location>` writes files. `HEADER = TRUE` writes CSV column names; `SINGLE = TRUE` requests one file and may be less efficient for large exports. `PARTITION BY` writes output under partition paths. `OVERWRITE = TRUE` allows matching files to be replaced.

**Exam decision:** use bulk `COPY` for a known batch of staged files; use Snowpipe when new files arrive continuously.

References: [Loading overview](https://docs.snowflake.com/en/user-guide/data-load-overview), [COPY INTO table](https://docs.snowflake.com/en/sql-reference/sql/copy-into-table), [Unload data](https://docs.snowflake.com/en/user-guide/data-unload-overview), [Schema evolution](https://docs.snowflake.com/en/user-guide/data-load-schema-evolution).

---

## 3.2 Perform Automated Data Ingestion

### 3.2.1 Choose the right feature

| Need | Use | Remember |
| --- | --- | --- |
| Load arriving **files** | Snowpipe | Pipe definition + file notification + managed compute |
| Ingest arriving **rows** directly | Snowpipe Streaming | SDK/API sends rows; no staged file required |
| See changes after a saved position | Stream | CDC view over a source, with an offset |
| Run SQL or a procedure later | Task | Schedule, dependency, or change trigger |
| Keep a query result fresh | Dynamic Table | Define the result with `SELECT`; Snowflake refreshes it |
| Build a managed flow from source systems | Openflow | Connector and flow configuration |

### 3.2.2 Snowpipe and Snowpipe Streaming

**Snowpipe** loads staged files asynchronously with Snowflake-managed compute, not your virtual warehouse. A file-based pipe stores a `COPY INTO` definition. With `AUTO_INGEST = TRUE`, cloud events tell it about new files; the cloud notification route still needs setup. The Snowpipe REST API can submit names of files already staged. It does not upload file bytes.

```sql
CREATE PIPE orders_pipe AUTO_INGEST = TRUE AS
  COPY INTO orders
  FROM @orders_external_stage/incoming/
  FILE_FORMAT = (FORMAT_NAME = 'my_csv');

SELECT SYSTEM$PIPE_STATUS('D3_STUDY.LAB.ORDERS_PIPE');
```

- Check `COPY_HISTORY` for loaded, failed, or partially loaded files. `ON_ERROR = CONTINUE` can leave partial rows; `SKIP_FILE` skips a bad file.
- A file-based pipe cannot use every bulk `COPY` option; in particular, it cannot use `ON_ERROR = ABORT_STATEMENT`.
- Snowpipe remembers processed filenames for **14 days**; bulk `COPY` keeps separate table-level load metadata for **64 days**. Replacing an already loaded file under the same name might not reload it. Reconcile existing rows, then use a new name or a targeted bulk `COPY`.
- `ALTER PIPE ... REFRESH` queues eligible missed files staged within the last seven days. It is a recovery action, not the normal event flow.
- Snowpipe charges separately from warehouse compute, currently by loaded data volume. A warehouse resource monitor does not control it.

**Snowpipe Streaming** sends rows from an app, Kafka connector, or other producer through an SDK/API without staged files. It inserts rows; process CDC updates and deletes downstream with SQL, such as a Stream, Task, and `MERGE`.

- A **Named Channel** preserves order within that channel. Its committed offset token lets a correctly written client resume after a crash from the next retained source record. The token is a checkpoint, not a uniqueness constraint on business IDs.
- An **Elastic Channel** is simpler when ordering is unnecessary. It provides at-least-once delivery, so uncertain retries can duplicate rows.
- A default streaming pipe handles straightforward ingestion; a custom streaming pipe can define supported transformations. Creating a pipe alone does not send rows.

**Remember:** Snowpipe = staged **files**; Snowpipe Streaming = direct **rows**.

References: [Snowpipe](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-intro), [Snowpipe Streaming](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/data-load-snowpipe-streaming-overview), [Channel types](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-choosing-channel-type).

### 3.2.3 Streams and Tasks

A **Stream** exposes source changes since its offset; it does not ingest files or hold a second full copy of the source. A standard stream includes net inserts, updates, and deletes. An append-only stream tracks inserts. Standard stream output includes source columns plus `METADATA$ACTION`, `METADATA$ISUPDATE`, and `METADATA$ROW_ID`. An update can appear as a `DELETE` and an `INSERT` with `ISUPDATE = TRUE`.

```sql
CREATE STREAM order_changes ON TABLE raw_orders;
SELECT order_id, METADATA$ACTION, METADATA$ISUPDATE
FROM order_changes;
```

`SELECT` does **not** advance the stream offset. Committed DML that consumes the stream advances it; rollback leaves it unchanged. A stream can become stale if source history expires, so consume changes regularly. `SYSTEM$STREAM_HAS_DATA` helps a task decide whether to run, but `TRUE` can be a false positive.

A **Task** runs SQL or calls a stored procedure. It can run on a schedule, after another task, or when a stream has data. It can use a warehouse or Snowflake-managed serverless task compute. New tasks start suspended; `RESUME` them when ready. The owner role needs the required object and task execution privileges.

```sql
CREATE TASK apply_orders
  WAREHOUSE = my_wh
  WHEN SYSTEM$STREAM_HAS_DATA('order_changes')
AS
  INSERT INTO order_change_log
  SELECT order_id, METADATA$ACTION FROM order_changes;

ALTER TASK apply_orders RESUME;
```

This example logs changes. To maintain a **current-state** table with inserts, updates, and deletes, use a suitable `MERGE` instead. Check task history when a run is missing or failed.

### 3.2.4 Dynamic Tables and Openflow

A **Dynamic Table** stores the result of a `SELECT` and refreshes it as source data changes. `TARGET_LAG` is a **freshness goal**, not an exact schedule or guarantee. Its minimum is one minute. Use a Dynamic Table for a SQL-defined result; use a Task for procedural steps, `MERGE`, side effects, or stored procedure calls.

```sql
CREATE DYNAMIC TABLE region_totals
  TARGET_LAG = '10 minutes'
  WAREHOUSE = my_wh
AS
  SELECT region, SUM(amount) AS total
  FROM orders
  GROUP BY region;

ALTER DYNAMIC TABLE region_totals REFRESH;
```

`REFRESH_MODE = AUTO` chooses full or incremental refresh at creation. An explicit mode can be used when the query supports it. `INITIALIZE = ON_CREATE` or `ON_SCHEDULE` determines when the first result is populated.

**Openflow** is Snowflake's managed tool for building flows from source systems. For the exam, recognize when a connector-based flow fits. Actual setup depends on its source, credentials, and deployment.

References: [Streams](https://docs.snowflake.com/en/user-guide/streams-intro), [Tasks](https://docs.snowflake.com/en/user-guide/tasks-intro), [Dynamic Table target lag](https://docs.snowflake.com/en/user-guide/dynamic-tables/target-lag), [Openflow](https://docs.snowflake.com/en/user-guide/data-integration/openflow/about).

---

## 3.3 Connectors, Drivers, and Integrations

### 3.3.1 Clients and connectors

| Tool | Use it when |
| --- | --- |
| JDBC / ODBC driver | An application or BI tool needs a standard database connection. |
| Snowflake Connector for Python | Python code needs to run SQL and fetch results. |
| Snowflake Connector for Kafka | Kafka records need to flow into Snowflake. |
| Snowflake Connector for Spark | Spark jobs need to read or write Snowflake data. |
| Snowflake CLI / SnowSQL | A person or script runs Snowflake commands from a terminal. |
| Snowflake SQL API | An HTTPS client submits SQL and retrieves results/status. |

For any client, separate **authentication** (who are you?) from **authorization** (does the active role have the required privileges?). A working connection does not grant access to every database, schema, table, or warehouse.

### 3.3.2 Integration objects

| Object | Main purpose | Example decision |
| --- | --- | --- |
| **Storage integration** | Give Snowflake managed access to permitted cloud storage locations. | An external stage reads files in S3. |
| **API integration** | Configure a supported HTTPS endpoint for an external function or Git repository, depending on integration type. | SQL calls a partner API through an external function. |
| **External access integration** | Permit supported Snowflake code, such as a procedure/UDF, to call an external network endpoint. | Python procedure calls a REST API. |
| **Git repository clone** | Reference repository files from Snowflake. | Run a versioned SQL script from a Git source. |

Integration objects are **account-level** configuration; stages, external functions, and Git repository clones are **schema-level** objects. A storage integration does not identify a specific stage path by itself. An API integration is not interchangeable with a storage integration.

For an external function, configure its HTTPS endpoint and API integration, create the function, then grant the calling role the needed privileges. For a Git repository, configure an API integration and credentials as needed, create the repository clone, fetch the version you want, then access files through its stage-like path.

References: [Drivers and connectors](https://docs.snowflake.com/en/developer-guide/drivers), [Storage integrations](https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration), [External functions](https://docs.snowflake.com/en/sql-reference/external-functions-introduction), [Git integration](https://docs.snowflake.com/en/developer-guide/git/git-overview).

---

## What to Recall

Answer each question, then open **Show answer**. The SQL practice is in the [exercise files](#practice-files).

<details>
<summary><strong>1. Q:</strong> What is the difference between a stage, file format, and table?</summary>

<br>

**A:** A stage points to files; a file format tells Snowflake how to parse or write them; a table stores rows.

</details>

<hr>

<details>
<summary><strong>2. Q:</strong> Which COPY command loads files, and which one exports rows?</summary>

<br>

**A:** `COPY INTO table` loads; `COPY INTO @stage` unloads.

</details>

<hr>

<details>
<summary><strong>3. Q:</strong> What happens if you drop an external stage?</summary>

<br>

**A:** Its Snowflake reference is removed; the cloud files remain.

</details>

<hr>

<details>
<summary><strong>4. Q:</strong> How do ABORT_STATEMENT, CONTINUE, and SKIP_FILE differ?</summary>

<br>

**A:** They stop the load, load valid rows, or skip a bad file, respectively.

</details>

<hr>

<details>
<summary><strong>5. Q:</strong> Why can a corrected file create duplicates or fail to reload?</summary>

<br>

**A:** A new name can load the same rows again; Snowpipe may ignore a name it still remembers. Reconcile existing rows before replay.

</details>

<hr>

<details>
<summary><strong>6. Q:</strong> Does INFER_SCHEMA change the target table?</summary>

<br>

**A:** No. It detects a possible structure. Schema evolution needs separate table, privilege, and load settings.

</details>

<hr>

<details>
<summary><strong>7. Q:</strong> When do you choose bulk COPY, Snowpipe, and Snowpipe Streaming?</summary>

<br>

**A:** For a known file batch now; continuously arriving files; and continuously arriving rows without staged files, respectively.

</details>

<hr>

<details>
<summary><strong>8. Q:</strong> Does AUTO_INGEST = TRUE configure cloud notifications by itself?</summary>

<br>

**A:** No. The cloud event route and permissions must also be configured.

</details>

<hr>

<details>
<summary><strong>9. Q:</strong> What is a Named Channel offset token used for?</summary>

<br>

**A:** It records committed source progress so the client can resume from the next retained record after a crash.

</details>

<hr>

<details>
<summary><strong>10. Q:</strong> Does a Stream load files or store another full table?</summary>

<br>

**A:** Neither. It exposes source changes since an offset.

</details>

<hr>

<details>
<summary><strong>11. Q:</strong> What advances a Stream offset?</summary>

<br>

**A:** Committed DML that consumes it. A SELECT and rolled-back DML do not.

</details>

<hr>

<details>
<summary><strong>12. Q:</strong> How can a standard Stream show an update?</summary>

<br>

**A:** As a DELETE plus an INSERT, both marked METADATA$ISUPDATE = TRUE.

</details>

<hr>

<details>
<summary><strong>13. Q:</strong> Why pair a Stream with a Task?</summary>

<br>

**A:** The Stream exposes changes; the Task runs SQL to process them.

</details>

<hr>

<details>
<summary><strong>14. Q:</strong> What does TARGET_LAG = 10 minutes promise?</summary>

<br>

**A:** A best-effort freshness target, not a refresh every ten minutes or a strict guarantee.

</details>

<hr>

<details>
<summary><strong>15. Q:</strong> When is a Task better than a Dynamic Table?</summary>

<br>

**A:** When the work needs procedural logic, MERGE, a stored procedure call, or side effects.

</details>

<hr>

<details>
<summary><strong>16. Q:</strong> How does a storage integration differ from an external stage?</summary>

<br>

**A:** The integration configures cloud access; the stage points to a cloud location.

</details>

<hr>

<details>
<summary><strong>17. Q:</strong> Which API submits SQL over HTTPS, and which API notifies Snowpipe of staged files?</summary>

<br>

**A:** The Snowflake SQL API submits SQL; the Snowpipe REST API submits staged filenames.

</details>

<hr>

<details>
<summary><strong>18. Q:</strong> Does a successful client connection give a role table access?</summary>

<br>

**A:** No. Authentication and object privileges are separate.

</details>
