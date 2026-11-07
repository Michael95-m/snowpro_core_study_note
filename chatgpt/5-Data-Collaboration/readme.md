# Domain 5.0 · Data Collaboration

- **Exam scope.** The supplied [SnowPro Core C03 study guide](../../SnowProCoreStudyGuideC03.pdf) assigns Domain 5 **10%**. See pages 5 and 11.
- **Study method.** Read a numbered topic, explain its **Remember** line aloud, then try the related SQL and check the expected result.
- [SQL exercises and checkpoints](exercises/readme.md) · [Share data from multiple databases](#share-data-from-multiple-databases-in-one-direct-share) · [Scenario decision guide](#scenario-decision-guide) · [What to Recall](#what-to-recall)
- [25-question Domain 5 quiz](practice/domain-5-qa.md) · [Additional lab on sharing unstructured files](../additional-exercises/01-unstructured-data-sharing/readme.md)

| C03 objective | Topics covered |
| --- | --- |
| [5.1 Data collaboration and protection](#51-data-collaboration-and-protection) | Time Travel, Fail-safe, cloning, replication and failover, and the protection boundary of Secure Data Sharing |
| [5.2 Snowflake data sharing capabilities](#52-snowflake-data-sharing-capabilities) | Providers, consumers, reader accounts, direct shares, access grants, resharing, and Data Clean Rooms |
| [5.3 Marketplace, listings, and Native Apps](#53-marketplace-listings-and-native-apps) | Private and public listings, Cross-Cloud Auto-Fulfillment, and packaging and installing Native Apps |

The [course chapter on storage, data protection, and sharing](../../study-notes/9-Storage-Data-Protection-and-sharing/readme.md) covers the same foundations and adds storage billing and Data Exchange. The [Domain 1 storage note](../1-Snowflake-AI-Data-Cloud-Features-and-Architecture/05-storage-tables-and-views.md) explains table types. The [Domain 2 governance note](../2-Account-Management-and-Data-Governance/readme.md) covers roles, policies, and access control.

## Practice setup and exercise files

| File | Practice | Expected result |
| --- | --- | --- |
| [00-setup.sql](exercises/00-setup.sql) | Set up the lab database, schema, and X-Small warehouse | Context is `D5_STUDY.LAB` |
| [01-time-travel-and-undrop.sql](exercises/01-time-travel-and-undrop.sql) | Query before a delete, then drop and recover a lab table | Historical total **600**. Current and restored totals **400** |
| [02-zero-copy-cloning.sql](exercises/02-zero-copy-cloning.sql) | Clone a table, change it independently, and compare grants | Source total **350**. Clone total **325**. Each grant example produces a different reader |
| [03-secure-sharing.sql](exercises/03-secure-sharing.sql) | Preview a restricted secure view and review the two-account sharing flow | View returns orders **1 and 3**, total **400** |
| [04-replication-and-collaboration.sql](exercises/04-replication-and-collaboration.sql) | Inspect visible objects and walk through replication, failover, and Native App commands | Identify which commands run in the source and which run in the target |
| [99-stop-lab.sql](exercises/99-stop-lab.sql) | Suspend the lab warehouse | Lab data stays available for review |

- Run the files in order in Snowsight or a connected VS Code SQL editor. Use `D5_STUDY` for study data because scripts replace their own fixture tables.
- The single-account exercises use synthetic data. The multi-account templates are commented out and have separate permissions and prerequisites.
- The X-Small warehouse auto-suspends after 60 seconds of inactivity. Running the lab can consume credits. [Warehouse billing and suspension](https://docs.snowflake.com/en/user-guide/warehouses-considerations)

## 5.1 Data collaboration and protection

### 5.1.1 Time Travel

**Remember.** Time Travel lets you inspect or recover an earlier state while it is still inside its retention window.

- **Inspect** historical rows with `SELECT ... AT | BEFORE`.
- **Branch** from a past point with `CREATE ... CLONE ... AT | BEFORE`, for supported objects.
- **Restore** a dropped object in place with `UNDROP TABLE`, `UNDROP SCHEMA`, or `UNDROP DATABASE`. For a bad `DELETE`, query or clone the earlier data and restore the needed rows. [Time Travel](https://docs.snowflake.com/en/user-guide/data-time-travel)

| Table type | Time Travel retention | Fail-safe |
| --- | --- | --- |
| Permanent, Standard Edition | 0 or 1 day, with a 1-day default | 7 days |
| Permanent, Enterprise Edition or higher | 0 to 90 days, with a 1-day default unless configured differently | 7 days |
| Transient | 0 or 1 day | None |
| Temporary | 0 or 1 day while the table remains available in its session | None |

- Use `DATA_RETENTION_TIME_IN_DAYS` to set retention on eligible objects. Enterprise makes longer retention available. An account minimum, where applicable, sets a floor on effective retention. [Retention rules](https://docs.snowflake.com/en/user-guide/data-time-travel) · [Account minimum retention](https://docs.snowflake.com/en/sql-reference/parameters#min-data-retention-time-in-days)
- `AT` includes changes at the specified point. `BEFORE(STATEMENT => ...)` reads just before the identified statement completed. Capture the query ID before running unrelated statements. The lab calls `LAST_QUERY_ID()` immediately after the delete. [AT and BEFORE](https://docs.snowflake.com/en/sql-reference/constructs/at-before)
- A new active table with the same name blocks `UNDROP TABLE`. Rename that active table first, then restore the dropped table in its original schema. When several dropped versions share a name, inspect their IDs to choose the right one. [UNDROP TABLE](https://docs.snowflake.com/en/sql-reference/sql/undrop-table)

~~~sql
-- Substitute the query ID of the committed DELETE or UPDATE.
SELECT *
FROM D5_STUDY.LAB.D5_RECOVERY_ORDERS
BEFORE (STATEMENT => '<query_id>');
~~~

### 5.1.2 Fail-safe and historical storage

**Remember.** Snowflake handles Fail-safe recovery after Time Travel ends for permanent table data.

- Fail-safe lasts **7 days** and is non-configurable. Snowflake may recover historical data after an extreme operational failure. Fail-safe recovery goes through Snowflake. SQL Time Travel commands require data still in the Time Travel window. [Fail-safe](https://docs.snowflake.com/en/user-guide/data-failsafe)
- Permanent tables provide Fail-safe. Transient and temporary tables give you shorter protection and suit data you can recreate. A transient table can outlive a session. A temporary table belongs to its session. [Table storage considerations](https://docs.snowflake.com/en/user-guide/tables-storage-considerations)
- Snowflake retains old micro-partitions when needed for historical queries or recovery. Frequent changes and longer retention can raise storage costs. `SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS` separates active, Time Travel, Fail-safe, and retained-for-clone bytes. [Historical storage costs](https://docs.snowflake.com/en/user-guide/data-cdp-storage-costs) · [Table storage metrics](https://docs.snowflake.com/en/sql-reference/account-usage/table_storage_metrics)

### 5.1.3 Zero-copy cloning

**Remember.** A standard table clone starts from a snapshot and shares its existing micro-partitions. The source and clone can then change independently.

- Use a clone for a test environment or to inspect a past state before recovery. Ordinary changes to a standard table clone and its source create separate versions of the changed data. Shared micro-partitions may remain billed while a clone still references them. [CREATE CLONE](https://docs.snowflake.com/en/sql-reference/sql/create-clone) · [Storage for clones](https://docs.snowflake.com/en/user-guide/tables-storage-considerations)
- For a new standalone table clone, `COPY GRANTS` carries explicit access grants from the source except `OWNERSHIP`. Without it, applicable future grants can apply. Database and schema cloning have separate rules for grants on the container and its children. Review external references and other object-specific behavior before using a clone as an isolated environment. [Clone grants and object behavior](https://docs.snowflake.com/en/user-guide/object-clone)

**Worked example.** The source grants `SELECT` explicitly to `CLONE_SOURCE_READER`. The destination schema grants `SELECT` on future tables to `CLONE_FUTURE_READER`. Predict which of those roles can see each new clone's `SELECT` grant, then check with `SHOW GRANTS ON TABLE`.

| New clone | Which of the two roles gets `SELECT` |
| --- | --- |
| `CLONE … COPY GRANTS` | `CLONE_SOURCE_READER`, from the source table |
| `CLONE` without `COPY GRANTS` | `CLONE_FUTURE_READER`, from the destination schema |

Run the grant comparison in [SQL exercise 02](exercises/02-zero-copy-cloning.sql). It uses database roles in the lab database. [Snowflake CREATE CLONE grant rules](https://docs.snowflake.com/en/sql-reference/sql/create-clone)

~~~sql
CREATE TABLE D5_STUDY.LAB.D5_RECOVERY_SNAPSHOT
  CLONE D5_STUDY.LAB.D5_RECOVERY_ORDERS
  BEFORE (STATEMENT => '<query_id>');
~~~

### 5.1.4 Replication and failover

**Remember.** A refresh copies changes to a read-only secondary. Failover promotes a secondary so it can take over as primary.

| Requirement | Feature | Edition rule |
| --- | --- | --- |
| Copy a database or supported outbound share to another account | Database replication or a replication group, as appropriate | Database and share replication available across editions |
| Replicate additional account objects such as users, roles, or warehouses | Replication group or failover group with those object types | Business Critical or higher for these objects |
| Promote a group of replicated objects to a writable primary | Failover group | Business Critical or higher |

Source and target accounts for these groups belong to the **same Snowflake organization**. Include the supported objects your workloads actually need. Inbound shares have separate limitations and are excluded from share replication. [Replication features and edition matrix](https://docs.snowflake.com/en/user-guide/account-replication-intro)

1. **Source.** Define the primary group, object scope, allowed target accounts, and any refresh schedule.
2. **Target.** Create a secondary with `AS REPLICA OF` and refresh it. The target reflects the last successful refresh.
3. **During failover.** Promote the correct secondary with `ALTER FAILOVER GROUP ... PRIMARY`. Redirect and test client connections. Review refresh schedules after promotion.
4. **During failback.** Refresh the original account from the current primary, check readiness, then promote it back as part of a planned cutover. [Failover and failback](https://docs.snowflake.com/en/user-guide/account-replication-failover-failback) · [ALTER FAILOVER GROUP](https://docs.snowflake.com/en/sql-reference/sql/alter-failover-group)

- **RPO** is how much data loss the business can tolerate, expressed as time. If the last refresh captured data through 10:00 and the source fails at 10:08, writes made after 10:00 might be absent from the target.
- **RTO** is how long the business can tolerate disruption. Promotion, reconnecting clients, and validating workloads all take time.
- The lab includes separate [replication and failover templates](exercises/04-replication-and-collaboration.sql). [Replication and failover overview](https://docs.snowflake.com/en/user-guide/account-replication-intro)

### 5.1.5 The Secure Data Sharing protection boundary

**Remember.** A share gives another account governed, read-only access to selected objects. A secondary replica or a clone serves a different operational purpose.

- Use a secure view to expose only approved rows and columns. Grant access to the view and its required containers. A consumer with access to the view can query the permitted output.
- The provider controls grants and target accounts. If you revoke access, future queries lose that sharing path. Data already exported under an allowed workflow needs its own controls.
- Use Time Travel to recover from a bad write. Use a failover group for a recovery target that must take over. [Secure Data Sharing](https://docs.snowflake.com/en/user-guide/data-sharing-intro) · [Creating and configuring shares](https://docs.snowflake.com/en/user-guide/data-sharing-provider)

## 5.2 Snowflake data sharing capabilities

### 5.2.1 Provider, consumer, and reader account

**Remember.** The provider publishes data. A standard consumer pays for its query compute. The provider pays for query compute in a reader account it creates.

| Account | What it does | Cost and access |
| --- | --- | --- |
| Provider | Owns the original data and controls the share | Pays for storage of the original data |
| Standard consumer | Creates a read-only database from a share and grants access to its local roles | Pays for the warehouse used to query it. The same-region share adds no consumer storage copy |
| Reader account | Gives users access to data from the provider that created the account | Provider creates, owns, and pays for it. Common load and write commands such as `INSERT`, `MERGE`, and loading with `COPY INTO` are restricted |

A reader account can help a customer who has no Snowflake account query the provider's data. The provider can set a resource monitor for the reader warehouse to manage credit usage. [Secure Data Sharing costs](https://docs.snowflake.com/en/user-guide/data-sharing-intro) · [Reader account permissions and costs](https://docs.snowflake.com/en/user-guide/data-sharing-reader-create)

### 5.2.2 Direct shares and grants

**Remember.** The share is in the provider account. The imported database and querying roles are in the consumer account.

1. **Provider.** Create a share. Grant `USAGE` on the database and schema, and `SELECT` on the table or secure view. Add authorized same-region consumer accounts to the share.
2. **Consumer administrator.** Use `SHOW SHARES` to find the inbound share identifier. Create a database with `CREATE DATABASE ... FROM SHARE <provider_account>.<share_name>`.
3. **Consumer access.** With direct object grants to the share, grant `IMPORTED PRIVILEGES` on the imported database to a local account role. If the provider shared database roles, grant the appropriate imported database role to a local account role to give access to its slice of the share.
4. **Consumer user.** Run a query with a role that has both the shared data access and `USAGE` on a consumer warehouse. [Provider workflow](https://docs.snowflake.com/en/user-guide/data-sharing-provider) · [Consumer workflow](https://docs.snowflake.com/en/user-guide/data-share-consumers)

- `SHOW SHARES` lets you inspect visible inbound or outbound shares. Delegated administrators need the applicable privileges to create shares, add targets, import databases, and grant access. [Share administration privileges](https://docs.snowflake.com/en/user-guide/security-access-privileges-shares)

#### Share data from multiple databases in one direct share

**Remember.** One direct share can expose data from several provider databases through secure views in one shared database. The consumer imports one database and queries those views from there.

In this example, follow the data from the source table to the consumer's query.

1. **`INTL_DB.PUBLIC.ORDERS`** holds the original rows in the provider account.
2. **`D5_STUDY.LAB.D5_PARTNER_INTL_ORDERS_V`** is the secure view the provider adds to the existing share.
3. **`D5_IMPORTED_ORDERS.LAB.D5_PARTNER_INTL_ORDERS_V`** is the same shared view as seen by the consumer.

| Grant | Where it goes |
| --- | --- |
| `USAGE` | On the one database that contains the shared views, and on the schemas that contain them |
| `REFERENCE_USAGE` | On each additional database that the views read from |
| `SELECT` | On each cross-database secure view |

Grant `REFERENCE_USAGE` directly to the share **before** granting `SELECT` on the view. Database roles are scoped to one database, so use direct grants to the share for cross-database views. [Snowflake's multi-database sharing guide](https://docs.snowflake.com/en/user-guide/data-sharing-multiple-db)

**Provider account.** This example extends `D5_LAB_ORDERS_SHARE`, which already has `USAGE` on `D5_STUDY` and `D5_STUDY.LAB`. Assume `INTL_DB.PUBLIC.ORDERS` exists in the same provider account and has `ORDER_ID` and `AMOUNT` columns. Select only the columns and rows you intend to expose.

If you already created the secure view, start with the grants. The [secure sharing SQL exercise](exercises/03-secure-sharing.sql) also includes these steps.

~~~sql
CREATE SECURE VIEW D5_STUDY.LAB.D5_PARTNER_INTL_ORDERS_V AS
SELECT ORDER_ID, AMOUNT
FROM INTL_DB.PUBLIC.ORDERS;

GRANT REFERENCE_USAGE ON DATABASE INTL_DB
  TO SHARE D5_LAB_ORDERS_SHARE;

GRANT SELECT ON VIEW D5_STUDY.LAB.D5_PARTNER_INTL_ORDERS_V
  TO SHARE D5_LAB_ORDERS_SHARE;

SHOW GRANTS TO SHARE D5_LAB_ORDERS_SHARE;
~~~

**Consumer account.** In `SHARE_LAB`, use a role with access to the share and a consumer warehouse. Both views are available through the same imported database. Replace `D5_IMPORTED_ORDERS` if you chose a different name. [Consuming a direct share](https://docs.snowflake.com/en/user-guide/data-share-consumers)

~~~sql
SELECT * FROM D5_IMPORTED_ORDERS.LAB.D5_PARTNER_ORDERS_V;
SELECT * FROM D5_IMPORTED_ORDERS.LAB.D5_PARTNER_INTL_ORDERS_V;
~~~

### 5.2.3 Sharing versus resharing

**Remember.** Sharing starts with the provider. Resharing starts with a consumer that passes on access to data it received, subject to Snowflake's rules.

- **Direct shares.** Under Snowflake's generally enabled 2026_06 change, a consumer can reshare eligible data with accounts in **its own organization and region**. Create a secure view over the imported data and share that view. Directly attaching an imported object to a new share is unsupported. [Direct-share behavior change](https://docs.snowflake.com/en/release-notes/bcr-bundles/2026_06/bcr-2364) · [Direct-share resharing limits](https://docs.snowflake.com/en/user-guide/data-share-consumers)
- **Listings.** The original provider enables listing resharing. The provider can restrict downstream sharing to the consumer's organization. For a cross-organization or cross-region scenario, check the listing's policy and supported configuration. [Provider resharing controls](https://docs.snowflake.com/en/collaboration/resharing-as-provider) · [Resharing listings](https://docs.snowflake.com/en/collaboration/reshare-listings)
- **Governance.** Check which account context evaluates upstream policies when data is reshared. Direct-share resharing uses `RESHARER` enforcement. The recipient sees the data allowed in the resharer's context. [Resharing enforcement modes](https://docs.snowflake.com/en/collaboration/reshare-listings)

### 5.2.4 Snowflake Data Clean Rooms

**Remember.** Use a clean room when participants need an approved analysis across data they control, such as audience overlap, with rules for what can be joined and returned.

1. Participants link approved datasets or data offerings.
2. Policies define allowed joins and what the result can reveal. Templates express approved analyses.
3. An authorized participant runs the analysis. For example, a retailer and ad platform can measure how many customers overlap and receive an allowed count.
4. If the collaboration and its resources permit **activation**, results can be saved to a designated account. Review that separately from permission to run the analysis. [Clean Rooms overview](https://docs.snowflake.com/en/user-guide/cleanrooms/overview) · [Provider and consumer clean rooms](https://docs.snowflake.com/en/user-guide/cleanrooms/getting-started)

- In a collaboration clean room, the **owner** sets up the collaboration, **data providers** make data offerings available, and **analysis runners** run permitted analyses. Some collaborations allow policy-controlled free-form SQL. A scenario that requires approved aggregate output should specify that restriction. [Collaboration clean room roles and analyses](https://docs.snowflake.com/en/user-guide/cleanrooms/overview)
- **Exam clue.** A partner who needs recurring access to approved rows may use a secure share. Two parties who need a controlled overlap calculation should consider a clean room.

## 5.3 Marketplace, listings, and Native Apps

### 5.3.1 Direct share, private listing, or public listing

**Remember.** A listing adds product information and distribution controls to a share or application package. Marketplace is where users discover public listings.

| Option | Use it when |
| --- | --- |
| Direct share | You know the target Snowflake accounts, they are in the same region, and you want a direct read-only share |
| Private listing | You want selected consumers to receive a product with listing metadata, or you need listing distribution features such as cross-region fulfillment |
| Public Marketplace listing | You want a broader audience to discover the data product or Native App |

- Listings can include descriptions, sample queries, and terms. Listings can be free, offer a trial, or be paid where supported. Visibility and price are separate decisions. [Listings and listing types](https://docs.snowflake.com/en/collaboration/collaboration-listings-about)
- **Cross-Cloud Auto-Fulfillment** can replicate the product to eligible consumer regions as needed. Check supported regions, configuration, and fulfillment costs. This distribution workflow is separate from promoting a disaster-recovery account. [Cross-Cloud Auto-Fulfillment](https://docs.snowflake.com/en/collaboration/provider-listings-auto-fulfillment)

### 5.3.2 Snowflake Native Apps

**Remember.** The provider publishes an **application package**. Installation creates an **application** in the consumer's account.

1. **Application package.** Contains app logic, setup artifacts, version and patch information, and any included data content or references.
2. **Manifest.** Describes how Snowflake sets up the app, including where to find the setup script.
3. **Setup script.** Runs on installation or upgrade to create or update the app's objects.
4. **Listing.** Makes the package available privately or through Marketplace.
5. **Installed application.** Runs in the consumer account. Application roles grant consumers access to app features. The consumer can grant requested access to its own objects when the app needs that access. [Snowflake Native App Framework](https://docs.snowflake.com/en/developer-guide/native-apps/native-apps-about)

- Share a dataset when users need to query data. Choose a Native App when the product also needs to deliver code, a workflow, or an interface.
- `SHOW APPLICATION PACKAGES` lists packages visible to the current role. `SHOW APPLICATIONS` lists installed apps visible to it. These commands let you inspect the difference without installing or publishing anything. [SHOW APPLICATION PACKAGES](https://docs.snowflake.com/en/sql-reference/sql/show-application-packages) · [SHOW APPLICATIONS](https://docs.snowflake.com/en/sql-reference/sql/show-applications)

## Scenario decision guide

| Scenario | First choice | Clue |
| --- | --- | --- |
| An update overwrote amounts an hour ago | Time Travel with `BEFORE` | You want the previous rows |
| An analyst dropped a table within retention | `UNDROP TABLE` | You want the dropped object back |
| A test team needs an independent writable snapshot | Zero-copy clone | Test changes should stay in the test table |
| A second account needs a read-only copy of a database | Replication | A refresh updates the copy |
| A standby account must become writable after an outage | Failover group | Promotion changes which group is primary |
| An approved same-region partner needs a live read-only view | Direct share with a secure view | Provider controls the rows and columns exposed |
| One share must expose approved data from two provider databases | Secure views in one shared database and `REFERENCE_USAGE` on the other | Consumer queries both views through one imported database |
| A partner lacks its own Snowflake account | Reader account | Provider provisions it and pays for its compute |
| Partners need audience overlap counts with controlled inputs and outputs | Data Clean Rooms | They need an approved joint analysis |
| Selected customers in another region need a product | Private listing with supported auto-fulfillment | Distribution is targeted across regions |
| The product includes code and a UI installed in the customer's account | Native App | The customer installs an application |

## What to Recall

### 5.1 Data collaboration and protection

1. How do `AT` and `BEFORE` differ when you use a query ID?
2. When should you use `UNDROP`, and what happens if an active table already has the name?
3. Which edition supports 30 days of Time Travel on a permanent table? Does an upgrade set the retention by itself?
4. Which table types have Fail-safe? Who performs the recovery?
5. What does a zero-copy clone share at creation? How do later writes behave? How does `COPY GRANTS` change which grants a new table clone receives?
6. How do `REFRESH` and `PRIMARY` differ? Which edition supports failover groups?
7. If the last successful refresh captured source data through 10:00, what happens to later writes if the primary is lost at 10:08?

### 5.2 Snowflake data sharing capabilities

8. Who pays for source storage, standard consumer query compute, and reader account query compute?
9. Where do you create the share and where do you create the imported database?
10. When do you grant `IMPORTED PRIVILEGES` and when do you grant an imported database role?
11. What can the consumer reshare from a direct share? How does a listing change that decision?
12. How do you expose selected rows and columns to a partner? When is a clean room a better fit?
13. How do you expose data from two provider databases through one direct share?

### 5.3 Marketplace, listings, and Native Apps

14. When would you pick a private listing over a direct share or public listing?
15. What does Cross-Cloud Auto-Fulfillment do?
16. Which Native App object belongs to the provider, and what gets created on installation?
17. What are the jobs of the manifest and setup script?

<details>
<summary>Answer key</summary>

1. `AT` includes changes at that point. `BEFORE` reads immediately before the specified statement completed.
2. Use it to restore a dropped object inside retention. Rename a same-named active table before restoring the dropped one.
3. Enterprise or higher. Set the required retention on the permanent table or through the appropriate inherited configuration.
4. Permanent table data has the 7-day Fail-safe period. Snowflake handles recovery. Transient and temporary tables have no Fail-safe.
5. A standard table clone initially shares the existing micro-partitions. Writes to either table leave the other table's logical rows unchanged. A new table clone with `COPY GRANTS` gets the source's explicit access grants except ownership. Omitting it allows the destination's applicable future grants to apply.
6. `REFRESH` updates the read-only secondary. `PRIMARY` promotes a failover group. Failover groups require Business Critical or higher.
7. Writes after the last captured point might be absent from the promoted target. That gap is relevant to RPO.
8. Provider pays source storage, the standard consumer pays its own query compute, and the provider pays its reader account's query compute.
9. Create the share in the provider account and the imported database in the consumer account.
10. Use `IMPORTED PRIVILEGES` for objects granted directly to the share. Use the shared database role when the provider published access through database roles.
11. Under the current direct-share behavior, eligible data can be reshared through a secure view to accounts in the consumer's own organization and region. A listing needs provider-enabled resharing and can support other downstream targets depending on its configuration.
12. Share a secure view for approved rows and columns. Use a clean room when participants need a controlled joint analysis, such as an approved overlap count.
13. Create the secure views in the shared database and grant `USAGE` on that database and their schemas. Grant `REFERENCE_USAGE` on each additional source database, then grant `SELECT` on the views directly to the share.
14. Pick a private listing for selected customers who need listing features. Pick a direct share for a direct same-region grant, or a public listing for broad Marketplace discovery.
15. It fulfills an eligible listing's data product to consumer regions as needed.
16. The provider creates and publishes an application package. Installation creates an application in the consumer account.
17. The manifest describes configuration and identifies the setup script. The setup script creates or updates objects on installation or upgrade.

</details>
