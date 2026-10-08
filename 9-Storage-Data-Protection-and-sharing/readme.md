# Storage, Data Protection, and Data Sharing

## Storage Summary

Snowflake stores table data in cloud-object storage managed by Snowflake on the cloud provider where the account runs, such as Amazon S3 on AWS. Users do not access Snowflake's underlying storage files directly. Instead, they load, query, and manage data through Snowflake SQL, stages, and supported interfaces.

## Micro-Partitions

Snowflake automatically divides data in every table into immutable, columnar micro-partitions. You do not create or manage these partitions yourself.

- Each micro-partition contains approximately **50 MB to 500 MB of uncompressed data**. Snowflake stores the actual data compressed.
- Snowflake records metadata for each micro-partition, including the range of values and number of distinct values for columns.
- When a query has a selective predicate, such as `WHERE order_date >= '2026-01-01'`, Snowflake can use this metadata to skip micro-partitions that cannot contain matching rows. This is **micro-partition pruning**.
- Updates and deletes do not change an existing micro-partition. Snowflake writes new micro-partitions and keeps the old versions for Time Travel when applicable.

### Clustering and Pruning

Micro-partitions are created using the order in which data is inserted or loaded. If commonly filtered values are spread across many overlapping micro-partitions, pruning is less effective.

For large tables with frequent, selective filters, a clustering key can improve the natural ordering of the data and reduce the number of micro-partitions scanned. Clustering is optional; use it only when query-performance benefits justify its maintenance cost.

## Time Travel and Fail-safe

Snowflake protects historical data in two different ways:

| Feature | Purpose | Direct user access? |
| --- | --- | --- |
| Time Travel | Query, clone, or restore historical data within the retention period. | Yes, using SQL. |
| Fail-safe | Disaster recovery after Time Travel has ended. | No. Contact Snowflake Support. |

Time Travel supports three main use cases:

1. Query data as it existed at an earlier point in time.
2. Clone a table, schema, or database from an earlier point in time.
3. Restore a dropped supported object with `UNDROP`.

### Time Travel Retention Period

Configure retention with `DATA_RETENTION_TIME_IN_DAYS` at the account, database, schema, or table level. A more specific object-level setting can override its parent default.

```sql
-- Requires Enterprise Edition or higher for a value greater than 1.
ALTER DATABASE my_db
  SET DATA_RETENTION_TIME_IN_DAYS = 90;
```

| Object and edition | Allowed retention |
| --- | --- |
| Permanent objects - Standard Edition | `0` or `1` day |
| Permanent objects - Enterprise Edition or higher | `0` to `90` days |
| Transient objects and temporary tables | `0` or `1` day |

The standard default is 1 day. A value of `0` effectively disables Time Travel for that object. Temporary and transient tables have no Fail-safe period.

### Time Travel Syntax

Use `AT` or `BEFORE` after a table name in a `FROM` clause.

- `AT` is inclusive of changes at the specified point in time.
- `BEFORE` returns the state immediately before the specified point.
- Common reference points are `TIMESTAMP`, `OFFSET` (seconds before now), and `STATEMENT` (a query ID).

```sql
-- Table state five minutes ago.
SELECT *
FROM my_table AT (OFFSET => -60 * 5);

-- Table state immediately before the statement completed.
SELECT *
FROM my_table BEFORE (STATEMENT => 'query-id');
```

The requested point must be inside the retention period. A `STATEMENT` query ID is available for 14 days; use a timestamp for an older reference point that is still within the data-retention period.

### `UNDROP`

`UNDROP` restores the most recent dropped version of a supported object, as long as it has not been purged. Common examples are tables, schemas, and databases.

```sql
SHOW TABLES HISTORY LIKE 'my_table' IN SCHEMA my_db.my_schema;

UNDROP TABLE my_table;
UNDROP SCHEMA my_schema;
UNDROP DATABASE my_db;
```

If an object with the same name already exists, `UNDROP` fails until that object is renamed or dropped.

### Fail-safe

