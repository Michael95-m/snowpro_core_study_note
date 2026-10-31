# 1.3 Practice: Objects, Sessions, and Parameters

[Practice index](readme.md) | [Study note](../03-objects-sessions-and-parameters.md)

This records all 15 multiple-choice questions and the follow-up recall/explanation exchanges from our 1.3 round. Initial choices were correct on 13 of 15 questions. Questions 10 and 15 needed correction; later explanations also clarified stages, file formats, and pipes.

## Question 1: Warehouse location in the hierarchy

A developer creates database `ANALYTICS`, schema `MART`, and warehouse `BI_WH`. They expect the warehouse inside `ANALYTICS.MART`. Which statement is correct?

A. Warehouses belong inside schemas, but only appear when running.  
B. Warehouses are account-level objects, separate from the database/schema hierarchy.  
C. Every database automatically owns one warehouse.  
D. A warehouse must be moved into a schema before it can query its tables.

<details>
<summary>Your answer and explanation</summary>

**Your answer:** B. **Correct.**

A warehouse supplies account-level compute. Tables and other schema objects sit under `database.schema`; the warehouse can query across those namespaces with the required access.

</details>

## Question 2: Reusable CSV parsing settings

Several CSV loads must use the same comma delimiter and skip the header. Which object saves those settings?

A. A file format  
B. A pipe  
C. A named stage  
D. A sequence

<details>
<summary>Your answer and explanation</summary>

**Your answer:** A. **Correct.**

```sql
CREATE FILE FORMAT study_csv
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1;
```

A file format stores parsing settings, not source files or target rows.

</details>

## Question 3: Referencing files in S3

A team needs a reusable Snowflake object referencing files in S3. Files remain there until explicitly loaded. Which object fits?

A. A permanent table  
B. A named external stage  
C. A file format  
D. A stored procedure

<details>
<summary>Your answer and explanation</summary>

**Your answer:** B. **Correct.**

An external stage references the cloud-storage location. Creating it does not automatically load files into a table.

</details>

## Question 4: Reusable calculation inside SELECT

Which object should implement this calculation?

```sql
SELECT order_id, calculate_tax(amount)
FROM orders;
```

A. A stored procedure  
B. A sequence  
C. A scalar UDF  
D. A pipe

<details>
<summary>Your answer and explanation</summary>

**Your answer:** C. **Correct.**

A scalar UDF produces a value that can be used in an expression. A procedure is typically invoked with `CALL` for a workflow.

</details>

## Question 5: Multi-step DDL/DML workflow

A workflow creates a staging table, inserts transformed data, and updates an audit table. Which object fits?

A. A stored procedure  
B. A scalar UDF  
C. A file format  
D. A sequence

<details>
<summary>Your answer and explanation</summary>

**Your answer:** A. **Correct.**

A stored procedure can execute authorized DDL and DML as part of a procedural workflow.

</details>

## Question 6: Fully qualified table name

```sql
USE DATABASE analytics;
USE SCHEMA mart;
SELECT * FROM orders;
```

Assuming a normal table in the selected schema, which name does `orders` resolve to?

A. `analytics.orders.mart`  
B. `mart.analytics.orders`  
C. `analytics.mart.orders`  
D. `orders.analytics.mart`

<details>
<summary>Your answer and explanation</summary>

**Your answer:** C. **Correct.**

The order is **database → schema → object**.

</details>

## Question 7: Session parameter precedence

`TIMEZONE` is `UTC` at account level, `Asia/Bangkok` at user level, and explicitly `Asia/Tokyo` in the session. Which applies?

A. `UTC`  
B. `Asia/Tokyo`  
C. `Asia/Bangkok`  
D. The laptop's timezone

<details>
<summary>Your answer and explanation</summary>

**Your answer:** B. **Correct.**

For session parameters, explicit **session → user → account → system default** settings determine precedence.

</details>

## Question 8: Removing a session override

In that same session, the user runs:

