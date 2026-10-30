# Domain 3.0: Data Loading, Unloading, and Connectivity

- **Exam outline:** the supplied [SnowPro Core C03 study guide](../SnowProCoreStudyGuideC03.pdf), pages 5 and 9.
- **Domain weighting in that guide:** **18%**.
- **Documentation checked:** October 30, 2026.
- **Purpose:** understand the feature, recognize when to use it, and practice with SQL.
- **Technical terms stay unchanged.** The explanations use short bullets and simple words.
- **Examples have not been executed in your Snowflake account.** The SQL has been reviewed against official documentation.

## How to use this note

1. Read one numbered topic.
2. Learn its **Remember** line.
3. Try the related exercise and check its expected result.
4. Answer the matching **What to Recall** questions without looking.
5. Use the linked official documentation when a detail needs a deeper explanation.

### The C03 coverage checklist

| C03 objective | Topics covered here | Where to start |
| --- | --- | --- |
| **3.1 Perform data loading and unloading** | File formats; internal/external stages; server-side encryption; directory tables; `COPY INTO`; error handling. | [3.1](#31-perform-data-loading-and-unloading) |
| **3.2 Perform automated data ingestion** | Snowpipe; Snowpipe Streaming; Streams; Tasks; Dynamic Tables; Openflow and the guide's availability condition. | [3.2](#32-perform-automated-data-ingestion) |
| **3.3 Identify the different Snowflake Connectors and integrations** | Drivers; connectors; storage integration; API integration; Git integration. | [3.3](#33-connectors-drivers-and-integrations) |

### Quick navigation

- [Practice setup and SQL files](#practice-setup-and-exercise-files)
- [File formats](#312-file-formats) / [Stages](#313-internal-stages-and-external-stages) / [File-transfer commands](#314-put-get-list-remove-and-drop-stage)
- [Encryption](#315-server-side-encryption) / [Directory tables](#316-directory-tables-a-file-inventory)
- [Duplicates and load metadata](#318-duplicate-handling-and-load-metadata) / [Error handling](#319-error-handling-choose-the-outcome-you-need)
- [Load transformations](#3110-transform-data-during-a-load) / [Schema detection and evolution](#3112-schema-detection-versus-schema-evolution)
- [Snowpipe](#322-snowpipe-continuous-file-ingestion) / [Snowpipe Streaming](#323-snowpipe-streaming-ingest-rows-without-staged-files)
- [Streams](#324-streams-remember-a-processing-position) / [Tasks](#325-tasks-run-the-work) / [Task permissions](#326-task-permissions-and-troubleshooting)
- [Dynamic Tables](#327-dynamic-tables-define-the-desired-result) / [Openflow](#328-openflow-connect-source-systems-and-build-flows)
- [Drivers](#332-drivers-connect-application-code-to-snowflake) / [Connectors](#333-connectors-connect-another-platform-or-data-workflow) / [SQL API](#334-sql-clients-and-the-snowflake-sql-api)
- [Storage integration](#335-storage-integrations) / [API integration](#336-api-integrations) / [Git integration](#337-git-integration)
- [Scenario decisions](#scenario-decision-guide) / [Exercise checkpoints](#exercise-checkpoints) / [What to Recall](#what-to-recall)

### What is core, and what goes deeper?

- **Start with the named C03 topics:** what each feature does, its compute, its permissions, and when to choose it.
- **Then study the practical details:** load history, duplicate handling, stream offsets, task state, and refresh behavior.
- **Optional implementation depth:** complete cloud IAM setup, streaming SDK code, and individual Openflow connector configuration.
- The guide says its topic list is **not exhaustive**.
- An example or an **Exam clue** below is a study scenario, not a claim about a particular live exam question.
- Product documentation changes independently of the exam outline. A new feature in the docs does not automatically become a new exam objective.

### Where your earlier notes fit

- [Loading and unloading course note](../7-Data-Loading-and-Unloading/readme.md):
  - Earlier explanations of stages, bulk loading, Snowpipe, and semi-structured files.
  - This Domain 3 note puts those ideas into the C03 structure and adds the other named objectives.
- [Domain 1 object types](../1-Snowflake-AI-Data-Cloud-Features-and-Architecture/03-objects-sessions-and-parameters.md):
  - Where stages, file formats, pipes, and other objects sit in Snowflake.
- [Domain 2](../2-Account-Management-and-Data-Governance/readme.md):
  - Roles, authentication, privileges, and cost controls.
- [Domain 4 transformations](../4-Performance-Optimization-Querying-and-Transformation/readme.md#44-perform-data-transformation-techniques):
  - Deeper SQL transformations, JSON paths, `FLATTEN`, and unstructured-file access.
- [Earlier transformation course note](../8-Data-transformation/readme.md):
  - File URL functions and directory tables, with more transformation examples.
- Folder numbers **7, 8, and 9 are course chapters**, not C03 domain numbers.

---

## Practice setup and exercise files

### 1. Run the exercises in this order

| File | What you practice | What you should observe |
| --- | --- | --- |
| [00-setup.sql](exercises/00-setup.sql) | A small warehouse, a lab database, a stage, and file formats. | Lab context is `D3_STUDY.LAB`. |
| [01-file-loading-and-unloading.sql](exercises/01-file-loading-and-unloading.sql) | Generate sample files, validate, load, handle bad rows, transform, unload, and inspect file metadata. | Good load: 3 rows; partial bad-file load: 2 rows; skipped bad file: 0 rows. |
| [02-streams-and-tasks.sql](exercises/02-streams-and-tasks.sql) | Stream offsets, updates/deletes, `MERGE`, rollback, and a triggered task. | `SELECT` keeps changes available; committed DML consumes them. |
| [03-dynamic-tables.sql](exercises/03-dynamic-tables.sql) | Create, inspect, suspend, and manually refresh a Dynamic Table. | APAC total changes from 150 to 175 after refresh. |
| [04-schema-detection-and-evolution.sql](exercises/04-schema-detection-and-evolution.sql) | Infer a schema from CSV, then add a new column during loading. | The later file adds an `EMAIL` column. |
| [99-stop-lab.sql](exercises/99-stop-lab.sql) | Stop lab scheduling and suspend the warehouse. | Lab data remains available for later review. |

### 2. Know the exercise boundaries

- Run the SQL yourself in a connected VS Code SQL editor or Snowsight.
- Use **`D3_STUDY` only for these exercises**:
  - Exercise scripts replace their own lab tables when rerun.
  - Replacing a table also changes its load-history context.
- The warehouse is **X-Small**, with `AUTO_SUSPEND = 60`:
  - It still consumes credits while running.
  - Starting or resuming a standard warehouse has a minimum compute charge.
- The scripts generate small input files using `COPY INTO <location>`:
  - No local CSV preparation is needed.
  - No external bucket is needed for the basic exercises.
- Task definitions stay suspended unless you explicitly resume them.
- The Dynamic Table initializes once, then its scheduled refreshes are suspended.
- Cloud Snowpipe, streaming clients, Openflow, and Git setup are separate optional examples.
- After practice, run [99-stop-lab.sql](exercises/99-stop-lab.sql).

### 3. Use the right permissions

- The basic setup uses `SYSADMIN` for lab objects.
- A custom role can also be used if it has the required privileges.
- To load/query data, check:
  1. `USAGE` on the database and schema.
  2. `USAGE` on the warehouse when the operation uses a warehouse.
  3. The needed table privilege, such as `INSERT` or `SELECT`.
  4. Stage access.
  5. `USAGE` on a named file format, when one is used.
- Internal named stage:
  - `READ` to list/read files.
  - `WRITE` to add/remove files; `READ` is also required when granting `WRITE`.
- External stage:
  - `USAGE` on the stage.
  - The cloud identity must also have the needed bucket/container permissions.
- Tasks need additional account privileges; see [task permissions](#326-task-permissions-and-troubleshooting).
- **A successful connection does not supply missing object privileges.**

Reference: [Data loading access control](https://docs.snowflake.com/en/user-guide/security-access-control-privileges).

---

## 3.1 Perform Data Loading and Unloading

### 3.1.1 Understand the direction of data movement

1. **Loading:** files or incoming rows become rows in a Snowflake table.
2. **Unloading:** a table or query result becomes files outside the table.
3. **Staging:** files are placed in, or referenced through, a stage.
4. **Parsing:** a file format tells Snowflake how to read/write those files.

```text
Local file -> PUT -> internal stage -> COPY INTO table -> table rows

Cloud file -> external stage --------> COPY INTO table -> table rows

Table/query -> COPY INTO location -> staged output files -> GET -> local files
```

- A **stage** identifies where files are stored.
- A **file format** describes how files are interpreted.
- A **table** stores rows.
- A **pipe** stores an ingestion definition:
  - A file-based Snowpipe pipe reads staged files.
  - A high-performance Snowpipe Streaming pipe can read incoming row data.
- **Remember:** staging a file does not insert its rows into a table.

Reference: [Overview of data loading](https://docs.snowflake.com/en/user-guide/data-load-overview).

### 3.1.2 File formats

#### A. Supported formats to recognize

- Common loading formats:
  - `CSV`, including other delimited text such as TSV.
  - `JSON`.
  - `AVRO`.
  - `ORC`.
  - `PARQUET`.
  - `XML`.
- Common unloading formats:
  - `CSV`.
  - `JSON`.
  - `PARQUET`.
- A file extension alone does not tell Snowflake how to parse every field.
- A reusable file format is a **schema-level object**.
- You can also put format options directly inside a `COPY` statement.

#### B. CSV options: learn the reason for each one

| Option | Simple meaning | Typical problem it solves |
| --- | --- | --- |
| `FIELD_DELIMITER` | Character between fields. | A TSV file uses a tab rather than a comma. |
| `SKIP_HEADER` | Skip a number of header lines. | Column labels should not become table data. |
| `FIELD_OPTIONALLY_ENCLOSED_BY` | Quote character around a field. | A name such as `"Min, Khant"` contains a comma. |
| `NULL_IF` | Text values that should become SQL `NULL`. | The source uses `NULL` or `\N` for missing data. |
| `EMPTY_FIELD_AS_NULL` | Treat an empty field as SQL `NULL`. | The source has empty values between delimiters. |
| `TRIM_SPACE` | Remove surrounding spaces from fields. | Source values contain unwanted spaces. |
| `ERROR_ON_COLUMN_COUNT_MISMATCH` | Check whether field count matches the expected structure. | A row has extra/missing fields. |
| `DATE_FORMAT` / `TIMESTAMP_FORMAT` | Explain the source date/time representation. | Dates are not in the expected layout. |
| `COMPRESSION` | Explain the file's compression. | The parser needs the correct decompression method. |

```sql
CREATE FILE FORMAT csv_orders_format
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('NULL', '\\N')
  EMPTY_FIELD_AS_NULL = TRUE;

SHOW FILE FORMATS;
DESCRIBE FILE FORMAT csv_orders_format;
```

- **Remember:** `SKIP_HEADER = 1` skips the header; it does not match source fields to target columns by name.
- `PARSE_HEADER = TRUE` is for header-based schema inference/name matching:
  - It is a different choice from `SKIP_HEADER`.
  - Do not set both in the same CSV format.
- `COMPRESSION = AUTO` handles supported detectable compression types; it is not a promise to detect every algorithm.

#### C. JSON options

- `STRIP_OUTER_ARRAY = TRUE`:
  - Turns the elements of a top-level JSON array into separate input records.
  - It does not flatten every nested array.
- `STRIP_NULL_VALUES = TRUE`:
  - Removes elements with JSON null values during parsing.
  - Use it only if removing those elements fits the meaning of the source.
- JSON `null` and SQL `NULL` are different:
  - A value inside `VARIANT` can represent JSON null.
  - A missing path can produce SQL `NULL`.
- Keep raw JSON in `VARIANT` when you want to retain a flexible payload.

```sql
CREATE FILE FORMAT json_events_format
  TYPE = JSON
  STRIP_OUTER_ARRAY = TRUE;
```

- **Exam clue:** a file contains `[{...}, {...}]` and each object should become a row -> consider `STRIP_OUTER_ARRAY`.

References: [CREATE FILE FORMAT](https://docs.snowflake.com/en/sql-reference/sql/create-file-format), [Loading semi-structured data](https://docs.snowflake.com/en/user-guide/semistructured-data-formats).

### 3.1.3 Internal stages and external stages

#### A. Internal stages

| Stage | How it is created | Reference | Useful when |
| --- | --- | --- | --- |
| User stage | Available automatically for a user. | `@~` | One user works with files. |
| Table stage | Available automatically for a table. | `@%orders` | Files belong to one table's loading workflow. |
| Named internal stage | Create it explicitly. | `@orders_stage` | Multiple users/tables need a reusable stage. |

- A user stage belongs to its user.
- User/table stages cannot be separately altered or dropped like named stages.
- Named stages can have configurable properties, grants, and a directory table.
- Files in an internal stage use Snowflake-managed storage.
- Table rows and staged files have separate lifecycles:
  - Loading the file does not automatically delete it.
  - Removing the file does not delete rows already loaded into a table.

```sql
CREATE STAGE orders_stage
  FILE_FORMAT = (FORMAT_NAME = 'csv_orders_format');

LIST @orders_stage;
LIST @~;
-- Requires an existing orders table and appropriate access:
LIST @%orders;
```

#### B. External stages

- A named external stage references cloud storage:
  - Amazon S3: `s3://bucket/path/`.
  - Google Cloud Storage: `gcs://bucket/path/`.
  - Azure: `azure://account.blob.core.windows.net/container/path/`.
- Creating an external stage does **not** copy all files into Snowflake.
- Use a **storage integration** for controlled access to private cloud storage.
- SQL grants and cloud IAM permissions must both allow the operation.
- **Remember:** external stage = reference to external files, not a second copy of those files.

```sql
-- Prerequisite: orders_s3_access already exists and its cloud trust is configured.
CREATE STAGE orders_external_stage
  URL = 's3://your-bucket/orders/'
  STORAGE_INTEGRATION = orders_s3_access
  FILE_FORMAT = (FORMAT_NAME = 'csv_orders_format');
```

References: [Choosing a stage](https://docs.snowflake.com/en/user-guide/data-load-local-file-system-create-stage), [CREATE STAGE](https://docs.snowflake.com/en/sql-reference/sql/create-stage).

### 3.1.4 PUT, GET, LIST, REMOVE, and DROP STAGE

1. **`PUT`:** upload a local file to an **internal** stage.
2. **`GET`:** download staged files from an **internal** stage to your computer.
3. **`LIST`:** list staged files.
4. **`REMOVE` / `RM`:** delete matching staged files:
   - Works with internal stages.
   - Can also delete external cloud files when the cloud identity has delete permission.
5. **`DROP STAGE`:** remove the named stage object:
   - Internal stage: its staged files are removed too.
   - External stage: external cloud files remain.

#### Run local file-transfer commands from a supported client

```sql
-- Snowflake CLI SQL execution, SnowSQL, or a supported driver:
-- replace /absolute/path with a real local path.
PUT file:///absolute/path/orders.csv @orders_stage
  AUTO_COMPRESS = TRUE;

GET @orders_stage file:///absolute/path/downloads/;
```

- These local-transfer commands do not work as ordinary Snowsight worksheet file access.
- Snowsight also provides supported UI upload/download workflows.
- Uploading to S3/Azure/GCS itself uses cloud tools or the appropriate supported service:
  - `PUT` is not an upload command for an external stage.
- With `AUTO_COMPRESS = TRUE`, an uncompressed uploaded CSV is normally compressed:
  - Check `LIST` before writing an exact filename in a later `COPY`.
- `OVERWRITE` controls replacement of a staged file:
  - It is different from whether table load history permits reloading.

```sql
LIST @orders_stage;

-- Deletes files, not loaded table rows. Review the path before running.
REMOVE @orders_stage/old_batch/;
```

- **Exam trap:** `DROP external stage` and `REMOVE files from external stage` do different things.
- **Remember:** `PUT/GET` move files between your computer and an internal stage; `COPY` moves data between files and tables.

References: [PUT](https://docs.snowflake.com/en/sql-reference/sql/put), [GET](https://docs.snowflake.com/en/sql-reference/sql/get), [REMOVE](https://docs.snowflake.com/en/sql-reference/sql/remove), [DROP STAGE](https://docs.snowflake.com/en/sql-reference/sql/drop-stage).

### 3.1.5 Server-side encryption

#### A. Internal stages

- **Server-side encryption:** the storage service encrypts files after receiving them.
- **Client-side encryption:** a client encrypts files before uploading them.
- Internal stage encryption choices:
  - `SNOWFLAKE_FULL`:
    - Client-side plus server-side encryption.
    - The default for named internal stages.
  - `SNOWFLAKE_SSE`:
    - Server-side encryption only.
    - Use this for internal-stage files that need pre-signed URL access.
- An internal stage's encryption type cannot be changed after creation.
- If Tri-Secret Secure is required, use `SNOWFLAKE_FULL`:
  - `SNOWFLAKE_SSE` does not support Tri-Secret Secure.

```sql
CREATE STAGE documents_stage
  ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
  DIRECTORY = (ENABLE = TRUE);
```

#### B. External stages

- External storage can use its cloud provider's server-side encryption.
- S3 examples include:
  - `AWS_SSE_S3`: S3-managed encryption.
  - `AWS_SSE_KMS`: AWS KMS-based encryption.
- A storage integration does not automatically give access to every encryption key.
- A KMS-protected object needs the appropriate key permissions as well as object access.
- **Remember:** permission to read an object and permission to decrypt it are related but separate checks.

```sql
-- Cloud-dependent example; replace the bucket/key and configure IAM first.
CREATE STAGE encrypted_orders_external_stage
  URL = 's3://your-bucket/encrypted-orders/'
  STORAGE_INTEGRATION = orders_s3_access
  ENCRYPTION = (
    TYPE = 'AWS_SSE_KMS'
    KMS_KEY_ID = 'your-kms-key-id'
  );
```

Reference: [Stage encryption parameters](https://docs.snowflake.com/en/sql-reference/sql/create-stage#internal-stage-parameters-internalstageparams).

### 3.1.6 Directory tables: a file inventory

- A **directory table** stores metadata about files in a stage.
- It is associated with the stage:
  - Enable it on a named internal or external stage.
  - It is not an independent table created with `CREATE TABLE`.
- Useful columns include:
  - `RELATIVE_PATH`.
  - `SIZE`.
  - `LAST_MODIFIED`.
  - `FILE_URL`.
- It does not parse the document's text or return CSV data rows.
- Metadata must be refreshed to reflect file changes:
  - Manual refresh is available.
  - Automatic refresh depends on the stage/provider and notification configuration.
- A directory table is not the same thing as an **external table**, which exposes file data as queryable columns.

```sql
ALTER STAGE documents_stage SET DIRECTORY = (ENABLE = TRUE);
ALTER STAGE documents_stage REFRESH;

SELECT RELATIVE_PATH, SIZE, LAST_MODIFIED, FILE_URL
FROM DIRECTORY(@documents_stage);
```

- To read a CSV's rows, query the stage with a file format instead:

```sql
SELECT
  METADATA$FILENAME AS SOURCE_FILE,
  METADATA$FILE_ROW_NUMBER AS SOURCE_ROW,
  f.$1,
  f.$2
FROM @orders_stage (FILE_FORMAT => 'csv_orders_format') f;
```

- **Remember:** `DIRECTORY(@stage)` describes files; `SELECT ... FROM @stage` parses supported data files.
- **Practice:** exercise 01 generates files and compares `LIST`, staged-file queries, and directory metadata.

References: [Directory tables](https://docs.snowflake.com/en/user-guide/data-load-dirtables), [Query staged-file metadata](https://docs.snowflake.com/en/user-guide/querying-metadata).

### 3.1.7 Bulk loading with `COPY INTO <table>`

1. Create or identify the target table.
2. Make files available through a stage or supported cloud URL.
3. Choose the file format.
4. Use a virtual warehouse.
5. Validate or load the files.
6. Check rows loaded and error details.

```sql
CREATE TABLE orders (
  order_id NUMBER,
  customer_name STRING,
  region STRING,
  amount NUMBER(12, 2),
  order_date DATE
);

COPY INTO orders
  FROM @orders_stage/incoming/
  FILE_FORMAT = (FORMAT_NAME = 'csv_orders_format');
```

- Bulk `COPY INTO <table>` uses a **virtual warehouse**.
- The target table normally exists before loading:
  - Schema inference can help create it, but a normal `COPY` is not a substitute for table creation.
- Source files remain staged unless a deletion option or separate cleanup removes them.
- By default, a load with an error uses `ON_ERROR = ABORT_STATEMENT`.

#### Choose the files to load

```sql
COPY INTO orders
  FROM @orders_stage/incoming/
  FILES = ('orders_01.csv.gz', 'orders_02.csv.gz')
  FILE_FORMAT = (FORMAT_NAME = 'csv_orders_format');

COPY INTO orders
  FROM @orders_stage/incoming/
  PATTERN = '.*[.]csv([.]gz)?$'
  FILE_FORMAT = (FORMAT_NAME = 'csv_orders_format');
```

- `FILES`:
  - Explicit filenames relative to the source location.
  - Useful when you know exactly which files belong to a batch.
- `PATTERN`:
  - A regular expression.
  - Useful when a filename rule defines the batch.
- Keep stage prefixes narrow:
  - Avoid scanning an entire bucket when only one date/source path is needed.
- Bulk `COPY` and Snowpipe can apply regex matching to different path portions:
  - Do not copy a complicated regex between them without checking the effective stage/pipe path.
- **Remember:** choosing files and parsing files are separate choices.

Reference: [COPY INTO table](https://docs.snowflake.com/en/sql-reference/sql/copy-into-table).

### 3.1.8 Duplicate handling and load metadata

- Snowflake tracks which files were loaded into a target table.
- Bulk loading metadata is kept for **64 days**, with rules for determining older files' status.
- Normal repeated `COPY` calls can skip an unchanged file already loaded into the same table.
- This is **file-load protection**, not general row deduplication:
  - A new file can contain business rows that already exist.
  - The same file can be loaded into a different target table.
  - A renamed file can be treated as a different source file.
- Do not assume primary-key declarations on standard tables prevent duplicate business rows.

#### Understand the override options

1. `FORCE = TRUE`:
   - Reloads files without using existing load metadata to skip them.
   - Can insert duplicate rows.
2. `LOAD_UNCERTAIN_FILES = TRUE`:
   - Tries files whose old load status cannot be determined.
   - Still uses available load metadata where possible.
3. `PURGE = TRUE`:
   - Requests removal of successfully loaded source files.
   - Changes file retention, not business-row uniqueness.
   - External deletion also needs cloud delete permissions.

```sql
-- Intentional reload only. This can duplicate previously loaded rows.
COPY INTO orders
  FROM @orders_stage/incoming/
  FILE_FORMAT = (FORMAT_NAME = 'csv_orders_format')
  FORCE = TRUE;
```

- When old metadata expires, Snowflake does **not** simply reload every old file:
  - An uncertain old file can be skipped by default to avoid an accidental reload.
- Recreating target tables or pipes changes the relevant object/history context.
- For a backfill:
  1. Define the exact file/date range.
  2. Check previous loads.
  3. Decide how duplicate business keys will be handled.
  4. Load and verify the result.
- **Remember:** `FORCE` is a reload instruction, not a duplicate-prevention feature.

Reference: [Load metadata and older files](https://docs.snowflake.com/en/user-guide/data-load-considerations-load#load-metadata).

### 3.1.9 Error handling: choose the outcome you need

| Option | Outcome | Use when |
| --- | --- | --- |
| `ABORT_STATEMENT` | Abort the load statement when an error is encountered. | The batch must not be partly accepted. |
| `CONTINUE` | Keep valid rows and report rejected rows. | Partial loading is acceptable and rejected rows are monitored. |
| `SKIP_FILE` | Reject an entire file if it contains an error. | A file should be accepted or rejected as a unit. |
| `SKIP_FILE_10` | Skip a file after the specified error-count threshold. | A count-based tolerance is intended. |
| `SKIP_FILE_10%` | Skip a file after the specified error-percentage threshold. | A percentage-based tolerance is intended. |

- The default for bulk `COPY INTO <table>` is `ABORT_STATEMENT`.
- `CONTINUE` does not repair a bad row:
  - It can leave missing business data in the target.
  - Inspect errors and decide how to correct/replay rejected records.
- `SKIP_FILE` can add work because Snowflake needs to evaluate file errors.
- Do not assume every ingestion architecture supports every bulk `COPY` option.

```sql
COPY INTO orders
  FROM @orders_stage/incoming/
  FILE_FORMAT = (FORMAT_NAME = 'csv_orders_format')
  ON_ERROR = CONTINUE;
```

#### A. Validate before loading

- `VALIDATION_MODE` checks files **without inserting rows**.
- Common modes:
  - `RETURN_ERRORS`: return validation errors.
  - `RETURN_ALL_ERRORS`: include all relevant errors, including files partly loaded earlier with `CONTINUE`.
  - `RETURN_10_ROWS`: preview parsed rows, stopping if an error is encountered.
- A row preview is not proof that every row in every file is valid.
- A transforming `COPY` cannot use `VALIDATION_MODE`.
- `MATCH_BY_COLUMN_NAME` also cannot be combined with `VALIDATION_MODE`.

```sql
COPY INTO orders
  FROM @orders_stage/incoming/
  FILE_FORMAT = (FORMAT_NAME = 'csv_orders_format')
  VALIDATION_MODE = RETURN_ERRORS;
```

#### B. Inspect a previous load

- `VALIDATE` reports errors from a previous bulk load.
- Keep the **COPY query ID**:
  - Use the ID returned by your client, or capture `LAST_QUERY_ID()` immediately after the `COPY`.
  - Running another statement first changes which query is "last."
- Do not treat `VALIDATE` as a way to test arbitrary transformation expressions:
  - Transformed loads have validation restrictions.
- For ordinary file-based Snowpipe errors, use `VALIDATE_PIPE_LOAD`.

```sql
-- Run immediately after the COPY being investigated:
SET previous_copy_id = LAST_QUERY_ID();

SELECT *
FROM TABLE(VALIDATE(
  orders,
  JOB_ID => $previous_copy_id
));
```

- **Remember:** `VALIDATION_MODE` checks before loading; `VALIDATE` investigates a previous load.
- **Practice:** exercise 01 compares validation, `CONTINUE`, and `SKIP_FILE` using the same bad file.

References: [COPY validation and error options](https://docs.snowflake.com/en/sql-reference/sql/copy-into-table), [VALIDATE](https://docs.snowflake.com/en/sql-reference/functions/validate), [VALIDATE_PIPE_LOAD](https://docs.snowflake.com/en/sql-reference/functions/validate_pipe_load).

### 3.1.10 Transform data during a load

- A `SELECT` inside `COPY INTO <table>` can:
  1. Select or reorder columns.
  2. Cast values.
  3. Trim or combine strings.
  4. Extract fields from JSON.
  5. Add supported file metadata.
- This is a **limited transformation query**, not a full SQL transformation pipeline.
- Do not use these inside the load transformation:
  - `JOIN`.
  - `GROUP BY` / aggregations.
  - `FLATTEN`.
  - `WHERE`.
  - `ORDER BY` or `LIMIT`.
- Do not combine the transforming `SELECT` with:
  - `MATCH_BY_COLUMN_NAME`.
  - `VALIDATION_MODE`.

```sql
CREATE TABLE orders_with_source (
  order_id NUMBER,
  customer_name STRING,
  region STRING,
  amount NUMBER(12, 2),
  order_date DATE,
  source_file STRING
);

COPY INTO orders_with_source
  FROM (
    SELECT
      f.$1::NUMBER,
      TRIM(f.$2),
      UPPER(f.$3),
      TRY_TO_DECIMAL(f.$4, 12, 2),
      f.$5::DATE,
      METADATA$FILENAME
    FROM @orders_stage/incoming/ f
  )
  FILE_FORMAT = (FORMAT_NAME = 'csv_orders_format');
```

- `TRY_TO_DECIMAL` returns SQL `NULL` when conversion fails:
  - Decide whether that is acceptable.
  - Do not silently replace important bad values with `NULL` without monitoring.
- Use `METADATA$START_SCAN_TIME` when you need supported scan/load-time metadata.
- **Exam clue:** reorder/cast fields while loading -> a COPY transformation.
- **Exam clue:** join, filter, flatten, or aggregate substantial business logic -> load raw data first, then transform it.
- General transformation syntax is covered more deeply in [Domain 4.4](../4-Performance-Optimization-Querying-and-Transformation/readme.md#44-perform-data-transformation-techniques).

Reference: [Transform data during a load](https://docs.snowflake.com/en/user-guide/data-load-transform).

### 3.1.11 Load semi-structured files

#### A. Keep the raw payload

- `VARIANT` can hold nested values such as objects and arrays.
- Raw loading is useful when:
  - Fields change over time.
  - You want to preserve the incoming payload.
  - Different consumers need different fields later.

```sql
CREATE TABLE raw_events (payload VARIANT);

COPY INTO raw_events
  FROM @orders_stage/events/
  FILE_FORMAT = (FORMAT_NAME = 'json_events_format');

SELECT
  payload:event_id::NUMBER AS event_id,
  payload:region::STRING AS region
FROM raw_events;
```

- JSON key names are case-sensitive.
- Casting makes the intended SQL type clear.
- Loading into `VARIANT` does not automatically create one relational column per JSON key.

#### B. Load known fields into typed columns

```sql
CREATE TABLE typed_events (event_id NUMBER, region STRING);

COPY INTO typed_events
  FROM (
    SELECT
      f.$1:event_id::NUMBER,
      f.$1:region::STRING
    FROM @orders_stage/events/ f
  )
  FILE_FORMAT = (FORMAT_NAME = 'json_events_format');
```

- **Remember:** raw `VARIANT` keeps flexibility; typed columns make a known schema explicit.
- **Practice:** exercise 01 loads two generated JSON records, then extracts typed fields.

Reference: [Loading JSON data](https://docs.snowflake.com/en/user-guide/semistructured-data-formats#json-data).

### 3.1.12 Schema detection versus schema evolution

#### A. Schema detection: discover the starting structure

1. Stage representative files.
2. Call `INFER_SCHEMA`.
3. Review inferred names and types.
4. Use `CREATE TABLE ... USING TEMPLATE` if the result is suitable.

- `INFER_SCHEMA` supports formats including Parquet, Avro, ORC, JSON, and CSV.
- For header-based CSV names, use `PARSE_HEADER = TRUE`.
- Inference is a proposal based on inspected files:
  - Check business meaning.
  - Check timestamps, decimals, case, and optional fields.
- It does not keep an existing table automatically synchronized with every future source file.

```sql
SELECT COLUMN_NAME, TYPE, NULLABLE, ORDER_ID
FROM TABLE(INFER_SCHEMA(
  LOCATION => '@orders_stage/new_source/',
  FILE_FORMAT => 'csv_header_format'
))
ORDER BY ORDER_ID;
```

#### B. Schema evolution: adapt an existing table during loading

- For file-based loading, the key requirements are:
  1. `ENABLE_SCHEMA_EVOLUTION = TRUE` on the target table.
  2. `MATCH_BY_COLUMN_NAME` in the `COPY`.
  3. `EVOLVE SCHEMA` or `OWNERSHIP` on the target table for the loading role.
- For CSV:
  - Use `PARSE_HEADER = TRUE`.
  - Set `ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE`.
- Supported evolution can:
  - Add new columns.
  - Drop a `NOT NULL` constraint when a later file lacks that column.
- Ordinary `INSERT` does not automatically evolve the table schema.
- High-performance Snowpipe Streaming has its own supported schema-evolution behavior.
- Do not assume every source type or incompatible type change is handled automatically.

```sql
ALTER TABLE evolving_customers SET ENABLE_SCHEMA_EVOLUTION = TRUE;

COPY INTO evolving_customers
  FROM @orders_stage/new_source/
  FILE_FORMAT = (FORMAT_NAME = 'csv_header_format')
  MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
```

- **Remember:** detection suggests the first schema; evolution changes an existing schema during supported ingestion.
- **Practice:** exercise 04 creates the input CSVs, infers the first schema, and adds `EMAIL` from a later file.

References: [INFER_SCHEMA](https://docs.snowflake.com/en/sql-reference/functions/infer_schema), [Automatic table schema evolution](https://docs.snowflake.com/en/user-guide/data-load-schema-evolution).

### 3.1.13 Unload data with `COPY INTO <location>`

1. Choose the table or query result.
2. Choose an internal stage, external stage, or supported cloud location.
3. Choose CSV, JSON, or Parquet output.
4. Decide whether you need multiple output files, one file, or partitioned paths.
5. Check the written files.

```sql
COPY INTO @orders_stage/exports/orders.csv
  FROM orders
  FILE_FORMAT = (TYPE = CSV COMPRESSION = NONE)
  HEADER = TRUE
  SINGLE = TRUE
  OVERWRITE = TRUE;
```

- Unloading uses a virtual warehouse.
- `SINGLE = TRUE`:
  - Requests one output file.
  - Give an explicit output filename/extension when needed.
  - Reduces the benefits of parallel output for large exports.
- `MAX_FILE_SIZE`:
  - A target size for generated output files.
  - Not an exact file size or a guaranteed hard upper bound.
- `OVERWRITE = TRUE`:
  - Replaces files whose names collide.
  - Does not mean "empty this whole output directory."
- For repeatable multi-file exports:
  - Use a new destination path per run, or
  - Use `INCLUDE_QUERY_ID = TRUE` with a compatible unload configuration.

#### A. Unload a query result

```sql
COPY INTO @orders_stage/exports/by_region/
  FROM (
    SELECT region, SUM(amount) AS total_amount
    FROM orders
    GROUP BY region
  )
  FILE_FORMAT = (TYPE = PARQUET)
  INCLUDE_QUERY_ID = TRUE;
```

- The `FROM (SELECT ...)` here is an **unload query**:
  - It can perform ordinary supported query transformations.
  - Do not confuse it with the restricted `SELECT` used when loading files.

#### B. Partition the output paths

```sql
COPY INTO @orders_stage/exports/by_day/
  FROM orders
  PARTITION BY ('order_date=' || TO_VARCHAR(order_date))
  FILE_FORMAT = (TYPE = PARQUET)
  INCLUDE_QUERY_ID = TRUE;
```

- `PARTITION BY` affects output file paths.
- Simply putting a path prefix in `COPY INTO @stage/path/` does not partition rows.
- Do not combine partitioned unloading with:
  - `SINGLE = TRUE`.
  - `OVERWRITE = TRUE`.
  - `INCLUDE_QUERY_ID = FALSE`.
- Partition values can appear in file paths and logs:
  - Use appropriate partition columns.
  - Avoid putting personal/sensitive identifiers in paths.

#### C. Export relational rows as JSON objects

```sql
COPY INTO @orders_stage/exports/json/
  FROM (
    SELECT OBJECT_CONSTRUCT(
      'order_id', order_id,
      'region', region,
      'amount', amount
    )
    FROM orders
  )
  FILE_FORMAT = (TYPE = JSON)
  INCLUDE_QUERY_ID = TRUE;
```

- `OBJECT_CONSTRUCT` turns each selected row into an object for JSON output.
- To download internal-stage output locally, use `GET` from a supported client.
- `GET` is not the command for downloading directly from an external stage.
- **Remember:** `COPY INTO table` loads rows; `COPY INTO location` writes files.

#### D. Unload directly to cloud storage

```sql
-- Optional cloud template: the integration and cloud write permissions
-- must already be configured. Replace the destination bucket/path.
COPY INTO 's3://your-bucket/orders/exports/'
  FROM orders
  STORAGE_INTEGRATION = orders_s3_access
  FILE_FORMAT = (TYPE = PARQUET)
  INCLUDE_QUERY_ID = TRUE;
```

- A named external stage can be used instead of writing the cloud URL inline.
- Storage, transfer, and cloud-side charges can be separate from warehouse compute.

References: [Overview of data unloading](https://docs.snowflake.com/en/user-guide/data-unload-overview), [COPY INTO location](https://docs.snowflake.com/en/sql-reference/sql/copy-into-location), [Unloading considerations](https://docs.snowflake.com/en/user-guide/data-unload-considerations).

### 3.1.14 File sizing, load history, and a troubleshooting order

#### A. File preparation

- As a general starting point, aim for roughly **100-250 MB compressed files**:
  - This is a recommendation, not a required file size.
  - Too many tiny files add scheduling/processing overhead.
  - One huge file can limit parallel work.
- For low-volume Snowpipe workloads:
  - Creating a smaller file about once per minute can be reasonable.
  - Do not wait indefinitely to fill a large file if freshness matters.
- Current Snowpipe pricing has **no per-file charge**:
  - File sizing still affects throughput and latency.
- A larger bulk-load warehouse is not automatically the cheapest or fastest answer:
  - Enough usable input files are needed for useful parallelism.
  - Compare load time and compute consumption.

Reference: [Preparing data files](https://docs.snowflake.com/en/user-guide/data-load-considerations-prepare).

#### B. Choose the correct history tool

| Tool | What it tells you |
| --- | --- |
| `INFORMATION_SCHEMA.COPY_HISTORY` table function | Recent file loads from bulk `COPY` and Snowpipe; up to 14 days. |
| `ACCOUNT_USAGE.COPY_HISTORY` view | Longer history for bulk and Snowpipe loads; historical data can be delayed. |
| `INFORMATION_SCHEMA.LOAD_HISTORY` view | Bulk `COPY` load history; not the main Snowpipe history tool. |
| `VALIDATE` | Errors from a previous bulk `COPY` job. |
| `VALIDATE_PIPE_LOAD` | Errors from supported Snowpipe file-load attempts. |
| `SYSTEM$PIPE_STATUS` | Current pipe execution/queue status. |

```sql
SELECT
  file_name,
  status,
  row_count,
  error_count,
  first_error_message
FROM TABLE(D3_STUDY.INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'D3_STUDY.LAB.D3_PARTIAL_ORDERS',
  START_TIME => DATEADD('hour', -24, CURRENT_TIMESTAMP())
))
ORDER BY last_load_time DESC;
```

- Load metadata used for duplicate protection and a history view's reporting window are **different things**.
- Do not confuse:
  - **64 days:** bulk-load metadata.
  - **14 days:** the recent `COPY_HISTORY` table-function window; also a separate Snowpipe pipe-metadata period.
  - **7 days:** recently staged files eligible for `ALTER PIPE ... REFRESH`.
- A recent failed or aborted statement might need investigation in **Query History**, not only file-load history.

#### C. Troubleshoot in this order

1. **Connection and session context**
   - Correct account, role, database, schema, and warehouse?
2. **Access**
   - Correct table/stage/file-format grants?
   - For external storage: correct cloud trust, object permissions, and encryption-key access?
3. **File discovery**
   - Does `LIST @stage/path/` show the expected files?
   - Do stage prefix, `FILES`, and `PATTERN` select the intended files?
4. **Parsing**
   - Correct delimiter, quotes, header, compression, and date formats?
5. **Conversion**
   - Do source values fit the target data types?
6. **Load state**
   - Was the file already loaded, skipped, partly loaded, or rejected?
7. **Compute or automation**
   - Is the warehouse available?
   - For Snowpipe: did the event reach the pipe, and is the pipe running?

References: [COPY_HISTORY function](https://docs.snowflake.com/en/sql-reference/functions/copy_history), [COPY_HISTORY view](https://docs.snowflake.com/en/sql-reference/account-usage/copy_history), [LOAD_HISTORY](https://docs.snowflake.com/en/sql-reference/info-schema/load_history).

---

## 3.2 Perform Automated Data Ingestion

### 3.2.1 Choose the right pipeline feature

| Requirement | Feature | Simple job description |
| --- | --- | --- |
| Load a known batch of files now. | Bulk `COPY INTO <table>` | Load these files using my warehouse. |
| Load newly arriving files continuously. | Snowpipe | Load files when the pipe is notified. |
| Ingest a continuous flow of rows without staged files. | Snowpipe Streaming | Send rows through a streaming client/API. |
| Identify table changes since a previous processing point. | Stream | Show the net changes after my offset. |
| Run SQL/procedure logic on a schedule or trigger. | Task | Run this work when its condition/schedule allows. |
| Maintain the stored result of a SQL query. | Dynamic Table | Keep this query result reasonably fresh. |
| Connect and route data from many source systems. | Openflow | Build a managed integration flow. |

- A **Stream** does not upload external events by itself.
- A **Task** does not automatically discover cloud files unless its SQL does that work.
- Snowpipe and Snowpipe Streaming ingest data.
- Streams, Tasks, and Dynamic Tables are often used **after ingestion** to process that data.
- **Remember:** a pipeline can combine features rather than choosing exactly one for everything.

### 3.2.2 Snowpipe: continuous file ingestion

#### A. The normal cloud-event pattern

1. A source writes a new file into cloud storage.
2. The cloud sends an event notification.
3. Snowpipe receives notification of the file.
4. The pipe's `COPY INTO` definition tells Snowflake how to load it.
5. Snowflake-managed compute inserts rows into the target table.

```text
Source -> cloud files -> cloud event -> Snowpipe -> raw table
```

- Common notification systems include:
  - AWS S3 notifications and SNS/SQS.
  - Azure Event Grid.
  - Google Cloud Pub/Sub.
- Snowpipe uses **serverless compute**, not your selected virtual warehouse.
- Files are loaded asynchronously:
  - Query availability is usually within minutes.
  - It is not a fixed per-file latency guarantee.
- Do not depend on files loading in arrival or alphabetical order.

#### B. Define a file-based pipe

```sql
-- Cloud-dependent example:
-- 1. Create/configure the storage integration and external stage first.
-- 2. Configure the cloud notification route.
-- 3. Then send new files through that route.
CREATE PIPE orders_pipe
  AUTO_INGEST = TRUE
AS
  COPY INTO orders
    FROM @orders_external_stage/incoming/
    FILE_FORMAT = (FORMAT_NAME = 'csv_orders_format')
    ON_ERROR = CONTINUE;

SHOW PIPES LIKE 'ORDERS_PIPE';
DESCRIBE PIPE orders_pipe;
```

- The example is the pipe definition, **not complete cloud setup**.
- `AUTO_INGEST = TRUE` does not create all cloud-side event permissions for you.
- The stage URL and the pipe's additional path combine:
  - Stage: `s3://bucket/orders/`.
  - Pipe source: `@stage/incoming/`.
  - Effective location: `s3://bucket/orders/incoming/`.
- Existing files do not become a complete backfill merely because a new pipe exists.
- Current Snowflake also has provider-specific internal-stage auto-ingest support in preview:
  - Do not treat a newer preview example as the universal cloud-event setup.

#### C. Notify through the Snowpipe REST API

- Another pattern uses `AUTO_INGEST = FALSE`.
- The client submits staged filenames through Snowpipe's `insertFiles` endpoint.
- This tells Snowpipe **which existing staged files to load**:
  - It does not upload local file bytes.
  - It is not the same API as row-based Snowpipe Streaming.
- Supported staging choices include named internal stages and external stages.
- Authentication and the relevant stage/table/pipe privileges are still required.

References: [Snowpipe overview](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-intro), [Automating Snowpipe](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-auto), [Snowpipe REST API](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-rest-overview), [CREATE PIPE](https://docs.snowflake.com/en/sql-reference/sql/create-pipe).

#### D. Monitor, pause, and resume

```sql
SELECT SYSTEM$PIPE_STATUS('D3_STUDY.LAB.ORDERS_PIPE');

ALTER PIPE orders_pipe SET PIPE_EXECUTION_PAUSED = TRUE;
ALTER PIPE orders_pipe SET PIPE_EXECUTION_PAUSED = FALSE;

SELECT *
FROM TABLE(D3_STUDY.INFORMATION_SCHEMA.VALIDATE_PIPE_LOAD(
  PIPE_NAME => 'D3_STUDY.LAB.ORDERS_PIPE',
  START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())
));
```

- Inspect:
  - `executionState`.
  - `pendingFileCount`.
  - Notification timestamps and errors where reported.
  - `COPY_HISTORY` for the target table.
- A growing queue is a symptom:
  - Check pipe state, event delivery, cloud access, parsing, and target conversion.
  - Increasing your BI warehouse does not add Snowpipe compute.
- Validation functions have restrictions for transformed pipe definitions:
  - Do not assume `VALIDATE_PIPE_LOAD` can evaluate every transformation.
- Pausing prevents new file loads from starting:
  - An in-progress file load can finish.
  - Notifications can still add files to the queue.

#### E. Duplicate protection and recovery

- Snowpipe keeps pipe-level file-load metadata for **14 days**.
- During that period, reusing the same file path/name can be ignored:
  - Even if the contents were corrected.
  - This can also affect previously failed files.
- Prefer unique filenames for new deliveries.
- Treat replay/backfill as planned operations, not random retries.
- `ALTER PIPE ... REFRESH`:
  - Queues eligible files that were not loaded.
  - Only handles files staged within the last **7 days**.
  - Is for short-term recovery, not a permanent ingestion schedule.
- A pipe paused for longer than 14 days can become stale:
  - Check what queued files may have been lost.
  - The owner can use `SYSTEM$PIPE_FORCE_RESUME` with the documented override.
  - Force-resuming does not restore files/events that have expired from the queue.
- Recreating a pipe removes its previous pipe-load metadata:
  - A broad refresh afterward can reload old files and duplicate data.

```sql
-- Recovery example: use a narrow prefix for the intended recent files.
ALTER PIPE orders_pipe REFRESH PREFIX = 'recovery_batch/';

-- Only after investigating a stale pipe and planning missed-file recovery:
-- SELECT SYSTEM$PIPE_FORCE_RESUME(
--   'D3_STUDY.LAB.ORDERS_PIPE',
--   'staleness_check_override'
-- );
```

#### F. Current cost model

- Snowpipe charges credits by **data volume loaded**.
- Text formats such as CSV/JSON/XML:
  - Billed on uncompressed size.
- Binary formats such as Parquet/Avro/ORC:
  - Billed on size in storage, also called observed size.
- There is **no current per-file fee**:
  - Older lessons may describe a per-core/per-second plus per-1,000-files model.
  - File count and size still affect performance.
- Warehouse resource monitors do not control Snowpipe spending.
- Use appropriate budget/usage monitoring; see [Domain 2.3](../2-Account-Management-and-Data-Governance/readme.md#23-monitoring-and-cost-management).
- **Remember:** Snowpipe loads notified files with managed compute; a pipe is not a user-managed warehouse.

References: [Troubleshooting Snowpipe](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-ts), [Manage Snowpipe](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-manage), [ALTER PIPE](https://docs.snowflake.com/en/sql-reference/sql/alter-pipe), [Snowpipe costs](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-billing).

### 3.2.3 Snowpipe Streaming: ingest rows without staged files

#### A. What changes compared with file-based Snowpipe?

- A client sends **rows** through a supported SDK or REST API.
- There is no intermediate staged data file in the normal streaming path.
- Typical use cases:
  - Application events.
  - IoT measurements.
  - Kafka messages.
  - Source CDC records delivered by an upstream system.
- Snowflake manages ingestion compute.
- Seconds-level query availability is a design goal, not an unconditional latency promise.

```text
Application/Kafka -> streaming SDK or REST API -> Snowflake table
```

#### B. Channels, ordering, and recovery

- A **Named Channel** identifies a stream of submitted rows.
- Ordering is associated with the channel:
  - Do not assume one global order across all channels.
- An **offset token** records a source position associated with committed ingestion.
- For reliable recovery:
  1. Keep source records in a durable source such as Kafka.
  2. Read the last committed offset token.
  3. Resume at the next uncommitted source position.
  4. Handle retryable errors and validate progress.
- Exactly-once delivery requires correct client/source offset handling:
  - Snowflake does not make every repeated business event unique.
  - Losing the client's uncommitted in-memory buffer is not fixed by an offset token alone.
- Different channel types/architectures can have different guarantees:
  - Learn the Named Channel/offset idea.
  - Check the SDK/API contract used by a real implementation.

#### C. Classic versus high-performance architecture

- Older material can describe **Snowpipe Streaming Classic**.
- Current **high-performance architecture** includes:
  - Managed high-throughput ingestion.
  - Volume-based ingestion billing.
  - Custom streaming pipes for supported in-flight transformations.
  - Supported schema-evolution options.
- Do not assume every Classic SDK option or every bulk `COPY` option applies unchanged.
- Deep SDK installation/version details are implementation work; the central exam distinction is **files versus rows**.

#### D. A streaming pipe definition

```sql
-- Optional architecture example: no rows are sent by this DDL alone.
CREATE TABLE streaming_events (
  event_id NUMBER,
  region STRING,
  amount NUMBER(12, 2)
);

CREATE PIPE streaming_events_pipe
AS
  COPY INTO streaming_events (event_id, region, amount)
    FROM (
      SELECT
        $1:event_id::NUMBER,
        $1:region::STRING,
        $1:amount::NUMBER(12, 2)
      FROM TABLE(DATA_SOURCE(TYPE => 'STREAMING'))
    );
```

- The source is `DATA_SOURCE(TYPE => 'STREAMING')`, not `@stage`.
- `AUTO_INGEST = TRUE` and a stage file format are not how this pipe receives rows.
- Creating the pipe does not open a client channel or send data.
- An SDK/REST client must still authenticate, open the appropriate channel, and submit rows.
- Use ordinary `SELECT` to verify rows after the client commits ingestion.
- **Remember:** Snowpipe = staged files; Snowpipe Streaming = direct row ingestion.

References: [Snowpipe Streaming](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/data-load-snowpipe-streaming-overview), [Streaming CREATE PIPE](https://docs.snowflake.com/en/sql-reference/sql/create-pipe#pipes-for-snowpipe-streaming-with-high-performance-architecture), [High-performance best practices](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-high-performance-best-practices), [Streaming error handling and offsets](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-high-performance-error-handling).

### 3.2.4 Streams: remember a processing position

#### A. What a Stream stores

- A Stream tracks **Change Data Capture (CDC)** information for a supported source object.
- Its central state is an **offset**:
  - A point in the source's version history.
  - Used to return changes after that point.
- A Stream is not a separate stored copy of all source rows.
- It exposes source columns plus change metadata.
- It does not ingest external data by itself.
- Source examples include supported tables, views, and directory tables.

#### B. Stream types

| Type | Captures | Typical fit |
| --- | --- | --- |
| Standard stream | Net inserts, updates, and deletes. | Maintain a downstream table when source rows change. |
| Append-only stream | Inserts only; does not track update/delete changes. | Process immutable event rows appended to a table. |
| Insert-only stream | New-file row information for supported external-table sources. | Process external-table file arrivals; not full row-by-row update/delete CDC. |

```sql
CREATE STREAM order_changes ON TABLE raw_orders;

CREATE STREAM new_order_events
  ON TABLE raw_order_events
  APPEND_ONLY = TRUE;
```

- Normally, a newly created stream begins at the source's current version:
  - It does not automatically return all older rows.
  - `SHOW_INITIAL_ROWS = TRUE` is an explicit initialization option for supported streams.
- Source change tracking and the relevant ownership/`SELECT` privileges matter.

#### C. Read the metadata columns

- `METADATA$ACTION`:
  - `INSERT` or `DELETE`.
- `METADATA$ISUPDATE`:
  - Whether this record is part of an update.
- `METADATA$ROW_ID`:
  - A stable identifier for the source row.
- A standard stream can represent an update with:
  - A `DELETE` record for the old value.
  - An `INSERT` record for the new value.
  - Both marked `METADATA$ISUPDATE = TRUE`.
- Streams show **net changes between offsets**, not every intermediate event:
  - A new row inserted and then deleted within the unconsumed window can disappear from the net result.
  - A new row inserted and then updated can appear as one final insertion.
- Do not use a Stream as an automatic complete audit log of every source transition.

```sql
SELECT
  order_id,
  amount,
  METADATA$ACTION AS change_action,
  METADATA$ISUPDATE AS is_update,
  METADATA$ROW_ID AS row_id
FROM order_changes;
```

#### D. What advances the offset?

1. `SELECT` alone:
   - Does **not** advance it.
   - You can inspect the same change set repeatedly.
2. Committed DML that consumes the stream:
   - Advances it.
   - Examples include `INSERT ... SELECT FROM stream` and `MERGE ... USING stream`.
3. Rolled-back DML:
   - Does **not** permanently advance it.
4. A filter in a consuming DML statement:
   - Does not create an independent offset for each selected row.
   - Do not assume filtered-out changes remain available afterward.

```sql
-- Inspect only: changes remain available.
SELECT * FROM order_changes;

-- Consume when this DML transaction commits:
INSERT INTO processed_orders (order_id, amount)
SELECT order_id, amount
FROM order_changes
WHERE METADATA$ACTION = 'INSERT';
```

- The short `INSERT` example is an insert-processing pattern:
  - It is not a complete upsert/delete replication solution.
  - Exercise 02 includes a controlled `MERGE` example that handles source updates and deletes.
- Create **separate streams for independent consumers**:
  - One consumer's commit must not move another consumer's bookmark.

#### E. Staleness and checking for work

- A stream needs source change history to interpret its offset.
- If that history is no longer retained, it can become **stale**.
- Inspect `SHOW STREAMS`, including staleness information such as `STALE_AFTER`.
- Consume changes before the needed history expires.
- Recreating a stale stream at the current point does not recover old changes automatically.
- `SYSTEM$STREAM_HAS_DATA`:
  - Useful as a Task condition.
  - Can return `TRUE` even when the stream query has no rows.
  - Is not an exact count of pending business events.
- If it returns a false positive, the consuming DML can still advance the offset:
  - Simply doing another `SELECT` does not consume it.

```sql
SHOW STREAMS;
SELECT SYSTEM$STREAM_HAS_DATA('D3_STUDY.LAB.D3_TASK_INSERTS');
```

- **Remember:** Stream = offset + net change records; committed consumption moves the offset.
- **Practice:** exercise 02 checks repeated reads, committed consumption, an update pair, a delete, and rollback.

References: [Introduction to Streams](https://docs.snowflake.com/en/user-guide/streams-intro), [CREATE STREAM and metadata](https://docs.snowflake.com/en/sql-reference/sql/create-stream), [SYSTEM$STREAM_HAS_DATA](https://docs.snowflake.com/en/sql-reference/functions/system_stream_has_data).

### 3.2.5 Tasks: run the work

#### A. What a Task does

- A Task runs a SQL statement:
  - The statement can load or transform data.
  - It can call a stored procedure.
  - Supported Snowflake Scripting can express multiple steps.
- A stored procedure defines reusable logic.
- A Task supplies scheduled or triggered execution of that logic.
- A Stream supplies the change set; a Task processes it.

#### B. Choose the compute

1. **User-managed Task**
   - Specify `WAREHOUSE = ...`.
   - The Task uses that virtual warehouse.
   - Warehouse size, auto-resume, availability, and access matter.
2. **Serverless Task**
   - Do not specify `WAREHOUSE`.
   - Snowflake manages compute.
   - `USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE` can guide initial sizing for a scheduled Task.
   - That initial size is not a permanent fixed warehouse allocation.

#### C. Schedule a Task

```sql
-- Prerequisites: tables/warehouse exist; task owner has the needed privileges.
CREATE TASK hourly_order_summary
  WAREHOUSE = D3_STUDY_WH
  SCHEDULE = '60 MINUTES'
AS
  INSERT INTO order_summary_log
  SELECT CURRENT_TIMESTAMP(), COUNT(*)
  FROM orders;
```

- Newly created or cloned Tasks start **suspended**.
- To enable future scheduled runs:

```sql
ALTER TASK hourly_order_summary RESUME;

-- Later, stop future automatic runs:
ALTER TASK hourly_order_summary SUSPEND;
```

- A cron schedule includes a timezone:
  - Example: `SCHEDULE = 'USING CRON 0 9 * * * UTC'`.
  - Know the intended timezone rather than assuming the client laptop's clock.
- Do not assume a scheduled Task creates unlimited overlapping executions when a run is slow.
- For one manual run:

```sql
EXECUTE TASK hourly_order_summary;
```

- `EXECUTE TASK` submits a run asynchronously.
- It can run a standalone suspended Task without enabling its future schedule.
- Suspending a Task does not by itself cancel SQL that is already executing.

References: [Introduction to Tasks](https://docs.snowflake.com/en/user-guide/tasks-intro), [CREATE TASK](https://docs.snowflake.com/en/sql-reference/sql/create-task), [EXECUTE TASK](https://docs.snowflake.com/en/sql-reference/sql/execute-task).

#### D. Trigger a Task when a Stream has changes

```sql
CREATE TASK process_new_order_events
  WAREHOUSE = D3_STUDY_WH
  WHEN SYSTEM$STREAM_HAS_DATA('D3_STUDY.LAB.D3_TASK_INSERTS')
AS
  INSERT INTO D3_STUDY.LAB.D3_TASK_TARGET (order_id, region, amount)
  SELECT order_id, region, amount
  FROM D3_STUDY.LAB.D3_TASK_INSERTS;
```

- A triggered Task omits `SCHEDULE`.
- `WHEN` identifies the stream condition.
- The Task body must consume the appropriate changes correctly.
- A scheduled Task can also have a `WHEN` condition:
  - The schedule determines when to check.
  - The condition determines whether to do the work.
- A **serverless triggered Task** has additional configuration:
  - Omit `WAREHOUSE`.
  - Set `TARGET_COMPLETION_INTERVAL`.
  - Keep the appropriate `WHEN` condition.

```sql
-- Alternative to the user-managed triggered Task; do not enable both
-- as independent consumers of the same stream.
CREATE TASK process_new_order_events_serverless
  TARGET_COMPLETION_INTERVAL = '5 MINUTES'
  WHEN SYSTEM$STREAM_HAS_DATA('D3_STUDY.LAB.D3_TASK_INSERTS')
AS
  INSERT INTO D3_STUDY.LAB.D3_TASK_TARGET (order_id, region, amount)
  SELECT order_id, region, amount
  FROM D3_STUDY.LAB.D3_TASK_INSERTS;
```

- The completion interval guides serverless sizing:
  - It is not a command to wait exactly five minutes before checking the stream.
- **Remember:** a Stream identifies changes; a Task runs processing; each needs correct permissions.

Reference: [Triggered Tasks](https://docs.snowflake.com/en/user-guide/tasks-triggered).

#### E. Task graphs

- A **Task graph** connects Tasks through dependencies.
- Normal pattern:
  1. Root Task has a schedule.
  2. Child Tasks use `AFTER`.
  3. A child waits for its predecessor dependencies to finish successfully.
- Graph Tasks must share the same owner role and schema.
- Resume child Tasks before enabling the root.
- Keep the root suspended while making required structural changes.

```sql
-- Illustration: create the log table first.
CREATE TABLE task_graph_log (step STRING, run_at TIMESTAMP_LTZ);

CREATE TASK root_ingestion_check
  WAREHOUSE = D3_STUDY_WH
  SCHEDULE = '60 MINUTES'
AS
  INSERT INTO task_graph_log VALUES ('root', CURRENT_TIMESTAMP());

CREATE TASK downstream_quality_check
  WAREHOUSE = D3_STUDY_WH
  AFTER root_ingestion_check
AS
  INSERT INTO task_graph_log VALUES ('child', CURRENT_TIMESTAMP());

-- Optional activation:
-- ALTER TASK downstream_quality_check RESUME;
-- ALTER TASK root_ingestion_check RESUME;

-- Stop the root's future schedule when finished:
-- ALTER TASK root_ingestion_check SUSPEND;
-- ALTER TASK downstream_quality_check SUSPEND;
```

- **Exam clue:** "run B only after A succeeds" -> Task dependencies.
- Do not give a child an unrelated timer when the requirement is dependency order.

Reference: [Task graphs](https://docs.snowflake.com/en/user-guide/tasks-graphs).

### 3.2.6 Task permissions and troubleshooting

#### A. Task owner privileges

- The owner normally needs:
  1. `USAGE` on the database and schema.
  2. `CREATE TASK` on the schema to create the Task.
  3. The table/stage/procedure privileges needed by the Task body.
  4. `EXECUTE TASK` on the account to run owned Tasks.
  5. `USAGE` on the selected warehouse for a user-managed Task.
  6. `EXECUTE MANAGED TASK` on the account for a serverless Task.
- Default execution uses the Task owner role's privileges:
  - Your interactive session succeeding with extra roles does not prove the Task owner can run the same SQL.
- Granting operation rights to another role does not supply missing SQL privileges to the owner.

```sql
-- Administrator example; use a real existing dedicated Task owner role.
GRANT EXECUTE TASK ON ACCOUNT TO ROLE pipeline_owner;

-- Additional privilege only for managed/serverless Task compute:
GRANT EXECUTE MANAGED TASK ON ACCOUNT TO ROLE pipeline_owner;
```

#### B. Find why a Task did not run

1. Check `SHOW TASKS`:
   - Suspended or started?
   - Correct warehouse, schedule, and condition?
2. Check `TASK_HISTORY`:
   - Scheduled, executing, succeeded, failed, canceled, or skipped?
   - What is the error message/query ID?
3. Check the Task owner role:
   - Account execution privilege?
   - Warehouse and data privileges?
4. Check the Stream:
   - Stale?
   - Already consumed by another process?
   - `SYSTEM$STREAM_HAS_DATA` false positive?
5. Check the SQL separately under the correct role.

```sql
SELECT
  name, state, query_id, error_code, error_message, scheduled_time
FROM TABLE(D3_STUDY.INFORMATION_SCHEMA.TASK_HISTORY(
  TASK_NAME => 'D3_PROCESS_NEW_ORDERS',
  SCHEDULED_TIME_RANGE_START => DATEADD('hour', -24, CURRENT_TIMESTAMP()),
  RESULT_LIMIT => 100
))
ORDER BY scheduled_time DESC;
```

- In `TASK_HISTORY`, `TASK_NAME` takes an **unqualified** Task name.
- The recent Information Schema function covers the last seven days.
- Longer Account Usage history can have reporting latency.
- Warehouse resource monitors can stop user-managed Task compute through the warehouse:
  - They do not control serverless Task spending.
- **Practice:** exercise 02 creates a paused triggered Task and provides an optional one-time run.

References: [Task security](https://docs.snowflake.com/en/user-guide/tasks-intro#task-security), [TASK_HISTORY](https://docs.snowflake.com/en/sql-reference/functions/task_history).

### 3.2.7 Dynamic Tables: define the desired result

#### A. The main idea

- A **Dynamic Table** stores the result of a SQL query.
- You define the result with `SELECT`.
- Snowflake manages refreshes to meet a freshness goal.
- The normal pipeline does not require you to write your own Stream, Task, and `MERGE` for every refresh step.
- It uses a specified virtual warehouse for refresh compute.
- It is useful for maintained transformation results:
  - Cleaned rows.
  - Joins.
  - Aggregations.
  - Multi-step SQL transformation pipelines, within supported query rules.

```sql
CREATE DYNAMIC TABLE region_totals
  TARGET_LAG = '10 minutes'
  WAREHOUSE = D3_STUDY_WH
  REFRESH_MODE = INCREMENTAL
  INITIALIZE = ON_CREATE
AS
  SELECT
    region,
    COUNT(*) AS order_count,
    SUM(amount) AS total_amount
  FROM orders
  GROUP BY region;
```

#### B. TARGET_LAG is a freshness goal

- `TARGET_LAG = '10 minutes'` means:
  - Aim to keep the result within that source-data freshness goal.
  - Snowflake chooses when to schedule refreshes.
- It does **not** mean:
  - Run exactly at minute 00, 10, 20, and so on.
  - Every refresh finishes in ten minutes.
  - Freshness can never exceed the target.
- Slow refreshes or failures can produce more lag than requested.
- The minimum time-based target lag is **60 seconds**.
- `TARGET_LAG = DOWNSTREAM`:
  - Lets downstream Dynamic Tables drive refresh needs.
  - A pipeline still needs an appropriate downstream refresh requirement to drive automatic work.

#### C. Refresh modes and initialization

- `INCREMENTAL`:
  - Processes changes using supported incremental refresh operations.
  - Creation fails if the query cannot use the requested incremental mode.
- `FULL`:
  - Recomputes the whole result.
- `AUTO`:
  - Snowflake chooses the refresh mode at creation.
  - Do not assume it switches between full and incremental on every refresh.
- `SHOW DYNAMIC TABLES` reports the resolved mode.
- `INITIALIZE = ON_CREATE`:
  - Initializes during creation.
  - Can immediately consume warehouse compute.
- `INITIALIZE = ON_SCHEDULE`:
  - Defers initialization to a scheduled refresh.

- **Optional current-documentation detail; not a separate named C03 objective:**
  - `ADAPTIVE` refresh can process incrementally and reinitialize when that is more efficient.
  - `CUSTOM_INCREMENTAL` lets advanced pipelines define their own refresh logic.
  - Learn the core freshness/compute/mode distinctions first; this lab explicitly uses `INCREMENTAL`.

References: [Create a Dynamic Table](https://docs.snowflake.com/en/user-guide/dynamic-tables/create), [Target lag](https://docs.snowflake.com/en/user-guide/dynamic-tables/target-lag), [Refresh modes](https://docs.snowflake.com/en/user-guide/dynamic-tables/refresh-modes).

#### D. Operational controls

```sql
SHOW DYNAMIC TABLES LIKE 'REGION_TOTALS';

ALTER DYNAMIC TABLE region_totals SUSPEND;
ALTER DYNAMIC TABLE region_totals REFRESH;
-- Optional: re-enable future automatic refreshes.
-- ALTER DYNAMIC TABLE region_totals RESUME;
```

- `SUSPEND` stops scheduled refreshes:
  - Stored results remain queryable.
  - Storage remains allocated.
- A manual `REFRESH` is supported even while scheduling is suspended.
- Suspending a warehouse alone does not permanently disable Dynamic Table refresh scheduling:
  - A permitted scheduled refresh can resume an auto-resumable warehouse.
- Inspect refresh history rather than assuming a changed source is already reflected in the result.
- Maintain the needed owner-role privileges and source change tracking.
- **Practice:** exercise 03 suspends scheduling, changes source data, then manually refreshes.

#### E. Choose Dynamic Tables versus Streams and Tasks

- Choose **Dynamic Tables** when:
  - The result can be described by supported SQL.
  - You want Snowflake to manage refresh dependencies.
  - Freshness is the main requirement.
- Choose **Streams and Tasks** when:
  - You need explicit `MERGE`/`DELETE` processing into an ordinary target table.
  - You need procedure calls, conditional steps, or side effects.
  - You need direct control of the processing workflow.
- A Dynamic Table:
  - Stores data, unlike a standard view.
  - Is maintained by refresh operations.
  - Is not normally a target for your own `INSERT`, `UPDATE`, or `DELETE` statements.
- A materialized view is also stored/maintained, but has different query restrictions and optimizer behavior:
  - Do not assume Dynamic Tables and materialized views are interchangeable.
  - Use [Domain 1 table/view notes](../1-Snowflake-AI-Data-Cloud-Features-and-Architecture/05-storage-tables-and-views.md) for that broader comparison.
- **Remember:** Streams and Tasks describe processing steps; a Dynamic Table describes the result to maintain.

References: [Manage Dynamic Tables](https://docs.snowflake.com/en/user-guide/dynamic-tables/manage), [Dynamic Tables versus other features](https://docs.snowflake.com/en/user-guide/dynamic-tables/decision-guide), [Refresh history](https://docs.snowflake.com/en/sql-reference/functions/dynamic_table_refresh_history).

### 3.2.8 Openflow: connect source systems and build flows

#### A. What to know

- **Snowflake Openflow** is a data-integration service built on **Apache NiFi**.
- It connects sources and destinations using connectors and processors.
- A flow can:
  1. Read data from a source.
  2. Route or transform it.
  3. Deliver it to a destination.
  4. Track operational state and errors.
- Source examples include supported databases, SaaS systems, and file/event sources.
- Individual connector capabilities vary:
  - Do not assume every connector supports every database or CDC mode.

#### B. Keep the exam caveat accurate

- The supplied C03 guide lists:
  - **Openflow**, with the condition that it will not be tested until globally GA.
- Current official overview documentation marks the platform **Generally Available**:
  - It lists Snowflake Deployments across AWS, Azure, and GCP commercial regions.
  - BYOC and individual generation/connector capabilities have their own availability limits.
- Include the core concept in your preparation:
  - Do not assume it is permanently excluded because an older course called it preview.
  - Platform GA does not mean every connector or newer option is GA.
- The live exam guide and Snowflake's certification announcements determine exam scope.

#### C. Why there is no pretend one-command exercise here

- A useful Openflow exercise needs:
  - A supported deployment/runtime.
  - A source system and its access configuration.
  - A connector/flow configuration.
  - Network and credential setup.
- A running runtime can have compute costs independently of a SQL warehouse.
- Use the official setup guide when you have an appropriate source/runtime.
- **Remember:** Openflow moves/connects data across systems; a Stream tracks changes inside a supported Snowflake source.

References: [About Openflow](https://docs.snowflake.com/en/user-guide/data-integration/openflow/about), [Openflow setup](https://docs.snowflake.com/en/user-guide/data-integration/openflow/gen2/quickstart), [Openflow release history](https://docs.snowflake.com/en/user-guide/data-integration/openflow/version-history).

---

## 3.3 Connectors, Drivers, and Integrations

### 3.3.1 Separate a client library from an integration object

- A **driver/connector** lets a client, application, or platform work with Snowflake.
- An **integration object** stores controlled configuration for a type of access.
- Integration objects do not replace:
  - User authentication.
  - Role/object privileges.
  - Cloud-side trust and permissions.
- Most integrations discussed here are account-level objects.
- Stages, file formats, pipes, and Git repository objects are schema-level objects.
- **Remember:** a connector is a way to communicate; an integration defines an allowed connection to another service.

### 3.3.2 Drivers: connect application code to Snowflake

| Driver/client | Typical environment | Recognize this requirement |
| --- | --- | --- |
| JDBC Driver | Java applications and JDBC-compatible tools. | A Java application must execute SQL. |
| ODBC Driver | ODBC-compatible desktop/server tools. | A tool connects through an ODBC data source. |
| .NET Driver | C# / .NET applications. | A .NET service must query Snowflake. |
| Node.js Driver | JavaScript/Node.js applications. | A Node.js backend needs SQL access. |
| Go Driver | Go applications. | A Go service needs Snowflake access. |
| Connector for Python | Python applications. | Python code must submit SQL and fetch results. |

- Drivers send operations to Snowflake; they do not move the whole warehouse onto your laptop.
- Client support for authentication methods depends on the driver and configuration.
- Common supported authentication patterns include:
  - Interactive authentication for humans, with the account's required controls.
  - SSO where configured.
  - OAuth.
  - Key-pair authentication for supported programmatic clients.
- Use the correct driver's documentation rather than guessing connection-string fields.
- TLS secures the client connection.
- Do not put passwords/private keys in a study repository.

Reference: [Snowflake Drivers](https://docs.snowflake.com/en/developer-guide/drivers).

### 3.3.3 Connectors: connect another platform or data workflow

#### A. Snowflake Connector for Python

- Executes SQL and retrieves results from Python.
- Supports parameter binding:
  - Pass values separately from SQL.
  - Do not build SQL by concatenating untrusted input.
- Close cursors/connections when finished.
- Fetch only the rows needed by the application.
- The Python Connector is not the same abstraction as Snowpark:
  - Connector: submit SQL and handle returned results.
  - Snowpark: build supported data-processing operations for execution in Snowflake.

```python
# Optional client exercise.
# Prerequisites:
# - Install snowflake-connector-python in your Python environment.
# - Configure a Python Connector connections.toml profile named "study".
# - Its authentication and role must already work in your account.
# - Run exercises 00 and 01 first.

import snowflake.connector

with snowflake.connector.connect(
    connection_name="study",
    warehouse="D3_STUDY_WH",
    database="D3_STUDY",
    schema="LAB",
) as connection:
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT ORDER_ID, AMOUNT
            FROM D3_ORDERS
            WHERE AMOUNT > %s
            ORDER BY ORDER_ID
            """,
            (100,),
        )
        print(cursor.fetchall())

# Expected: orders 1 and 3, with amounts 120 and 200.
```

- An existing VS Code connection is not proof that a Python profile named `study` exists.
- Configure the client profile separately if needed.

Reference: [Python Connector connections](https://docs.snowflake.com/en/developer-guide/python-connector/python-connector-connect), [Python Connector examples](https://docs.snowflake.com/en/developer-guide/python-connector/python-connector-example).

#### B. Snowflake Connector for Kafka

- Connects Kafka data streams to Snowflake.
- Learn the source clue:
  - Kafka topics/messages -> Kafka connector.
- Supported connector versions/configurations can use file-based Snowpipe or Snowpipe Streaming.
- Delivery behavior depends on the connector's ingestion method and offset management.
- Do not assume Kafka source offsets eliminate all possible business-data duplicates.
- Snowpipe Streaming itself is not limited to Kafka.

#### C. Snowflake Connector for Spark

- Connects Spark workloads/DataFrames with Snowflake.
- Supports reading and writing data between the systems.
- Can push supported operations to Snowflake:
  - This reduces unnecessary movement for those operations.
  - It does not mean every arbitrary Spark operation runs inside Snowflake.
- It is different from choosing JDBC for a small Java SQL client.

#### D. BI and other data tools

- BI tools can connect through supported native connectors or drivers.
- Examples include supported Snowflake connections in Tableau and Power BI.
- A connection does not bypass Snowflake RBAC, masking, or row access policies.
- For an exam scenario:
  1. Identify the source/application.
  2. Identify whether it needs SQL querying or continuous ingestion.
  3. Choose a compatible driver/connector.
  4. Apply the required authentication and privileges.

References: [Kafka connector](https://docs.snowflake.com/en/user-guide/kafka-connector-overview), [Spark connector](https://docs.snowflake.com/en/user-guide/spark-connector-overview), [Connecting to Snowflake](https://docs.snowflake.com/en/user-guide/ecosystem).

### 3.3.4 SQL clients and the Snowflake SQL API

#### A. Snowflake CLI, SnowSQL, VS Code, and Snowsight

- **Snowflake CLI**:
  - Terminal commands for Snowflake workflows.
  - Can execute SQL strings and SQL files.
- **SnowSQL**:
  - A separate SQL-focused command-line client.
  - Its command syntax is not identical to Snowflake CLI.
- **VS Code Snowflake extension**:
  - SQL editing and execution from the editor.
  - Needs an active connection and suitable session context.
- **Snowsight**:
  - Browser-based Snowflake interface.
- The same user/role restrictions still apply in every client.

```bash
# Terminal commands, not statements to paste into a SQL worksheet.
# Requires an existing Snowflake CLI connection profile named study.
snow connection test --connection study
snow sql --connection study -q "SELECT CURRENT_USER(), CURRENT_ROLE();"
snow sql --connection study -f exercises/00-setup.sql
```

- Run the file example from this Domain 3 folder, or use an absolute file path.
- The CLI command starts SQL execution; the SQL file contains SQL statements.

Reference: [Snowflake CLI SQL commands](https://docs.snowflake.com/en/developer-guide/snowflake-cli/sql/execute-sql).

#### B. Snowflake SQL API

- Lets an external application submit SQL over HTTPS/REST.
- General flow:
  1. Authenticate with a supported token method.
  2. Send SQL to `POST /api/v2/statements`.
  3. Keep the returned statement handle.
  4. Check execution status and retrieve results.
- A request may finish asynchronously even when you expected a quick response.
- Example request body:

```json
{
  "statement": "SELECT ORDER_ID, AMOUNT FROM D3_STUDY.LAB.D3_ORDERS ORDER BY ORDER_ID",
  "warehouse": "D3_STUDY_WH",
  "database": "D3_STUDY",
  "schema": "LAB",
  "role": "SYSADMIN",
  "timeout": 60
}
```

- This is a **request body**, not a complete authenticated HTTP call.
- `GET /api/v2/statements/{statementHandle}` checks/fetches a submitted statement.
- Large results can require fetching additional result partitions.
- For an uncertain network retry, use the documented request-ID/retry workflow:
  - Do not blindly resubmit a mutating SQL statement and assume it ran only once.
- **Remember:** SQL API = an external client calling Snowflake SQL.
- This is different from:
  - Snowpipe REST API: notify Snowpipe about staged files.
  - Snowpipe Streaming API: submit rows.
  - API integration: configure Snowflake's access to a supported external service.

References: [SQL API reference](https://docs.snowflake.com/en/developer-guide/sql-api/reference), [Submitting SQL API requests](https://docs.snowflake.com/en/developer-guide/sql-api/submitting-requests), [SQL API responses](https://docs.snowflake.com/en/developer-guide/sql-api/handling-responses).

### 3.3.5 Storage integrations

#### A. What problem they solve

- A **storage integration** defines controlled access to external cloud storage.
- It avoids placing long-lived cloud access keys directly in stage/COPY SQL.
- It contains configuration such as:
  - Cloud provider.
  - Cloud identity/role information.
  - Allowed/blocked storage locations.
  - Whether the integration is enabled.
- A stage references the integration.
- The integration does not itself contain file rows or act as a warehouse.

#### B. S3 setup order

1. Create a cloud IAM policy and role with the required bucket permissions.
2. Create the Snowflake storage integration referencing that role.
3. Run `DESCRIBE INTEGRATION`.
4. Retrieve Snowflake's generated IAM identity and external ID.
5. Configure the AWS role's trust relationship using those values.
6. Grant the appropriate Snowflake integration access to the stage creator.
7. Create the external stage and test `LIST`/loading.

```sql
-- OPTIONAL CLOUD TEMPLATE: replace every your-* value and configure AWS IAM.
-- Run integration creation with an appropriately authorized administrator.
CREATE STORAGE INTEGRATION orders_s3_access
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/your-snowflake-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://your-bucket/orders/');

DESCRIBE INTEGRATION orders_s3_access;
-- Use STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID in AWS trust setup.

-- Run with an administrator authorized to grant integration access:
GRANT USAGE ON INTEGRATION orders_s3_access TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
USE DATABASE D3_STUDY;
USE SCHEMA LAB;

CREATE STAGE orders_external_stage
  URL = 's3://your-bucket/orders/'
  STORAGE_INTEGRATION = orders_s3_access
  FILE_FORMAT = (FORMAT_NAME = 'D3_CSV_LOAD');

LIST @orders_external_stage;
```

- An AWS bucket name or role ARN is not sufficient by itself.
- `STORAGE_ALLOWED_LOCATIONS` and the cloud IAM policy both restrict access.
- To load files, the cloud identity needs read/list access.
- To unload or remove files, it needs the corresponding write/delete access.
- Encryption keys can need additional permissions.
- Replacing a storage integration can change its generated external ID:
  - The old cloud trust relationship might no longer work.
  - Avoid casual `CREATE OR REPLACE` on a working production integration.
- **Remember:** Snowflake grants allow use of the integration; cloud trust allows its cloud identity to reach the objects.

References: [S3 storage integration setup](https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration), [CREATE STORAGE INTEGRATION](https://docs.snowflake.com/en/sql-reference/sql/create-storage-integration).

### 3.3.6 API integrations

#### A. External functions

- An **external function** calls a remote service from Snowflake SQL.
- An **API integration** stores the configuration needed to reach a supported proxy/remote service.
- The function describes the callable SQL interface.
- A common pattern is:

```text
SQL query -> external function -> API integration/proxy -> remote service
```

- A remote address-enrichment or scoring service is an example.
- Creating the integration does not deploy the remote function.
- The remote service must implement Snowflake's expected request/response contract.
- Authentication, allowed URL prefixes, cloud trust, and remote permissions must be configured.

```sql
-- OPTIONAL CLOUD TEMPLATE: not a complete external-service deployment.
CREATE API INTEGRATION scoring_api_access
  API_PROVIDER = aws_api_gateway
  API_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/your-api-role'
  API_ALLOWED_PREFIXES = (
    'https://your-api-id.execute-api.us-west-2.amazonaws.com/prod/'
  )
  ENABLED = TRUE;

DESCRIBE INTEGRATION scoring_api_access;
```

- A complete `CREATE EXTERNAL FUNCTION` example additionally needs a real compatible service endpoint.
- Do not invent an endpoint and assume this DDL makes a working service.

#### B. API integration versus external access integration

- **API integration**:
  - Used by supported external-function/proxy connections.
  - Also used with `API_PROVIDER = git_https_api` for Git access.
- **External access integration**:
  - Allows UDF/procedure handler code to contact approved external network locations.
  - Uses network rules and allowed secrets.
- **Storage integration**:
  - Access to cloud storage.
- **Security integration**:
  - Authentication/security connections such as configured SAML/OAuth cases.
- **Notification integration**:
  - Delivery of supported notifications or messages.
- **Remember:** choose the integration type from the connection's purpose, not merely because the requirement contains the word "API."

References: [Introduction to external functions](https://docs.snowflake.com/en/sql-reference/external-functions-introduction), [CREATE API INTEGRATION](https://docs.snowflake.com/en/sql-reference/sql/create-api-integration), [External network access](https://docs.snowflake.com/en/developer-guide/external-network-access/external-network-access-overview).

### 3.3.7 Git integration

#### A. Objects and their roles

1. **Remote Git repository**
   - The source repository hosted by a supported Git service.
2. **API integration**
   - Allows access to approved HTTPS Git origins.
   - Uses `API_PROVIDER = git_https_api`.
3. **Secret/authentication configuration**
   - Needed for private repositories according to the chosen authentication method.
   - A public repository can use no-auth access.
4. **Git repository object**
   - A schema-level object holding the fetched repository contents in Snowflake.

#### B. Optional public-repository exercise

```sql
-- Account-level setup: requires an authorized integration creator.
-- This public repository is maintained in the Snowflake-Labs organization.
CREATE API INTEGRATION d3_public_git_access
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = (
    'https://github.com/Snowflake-Labs/snowflake-demo-notebooks'
  )
  ENABLED = TRUE;

GRANT USAGE ON INTEGRATION d3_public_git_access TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
USE DATABASE D3_STUDY;
USE SCHEMA LAB;

CREATE GIT REPOSITORY d3_demo_repository
  API_INTEGRATION = d3_public_git_access
  ORIGIN = 'https://github.com/Snowflake-Labs/snowflake-demo-notebooks.git';

ALTER GIT REPOSITORY d3_demo_repository FETCH;
SHOW GIT BRANCHES IN d3_demo_repository;
SHOW GIT TAGS IN d3_demo_repository;

-- Use a branch returned by SHOW GIT BRANCHES; main is an example.
LIST @d3_demo_repository/branches/main/;
```

- The user needs:
  - `USAGE` on the database/schema.
  - `CREATE GIT REPOSITORY` on the schema.
  - Appropriate access to the API integration.
  - Additional secret/authentication access for private-repository patterns.
- `FETCH` updates the repository object's available contents.
- Fetching code does not automatically execute it or deploy its objects.
- Repository files can be referenced by:
  - Branch.
  - Tag.
  - Commit hash.
- A commit hash is useful when you need a specific code version rather than a moving branch.
- Do not paste a private Git token into an `ORIGIN` URL or commit it in SQL.
- **Remember:** Git integration is configured with an API integration plus a Git repository object; there is no generic `CREATE GIT INTEGRATION` command.

References: [Git setup](https://docs.snowflake.com/en/developer-guide/git/git-setting-up-public), [CREATE GIT REPOSITORY](https://docs.snowflake.com/en/sql-reference/sql/create-git-repository), [Git operations](https://docs.snowflake.com/en/developer-guide/git/git-operations), [Public example repository](https://github.com/Snowflake-Labs/snowflake-demo-notebooks).

### 3.3.8 Connection troubleshooting

1. **Find which layer failed**
   - Before login: network/authentication configuration.
   - After login: session context, object privileges, or execution.
2. **Check the account identifier**
   - Preferred connection form is normally `organization-account`.
   - `CURRENT_ACCOUNT()` returns the account locator, not the account name.
3. **Check the active role**
   - A successful SSO/OAuth/key-pair login does not grant table access.
4. **Check database/schema**
   - An unqualified table name uses the current database and schema.
5. **Check warehouse**
   - Data-processing queries generally need an available authorized warehouse.
   - A connection/metadata check succeeding does not prove a warehouse-backed query will succeed.
6. **Check the client-specific configuration**
   - Correct driver, supported authentication, proxy/network rules, and parameters?
7. **Use the right history**
   - Authentication attempt: `LOGIN_HISTORY`.
   - Submitted SQL failure: `QUERY_HISTORY`.

```sql
SELECT
  CURRENT_ORGANIZATION_NAME() AS organization_name,
  CURRENT_ACCOUNT_NAME() AS account_name,
  CURRENT_ACCOUNT() AS account_locator,
  CURRENT_USER() AS user_name,
  CURRENT_ROLE() AS primary_role,
  CURRENT_WAREHOUSE() AS warehouse_name,
  CURRENT_DATABASE() AS database_name,
  CURRENT_SCHEMA() AS schema_name;
```

- **Remember:** authentication answers "Who are you?"; authorization answers "What are you allowed to do?"
- The same account/role can reach the same permitted objects through different supported clients.

References: [Connection settings](https://docs.snowflake.com/en/user-guide/gen-conn-config), [Authentication overview](https://docs.snowflake.com/en/user-guide/security-authentication-overview).

---

## Scenario Decision Guide

| If the requirement says... | Think of... | Check this distinction |
| --- | --- | --- |
| "Upload a local CSV into Snowflake staging." | `PUT` to an internal stage. | Uploading a file is not loading its rows. |
| "Download files already unloaded into an internal stage." | `GET`. | This is not the external-stage download command. |
| "Load a large planned batch using our warehouse." | Bulk `COPY INTO <table>`. | Warehouse-based loading versus managed Snowpipe ingestion. |
| "Automatically ingest new files in a bucket." | Snowpipe with the correct event route. | A pipe definition alone does not configure cloud notifications. |
| "Send individual events without writing files first." | Snowpipe Streaming. | Rows versus staged files. |
| "Inspect the filenames and sizes of staged documents." | Directory table. | File metadata versus document content. |
| "Give a short-lived download link for a staged file." | A suitable pre-signed/scoped file URL pattern. | Encryption, privileges, expiry, and URL purpose matter; see Domain 4.4. |
| "Validate files without inserting table rows." | `VALIDATION_MODE`. | Not supported with a transforming load. |
| "Keep good rows from a partly bad file." | `ON_ERROR = CONTINUE`. | Rejected rows still need follow-up. |
| "Reject the entire file if any row is bad." | `ON_ERROR = SKIP_FILE`. | Different from aborting the whole load statement. |
| "Reorder/cast columns during ingestion." | Supported COPY transformation. | Joins/aggregations need a fuller transformation step. |
| "New source files add columns over time." | Schema evolution with all prerequisites. | Inference alone does not evolve an existing table. |
| "Export a result into CSV/JSON/Parquet files." | `COPY INTO <location>`. | Output prefix versus `PARTITION BY`. |
| "Find changes since the previous processing point." | Stream. | Stream is an offset, not an external message loader. |
| "Process changes whenever they arrive." | Stream plus triggered Task. | The Task must be resumed and authorized. |
| "Run a stored procedure every hour." | Scheduled Task calling the procedure. | Procedure defines logic; Task schedules it. |
| "Run B after A succeeds." | Task graph using `AFTER`. | Dependency order versus unrelated timers. |
| "Maintain a joined/aggregated result with a freshness goal." | Dynamic Table. | Target freshness versus an exact cron schedule. |
| "Ingest from Kafka topics." | Kafka connector with a suitable ingestion mode. | Kafka connector versus a general SQL driver. |
| "Query Snowflake from Java." | JDBC Driver. | Connecting to SQL versus building an ingestion flow. |
| "Read private S3 files without embedding access keys." | Storage integration plus external stage. | Snowflake grants and cloud IAM/trust are both needed. |
| "Call a remote service through an external function." | API integration and compatible remote service. | Different from an application calling the Snowflake SQL API. |
| "Allow Python UDF/procedure code to call an approved host." | External access integration. | Different from a storage integration. |
| "Use versioned SQL/Python files from Git." | Git API integration plus Git repository object. | `FETCH` synchronizes contents; it does not execute them. |

---

## Exercise Checkpoints

Use these to check understanding after running the SQL yourself.

### Loading and unloading

- [ ] I can explain why the exercise can create CSV input files using `COPY INTO <location>`.
- [ ] I can list staged files and query their contents with a file format.
- [ ] Validation leaves the target row count at **0**.
- [ ] Loading the good file produces **3** rows.
- [ ] Repeating the same ordinary `COPY` still leaves **3** rows.
- [ ] `CONTINUE` loads **2** valid rows from the bad file.
- [ ] `SKIP_FILE` loads **0** rows from that file.
- [ ] A supported `TRY_TO_DECIMAL` transformation keeps **3** rows, with one `NULL` amount.
- [ ] JSON loading returns events **101** and **102**.
- [ ] The good-order aggregation returns **APAC = 200** and **EMEA = 200**.
- [ ] Directory rows describe files, not CSV order records.

### Streams and Tasks

- [ ] Reading a Stream twice does not consume its change set.
- [ ] Committed `INSERT ... SELECT FROM stream` advances the offset.
- [ ] I can identify the old/new records of a standard-stream update.
- [ ] The exercise's `MERGE` leaves orders **1 = 125** and **3 = 300**.
- [ ] Rollback leaves order **4** available in the Stream.
- [ ] A newly created Task is suspended.
- [ ] I know which privilege is needed before the optional Task execution.
- [ ] I can distinguish "submitted," "executing," and "succeeded" in Task history.

### Dynamic Tables and schema evolution

- [ ] A suspended Dynamic Table still returns its stored result.
- [ ] The APAC total remains **150** after a source insert while refresh scheduling is suspended.
- [ ] Manual refresh changes that total to **175**.
- [ ] I can explain why this does not demonstrate an exact ten-minute refresh schedule.
- [ ] Schema inference describes the first CSV's columns.
- [ ] A later supported load adds **EMAIL**.
- [ ] I know why the first customer's EMAIL is `NULL`.
- [ ] I have stopped the lab's automatic work and warehouse after finishing.

---

## What to Recall

- Try these without looking at the answers.
- Give a short explanation, not only a feature name.
- If you miss one, reread that topic and try a new scenario later.

### 3.1 Loading, unloading, stages, and errors

1. What is the difference between staging a file, loading a table, and unloading a query result?
2. What does a file format describe? How do `SKIP_HEADER` and `PARSE_HEADER` differ?
3. What are the references for a user stage, table stage, and named stage?
4. Does creating an external stage copy the external files into Snowflake?
5. How do `REMOVE` and `DROP STAGE` differ for an external stage?
6. How do `SNOWFLAKE_FULL` and `SNOWFLAKE_SSE` differ?
7. What does a directory table store? How does it differ from querying `@stage`?
8. Which compute runs bulk `COPY INTO <table>`?
9. Why might a repeated `COPY` skip a file? Does that prevent all duplicate business rows?
10. How do `FORCE`, `LOAD_UNCERTAIN_FILES`, and `PURGE` differ?
11. How do `ABORT_STATEMENT`, `CONTINUE`, and `SKIP_FILE` differ?
12. How do `VALIDATION_MODE` and `VALIDATE` differ?
13. Why should you capture the load query ID immediately?
14. Which transformations are suitable inside a load `COPY`, and which are not?
15. Why choose raw `VARIANT` versus typed columns for JSON?
16. How do schema detection and schema evolution differ? What enables evolution?
17. What do `SINGLE`, `MAX_FILE_SIZE`, and `OVERWRITE` mean during unloading?
18. How does an output prefix differ from `PARTITION BY`?

### 3.2 Automated ingestion and pipelines

19. What does a file-based pipe store, and which compute runs Snowpipe?
20. Why is `AUTO_INGEST = TRUE` not the complete cloud-event setup?
21. What can happen if you correct a Snowpipe file and reuse its name within the metadata window?
22. What are the separate meanings of the 64-day, 14-day, and 7-day periods?
23. How do you inspect, pause, and resume a pipe? What changes for a stale pipe?
24. How does current Snowpipe pricing differ from older per-file/per-compute pricing?
25. How does Snowpipe Streaming differ from file-based Snowpipe?
26. Why do channels and committed offset tokens matter for streaming recovery?
27. Does a Stream store a second copy of the source table?
28. What happens to a Stream offset after `SELECT`, committed DML, and rolled-back DML?
29. How can a standard Stream represent an update? Why is it not a full event audit log?
30. Why should independent consumers have separate Streams?
31. What causes Stream staleness? Can `SYSTEM$STREAM_HAS_DATA` return a false positive?
32. How do a Stream, a Task, and a stored procedure differ?
33. What state does a new Task start in? Does `EXECUTE TASK` enable its recurring schedule?
34. How do scheduled/triggered Tasks and user-managed/serverless compute differ?
35. What permissions must the Task owner have?
36. How do `AFTER` dependencies work in a Task graph?
37. What do Dynamic Table `TARGET_LAG`, refresh mode, and initialization mean?
38. When would you choose a Dynamic Table versus Streams and Tasks?
39. What is Openflow, and how should you interpret the C03 guide's GA caveat?

### 3.3 Connectivity and integrations

40. Which drivers fit Java, ODBC-compatible tools, .NET, Node.js, and Go?
41. How does the Python Connector differ from Snowpark?
42. Which connector fits Kafka? Which fits Spark?
43. How do the SQL API, Snowpipe REST API, and Snowpipe Streaming API differ?
44. What does a storage integration configure, and why is cloud IAM/trust still needed?
45. How do API integrations and external access integrations differ?
46. Which objects are involved in Git integration? What does `FETCH` do?
47. Does switching clients or successfully authenticating give extra table privileges?
48. Which connection/session settings would you check when a query works in one client but fails in another?

<details>
<summary>Answer check: 3.1 loading and unloading</summary>

1. Staging makes files available; loading inserts file data into tables; unloading writes table/query results to files.
2. A file format describes parsing/output rules. `SKIP_HEADER` skips lines; `PARSE_HEADER` reads column names for supported inference/name matching.
3. `@~`, `@%table_name`, and `@stage_name`.
4. No. It references the cloud location.
5. `REMOVE` can delete cloud objects if authorized. `DROP STAGE` removes the external stage object while leaving those objects.
6. FULL adds client-side and server-side encryption; SSE is server-side only. FULL is the internal-stage default and is needed for Tri-Secret Secure.
7. File metadata. A staged-file query parses supported file contents using a file format.
8. A user-managed virtual warehouse.
9. Existing table load metadata can identify a previously loaded file. It does not enforce uniqueness of business rows from other files.
10. FORCE reloads regardless of metadata; LOAD_UNCERTAIN_FILES attempts uncertain older files; PURGE requests deletion of successfully loaded source files.
11. Abort the load statement; accept good rows; reject the bad file as a unit.
12. VALIDATION_MODE checks before inserting rows; VALIDATE reports errors from a prior bulk load.
13. Later statements change what `LAST_QUERY_ID()` refers to.
14. Supported projections, casts, expressions, and field extraction are suitable. Joins, GROUP BY, FLATTEN, WHERE, ORDER BY, and LIMIT are not load-transform features.
15. VARIANT preserves a flexible payload; typed columns express a known schema and make downstream querying explicit.
16. Detection proposes initial columns. File-based evolution needs the table flag, name matching, and EVOLVE SCHEMA/OWNERSHIP; CSV also needs the appropriate header/count settings.
17. SINGLE requests one output file; MAX_FILE_SIZE is a target size; OVERWRITE replaces colliding filenames rather than clearing an output directory.
18. A prefix names a location; PARTITION BY separates output paths according to row values.

</details>

<details>
<summary>Answer check: 3.2 automated ingestion</summary>

19. The pipe stores its COPY definition. Snowflake-managed serverless compute performs Snowpipe loads.
20. Cloud event delivery, trust, permissions, and the stage/table configuration must also work.
21. Snowpipe can ignore the same path/name, even after a correction; use a planned replay strategy.
22. Bulk load metadata: 64 days; Snowpipe file metadata/recent COPY_HISTORY function window: separate 14-day concepts; ALTER PIPE REFRESH: files staged within seven days.
23. SYSTEM$PIPE_STATUS; ALTER PIPE with PIPE_EXECUTION_PAUSED; a stale pipe needs the documented force-resume process and missed-file recovery.
24. Current billing is by loaded data volume, not a per-file fee or user-sized warehouse time. Text uses uncompressed size; binary uses observed size.
25. Snowpipe loads staged files; Streaming submits rows without intermediate staged files.
26. They define source progress and recovery boundaries. Correct replay from committed offsets is required; business-event uniqueness is not automatic.
27. No. It stores an offset and uses source change tracking/version history.
28. SELECT leaves it; committed consumption advances it; rollback preserves it.
29. An update can appear as an old-value DELETE and new-value INSERT, both marked as updates. Net changes can collapse intermediate actions.
30. Each needs its own offset; one consumer must not consume another consumer's change window.
31. Needed source history expires. Yes, STREAM_HAS_DATA can return TRUE without queryable change rows.
32. Stream exposes changes; Task runs SQL; procedure defines reusable logic that a Task can call.
33. Suspended. EXECUTE TASK submits a run without enabling the recurring schedule.
34. A schedule checks time; a triggered Task checks a supported change condition. A warehouse runs user-managed Tasks; Snowflake supplies serverless compute.
35. Appropriate database/schema and SQL-object access, EXECUTE TASK, warehouse USAGE for user-managed compute, and EXECUTE MANAGED TASK for serverless.
36. Children depend on successful predecessor completion; graph Tasks share an owner/schema. Enable children before the root.
37. TARGET_LAG is desired freshness; refresh mode chooses incremental/full processing; initialization determines when the first result is built.
38. Use Dynamic Tables for supported maintained SQL results. Use Streams/Tasks for explicit DML, procedure calls, conditions, or side effects.
39. Openflow is a NiFi-based integration service. The guide's testability caveat is conditional; current platform GA and individual connector availability must not be treated as identical.

</details>

<details>
<summary>Answer check: 3.3 connectivity</summary>

40. JDBC, ODBC, .NET, Node.js, and Go drivers respectively.
41. The Connector submits SQL/fetches results; Snowpark provides data-processing abstractions for work executed in Snowflake.
42. Kafka connector for Kafka topics; Spark connector for Spark/Snowflake data exchange.
43. SQL API submits SQL; Snowpipe REST notifies about staged files; Streaming APIs submit rows.
44. Controlled cloud-storage access. Snowflake configuration cannot replace the cloud's identity trust, object permissions, or key permissions.
45. API integration supports configured external-function/Git connections. External access integration allows approved UDF/procedure handler network access.
46. Remote repository, suitable API integration, optional authentication/secret, and a Git repository object. FETCH updates the available repository contents.
47. No. Authentication and authorization remain separate; changing clients does not grant extra data access.
48. Account identifier, authentication, role, database, schema, warehouse, object grants, and driver/network configuration.

</details>

---

## A manageable study order

1. **First pass:** 3.1.1-3.1.9, then the first half of exercise 01.
2. **Second pass:** remaining 3.1 topics, then finish exercises 01 and 04.
3. **Third pass:** Snowpipe, Snowpipe Streaming, and their differences.
4. **Fourth pass:** Streams and Tasks, then exercise 02.
5. **Fifth pass:** Dynamic Tables/Openflow, then exercise 03.
6. **Sixth pass:** drivers, connectors, integrations, and connection troubleshooting.
7. **Review:** answer the recall questions and explain why the nearby alternative feature would not meet each scenario's requirement.

- You do not need to finish all six passes in one sitting.
- Aim to explain a feature and demonstrate its behavior, rather than memorize every option from every documentation page.