After the Time Travel retention period ends, historical data for **permanent tables** moves to Fail-safe for a non-configurable 7-day period. During Fail-safe:

- Data cannot be queried, cloned, or restored with `UNDROP`.
- Only Snowflake can attempt recovery after you contact Snowflake Support.
- Recovery can take hours or days and is not a substitute for backups or normal recovery operations.

## Cloning

Cloning creates an independent copy of a supported Snowflake object in the same account. For standard tables, schemas, and databases, it is a **zero-copy** operation: the clone initially references the source data instead of physically duplicating it.

```sql
-- Current version of the source table.
CREATE TABLE orders_dev CLONE orders;

-- Historical version of the source table, if it is inside Time Travel retention.
CREATE TABLE orders_before_load CLONE orders
  AT (OFFSET => -60 * 30);

-- Clone an entire schema for development or testing.
CREATE SCHEMA analytics_dev CLONE analytics_prod;
```

### What Happens After Cloning?

- Source and clone are independent after creation. Changes to one are not automatically applied to the other.
- Additional storage is charged only when changes cause source and clone to retain different micro-partitions.
- A cloned table does **not** inherit the source table's load history. A file loaded into the source can therefore be loaded into the clone again.
- Most explicit privileges are not copied by default. Use `COPY GRANTS` when you want to copy the source object's explicit privileges.

```sql
CREATE TABLE orders_dev CLONE orders COPY GRANTS;
```

Cloning is recursive for a database or schema: child objects are cloned with the container. However, not every object is cloneable; for example, external tables and internal named stages are not cloned. Use the object-specific `CREATE ... CLONE` documentation when cloning less common object types.

### Cloning with Time Travel

For databases, schemas, and non-temporary tables, `AT` and `BEFORE` let you create a clone from a historical point. The requested historical data must still be retained.

```sql
CREATE TABLE orders_at_midnight CLONE orders
  AT (TIMESTAMP => '2026-10-01 00:00:00 +00:00'::TIMESTAMP_TZ);
```

## Replication and Failover

**Cloning** creates a local, independent copy in one account. **Replication** copies data and supported database objects to a secondary account for business continuity and disaster recovery.

Snowflake recommends account replication and failover groups for broader account-level disaster-recovery designs. The database-replication example below is useful for understanding the primary/secondary pattern.

### Replicate a Database

In the source account, designate a database as primary and list the target account that may host its replica:

```sql
ALTER DATABASE primary_db
  ENABLE REPLICATION TO ACCOUNTS myorg.target_account;
```

In the target account, create and refresh the secondary database:

```sql
CREATE DATABASE secondary_db
  AS REPLICA OF myorg.source_account.primary_db;

ALTER DATABASE secondary_db REFRESH;
```

The secondary database is read-only until it is promoted during a failover process. Database replication can work across regions and cloud platforms for accounts in the same Snowflake organization. Failover and failback require Business Critical Edition or higher.

### Schedule a Secondary Refresh

Create this task in a separate writable database in the target account, because a secondary database is read-only. The warehouse is required in the task definition but is not used for the database-refresh operation itself.

```sql
CREATE TASK admin_db.public.refresh_secondary_db
  WAREHOUSE = admin_wh
  SCHEDULE = '10 MINUTE'
AS
  ALTER DATABASE secondary_db REFRESH;

ALTER TASK admin_db.public.refresh_secondary_db RESUME;
```

## Storage Billing

Storage is charged based on average daily stored bytes. This includes active table data, historical data retained by Time Travel and Fail-safe, and files in Snowflake internal stages.

- Updated or deleted data can continue to incur storage charges until it leaves both Time Travel and Fail-safe.
- Internal-stage files incur normal storage charges, so remove files after loading when they are no longer needed.
- Storage pricing varies by cloud region and contract type.

Use `TABLE_STORAGE_METRICS` to inspect active, Time Travel, and Fail-safe bytes per table:

```sql
SELECT
  table_catalog,
  table_schema,
  table_name,
  active_bytes,
  time_travel_bytes,
  failsafe_bytes
FROM snowflake.account_usage.table_storage_metrics
ORDER BY active_bytes + time_travel_bytes + failsafe_bytes DESC
LIMIT 20;
```