```sql
ALTER SESSION UNSET TIMEZONE;
```

The user setting remains `Asia/Bangkok`, and the account setting is `UTC`. Which now applies?

A. `UTC`  
B. `NULL`  
C. `Asia/Bangkok`  
D. `Asia/Tokyo` permanently remains active

<details>
<summary>Your answer and explanation</summary>

**Your answer:** C. **Correct.**

`UNSET` removes the explicit session override. It does not mean setting the value to NULL, zero, or false.

</details>

## Question 9: Referencing a session variable

After `SET study_region = 'APAC';`, which expression references that variable?

A. `CURRENT_REGION()`  
B. `study_region`  
C. `:study_region`  
D. `$study_region`

<details>
<summary>Your answer and explanation</summary>

**Your answer:** D. **Correct.**

```sql
SELECT $study_region AS selected_region;
```

An SQL session variable is different from a behavioral parameter such as `TIMEZONE`.

</details>

## Question 10: Gap-free invoice numbering

A finance team requires invoice numbers with no gaps. Is a Snowflake sequence with `INCREMENT = 1` sufficient?

A. Incrementing by 1 guarantees gap-free numbering.  
B. Sequence values can have gaps, so this alone does not meet the requirement.  
C. Sequences work only in Enterprise Edition.  
D. Sequence values restart whenever a warehouse suspends.

<details>
<summary>Your answer, correction, and retry</summary>

**Your initial answer:** A. **Incorrect. Correct answer: B.**

`INCREMENT = 1` does not guarantee contiguous stored values. Some generated values may never be stored in the final table.

```text
Generated:       1, 2, 3
Stored invoices: 1,    3
```

**Follow-up question:** Why isn't an increment of 1 enough to guarantee gap-free invoice numbers?

**Your retry:** "because even if increment = 1, snowflake gurantees that it can't be contiguous if they didn't save the value"

**Wording correction:** Snowflake **does not guarantee** contiguous numbers. It also does not guarantee that gaps always occur. The final stored identifiers **can** have gaps.

</details>

## Question 11: Sharing while retaining ownership

A provider wants another account to query selected data while retaining ownership. Which object enables it?

A. A file format  
B. A sequence  
C. A share  
D. A named internal stage

<details>
<summary>Your answer and explanation</summary>

**Your answer:** C. **Correct.**

A share is an account-level object granting access to selected data objects. The provider retains ownership.

</details>

## Question 12: File-based Snowpipe definition

Which object stores the `COPY INTO <table>` definition for file-based Snowpipe?

A. A file format  
B. A named stage  
C. A sequence  
D. A pipe

<details>
<summary>Your answer and explanation</summary>

**Your answer:** D. **Correct.**

The pipe stores loading instructions, the stage stores/references files, and the file format provides parsing settings.

</details>

## Question 13: Explicit table retention

In an Enterprise account, retention settings are account = 1 day, database = 7, schema = 14, and permanent table `orders` explicitly = 30. What is effective for `orders`?

A. 30 days  
B. 14 days  
C. 7 days  
D. 1 day

<details>
<summary>Your answer and explanation</summary>

**Your answer:** A. **Correct.**

The explicit table setting takes precedence over its inherited parent defaults for this parameter. Object parameters follow their supported object hierarchy, not automatically the session-parameter hierarchy.

</details>

## Question 14: Registered ML model

A team wants model versions, metadata, and callable inference methods. Which object represents the registered model?

A. A file format  
B. An ML model object  
C. A pipe  
D. A standard view

<details>
<summary>Your answer and explanation</summary>

**Your answer:** B. **Correct.**

A registered ML model object manages the model and its versions; it is distinct from the training table and a local Python variable.

</details>

## Question 15: Installed Native App

A provider packages data and application logic. A consumer installs the Native App. Which object represents the installed app in the consumer account?

A. An application package  
B. A database role  
C. An application  
D. A named stage

<details>
<summary>Your answer, correction, and retry</summary>

