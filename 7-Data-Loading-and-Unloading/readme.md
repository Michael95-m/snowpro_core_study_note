# Data Loading and Unloading

## Loading vs. Unloading

- **Loading** moves files into Snowflake tables: local files can be uploaded with `PUT`, then loaded with `COPY INTO <table>`.
- **Unloading** moves the result of a table or query out of Snowflake: use `COPY INTO <location>` to write files to a stage or cloud-storage location.

## Stages

- Stages are storage locations for files used in Snowflake loading and unloading.
- **Internal stages** store files inside Snowflake.
- **External stages** reference files in cloud storage, such as Amazon S3, Google Cloud Storage, or Microsoft Azure.

### Internal Stages

- Snowflake automatically provides a **user stage** for each user and a **table stage** for each table.
- User and table stages cannot be altered or dropped separately.
- A **named internal stage** must be created explicitly. It is the most flexible choice when multiple users or tables need access to the same files.

| Stage type | Reference | Typical use |
| --- | --- | --- |
| User stage | `@~` | Files used by one user, possibly for multiple tables |
| Table stage | `@%my_table` | Files loaded into one table |
| Named internal stage | `@my_stage` | Shared or reusable staging location |

### External Stages

- An external stage is a named stage that references a cloud-storage location. Create the storage integration first, then create the stage that uses it.

  ```sql
  CREATE STORAGE INTEGRATION my_s3_integration
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<account-id>:role/<role-name>'
    STORAGE_ALLOWED_LOCATIONS = ('s3://my_bucket/path/');

  CREATE STAGE my_ext_stage
    URL = 's3://my_bucket/path/'
    STORAGE_INTEGRATION = my_s3_integration;
  ```

- Use a storage integration instead of embedding cloud credentials in SQL statements.

### Stage Helper Commands

- `LIST` displays files in a stage.
- You can query staged files with SQL when you provide the appropriate file format.
- `REMOVE` deletes files from an internal stage. It does not delete objects from an external cloud-storage location.

```sql
LIST @my_stage;

SELECT
  METADATA$FILENAME,
  METADATA$FILE_ROW_NUMBER,
  t.$1,
  t.$2
FROM @my_stage (FILE_FORMAT => 'my_format') t;

REMOVE @my_stage/path/file.csv.gz;
```

### `PUT` Command

`PUT` uploads files from a local directory to an internal user, table, or named stage. Run it from Snowflake CLI, SnowSQL, or a supported driver—not from a worksheet.

By default, Snowflake skips an unmodified duplicate file with the same name. Use `OVERWRITE = TRUE` only when replacing the staged file is intentional.

```sql
PUT file:///folder/my_data.csv @my_internal_stage
  AUTO_COMPRESS = TRUE;
```

## Bulk Loading with `COPY INTO <table>`

`COPY INTO <table>` loads files from an internal stage, external stage, or external cloud-storage location into a table. A virtual warehouse executes the load.

Snowflake maintains load metadata for 64 days. This usually prevents an already loaded file from being loaded again into the same table.

### Basic Examples

```sql
-- Load all eligible files in a stage.
COPY INTO my_table
  FROM @my_int_stage
  FILE_FORMAT = (FORMAT_NAME = my_csv_format);

-- Load one specific file.
COPY INTO my_table
  FROM @my_int_stage/file1.csv
  FILE_FORMAT = (FORMAT_NAME = my_csv_format);

-- Load only files that match a regular expression.
COPY INTO my_table
  FROM @my_int_stage
  PATTERN = 'people/.*[.]csv'
  FILE_FORMAT = (FORMAT_NAME = my_csv_format);
```

### Transform During the Load

`COPY INTO` supports a limited set of SQL transformations while loading data:

```sql
COPY INTO my_table (value_as_number, raw_value)
  FROM (
    SELECT
      TO_DOUBLE(t.$1),
      t.$1
    FROM @my_int_stage t
  )
  FILE_FORMAT = (FORMAT_NAME = my_csv_format);
```

Loading from another cloud region or cloud platform can incur data-transfer charges.

### Error Handling

Use `ON_ERROR` to choose what happens when Snowflake encounters invalid rows. Common options include:

- `ABORT_STATEMENT` — stop the load at the first error; this is the default.
- `CONTINUE` — continue loading valid rows.
- `SKIP_FILE` — skip a file if it contains an error.
- `SKIP_FILE_<num>` or `SKIP_FILE_<num>%` — skip a file after a specified number or percentage of errors.

### Validate a `COPY INTO` Load

`VALIDATION_MODE` checks staged files without loading them. Use one of these values:

- `RETURN_ERRORS`
- `RETURN_10_ROWS` (replace `10` with the number of rows to validate)
- `RETURN_ALL_ERRORS`

```sql
COPY INTO my_table
  FROM @my_int_stage
  FILE_FORMAT = (FORMAT_NAME = my_csv_format)
  VALIDATION_MODE = 'RETURN_ERRORS';
```

`VALIDATE` returns errors from a previous `COPY INTO` command. Pass the query ID of that load (or use `_last` for the last load in the current session). It does not support transformed loads.

```sql
SELECT *
FROM TABLE(VALIDATE(my_table, JOB_ID => '<copy_query_id>'));
```

## Snowpipe

- Snowpipe is Snowflake's serverless service for continuous file ingestion.
- A pipe object stores the `COPY INTO <table>` statement that Snowpipe uses to load staged files.

### How Snowpipe Detects Files

There are two common ways to notify Snowpipe about new staged files:

1. **Cloud event notifications:** Set `AUTO_INGEST = TRUE` and configure cloud messaging for an external stage. This is the normal choice for automatic ingestion.
2. **Snowpipe REST API:** Set `AUTO_INGEST = FALSE`, then call the `insertFiles` endpoint to submit staged files for loading. This can be used with supported internal or external stages.

```sql
CREATE PIPE my_pipe
  AUTO_INGEST = TRUE
AS
COPY INTO my_table
  FROM @my_external_stage
  FILE_FORMAT = (TYPE = CSV);
```

> `AUTO_INGEST = TRUE` also requires the appropriate cloud-notification configuration. The example shows the pipe definition only.

### Snowpipe Behavior

- Snowflake manages the compute resources, so Snowpipe does not use your virtual warehouse.
- Snowpipe is designed for continuous ingestion of newly staged files, typically making data available within minutes.
- Snowpipe keeps pipe-level file-load metadata for 14 days to reduce duplicate loading. A file with the same name is ignored during this period, even if its contents change.
- A cloud-messaging pipe paused for more than 14 days can become stale. Resume it with `SYSTEM$PIPE_FORCE_RESUME` after checking its status.

Use `ALTER PIPE ... REFRESH` only for short-term recovery of files that Snowpipe did not queue; it is not a general reset command.

```sql
ALTER PIPE my_pipe REFRESH;
```

### Best Practices for File Loading

These practices apply to both Snowpipe and bulk loading:

- Aim for compressed files of roughly 100-250 MB. Split very large files and avoid large numbers of tiny files.
- Organize files in logical stage paths, such as by date or source system.
- For Snowpipe, creating a new file about once per minute is usually a good balance between cost and latency. More frequent small files increase queue-management overhead and do not guarantee lower latency.
- Snowpipe is serverless. For bulk loads, use a warehouse separate from interactive-query workloads when isolation is needed.
- Pre-sort files only when it supports a known clustering or query-access pattern.

## Snowpipe Streaming

- Snowpipe uses staged files. Snowpipe Streaming sends rows directly from a client application to Snowflake without an intermediate stage.
- It is designed for continuous event or row ingestion, such as IoT telemetry, application logs, CDC, and live analytics.
- Supported integration choices include the Python, Java, and Node.js SDKs, the direct REST API, and the Snowflake Connector for Kafka.

### Snowpipe Streaming Features

- **Low latency and high throughput:** Designed for up to 10 GB per second per table, with data available for query in as little as 5 seconds.
- **Named Channels:** Provide ordered ingestion within one channel and exactly-once delivery when the client tracks and replays source offsets correctly.
- **Offset tokens:** Record the last committed source position. The client must retain source data and use the committed token during recovery; tokens do not make client memory durable.
- **Serverless billing:** Snowflake manages the ingestion compute. High-performance Snowpipe Streaming is charged by uncompressed data volume ingested.
- **Schema evolution:** Enable it with `ENABLE_SCHEMA_EVOLUTION = TRUE`. It supports standard Snowflake tables and Snowflake-managed Iceberg tables, subject to data-type limitations.
- **In-flight transformations:** A streaming pipe can apply supported `COPY INTO` transformations before rows are committed to the target table.


