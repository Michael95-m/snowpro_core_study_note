# 1.5 Snowflake Tables and Views: Practice Questions and Answers

These 15 questions were recovered from our completed chat practice round. Answer each question before opening its answer. The explanations and official Snowflake links are lightly edited from the original feedback. These are practice questions, not official exam questions.

## Question 1

A standard Snowflake table has these micro-partition value ranges:

| Micro-partition | Minimum `order_date` | Maximum `order_date` |
| --- | --- | --- |
| MP1 | 2026-01-01 | 2026-01-31 |
| MP2 | 2026-02-01 | 2026-02-28 |
| MP3 | 2026-03-01 | 2026-03-31 |

A user runs:

```sql
SELECT *
FROM orders
WHERE order_date = '2026-02-14'::DATE;
```

Which micro-partitions can Snowflake safely skip using this metadata?

A. MP2 only.  
B. All three.  
C. MP1 and MP3.  
D. None—pruning requires a manually defined clustering key.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Not quite, —**C: skip MP1 and MP3.**

Snowflake automatically records micro-partition metadata, including column value ranges. **Pruning does not require a manually defined clustering key.**

- **MP1:** January only → cannot contain February 14 → skip.
- **MP3:** March only → cannot contain February 14 → skip.
- **MP2:** Its range includes February 14 → remains a candidate to scan.

A clustering key can improve data organization and make pruning more effective, but it isn’t required for pruning to happen. [Reference: Micro-partitions and pruning](https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions)

</details>

## Question 2

A team needs a staging table that:

- Survives when the session ends.
- Can be rebuilt from source files.
- Supports one day of Time Travel.
- Does **not** have Fail-safe.

Which table type best fits?