**Your initial answer:** A. **Incorrect. Correct answer: C.**

```text
Provider account                 Consumer account
Application package -- install --> Application
```

**Follow-up question:** How does an application package differ from an application?

**Your retry:** "the application is the installed app installed in the consumer's account. Application package is like docker container for packaging and distributing the app"

**Correction:** The installed-app definition is right. Think of the application package as a **software installation/distribution package**, rather than a Docker runtime container. It is a provider-side Snowflake object organizing the app's data, setup logic, and versions.

</details>

## Recall follow-up: Stage, file format, and pipe

**Question:** Explain the difference between a stage, a file format, and a pipe.

<details>
<summary>Your answers and the corrected explanation</summary>

**Your answer:** "A stage is the reference for the files that is uploaded or from the cloud. A file format is the object which is like file parser that can be applied to the file stage"

**Correction:** An internal stage stores uploaded files; an external stage references cloud files. A file format stores instructions that Snowflake's parser uses; it is not the parser itself.

**Follow-up question:** What does a pipe store, and how does file-based Snowpipe use it?

**Your answer:** "A pipe is the object that can be used to ingest the data continuously like the streaming"

**Correction:** Continuous ingestion is the right idea. More precisely, for file-based Snowpipe, the pipe stores a `COPY INTO` loading definition. Snowpipe is the managed service that runs those loading instructions. Snowpipe Streaming ingests rows directly, rather than loading staged files.

**Retry question:** Does a pipe store the files, parsing settings, or loading instructions?

You requested an explanation instead of selecting an answer. We used this CSV example:

```csv
order_id,amount
101,50
102,80
```

| Object | Job |
| --- | --- |
| Stage | Where the files are stored or referenced. |
| File format | How to parse them: CSV, delimiter, and header settings. |
| Pipe | Loading definition: source stage, destination table, and file-format settings. |

```sql
-- Existing stage, table, format, and appropriate privileges required.
CREATE PIPE sales_pipe AS
COPY INTO sales
FROM @sales_stage
FILE_FORMAT = (FORMAT_NAME = 'csv_format');
```

```text
New file arrives
    → Snowpipe receives a configured notification
    → Snowpipe follows the pipe's loading instructions
    → Rows are inserted into the target table
```

Creating this pipe alone does not configure automatic detection. Auto-ingest requires the appropriate pipe setting and cloud-event notification setup; the REST API is another way to submit file notifications. This final explanation was discussed, but you did not give a further closed-book answer afterward.

</details>

## Review targets

1. Explain why a sequence can leave gaps even with an increment of 1.
2. Distinguish provider-side application packages from consumer-side installed applications.
3. Explain stage, file format, pipe, and Snowpipe without treating them as the same object or service.

## Official references used in the discussion

- [Object hierarchy and access](https://docs.snowflake.com/en/user-guide/security-access-control-overview)
- [File formats](https://docs.snowflake.com/en/sql-reference/sql/create-file-format)
- [Stages](https://docs.snowflake.com/en/sql-reference/sql/create-stage)
- [Procedures versus UDFs](https://docs.snowflake.com/en/developer-guide/stored-procedures-vs-udfs)
- [Name resolution](https://docs.snowflake.com/en/sql-reference/name-resolution)
- [Parameters](https://docs.snowflake.com/en/sql-reference/parameters)
- [SQL variables](https://docs.snowflake.com/en/sql-reference/session-variables)
- [Sequences](https://docs.snowflake.com/en/user-guide/querying-sequences)
- [Data sharing](https://docs.snowflake.com/en/user-guide/data-sharing-intro)
- [Snowpipe](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-intro)
- [Time Travel](https://docs.snowflake.com/en/user-guide/data-time-travel)
- [Model Registry](https://docs.snowflake.com/en/developer-guide/snowpark-ml/model-registry/overview)
- [Native Apps](https://docs.snowflake.com/en/developer-guide/native-apps/native-apps-about)
