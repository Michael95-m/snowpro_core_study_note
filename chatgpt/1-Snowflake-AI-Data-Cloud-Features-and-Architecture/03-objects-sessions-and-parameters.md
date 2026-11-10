# 1.3 Objects, Sessions, and Parameters

[Domain 1 index](readme.md)

- **C03 objective:** 1.3. Read the definitions, work through the scenario, then answer recall questions.
- **Practice:** [ordered lab guide](exercises/readme.md); start with its setup.
- **SQL status:** examples reviewed against official documentation; not executed in your account.

<a id="object-hierarchy"></a>

## 1.3.1 Object hierarchy

```text
Organization
└── Account
    ├── Account-level objects: warehouses, users, roles, shares, integrations
    └── Database
        └── Schema
            └── Tables, views, named stages, file formats, UDFs,
                stored procedures, pipes, sequences, model objects
```

<p align="center"><img src="../../img/object_model.png" alt="Snowflake object hierarchy from the course notes" width="600"></p>

- A **container** organizes child objects.
- A **securable object** can have privileges granted on it.
- The C03 list groups many objects together for study.
- A **share is account-level**, not a child of a database schema.
- A Native App **application** is also an account-level installed object with its own contents.

<a id="object-comparison"></a>

## 1.3.2 Object comparison

| Object | What it represents | Important distinction |
| --- | --- | --- |
| Organization | Groups Snowflake accounts. | Organization-level administration differs from account administration. |
| Account | Security/administrative boundary deployed in a cloud region. | Different accounts do not automatically share data or roles. |
| Database | Container for schemas and their objects. | It stores organized data objects; it is not a compute warehouse. |
| Schema | Namespace inside a database. | `database.schema.object` is the normal fully qualified name. |
| Table | Stored rows or a supported table abstraction. | Table types differ in lifetime, storage, and maintenance. |
| View | Query definition over other objects. | A standard view does not store its result. |
| Named stage | Internal file storage or reference to external storage. | It holds/references files, not automatically loaded table rows. |
| File format | Parsing/unloading settings, such as delimiter, JSON, compression, and header behavior. | It contains settings, not the source file itself. |
| UDF | Reusable calculation returning a scalar value or table. | Use it in a query, subject to its supported function form. |
| Stored procedure | Reusable procedural workflow. | Invoke with `CALL`; can perform authorized DDL/DML. |
| Pipe | Stored ingestion definition for Snowpipe. | File-based Snowpipe uses a `COPY INTO` definition and serverless ingestion compute. |
| Share | Grants selected data-object access to consumer accounts. | Ownership stays with the provider; it is not an exported file. |
| Sequence | Generates numeric values for identifiers. | Values can have gaps; do not treat it as a gap-free row counter. |
| ML model | Registered model object with versions and inference methods. | Model artifacts/metadata differ from the training dataset. |
| Application | Installed Snowflake Native App and its packaged logic/data objects. | An application package is the provider's distribution container. |

- **Loading operations:** [loading note](../../study-notes/7-Data-Loading-and-Unloading/readme.md).
- **Shares and app distribution:** [sharing note](../../study-notes/9-Storage-Data-Protection-and-sharing/readme.md).
- **Grants and ownership:** [Domain 2](../2-Account-Management-and-Data-Governance/readme.md).

#### A missing schema between two dots