## Data Unloading

Use `COPY INTO <location>` to unload a table or query result to one of these destinations:

- An internal stage, such as a named stage, table stage, or user stage.
- An external stage.
- A cloud-storage URL in Amazon S3, Google Cloud Storage, or Microsoft Azure.

    ```sql
    COPY INTO @my_stage/unload/data_
    FROM (
        SELECT col1, col2
        FROM t1
    )
    FILE_FORMAT = (FORMAT_NAME = my_csv_file_format);
    ```

- Snowflake can unload data as delimited files (for example, CSV or TSV), JSON, or Parquet. The output path can include a directory and file-name prefix.

> `@my_stage/unload/data_` sets an output path and file-name prefix. It does not partition the output. Use the `PARTITION BY` clause when you need partitioned output.

### Unload Directly to Cloud Storage

Use a storage integration when unloading directly to a private cloud-storage location:

```sql
COPY INTO 's3://my_bucket/unload/'
  FROM t1
  STORAGE_INTEGRATION = my_storage_integration
  FILE_FORMAT = (FORMAT_NAME = my_csv_file_format);
```

### Download Files from an Internal Stage

`GET` downloads files from an **internal** Snowflake stage to a local directory. Run it from a supported client, not Snowsight. It is the reverse of `PUT`.

```sql
GET @my_stage/unload/ file:///tmp/data/
  PARALLEL = 8
  PATTERN = '.*[.]csv([.]gz)?$';
```

- `PARALLEL` controls the number of concurrent download threads. Increase it only when the client machine and network can benefit.
- `PATTERN` filters stage files with a regular expression.

## Semi-Structured Data Overview

Snowflake can load semi-structured formats such as JSON, Avro, ORC, Parquet, and XML. It represents hierarchical data with the `ARRAY`, `OBJECT`, and `VARIANT` data types.

### ARRAY

An `ARRAY` stores an ordered list of values. Access an element by its position, for example `hobbies[0]`.

```sql
CREATE OR REPLACE TABLE my_array_table (
  name VARCHAR,
  hobbies ARRAY
);

INSERT INTO my_array_table
SELECT 'Alina Novak', ARRAY_CONSTRUCT('writing', 'tennis', 'baking');
```

### OBJECT

An `OBJECT` stores key-value pairs, similar to a JSON object.

```sql
CREATE OR REPLACE TABLE my_object_table (
  name VARCHAR,
  address OBJECT
);

INSERT INTO my_object_table
SELECT
  'Alina Novak',
  OBJECT_CONSTRUCT(
    'postcode', 'TY5 7NN',
    'first_line', 'Soi 5'
  );
```

### VARIANT

`VARIANT` can store a value of any other type, including `ARRAY` and `OBJECT`. Use it for flexible or hierarchical data where the schema is not fully known in advance.

A `VARIANT` value can be up to **128 MB of uncompressed data**. The practical limit may be smaller because of internal overhead.

```sql
CREATE OR REPLACE TABLE my_variant_table (
  name VARCHAR,
  address VARIANT,
  hobbies VARIANT
);

INSERT INTO my_variant_table
SELECT
  'Min Khant',
  OBJECT_CONSTRUCT('street', 'Soi 5'),
  ARRAY_CONSTRUCT('writing', 'tennis');
```

## Unloading Semi-Structured Data

- JSON and Parquet are the supported semi-structured output formats for `COPY INTO <location>`.
- To unload relational rows as JSON, create a `VARIANT` value in the query with `OBJECT_CONSTRUCT`.

```sql
COPY INTO @my_stage/unload/customers_
  FROM (
    SELECT OBJECT_CONSTRUCT(
      'customer_id', customer_id,
      'customer_name', customer_name
    )
    FROM customers
  )
  FILE_FORMAT = (TYPE = JSON);
```

## Loading Semi-Structured Data

The overall flow is the same as for structured files, but Snowflake needs the correct file format to parse the source data:

```text
Local file -> PUT -> stage -> COPY INTO <table>
```

Snowflake supports JSON, Avro, ORC, Parquet, and XML as semi-structured input formats.

