# Mixed SnowPro Core Practice — Round 2

[Study notes](../readme.md) · [C03 study guide](../../SnowProCoreStudyGuideC03.pdf)

These 25 questions mix all five domains, with five questions from each. Try them without opening the answers. Each explanation links to Snowflake documentation. The questions are practice material, not official exam questions.

## Question 1

A table has `ENABLE_SCHEMA_EVOLUTION = TRUE`. A CSV file has a header and a new column. The loading role has `EVOLVE SCHEMA` on the table. The `COPY INTO` command uses `MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE`, and the file format uses `PARSE_HEADER = TRUE`. But the file format also has `ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE`.

What change is needed for CSV schema evolution?

- **A.** Set `ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE`.
- **B.** Run `INFER_SCHEMA` before every load.
- **C.** Remove `MATCH_BY_COLUMN_NAME`.
- **D.** Grant `OWNERSHIP` on the table as well as `EVOLVE SCHEMA`.

<details>
<summary>Correct answer and explanation</summary>

**A.** For CSV schema evolution with `MATCH_BY_COLUMN_NAME` and `PARSE_HEADER`, set `ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE`. The role already has the needed `EVOLVE SCHEMA` privilege; `OWNERSHIP` is an alternative, not an additional requirement. [Schema evolution](https://docs.snowflake.com/en/user-guide/data-load-schema-evolution)

</details>

## Question 2

A provider wants to give one specific customer access to a **native Snowflake table**. The customer's account is in a different Snowflake region. The provider wants Snowflake to handle fulfillment to that region.

Which approach fits?

- **A.** Add the customer's account to a direct share.
- **B.** Create a private listing with cross-cloud auto-fulfillment.
- **C.** Create a reader account in the provider's region.
- **D.** Grant the customer's user a role in the provider's account.

<details>
<summary>Correct answer and explanation</summary>

**B.** A direct share targets accounts in the same Snowflake region. A private listing can target a selected customer in another region, with auto-fulfillment handling the cross-region copy. [Sharing options](https://docs.snowflake.com/en/guides-overview-sharing)

</details>

## Question 3

A user queries a table in their own Snowflake account. Their primary role is `ANALYST`, and `PII_READ` is active as a secondary role. `ANALYST` does **not** inherit `PII_READ`.

Two masking policies are tested separately on the same column:

- Policy 1 reveals the value when `CURRENT_ROLE() = 'PII_READ'`.
- Policy 2 reveals the value when `IS_ROLE_IN_SESSION('PII_READ')` is true.

What does the user see?

- **A.** Unmasked values with both policies.
- **B.** Masked values with both policies.
- **C.** Masked with Policy 1; unmasked with Policy 2.
- **D.** Unmasked with Policy 1; masked with Policy 2.

<details>
<summary>Correct answer and explanation</summary>

**C.** `CURRENT_ROLE()` identifies the primary role, `ANALYST`. `IS_ROLE_IN_SESSION` can recognize a role in the active primary or secondary role hierarchy, so Policy 2 sees `PII_READ`. [IS_ROLE_IN_SESSION](https://docs.snowflake.com/en/sql-reference/functions/is_role_in_session)

</details>

## Question 4

A table contains these three rows:

| `event_ts` | `amount` |
| --- | ---: |
| 09:00 | 10 |
| 10:00 | 20 |
| 10:00 | 30 |

The query calculates:

```sql
SUM(amount) OVER (ORDER BY event_ts) AS running_total
```

What `running_total` appears on the **two 10:00 rows**?

- **A.** 30 and 60.
- **B.** 60 and 60.
- **C.** 20 and 30.
- **D.** The result cannot be determined.

<details>
<summary>Correct answer and explanation</summary>

**B.** For `SUM` with `ORDER BY` and no explicit frame, the default frame is `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`. Both 10:00 rows are peers, so each frame includes all three amounts: `10 + 20 + 30 = 60`. [Window-frame syntax](https://docs.snowflake.com/en/sql-reference/functions-window-syntax)

</details>

## Question 5

A team wants an Iceberg table whose data and metadata files stay in **its own S3 bucket**. It also wants **Snowflake to own the Iceberg catalog** and manage the table's lifecycle.

Which configuration matches?

- **A.** `CATALOG = 'SNOWFLAKE'` with an external volume pointing to the S3 location.
- **B.** An external catalog integration with no external volume.
- **C.** `EXTERNAL_VOLUME = SNOWFLAKE_MANAGED`.
- **D.** A named stage and a storage integration, with no Iceberg catalog setting.

<details>
<summary>Correct answer and explanation</summary>

**A.** The catalog setting controls who manages the Iceberg table metadata and lifecycle. The external volume controls where the files live. `SNOWFLAKE_MANAGED` storage would put files in Snowflake-provided storage instead of the team's S3 bucket. [Iceberg storage options](https://docs.snowflake.com/en/user-guide/tables-iceberg-storage) · [CREATE ICEBERG TABLE](https://docs.snowflake.com/en/sql-reference/sql/create-iceberg-table-snowflake)

</details>

## Question 6

Two independent tasks must process **every change** to the same `ORDERS` table. One updates a reporting table; the other writes an audit table. Each task runs its own committed DML transaction.

How should they track the changes?

- **A.** Have both tasks consume one stream on `ORDERS`; each task will maintain its own offset.
- **B.** Create a separate stream on `ORDERS` for each task.
- **C.** Have the second task query the first task's target table instead of change records.
- **D.** Use one stream and run `SELECT` on it after each task to reset its offset.

<details>
<summary>Correct answer and explanation</summary>

**B.** A stream has one offset. Once one task consumes it in a committed DML transaction, the other task may miss that change set. Separate streams let the independent tasks keep separate offsets. [Multiple consumers of streams](https://docs.snowflake.com/en/user-guide/streams-intro#multiple-consumers-of-streams)

</details>

## Question 7

On one UTC day, an account uses:

- 100 credits of warehouse compute.
- 15 credits of cloud services.
- 30 credits of Snowpipe.

Assume the cloud services usage supports those warehouses, and there are no other charges. What are the **resource monitor's counted credits** and the **total billed credits**, respectively?

- **A.** 105 counted; 135 billed.
- **B.** 115 counted; 135 billed.
- **C.** 145 counted; 135 billed.
- **D.** 115 counted; 145 billed.

<details>
<summary>Correct answer and explanation</summary>

**B.** The resource monitor counts `100 + 15 = 115` credits. It excludes Snowpipe and does **not** apply the cloud-services billing adjustment. Billing applies a 10-credit adjustment (10% of 100 warehouse credits), so the total is `100 + (15 - 10) + 30 = 135`. [Resource monitors](https://docs.snowflake.com/en/user-guide/resource-monitors) · [Cloud-services billing](https://docs.snowflake.com/en/user-guide/cost-understanding-compute)

</details>

## Question 8

A team wants a stored result that **joins `ORDERS` and `CUSTOMERS`**, then aggregates sales by region. They can tolerate roughly 10 minutes of delay, but they need to check whether the refreshes actually meet that goal.

Which plan fits?

- **A.** Create a materialized view with the join and set its refresh interval to 10 minutes.
- **B.** Create a dynamic table with `TARGET_LAG = '10 minutes'` and monitor its actual lag.
- **C.** Create a dynamic table with `TARGET_LAG = '10 minutes'`; this guarantees every change appears within 10 minutes.
- **D.** Create a standard view; the persisted result cache guarantees the stored result stays current.

<details>
<summary>Correct answer and explanation</summary>

**B.** Dynamic tables support SQL pipelines with joins and stored results. Target lag is a freshness goal, not a strict guarantee or exact refresh interval. A Snowflake materialized view cannot contain a join. [Dynamic-table target lag](https://docs.snowflake.com/en/user-guide/dynamic-tables-target-lag) · [Materialized-view limitations](https://docs.snowflake.com/en/user-guide/views-materialized#limitations-on-creating-materialized-views)

</details>

## Question 9

A provider creates `REPORTS.PUBLIC.PARTNER_V` as a **secure view**. It joins tables from `SALES` and `CRM`. A share already has `USAGE` on `REPORTS` and `REPORTS.PUBLIC`.

What must the provider do before granting `SELECT` on `PARTNER_V` to the share?

- **A.** Grant `REFERENCE_USAGE` on both `SALES` and `CRM` to the share.
- **B.** Grant `USAGE` on both `SALES` and `CRM` to the share.
- **C.** Grant a `SALES` database role and a `CRM` database role to the share.
- **D.** Grant `SELECT` on every underlying table directly to the share.

<details>
<summary>Correct answer and explanation</summary>

**A.** The share gets `USAGE` on the database containing the secure view. For each *other* database referenced by that view, grant `REFERENCE_USAGE` before granting `SELECT` on the view. [Sharing across databases](https://docs.snowflake.com/en/user-guide/data-sharing-multiple-db)

</details>

## Question 10

A Snowflake Notebook in Workspaces has a notebook service that still shows **`RUNNING`** on a compute pool. The user kills the notebook kernel and suspends the query warehouse. No SQL queries are running.

Which statement best describes compute charges now?

- **A.** Compute pool credits can continue while the notebook service is running; suspending the query warehouse does not stop that service.
- **B.** Killing the kernel automatically suspends the notebook service and compute pool.
- **C.** Only query warehouse credits continue because the compute pool is tied to that warehouse.
- **D.** No compute credits can accrue because no SQL query is running.

<details>
<summary>Correct answer and explanation</summary>

**A.** The notebook service's compute pool and the query warehouse are separate charge sources. Pool credits can continue while the service is running; suspend the service or use its idle timeout to stop it. [Notebook compute setup](https://docs.snowflake.com/en/user-guide/ui-snowsight/notebooks-in-workspaces/notebooks-in-workspaces-compute-setup)

</details>

## Question 11

Snowpipe tried to load `orders_001.csv`, but the file had an error. An engineer fixes the file, uploads it to the **same stage path with the same name**, and runs `ALTER PIPE ... REFRESH`.

What should they expect?

- **A.** Snowpipe loads it because the corrected file has different contents.
- **B.** Snowpipe may ignore it because the pipe recorded that path and name; use a new path or name, or explicitly reload it another way.
- **C.** Snowpipe loads it only after the virtual warehouse resumes.
- **D.** `ALTER PIPE ... REFRESH` deletes the failed file's load record and retries it.

<details>
<summary>Correct answer and explanation</summary>

**B.** Snowpipe records processed file paths and names, including failed attempts. Replacing a file under the same name does not make `ALTER PIPE ... REFRESH` retry it while that record is retained. Stage the corrected file under a new name, or use the documented bulk-load recovery route. [Troubleshooting Snowpipe](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-ts) · [Reloading a file](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-manage)

</details>

## Question 12

The `EMAIL` column has a tag whose masking policy replaces the whole value with `********`. The same column also has a **directly assigned** masking policy that shows only part of the value. Both policies match the column's data type.

Which policy takes effect when an authorized user queries the column?

- **A.** Both policies run, one after the other.
- **B.** The directly assigned masking policy.
- **C.** The tag-based masking policy.
- **D.** Neither; Snowflake rejects any column with both assignments.

<details>
<summary>Correct answer and explanation</summary>

**B.** A masking policy assigned directly to a column takes precedence over a masking policy inherited through a tag. [Tag-based masking policies](https://docs.snowflake.com/en/user-guide/tag-based-masking-policies)

</details>

## Question 13

One query is slow. Its Query Profile shows:

- Almost all irrelevant micro-partitions were pruned.
- Queue time is near zero.
- A necessary join spills a large amount of data to **remote storage**.
- Query Acceleration Service is disabled.

What is the most direct change to **test first**?

- **A.** Add a clustering key to the filtered table.
- **B.** Increase the maximum number of warehouse clusters.
- **C.** Try a larger warehouse size.
- **D.** Set `USE_CACHED_RESULT = FALSE`.

<details>
<summary>Correct answer and explanation</summary>

**C.** Remote spilling indicates that the operation needs more memory and local capacity. A larger warehouse is a direct test; extra clusters address concurrency, while pruning and queueing are already healthy. [Queries too large to fit in memory](https://docs.snowflake.com/en/user-guide/performance-query-warehouse-memory)

</details>

## Question 14

Yesterday, `COPY INTO` loaded `bulk.csv` into a table, and Snowpipe loaded `pipe.csv` into the same table. Today, the table is **truncated**. Both files remain staged and are within their load-history retention periods.

The team runs `COPY INTO` again for `bulk.csv` and `ALTER PIPE ... REFRESH` for `pipe.csv`. What should they expect?

- **A.** Both files reload.
- **B.** `bulk.csv` can reload; Snowpipe still recognizes and skips `pipe.csv`.
- **C.** Snowpipe can reload `pipe.csv`; `COPY INTO` still skips `bulk.csv`.
- **D.** Both files are skipped.

<details>
<summary>Correct answer and explanation</summary>

**B.** `TRUNCATE TABLE` clears the table's bulk-load metadata, so `COPY INTO` can reload `bulk.csv`. It does not clear Snowpipe's separate metadata on the pipe, so refreshing that pipe still skips `pipe.csv`. [TRUNCATE TABLE](https://docs.snowflake.com/en/sql-reference/sql/truncate-table) · [Snowpipe load metadata](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-intro)

</details>

## Question 15

A Cortex Search service indexes support documents. Its owner's role can read a sensitive document. A second role has `USAGE` on the service and its database and schema, but **no `SELECT`** on the source table.

What is the important access-control implication?

- **A.** The second role cannot search because it lacks `SELECT` on the source table.
- **B.** The second role may retrieve indexed content visible to the service owner, so grants on the service need care.
- **C.** Snowflake automatically rechecks every result using the second role's source-table privileges.
- **D.** `USAGE` on the service also gives the second role permission to edit the source documents.

<details>
<summary>Correct answer and explanation</summary>

**B.** Cortex Search queries run with the service owner's rights. A role allowed to query the service can retrieve indexed content even without `SELECT` on the source table. [Cortex Search access control](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/query-cortex-search-service#querying-with-owners-rights)

</details>

## Question 16

A team has two designs:

1. A Snowflake **external function** calls code running outside Snowflake through a cloud API gateway.
2. A **Python UDF running inside Snowflake** makes an HTTPS request from its handler code.

Which integration does each design use?

- **A.** 1: API integration; 2: external access integration.
- **B.** 1: external access integration; 2: API integration.
- **C.** Both use storage integrations.
- **D.** Both use notification integrations.

<details>
<summary>Correct answer and explanation</summary>

**A.** An external function invokes remote code through an API integration. Handler code running inside a Python UDF uses an external access integration to reach allowed network locations. [External functions](https://docs.snowflake.com/en/sql-reference/external-functions-introduction) · [External network access](https://docs.snowflake.com/en/developer-guide/external-network-access/external-network-access-overview)

</details>

## Question 17

All authentication checks pass. A user signs in through a SAML security integration from IP address `203.0.113.10`.

- The account network policy **allows** that IP.
- The user network policy **blocks** that IP.
- The network policy attached to the SAML security integration **allows** that IP.

What is the network-policy decision?

- **A.** Allowed, because the security integration's policy overrides the user and account policies.
- **B.** Blocked, because any blocked list wins across all three policies.
- **C.** Blocked, because a user policy always overrides an integration policy.
- **D.** Allowed only if the user has `ACCOUNTADMIN`.

<details>
<summary>Correct answer and explanation</summary>

**A.** Network policies are evaluated by specificity: security integration, then user, then account. The integration's policy is the one that applies to this login. A blocked rule wins over an allowed rule *within the same policy*, not across policies that have been overridden. [Network-policy precedence](https://docs.snowflake.com/en/user-guide/network-policies#network-policy-precedence)

</details>

## Question 18

Order `102` has an empty `items` array: `[]`. A query uses:

```sql
FROM orders o,
LATERAL FLATTEN(INPUT => o.items, OUTER => TRUE) f
```

For order `102`, what do `COUNT(*)` and `COUNT(f.index)` return when grouped by `o.order_id`?

- **A.** `0` and `0`.
- **B.** `1` and `0`.
- **C.** `1` and `1`.
- **D.** The order disappears from the result.

<details>
<summary>Correct answer and explanation</summary>

**B.** `OUTER => TRUE` emits one placeholder row for an empty array, so `COUNT(*)` is 1. That placeholder has a null `INDEX`, so `COUNT(f.index)` is 0. [FLATTEN](https://docs.snowflake.com/en/sql-reference/functions/flatten)

</details>

## Question 19

A consumer creates an imported database named `PARTNER` from a share. The provider included a database role named `READER`, which gives access to **only one subset** of the shared objects.

The consumer wants its local account role `ANALYST` to access that subset. Which grant fits?

- **A.** `GRANT DATABASE ROLE PARTNER.READER TO ROLE ANALYST;`
- **B.** `GRANT IMPORTED PRIVILEGES ON DATABASE PARTNER TO ROLE ANALYST;`
- **C.** `GRANT ROLE PARTNER.READER TO USER ANALYST;`
- **D.** `GRANT SELECT ON ALL TABLES IN DATABASE PARTNER TO ROLE ANALYST;`

<details>
<summary>Correct answer and explanation</summary>

**A.** The provider used a database role to define this subset. The consumer grants that imported database role to a local account role. `IMPORTED PRIVILEGES` applies to objects granted directly to the share without that database-role path. [Consuming shared data](https://docs.snowflake.com/en/user-guide/data-share-consumers#granting-privileges-on-an-imported-database)

</details>

## Question 20

A user runs this query on `WH_A`, then runs the **identical text** on `WH_B`. The table has not changed, and `USE_CACHED_RESULT` is enabled:

```sql
SELECT COUNT(*), RANDOM()
FROM EVENTS;
```

Which statement is most accurate?

- **A.** The second run can reuse the full persisted result because the SQL text and table data match.
- **B.** `WH_B` automatically inherits `WH_A`'s local data cache.
- **C.** `RANDOM()` prevents reuse of the full persisted query result, so the second query must execute.
- **D.** Suspending either warehouse deletes all persisted query results in the account.

<details>
<summary>Correct answer and explanation</summary>

**C.** `RANDOM()` is non-reusable: successive runs can return different values. An identical query text and unchanged table are not enough for full persisted-result reuse. Local warehouse caches are separate as well. [Persisted query results](https://docs.snowflake.com/en/user-guide/querying-persisted-results)

</details>

## Question 21

A stream has unconsumed changes. One session runs both statements in a **single explicit transaction**:

```sql
BEGIN;

INSERT INTO REPORT_ORDERS
SELECT * FROM ORDERS_STREAM;

INSERT INTO AUDIT_ORDERS
SELECT * FROM ORDERS_STREAM;

COMMIT;
```

Assume the target tables accept the selected columns. What happens to the stream data?

- **A.** The first `INSERT` consumes it, so the second gets no rows.
- **B.** Both statements see the same change set; the stream offset advances when the transaction commits.
- **C.** Snowflake rejects the second `INSERT` because a stream can appear only once per transaction.
- **D.** Reading the stream advances its offset before either `INSERT` runs.

<details>
<summary>Correct answer and explanation</summary>

**B.** Within one explicit transaction, both DML statements can read the same stream snapshot. Its offset advances when the transaction commits. For two *independent* task transactions, use separate streams as in Question 6. [CREATE STREAM usage notes](https://docs.snowflake.com/en/sql-reference/sql/create-stream#usage-notes)

</details>

## Question 22

A session's primary role is `ANALYST`. Its active secondary role, `TABLE_OWNER`, owns `DB.S.OLD_T` and has `CREATE TABLE` on `DB.S`. `ANALYST` has the required database and schema access but **no `CREATE TABLE`** privilege.

The user runs these statements separately:

```sql
DROP TABLE DB.S.OLD_T;
CREATE TABLE DB.S.NEW_T (ID NUMBER);
```

Which outcome is expected?

- **A.** Both succeed because secondary-role privileges are always combined.
- **B.** `DROP` succeeds, but `CREATE` fails.
- **C.** `DROP` fails, but `CREATE` succeeds.
- **D.** Both fail because secondary roles cannot authorize DDL.

<details>
<summary>Correct answer and explanation</summary>

**B.** An active secondary role's ownership can authorize DDL on an existing object, such as `DROP TABLE`. But Snowflake authorizes `CREATE <object>` using the primary role and roles it inherits, so this `CREATE TABLE` fails. [Primary and secondary role authorization](https://docs.snowflake.com/en/user-guide/security-access-control-overview#authorization-through-primary-role-and-secondary-roles)

</details>

## Question 23

A 4-billion-row table receives heavy inserts and updates all day. Analysts run a selective `transaction_id = ?` lookup only **twice a week**. A teammate proposes enabling Search Optimization on `transaction_id`.

What is the most important trade-off to evaluate?

- **A.** The search access path needs storage and ongoing maintenance; with high data churn and few lookups, its cost may outweigh the query benefit.
- **B.** Search Optimization has no ongoing cost after its initial build.
- **C.** Search Optimization speeds queries by adding warehouse clusters during peak concurrency.
- **D.** Search Optimization cannot help equality lookups on an ID column.

<details>
<summary>Correct answer and explanation</summary>

**A.** Search Optimization can help selective equality lookups, but it builds and maintains a search access path. Frequent table changes raise maintenance costs, while only two weekly lookups offer limited savings. Measure query benefit against build, storage, and maintenance costs. [Search Optimization cost](https://docs.snowflake.com/en/user-guide/search-optimization/cost-estimation)

</details>

## Question 24

A source account commits new orders at **10:06**. The secondary failover group's last successful refresh captured a source snapshot from **10:05**. The source account becomes unavailable at 10:07, and the team promotes the secondary.

What should the team assume about the 10:06 orders **immediately after promotion**?

- **A.** They are present because promotion automatically copies any unreplicated writes.
- **B.** They may be absent because the last completed refresh did not capture them.
- **C.** They are available through the secondary account's Fail-safe without further work.
- **D.** They become visible when the secondary warehouse is resized.

<details>
<summary>Correct answer and explanation</summary>

**B.** Promotion makes the replica writable; it does not automatically transfer commits that happened after its last captured snapshot. Reconcile or replay missing writes if the source or upstream pipeline can supply them. [Replication lag](https://docs.snowflake.com/en/sql-reference/functions/replication_group_lag_history) · [Avoiding data loss](https://docs.snowflake.com/en/user-guide/account-replication-considerations#avoiding-data-loss)

</details>

## Question 25

An account upgrades from Standard to Enterprise. An **existing permanent table** still has a one-day Time Travel retention setting. The team wants **30 days of Time Travel going forward** for that table.

What should they do?

- **A.** Set the table's `DATA_RETENTION_TIME_IN_DAYS` to `30`.
- **B.** Do nothing; upgrading automatically changes every permanent table to 90 days.
- **C.** Set the warehouse's `AUTO_SUSPEND` to 30 days.
- **D.** Change the table's Fail-safe period to 30 days.

<details>
<summary>Correct answer and explanation</summary>

**A.** Enterprise permits longer Time Travel retention, but upgrading does not automatically change this table's one-day setting. Set `DATA_RETENTION_TIME_IN_DAYS = 30` on the table. This does not bring back history that already expired. [Time Travel](https://docs.snowflake.com/en/user-guide/data-time-travel)

</details>

## Related correction

Current Snowflake syntax permits `GRANT DATABASE ROLE <name> TO USER <user_name>`. A database role still cannot be selected as the session's primary or secondary role. Earlier practice notes may say the direct grant syntax is impossible; that statement is outdated. [GRANT DATABASE ROLE](https://docs.snowflake.com/en/sql-reference/sql/grant-database-role) · [Role activation](https://docs.snowflake.com/en/user-guide/security-access-control-overview#authorization-through-primary-role-and-secondary-roles)