A. Temporary  
B. Transient  
C. Permanent  
D. External

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct —**B: Transient**. It survives session end, supports **0 or 1 day of Time Travel**, and has **no Fail-safe**. It remains until explicitly dropped. [Reference: Table types](https://docs.snowflake.com/en/user-guide/tables-temp-transient#comparison-of-table-types)

</details>

## Question 3

An analyst creates a temporary table in **Session A**:

```sql
CREATE TEMPORARY TABLE analytics.work.temp_orders (id NUMBER);
```

They open **Session B** using the same account, user, role, database, and schema. No other table has that name.

Can Session B query this temporary table?

A. Yes—temporary tables are shared across all sessions belonging to the same user.  
B. Yes—using its fully qualified name makes it accessible.  
C. No—it is visible only in the session that created it.  
D. Yes—if both sessions use the same warehouse.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct—**C**. A temporary table is **session-scoped, not user-scoped**. The same user in another session cannot access it, even with its fully qualified name or the same warehouse. [Reference: Temporary tables](https://docs.snowflake.com/en/user-guide/tables-temp-transient#temporary-tables)

</details>

## Question 4

A permanent table named `analytics.work.orders` contains one row: `id = 100`.

In the same session, an analyst runs:

```sql
CREATE TEMPORARY TABLE analytics.work.orders (id NUMBER);
INSERT INTO analytics.work.orders VALUES (999);

SELECT * FROM analytics.work.orders;
```

What does the `SELECT` return?

A. Only `100`, from the permanent table.  
B. Only `999`, from the temporary table.  
C. Both `100` and `999`.  
D. An error—the temporary table cannot have the same name as the permanent table.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct —**B**. The temporary table **takes precedence in that session**, even when you use the fully qualified name. The permanent table still exists underneath; it hasn’t been replaced. [Reference: Naming conflicts](https://docs.snowflake.com/en/user-guide/tables-temp-transient#potential-naming-conflicts-with-other-table-types)

</details>

## Question 5

A company uses **Enterprise Edition**. It needs a table that:

- Survives session end.
- Supports **30 days of Time Travel**.
- Has Fail-safe protection afterward.

Which setup meets these requirements?

A. A transient table with retention set to 30 days.  
B. A temporary table with retention set to 30 days.  
C. A permanent table with retention set to 1 day—Enterprise automatically extends it to 30.  
D. A permanent table with `DATA_RETENTION_TIME_IN_DAYS = 30`.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

Correct —**D**. Enterprise permits 30-day Time Travel for a **permanent table**, but you must configure it. Temporary and transient tables remain limited to 0 or 1 day and have no Fail-safe. [Reference: Table-type comparison](https://docs.snowflake.com/en/user-guide/tables-temp-transient#comparison-of-table-types)

</details>

## Question 6

A company has Parquet files in Amazon S3. It wants a **read-only table abstraction** to query those files with SQL, without first loading their contents into a native Snowflake table.

Which object best fits?

A. An external table.  
B. A permanent native table populated using `COPY INTO`.  
C. A temporary native table.  
D. A file format object alone.

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

Correct—**A: an external table**. The files remain in S3; Snowflake stores metadata to expose them as a queryable table. External tables are read-only—you cannot directly `INSERT`, `UPDATE`, or `DELETE` their rows. [Reference: External tables](https://docs.snowflake.com/en/user-guide/tables-external-intro)

</details>

## Question 7

A dynamic table has:

```sql
TARGET_LAG = '10 minutes'
```

What does this mean?

A. Snowflake must refresh it exactly once every 10 minutes.  
B. Snowflake schedules refreshes to target data freshness within 10 minutes of its source; it is not a fixed refresh interval or guaranteed SLA.  
C. Queries against it are cancelled after 10 minutes.  
D. Its historical data is retained for only 10 minutes.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct —**B**. More precisely, it’s a **freshness target**: Snowflake aims to keep the result within 10 minutes of its source data. Refresh timing can vary, and actual lag can exceed the target. [Reference: Target lag](https://docs.snowflake.com/en/user-guide/dynamic-tables/target-lag)

</details>

## Question 8

A team wants to save a reusable SQL definition that joins and filters existing tables. It does **not** want the object to persistently store a separate query result.

Which object best fits?

A. A materialized view.  
B. A transient table.  
C. A dynamic table.  
D. A standard, non-materialized view.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

Correct —**D**. A standard view is a reusable SQL abstraction: it stores the query definition, not a separate materialized result. [Reference: Non-materialized views](https://docs.snowflake.com/en/user-guide/views-introduction#non-materialized-views)

</details>

## Question 9

An Enterprise account repeatedly runs an expensive aggregation over one large table. The underlying data changes infrequently, and the query meets Snowflake’s definition restrictions.

The team wants to **store precomputed results that Snowflake maintains automatically**, accepting additional storage and maintenance costs.

Which object best fits?

A. A standard secure view.  
B. A materialized view.  
C. A temporary table populated once.  
D. A file format.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct —**B**. A materialized view stores the precomputed aggregation, and Snowflake maintains it as the base data changes. Frequent reuse and infrequent changes can make the benefit worth its storage and maintenance costs. [Reference: Materialized views](https://docs.snowflake.com/en/user-guide/views-materialized)

</details>

## Question 10

A company exposes selected customer data through a view. It wants to protect the view’s SQL definition from ordinary consumers and prevent optimizer behavior that could reveal hidden underlying data. It accepts a potential performance trade-off.

Which choice best fits?

A. Increase the warehouse size.  
B. Use a standard, non-secure view.  
C. Define the view as `SECURE`.  
D. Make the underlying table transient.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct—**C**. A secure view protects its definition from ordinary consumers and restricts optimizations that could expose hidden data. It may run more slowly, and `SECURE` does **not** automatically grant access. [Reference: Secure views](https://docs.snowflake.com/en/user-guide/views-secure)

</details>

## Question 11

A developer says, “Iceberg tables are just external tables, so every Iceberg table is read-only.”

Which response is correct?

A. Correct—all Iceberg tables are read-only.  
B. Incorrect—Iceberg is an open table format, and supported operations depend on the catalog and configuration; Iceberg tables are not inherently read-only.  
C. Correct—writing requires converting all files into native Snowflake storage format.  
D. Incorrect—every Iceberg table automatically has the same Fail-safe protection as a permanent native table.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct —**B**. Iceberg is an **open table format**, not another name for a read-only external table. Snowflake can read and write supported Iceberg configurations; capabilities depend on the catalog and setup. [Reference: Iceberg tables](https://docs.snowflake.com/en/user-guide/tables-iceberg)

</details>

## Question 12

A company wants **Snowflake to manage the Iceberg catalog**, while keeping the table’s files in **its own Amazon S3 bucket**.

Which configuration fits?

A. A standard external table—it provides a Snowflake-managed Iceberg catalog.  
B. A permanent native table—the files must first be converted to Snowflake’s native format.  
C. An externally managed catalog—customer-owned storage always requires an external catalog.  
D. A Snowflake-managed Iceberg table using an external volume configured for its S3 storage.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

Correct—**D**. **Catalog management and file storage are separate choices.** A Snowflake-managed Iceberg catalog can work with files in your own S3 bucket through an external volume. [Reference: Iceberg storage options](https://docs.snowflake.com/en/user-guide/tables-iceberg-storage)

</details>

## Question 13

A large standard table is loaded in date order. Date-filtered queries already prune effectively and meet performance requirements.

A developer says, “Every table needs an explicit clustering key, otherwise pruning cannot work.”

Which response is best?

A. Correct—every table requires a clustering key.  
B. Correct—but only Enterprise accounts can prune micro-partitions.  
C. Incorrect—natural clustering and automatic metadata already support pruning; add a key only when its expected benefit justifies maintenance costs.  
D. Incorrect—Snowflake creates a traditional index on every date column instead.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct—**C**. Snowflake automatically creates micro-partitions and collects pruning metadata. An explicit clustering key is optional; if natural clustering already gives good performance, maintenance costs may outweigh any benefit. [Reference: Clustering keys](https://docs.snowflake.com/en/user-guide/tables-clustering-keys)

</details>

## Question 14

A user changes values in several rows of a standard permanent table using `UPDATE`.

Which statement best describes what happens to its **immutable micro-partitions**?

A. Snowflake edits the existing micro-partition files in place.  
B. Snowflake creates replacement micro-partitions for affected data; older versions can remain for applicable Time Travel and Fail-safe periods.  
C. Snowflake must rewrite every table in the database.  
D. The update fails because immutable micro-partitions mean table rows cannot change.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct—**B**. “Immutable” means the existing micro-partition files are not edited in place—not that table rows cannot change. Updates create replacement partitions, while older versions can remain for data protection. [Reference: Storage and updates](https://docs.snowflake.com/en/user-guide/tables-storage-considerations)

</details>

## Question 15

A team wants to define a transformation using SQL that joins several source tables and aggregates the results. It wants Snowflake to **store the output and manage refreshes toward a target freshness**, rather than manually maintaining each pipeline step.

Which object best fits?

A. A dynamic table.  
B. A standard view.  
C. A transient table populated only once.  
D. A non-materialized secure view.

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

Correct: a dynamic table stores the output of its SQL transformation, and Snowflake manages refreshes toward the target lag. Standard and non-materialized secure views do not store that output. [Reference: Dynamic-table freshness](https://docs.snowflake.com/en/user-guide/dynamic-tables/target-lag)

</details>

## Recall questions

1. **A micro-partition's `price` range is 10–100. Can Snowflake skip it for `price = 50` or `price = 150` based only on that range?** It cannot safely skip for 50, because the value might exist. It can skip for 150, which falls outside the range. The range never guarantees that every value inside it exists. [Micro-partitions](https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions)
2. **Which table types survive a session, have Fail-safe, or support 30-day Time Travel?** Transient and permanent tables survive a session. Only permanent tables have Fail-safe. On Enterprise Edition, configure a permanent table with `DATA_RETENTION_TIME_IN_DAYS = 30` for 30-day Time Travel. [Table types](https://docs.snowflake.com/en/user-guide/tables-temp-transient#comparison-of-table-types)
3. **Standard view versus materialized view versus `SECURE`?** A standard view stores its query definition. A materialized view stores a maintained result. `SECURE` protects the view definition and does not decide whether the result is stored. [View types](https://docs.snowflake.com/en/user-guide/views-introduction)
4. **For Iceberg, what do catalog management and file storage each do?** The catalog points to the current table metadata; storage holds data and metadata files. Snowflake can manage the catalog while the files remain in your S3 bucket through an external volume. [Iceberg tables](https://docs.snowflake.com/en/user-guide/tables-iceberg#catalog)
5. **Does `TARGET_LAG = '10 minutes'` mean refresh exactly every ten minutes?** No. It is a freshness target; actual refresh timing and lag can vary. [Target lag](https://docs.snowflake.com/en/user-guide/dynamic-tables/target-lag)