- `mydb..orders` means **`mydb.PUBLIC.orders`**. Snowflake fills the empty schema segment with `PUBLIC` for compatibility with other SQL systems.
- It does **not** search every schema in `mydb`, and it does not use your current schema for that empty segment.
- Prefer the explicit `mydb.PUBLIC.orders` in new SQL. Compare it with `orders`, which uses the session's current database and schema.
- [Official name-resolution rule](https://docs.snowflake.com/en/sql-reference/name-resolution#resolution-when-schema-omitted-double-dot-notation)

<a id="example-objects"></a>

## 1.3.3 Example objects

- Before running these examples:
  1. Select a writable schema using `USE DATABASE` and `USE SCHEMA`.
  2. Use a role with suitable creation privileges.

```sql
CREATE FILE FORMAT study_csv TYPE = CSV SKIP_HEADER = 1;
CREATE STAGE study_stage FILE_FORMAT = (FORMAT_NAME = 'study_csv');
CREATE SEQUENCE study_order_seq START = 1 INCREMENT = 1;

CREATE FUNCTION study_add_tax(amount NUMBER(12,2))
  RETURNS NUMBER(12,2)
  LANGUAGE SQL
  AS $$ amount * 1.07 $$;

SELECT study_add_tax(100), study_order_seq.NEXTVAL;
```

- A **function** applies a reusable calculation inside SQL.
- A **procedure** runs a workflow of statements:
  - It may return a value or table.
  - You do not generally substitute `CALL` into a scalar expression.

<a id="session-context"></a>

## 1.3.4 Session context

- Each connection has its own **session state**.
- **Session context** controls:
  - How unqualified object names are resolved.
  - Which compute and role the session uses.

```sql
USE ROLE SYSADMIN;
USE WAREHOUSE D1_STUDY_WH;
USE DATABASE D1_STUDY;
USE SCHEMA LAB;

SELECT CURRENT_ROLE(), CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_SCHEMA();
```

- With this context, `orders` resolves to `D1_STUDY.LAB.ORDERS`.
- Fully qualified names reduce ambiguity.
- **Quoted identifiers** are case-sensitive.
- **Unquoted identifiers** normally resolve in uppercase.

<a id="variables-versus-parameters"></a>

## 1.3.5 Variables versus parameters

| Concept | Example | Meaning |
| --- | --- | --- |
| SQL session variable | `SET region = 'APAC'` | A value referenced later as `$region`. |
| Context function | `CURRENT_ROLE()` | Returns current session/account context. |
| Session parameter | `ALTER SESSION SET TIMEZONE = 'UTC'` | Changes session behavior, not an arbitrary SQL variable. |
| Object parameter | Table retention setting | Changes the supported object's configuration. |

```sql
SET study_region = 'APAC';
SELECT $study_region AS selected_region;
UNSET study_region;

SHOW PARAMETERS LIKE 'TIMEZONE' IN SESSION;
-- If changed during practice, restore your previous setting afterward.
```

<a id="parameter-hierarchy-and-precedence"></a>

## 1.3.6 Parameter hierarchy and precedence

- For a **session parameter**, use this order from highest to lowest priority:
  1. Explicit session setting.
  2. User setting.
  3. Account default.
  4. System default, if none of the above is explicitly set.

- For **object parameters**, inheritance depends on the parameter and its supported containers.
- Example: table retention can be set at these levels:
  - Account.
  - Database.
  - Schema.
  - Table.
- A specific table setting takes precedence over a parent default.
- **Account-only parameters** cannot be overridden in a session.
- Do not apply one universal precedence rule to every parameter.

- `SHOW PARAMETERS` displays the value and level.
- `UNSET` removes an explicit override.
- The inherited or default value can then apply.
- `UNSET` does not necessarily set the parameter to zero or false.

<a id="more-object-distinctions-and-exercise-checkpoints"></a>

## 1.3.7 More object distinctions and exercise checkpoints

| Need | Object/control | Scope or behavior |
| --- | --- | --- |
| Secure access to external storage | Storage integration | Account-level; a stage can reference it. |
| Store or reference staged files | Named stage | Schema-level; not a table of loaded rows. |
| Keep parsing settings | Named file format | Schema-level; `FORMAT_NAME` references its saved settings. |
| Fetch code into Snowflake | Git repository object | Schema-level; distinct from its account-level API integration. |
| Configure allowed login methods | Authentication policy | Schema-level policy assigned to a user/account. |
| Restrict incoming network origins | Network policy | Account-level policy object; creation and activation are separate. |

- A **scalar function** returns one value per call; a **table function** returns rows/columns usable in a FROM clause.
- `TABLE(...)` makes a table function's output usable as a relation; it does not create a persistent table.

```sql
SELECT SEQ4() AS EXAMPLE_VALUE
FROM TABLE(GENERATOR(ROWCOUNT => 3));
-- Three result rows; no persistent table is created.
```

- A procedure can perform authorized work such as an INSERT and return a status; its execution rights still matter.
- A sequence allocates identifiers, not business-event counts. Rollbacks/concurrency can leave gaps.
- An application package is the provider's packaging/distribution object; an installed application exists in the consumer account. It is not simply a Docker image.
- **Practice:** [02-objects-and-parameters.sql](exercises/02-objects-and-parameters.sql).
- **Checkpoint:** UDF tax result **107**; procedure log **1 row**; region variable returns order IDs **1, 2, 5**.
- **Remember:** a variable holds a value, a context function reports state, and a parameter changes supported behavior.

## What to recall



1. Where do warehouses, shares, schemas, pipes, and UDFs sit in the hierarchy?
2. How do stage, file format, and pipe differ?
3. When do you choose a UDF versus a stored procedure?
4. Why is a sequence not a reliable row-count or gap-free invoice mechanism?
5. How does a fully qualified name differ from the current database/schema context?
6. How do a session variable and a session parameter differ?
7. Which session-parameter level wins, and what does `UNSET` do?
8. What are the scopes of a storage integration and a Git repository object?
9. What does a table function return, and does TABLE(...) create permanent storage?
10. What object does `mydb..orders` name? Does it search schemas or use the current schema?

<details>
<summary>Open the recall answer key</summary>

1. Warehouses/shares are account-level; schemas belong to databases; pipes/UDFs belong to schemas.
2. A stage stores/references files; a file format stores parsing settings; a pipe stores an ingestion definition.
3. Use a UDF for reusable expressions/table-returning calculations; use a procedure for an authorized workflow invoked with CALL.
4. Values can be allocated without becoming committed business rows, so gaps are possible.
5. A fully qualified name specifies database.schema.object explicitly; an unqualified name uses session defaults.
6. A session variable stores a referenced value; a session parameter configures supported behavior.
7. An explicit session value wins over user/account defaults for a session parameter. UNSET removes the override so inheritance/defaults can apply.
8. Storage integration: account-level. Git repository clone: schema-level. The clone is separate from its API integration.
9. Rows and columns that can be queried with FROM TABLE(...); it does not create a permanent table.
10. `mydb.PUBLIC.orders`; the empty schema segment resolves specifically to PUBLIC.

</details>

## Official references

- [Securable objects and hierarchy](https://docs.snowflake.com/en/user-guide/security-access-control-overview)
- [Parameters](https://docs.snowflake.com/en/sql-reference/parameters)
- [SQL variables](https://docs.snowflake.com/en/sql-reference/session-variables)
- [Procedures versus UDFs](https://docs.snowflake.com/en/developer-guide/stored-procedures-vs-udfs)
- [Sequences](https://docs.snowflake.com/en/user-guide/querying-sequences)
- [Object name resolution](https://docs.snowflake.com/en/sql-reference/name-resolution)