## Secure Data Sharing

Secure Data Sharing gives another Snowflake account read-only access to selected objects without copying the shared data. The provider continues to own and pay storage for the data; the consumer pays for the compute it uses to query the imported database.

- A **provider** creates a share, grants privileges on chosen objects, and adds consumer accounts.
- A **consumer** creates an imported database from the share and grants local roles access to it.
- Shared objects are read-only for consumers. A consumer cannot modify or delete them.
- A direct share is for accounts in the same region. Use a listing with auto-fulfillment when you need cross-region or cross-cloud sharing.

Common directly shared objects include tables, external tables, secure views, secure materialized views, and secure UDFs. Secure views are useful when you want to expose only selected columns or rows.

### Provider SQL

```sql
USE ROLE ACCOUNTADMIN;

CREATE SHARE sales_share;

GRANT USAGE ON DATABASE sales_db TO SHARE sales_share;
GRANT USAGE ON SCHEMA sales_db.reporting TO SHARE sales_share;
GRANT SELECT ON TABLE sales_db.reporting.monthly_sales TO SHARE sales_share;

-- Replace with the consumer's Snowflake account identifier.
ALTER SHARE sales_share
  ADD ACCOUNTS = myorg.consumer_account;

SHOW GRANTS TO SHARE sales_share;
```

### Consumer SQL

```sql
USE ROLE ACCOUNTADMIN;

-- Review what the provider shared before importing it.
DESC SHARE myorg.provider_account.sales_share;

CREATE DATABASE sales_shared
  FROM SHARE myorg.provider_account.sales_share;

GRANT IMPORTED PRIVILEGES ON DATABASE sales_shared TO ROLE analyst_role;

USE ROLE analyst_role;
SELECT *
FROM sales_shared.reporting.monthly_sales;
```

To create an imported database, the consumer role needs `IMPORT SHARE` and `CREATE DATABASE` privileges. Consumers can create their own objects in a separate local database, such as a secure view that references imported data.

### Reader Accounts

A reader account lets a provider give a non-Snowflake customer controlled access to shared data. A reader account has no data by default; it consumes databases created from the provider's shares. The provider pays for the reader account's warehouse usage and shared-data storage.

## Snowflake Marketplace and Listings

Listings use Snowflake's sharing technology but add a discovery and distribution layer. A provider can publish a listing privately, in a data exchange, or publicly on Snowflake Marketplace. Listings can support cross-region sharing, usage metrics, descriptions, sample queries, and paid offers.

## Snowflake Native App Framework

The Snowflake Native App Framework lets a provider package **data, application logic, and metadata** as a Snowflake Native App. A consumer installs the app and runs it inside their own Snowflake account, so the app can process consumer-approved data without extracting it to an external service.

Native Apps can include objects such as stored procedures, UDFs, and Streamlit in Snowflake apps. Providers distribute apps through private listings or Snowflake Marketplace listings.

### Core Objects and Flow

1. The provider creates an **application package**, which holds the app's data content, setup script, manifest, and versions.
2. The provider develops and tests the app, then attaches the package to a listing.
3. The consumer installs an **application** from the listing in their own account.

```sql
-- Provider: create the container for a Native App.
CREATE APPLICATION PACKAGE analytics_app_pkg;

SHOW APPLICATION PACKAGES;
```

Creating an application package requires the account-level `CREATE APPLICATION PACKAGE` privilege. The package alone is not a finished distributable app: it also needs app files, such as a manifest and setup script, and then a private or Marketplace listing for consumer distribution. After those files are ready, a provider can install it for testing with:

```sql
CREATE APPLICATION analytics_app_dev
  FROM APPLICATION PACKAGE analytics_app_pkg;
```

## Data Clean Room

Snowflake Data Clean Rooms provide a controlled collaboration environment. Collaborators can combine data to produce approved results or insights without giving one another unrestricted access to raw data.

