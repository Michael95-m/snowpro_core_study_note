# Data Transformation

## Snowflake Function Types

| Type | What it returns | Example |
| --- | --- | --- |
| Scalar | One value for each input row | `UPPER(name)`, `UUID_STRING()` |
| Aggregate | One value for a group of rows | `SUM(amount)`, `AVG(score)`, `COUNT(*)` |
| Window | A value for each input row, calculated over related rows with `OVER (...)` | `SUM(amount) OVER (PARTITION BY customer_id)` |
| Table | Zero or more rows, with one or more columns | `FLATTEN(input => json_column)` |
| System | System information or an administrative action | `SYSTEM$CANCEL_QUERY(query_id)` |

### Aggregate vs. Window Functions

An aggregate function normally reduces many rows to one row per group. A window function keeps the original rows and adds a calculation for each row.

```sql
-- One result row per customer.
SELECT customer_id, SUM(amount) AS customer_total
FROM orders
GROUP BY customer_id;

-- One result row per order, with the customer's total on every order row.
SELECT
  order_id,
  customer_id,
  amount,
  SUM(amount) OVER (PARTITION BY customer_id) AS customer_total
FROM orders;
```

## Approximation Functions

Approximation functions trade a small amount of accuracy for lower cost and faster processing on large data sets. Use the exact functions when an approximate answer is not acceptable.

### Cardinality: How Many Distinct Values?

`APPROX_COUNT_DISTINCT` uses Snowflake's HyperLogLog implementation to estimate the number of distinct values.

```sql
SELECT APPROX_COUNT_DISTINCT(customer_id) AS estimated_customers
FROM orders;
```

### Similarity: How Similar Are Two Sets?

`MINHASH` creates a compact state for each set. Pass the states to `APPROXIMATE_SIMILARITY` to estimate their Jaccard similarity: `intersection / union`. A result close to `1` means the sets are very similar.

```sql
SELECT APPROXIMATE_SIMILARITY(mh) AS estimated_similarity
FROM (
  SELECT MINHASH(100, customer_id) AS mh FROM customers_a
  UNION ALL
  SELECT MINHASH(100, customer_id) AS mh FROM customers_b
);
```

`100` is a commonly suggested number of hash functions: a larger value improves the approximation but requires more computation.

### Frequency: Which Values Occur Most Often?

`APPROX_TOP_K` uses the Space-Saving algorithm to return the most frequent values and their estimated frequencies.

```sql
SELECT APPROX_TOP_K(product_id, 10, 1000) AS frequent_products
FROM order_items;
```

In this example, `10` is the number of frequent values to return and `1000` is the number of distinct values the algorithm can track. The result is a JSON array of `[value, estimated_frequency]` pairs.

### Percentile: What Is the Approximate Distribution?

`APPROX_PERCENTILE` uses Snowflake's t-Digest implementation. The percentile must be from `0` (minimum) up to, but not including, `1`.

```sql
SELECT APPROX_PERCENTILE(order_amount, 0.95) AS estimated_p95_order_amount
FROM orders;
```

## Table Sampling

`SAMPLE` and `TABLESAMPLE` are synonyms. They return a random subset of rows from a table.

### Fraction-Based Sampling

| Method | What is sampled | Notes |
| --- | --- | --- |
| `BERNOULLI` / `ROW` | Individual rows | Default method; each row has the requested probability of being included. |
| `SYSTEM` / `BLOCK` | Storage-level blocks, usually micro-partitions | Often faster, but can be less representative for small tables. Supports `SEED` / `REPEATABLE`. |

```sql
-- Approximately 50% of individual rows.
SELECT col1, col2
FROM lineitem SAMPLE BERNOULLI (50);

-- Approximately 50% of storage blocks.
SELECT col1, col2
FROM lineitem SAMPLE SYSTEM (50);

-- Reproducible block sample while the table is unchanged.
SELECT col1, col2
FROM lineitem SAMPLE BLOCK (50) SEED (765);
```

For fraction-based sampling, the returned row count is approximate. A seed makes the same probability sample reproducible only when the table has not changed.

### Fixed-Size Sampling

Fixed-size sampling is row-based only. It returns the requested number of rows unless the table contains fewer rows; then it returns the whole table. The maximum request is 1,000,000 rows.

```sql
SELECT *
FROM lineitem SAMPLE BERNOULLI (1000 ROWS);
```

`SYSTEM` / `BLOCK` and `SEED` cannot be used with fixed-size sampling.

## Unstructured File Functions

Snowflake has many file functions. The three URL-generating functions below are the most useful for accessing files in internal or external stages.

| Function | URL behavior | Main use case |
| --- | --- | --- |
| `BUILD_SCOPED_FILE_URL` | Encoded and short-lived. It is valid until the persisted query result expires (currently 24 hours). | Give controlled, temporary access; for example, through a secure view. |
| `BUILD_STAGE_FILE_URL` | Does not expire, but the user still authenticates and must have stage privileges. | Create a durable file reference for an application. |
| `GET_PRESIGNED_URL` | Time-limited URL with an access token. The default expiration is 3,600 seconds. | Let a client download directly from cloud storage. |

### `BUILD_SCOPED_FILE_URL`

A scoped URL is encoded and temporary. In a direct query, the caller needs `USAGE` on an external stage or `READ` on an internal stage. A view owner can generate scoped URLs in a view, so a user with `SELECT` on that view can receive controlled access to the files exposed by the view.

```sql
SELECT BUILD_SCOPED_FILE_URL(@images_stage, 'file.jpg');
```

### `BUILD_STAGE_FILE_URL`

A stage file URL does not expire, but it does **not** bypass authorization. When the URL is used, Snowflake authenticates the user and checks for `USAGE` on an external stage or `READ` on an internal stage.

```sql
SELECT BUILD_STAGE_FILE_URL(@images_stage, 'file.jpg');
```

### `GET_PRESIGNED_URL`

A pre-signed URL gives temporary direct access to a staged file. The optional third argument is the expiration time in seconds. Server-side encryption is required on the stage. The role generating the URL needs `USAGE` on an external stage or `READ` on an internal stage.

```sql
SELECT GET_PRESIGNED_URL(@images_stage, 'file.jpg', 600);
```

## Directory Tables

- A directory table is a queryable metadata layer for files in a named internal or external stage. Query it with `DIRECTORY(@stage_name)` to retrieve file metadata, including `RELATIVE_PATH` and `FILE_URL`.
- It is useful when an application needs to query or filter staged-file metadata in SQL. `LIST` displays files, but it is not a table-like query interface.

```sql
CREATE STAGE int_stage
  DIRECTORY = (ENABLE = TRUE);

ALTER STAGE ext_stage
  SET DIRECTORY = (ENABLE = TRUE);

SELECT *
FROM DIRECTORY(@int_stage);
```

- Refresh the directory table to register added, changed, or deleted files. You can refresh it manually. Automatic refresh is also available when the stage and cloud configuration support it; external stages generally use cloud-event notifications.

```sql
ALTER STAGE int_stage REFRESH;
```

## File Support REST API

`GET /api/files/` downloads a file from an internal or external stage. Send either a scoped URL or a stage file URL in the GET request. An HTTP client must authenticate to Snowflake and allow redirects.

| URL sent to the API | Authorization behavior |
| --- | --- |
| Scoped URL | Only the user who generated the URL can access that file. |
| Stage file URL | Any role with `USAGE` on the external stage or `READ` on the internal stage can access the file. |

`GET_PRESIGNED_URL` is different: it creates a temporary direct URL to the cloud-storage file, so a client can open the pre-signed URL directly rather than using the Snowflake file-support endpoint.