### JSON File Format: `STRIP_OUTER_ARRAY`

`STRIP_OUTER_ARRAY = TRUE` removes the outer `[` and `]` from a JSON array during loading. This lets Snowflake load each top-level array element as a separate row. It does not change the `VARIANT` size limit.

```sql
CREATE OR REPLACE FILE FORMAT ff_json
  TYPE = JSON
  STRIP_OUTER_ARRAY = TRUE;
```

### Loading Approaches

#### 1. ELT: Load the Raw JSON into `VARIANT`

Use this approach when the JSON schema changes often or when you want to retain the original payload before transforming it.

```sql
CREATE OR REPLACE TABLE raw_events (
  src VARIANT
);

COPY INTO raw_events
  FROM @my_stage/file1.json
  FILE_FORMAT = (FORMAT_NAME = ff_json);
```

#### 2. ETL: Transform JSON into Typed Columns While Loading

Use this approach when the required fields and target data types are already known. Typed columns are easier to query and validate than repeatedly extracting values from `VARIANT`.

```sql
CREATE OR REPLACE TABLE customer_details (
  name STRING,
  age NUMBER,
  dob DATE
);

COPY INTO customer_details (name, age, dob)
  FROM (
    SELECT
      $1:name::STRING,
      $1:age::NUMBER,
      $1:dob::DATE
    FROM @my_stage/file1.json
  )
  FILE_FORMAT = (FORMAT_NAME = ff_json);
```

#### 3. Automatic Schema Detection

Automatic schema detection can speed up exploration of unfamiliar files. Review the inferred column names and data types before using them in a production table.

### Unloading Procedure

The general flow is:

```text
Table or query result -> COPY INTO <location> -> stage or cloud storage
```

Use `GET` only when the files are in an internal stage and you want to download them to a local computer.

## Accessing Semi-Structured Data

Assume a table called `employees` with a `src VARIANT` column:

```sql
CREATE OR REPLACE TABLE employees (
  src VARIANT
);
```

### Dot Notation

Use a colon after the column name, then use dots for nested keys:

```sql
SELECT src:employee.name::STRING AS employee_name
FROM employees;
```

`employee` is the first-level key, and `name` is its nested key. Unquoted Snowflake column names are case-insensitive, but JSON key names are case-sensitive.

### Bracket Notation

Bracket notation is useful when a JSON key contains spaces or punctuation:

```sql
SELECT src['employee']['name']::STRING AS employee_name
FROM employees;
```

### Repeating Elements

Use a zero-based index to access an array element:

```sql
SELECT src:skills[0]::STRING AS first_skill
FROM employees;
```

`GET()` can also retrieve a key or array element. Do not confuse this function with the `GET` command that downloads staged files.

```sql
SELECT GET(src, 'skills')[0]::STRING AS first_skill
FROM employees;
```

## Casting Semi-Structured Data

Values extracted from `VARIANT` are still `VARIANT` values. Explicit casting makes the intended SQL type clear and removes the double quotes often shown around extracted strings.

| Technique | Example | Notes |
| --- | --- | --- |
| Cast operator | `src:employee.name::STRING` | Common for direct conversion. |
| `TO_<type>()` | `TO_DATE(src:employee.dob)` | Converts a value to the requested SQL type. |
| `AS_<type>()` | `AS_VARCHAR(src:employee.name)` | Strict cast; returns `NULL` when the underlying type does not match. |

## Semi-Structured Functions

### `FLATTEN` Table Function

`FLATTEN` expands an `ARRAY` or `OBJECT` into one output row per element.

```sql
SELECT f.value::STRING AS skill
FROM employees e,
LATERAL FLATTEN(INPUT => e.src:skills) f;
```

`FLATTEN` returns these columns: `SEQ`, `KEY`, `PATH`, `INDEX`, `VALUE`, and `THIS`.

### `LATERAL FLATTEN`

Use `LATERAL FLATTEN` when you need values from the original row alongside each flattened element. If one employee has three skills, the query returns three rows for that employee.

```sql
SELECT
  e.src:employee.name::STRING AS employee_name,
  e.src:employee.id::STRING AS employee_id,
  f.value::STRING AS skill
FROM employees e,
LATERAL FLATTEN(INPUT => e.src:skills) f;
```