The current model is **Collaboration Data Clean Rooms**. It has three main collaboration roles:

| Role | Responsibility |
| --- | --- |
| Owner | Creates the collaboration and assigns roles to collaborators. |
| Data provider | Contributes a data offering and defines allowed policies. |
| Analysis runner | Runs approved templates against permitted data offerings. |

The provider controls how data can be used by applying policies, such as permitted join columns, projected columns, and activation columns. Analysis runs through approved templates; results can be returned as aggregated insights or activated to an approved destination.

**Exam distinction:** a direct share or listing lets a consumer query shared data directly. A clean room restricts the analyses that can run, so collaborators gain insights without unrestricted raw-data access.

Use the Clean Rooms page in Snowsight for the low-code workflow. Full setup through SQL-like procedures and YAML specifications is possible, but it requires a configured Clean Rooms environment and is beyond a simple standalone `CREATE` statement.

## Data Exchange

A Data Exchange is a private data-sharing hub for a selected group of Snowflake accounts, such as internal business units, suppliers, or partners. It uses listings and Secure Data Sharing technology.

- A Data Exchange Admin manages membership and can designate members as providers, consumers, or both.
- Providers publish listings for the exchange; consumers discover and consume those listings.
- It is useful when a controlled, consistent group needs to exchange data. For public distribution, use Snowflake Marketplace; for a small known set of accounts, a private listing may be simpler.
- Data Exchange is not enabled for every account. Request provisioning through Snowflake Support or your Snowflake representative.

Reader accounts are not supported as Data Exchange members; providers and consumers need full Snowflake accounts.

### Official References

- [Snowflake Native App Framework workflow](https://docs.snowflake.com/en/developer-guide/native-apps/native-apps-workflow)
- [Snowflake Data Clean Rooms overview](https://docs.snowflake.com/en/user-guide/cleanrooms/overview)
- [Data Exchange overview](https://docs.snowflake.com/en/user-guide/data-exchange)

## What to Recall

### Storage and Micro-Partitions

1. Where does Snowflake store table data, and how do users normally access it?
2. What is a micro-partition? Name its storage format, mutability, and approximate uncompressed size.
3. What micro-partition metadata allows Snowflake to prune data, and what type of query condition uses it?
4. When might a clustering key improve performance, and why is it not automatically useful for every table?

### Time Travel and Fail-safe

5. What are the three main Time Travel use cases?
6. Which permanent objects can have up to 90 days of Time Travel retention, and what edition is required?
7. What is the difference between `AT` and `BEFORE` in a Time Travel query?
8. When would you use `OFFSET` rather than `STATEMENT` in a Time Travel query?
9. Which table types have Fail-safe, and can you access Fail-safe with SQL?
10. Why is Fail-safe not a replacement for backups or normal recovery operations?

### Cloning, Replication, and Storage Billing

11. Why is a standard table clone called a zero-copy clone, and when can additional storage be charged?
12. What does `COPY GRANTS` do when creating a clone?
13. What source-table information is not copied to a cloned table?
14. How does replication differ from cloning in account scope and purpose?
15. What is a primary database, what is a secondary database, and why is the secondary read-only?
16. Which three storage states can contribute to table-storage cost?
17. Why should you remove files from internal stages after a load when they are no longer needed?

### Secure Sharing, Listings, and Reader Accounts

18. In a direct share, what does the provider create and what must the consumer create before querying shared data?
19. Who pays storage and who pays query compute for securely shared data?
20. When should you use a listing instead of a direct share?
21. What is the difference between a reader account and a normal consumer account?
22. What additional features can a listing provide beyond a direct share?

### Native Apps, Clean Rooms, and Data Exchange

23. What does a Snowflake Native App package contain, and where does a consumer-installed app run?
24. How does a Data Clean Room differ from a direct share or listing?
25. What are the three main roles in a Collaboration Data Clean Room?
26. What controls can a Data Clean Room provider use to restrict analysis of its data?
27. When is a Data Exchange more suitable than a private listing or Snowflake Marketplace?
