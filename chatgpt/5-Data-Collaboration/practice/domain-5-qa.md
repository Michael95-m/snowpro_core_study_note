# Domain 5 Practice Q&A

[Domain 5 study note](../readme.md) · [SQL exercises](../exercises/readme.md)

These are the 25 questions from our Domain 5 quiz. Pick an answer before opening the explanation. Each question includes a Snowflake reference.

## Question 1

Yesterday, an accidental `UPDATE` overwrote the `amount` on 12 orders. The permanent table has seven days of Time Travel retention. You know the bad query ID, and other orders have changed since then. How can you restore just the affected amounts?

- **A.** Read with `AT (STATEMENT => '<bad_query_id>')` and copy back the 12 amounts.
- **B.** Clone the table from before the update and swap it with the current table.
- **C.** Read with `BEFORE (STATEMENT => '<bad_query_id>')` and update just those amounts.
- **D.** Run `UNDROP TABLE ORDERS`.

<details>
<summary>Correct answer and explanation</summary>

**C.** `BEFORE` reads the state just before the specified statement completed. Restore the affected columns and rows in the current table to preserve unrelated later changes. [Time Travel syntax](https://docs.snowflake.com/en/sql-reference/constructs/at-before)

</details>

## Question 2

Two tables were dropped 48 hours ago. Each had one day of Time Travel retention. One was permanent and one was transient. Which recovery option is available?

- **A.** Run `UNDROP` on both within seven days.
- **B.** Ask Snowflake about Fail-safe recovery for the permanent table. The transient table has no Fail-safe.
- **C.** Ask Snowflake about Fail-safe recovery for both.
- **D.** Increase retention to seven days now and run `UNDROP` on both.

<details>
<summary>Correct answer and explanation</summary>

**B.** Both tables are past the one-day Time Travel window. Permanent tables have a seven-day Fail-safe period afterward. Snowflake handles recovery during that period. Transient tables have no Fail-safe. [Fail-safe](https://docs.snowflake.com/en/user-guide/data-failsafe)

</details>

## Question 3

An engineer drops `ORDERS` and creates a new table with the same name. The original is still in retention, and the new table contains data you need. How do you preserve both?

- **A.** Run `UNDROP TABLE ORDERS` and let Snowflake rename the new table.
- **B.** Drop the new `ORDERS`, then run `UNDROP TABLE ORDERS` by name.
- **C.** Clone the new `ORDERS` from before the original was dropped.
- **D.** Rename the new table, then run `UNDROP TABLE ORDERS`.

<details>
<summary>Correct answer and explanation</summary>

**D.** Rename the active table to a new name to preserve it. `UNDROP` can then restore the original under `ORDERS`. Dropping the new table first makes it the most recently dropped table with that name. [UNDROP TABLE](https://docs.snowflake.com/en/sql-reference/sql/undrop-table)

</details>

## Question 4

You make a zero-copy clone of a 2 TB table for testing, then update a small subset of rows in the clone. What happens?

- **A.** The tables initially share existing micro-partitions. The update changes the clone and can add storage for newly written micro-partitions.
- **B.** Snowflake copies all 2 TB when the clone is created.
- **C.** The update changes both tables because they share storage.
- **D.** The first update copies all 2 TB before applying the change.

<details>
<summary>Correct answer and explanation</summary>

**A.** A standard table clone initially references the same micro-partitions. Later changes are independent. New data written by the clone can increase storage usage. [Cloning and storage](https://docs.snowflake.com/en/user-guide/tables-storage-considerations)

</details>

## Question 5

`ORDERS` is an existing table with an explicit `SELECT` grant to `SUPPORT_REPORT`. After the table was created, the schema admin set a future `SELECT` grant on tables to `QA_ANALYST`. You create a new table in that schema using `CREATE TABLE ORDERS_TEST CLONE ORDERS COPY GRANTS;`. Who gets `SELECT` on the clone?

- **A.** `SUPPORT_REPORT` only.
- **B.** `QA_ANALYST` only.
- **C.** Both roles.
- **D.** Neither role.

<details>
<summary>Correct answer and explanation</summary>

**A.** For a new table clone, `COPY GRANTS` copies the source’s explicit grants except ownership and skips destination future grants. If you omit `COPY GRANTS`, the clone can inherit the applicable future grants instead. [CREATE CLONE grant rules](https://docs.snowflake.com/en/sql-reference/sql/create-clone)

</details>

## Question 6

The last successful refresh in `SHARE_LAB` captured source data through 10:00. The source added orders at 10:02 and 10:04. The 10:05 refresh failed. The source became unavailable at 10:08. What can you query in the replica?

- **A.** Both new orders.
- **B.** Only the 10:02 order.
- **C.** The data captured through 10:00, without either new order.
- **D.** The data through 10:08 because both accounts are in the same organization.

<details>
<summary>Correct answer and explanation</summary>

**C.** The replica reflects the last successfully refreshed point-in-time snapshot. The failed refresh did not bring the later orders into the target. [Replication and point-in-time consistency](https://docs.snowflake.com/en/user-guide/account-replication-intro)

</details>

## Question 7

Two Business Critical accounts have a primary and a secondary failover group. The standby refreshed successfully before the primary went offline. The application uses the original account URL and has no automatic connection redirection. What gets writes running in the standby?

- **A.** Refresh the secondary and keep the original account URL.
- **B.** Point the application to the standby and grant `INSERT` on the read-only replica.
- **C.** Make a direct share from the standby and write to its imported database.
- **D.** Promote the secondary group to primary and point the application to the standby.

<details>
<summary>Correct answer and explanation</summary>

**D.** `ALTER FAILOVER GROUP … PRIMARY` promotes the group and makes its replicated objects writable. The application must also connect to the newly promoted account. [Failover guide](https://docs.snowflake.com/en/user-guide/account-replication-failover-failback)

</details>

## Question 8

A company has Enterprise accounts in Oregon and Tokyo in the same organization. Tokyo needs a read-only copy of a database, refreshed nightly. Which setup fits?

- **A.** Directly share from Oregon to Tokyo because the accounts are in the same organization.
- **B.** Create a replication group in Oregon, create its replica in Tokyo, and schedule refreshes.
- **C.** Create a failover group and promote Tokyo nightly.
- **D.** Create a zero-copy clone directly in the Tokyo account.

<details>
<summary>Correct answer and explanation</summary>

**B.** A database replication group can target an account in the same organization in another region. Direct shares require the same region. Failover groups require Business Critical Edition or higher. [Replication feature and edition matrix](https://docs.snowflake.com/en/user-guide/account-replication-intro)

</details>

## Question 9

`MKMM_TEST` is a user in your account. A partner uses a separate Snowflake account in the same region. Both need to read the same secure view using their existing accounts. Which approach fits?

- **A.** Grant an appropriate role to `MKMM_TEST` and add the partner’s account to a direct share.
- **B.** Add both `MKMM_TEST` and the partner account as direct share recipients.
- **C.** Grant a role from your account directly to both users.
- **D.** Use a public listing for the partner because they are in a different organization.

<details>
<summary>Correct answer and explanation</summary>

**A.** Within your account, roles grant object access to users. A direct share targets another account in the same Snowflake region, including accounts in a different organization. [Secure Data Sharing](https://docs.snowflake.com/en/user-guide/data-sharing-intro)

</details>

## Question 10

In `SHARE_LAB`, `SHOW SHARES` lists `D5_LAB_ORDERS_SHARE` as `INBOUND`, with a blank `database_name`. What should you do next?

- **A.** Ask the provider to add `SHARE_LAB` again.
- **B.** Grant `IMPORTED PRIVILEGES` on the provider’s `D5_STUDY` database from `SHARE_LAB`.
- **C.** Create a local database in `SHARE_LAB` using `CREATE DATABASE … FROM SHARE`.
- **D.** Select a warehouse and query the provider’s fully qualified view directly.

<details>
<summary>Correct answer and explanation</summary>

**C.** The inbound share is available to consume. Importing it creates a locally named read-only database. A blank database name indicates that import has not happened yet. [Consume imported data](https://docs.snowflake.com/en/user-guide/data-share-consumers)

</details>

## Question 11

A share already exposes a view from `D5_STUDY.LAB`. A new secure view in that schema reads from `INTL_DB.PUBLIC.ORDERS`. The consumer should get both views through its existing imported database. Which grants should you add?

- **A.** Grant `USAGE` on `INTL_DB` to the same share, then grant `SELECT` on the view.
- **B.** Grant `REFERENCE_USAGE` on `INTL_DB` directly to the share, then grant `SELECT` on the view directly to the share.
- **C.** Grant `REFERENCE_USAGE` on `INTL_DB` to a database role in `D5_STUDY`, then grant the role to the share.
- **D.** Grant `SELECT` on the underlying `INTL_DB` table directly to the share.

<details>
<summary>Correct answer and explanation</summary>

**B.** The share has `USAGE` on the database containing the view. `REFERENCE_USAGE` lets the share resolve the additional database dependency. Grant it directly to the share before granting `SELECT` on the secure view. [Share data from multiple databases](https://docs.snowflake.com/en/user-guide/data-sharing-multiple-db)

</details>

## Question 12

A provider wants to share detailed transactions with the consumer’s Finance team and campaign summaries with Marketing. Both sets of views are in the same database, and the consumer wants independent access assignments through one share. Which setup fits?

- **A.** Grant both sets of views directly to the share and grant both teams `IMPORTED PRIVILEGES`.
- **B.** Grant the provider’s account roles directly to the consumer’s users.
- **C.** Create a database role per set of views, grant both database roles to the share, and let the consumer assign them to separate local account roles.
- **D.** Give each team a different warehouse.

<details>
<summary>Correct answer and explanation</summary>

**C.** Shared database roles let the consumer assign different subsets of the product to its local account roles. The roles package permissions on objects in the same provider database. [Shared database roles](https://docs.snowflake.com/en/user-guide/data-share-consumers)

</details>

## Question 13

A partner has no Snowflake account. They need SQL access to your reports without signing up separately. You want to control their warehouse credit usage. Which setup fits?

- **A.** Add their email to the direct share and let them use your warehouse.
- **B.** Publish a listing they can query without an account.
- **C.** Replicate to a new account that automatically bills query compute to the partner.
- **D.** Create a reader account, share the reports with it, and configure a resource monitor on its warehouse.

<details>
<summary>Correct answer and explanation</summary>

**D.** The provider creates the reader account and pays for the compute it uses. A resource monitor can help manage its warehouse consumption. [Reader accounts](https://docs.snowflake.com/en/user-guide/data-sharing-reader-create)

</details>

## Question 14

`ORG_A` directly shares eligible data with `ORG_B.BI` in Oregon. `ORG_B.BI` imports it and creates a secure view over it. Assume the current direct-share resharing behavior applies. Which account can `ORG_B.BI` reshare with through another direct share?

- **A.** `ORG_A.OPERATIONS` in Oregon.
- **B.** `ORG_B.ANALYTICS` in Oregon.
- **C.** `ORG_B.ANALYTICS_TOKYO` in Tokyo.
- **D.** `ORG_C.PARTNER` in Oregon.

<details>
<summary>Correct answer and explanation</summary>

**B.** The target must be in the resharing consumer’s own organization and in the same region. Here the resharing consumer belongs to `ORG_B`. [Direct-share resharing](https://docs.snowflake.com/en/user-guide/data-share-consumers)

</details>

## Question 15

`SHARE_LAB` already imported your share. The share has `USAGE` on `D5_STUDY` and `D5_STUDY.LAB`. You want to add a secure view from `D5_STUDY.REPORTING`. What should you do?

- **A.** Grant `SELECT` on the view because the database grant covers every schema.
- **B.** Grant `REFERENCE_USAGE` on `D5_STUDY` and ask the consumer to re-import.
- **C.** Grant `USAGE` on `D5_STUDY.REPORTING` and `SELECT` on the view to the existing share.
- **D.** Have the consumer grant itself `SELECT` on the provider’s view.

<details>
<summary>Correct answer and explanation</summary>

**C.** Grant access to the view’s schema and the view itself. Both schemas belong to the same shared database, so the view becomes available through the existing imported database. [Grant privileges to a share](https://docs.snowflake.com/en/sql-reference/sql/grant-privilege-share)

</details>

## Question 16

`SHARE_READER` in your regular consumer account has access to the imported views but gets “No active warehouse selected.” A warehouse is running in the provider account. What should you do?

- **A.** Grant `SHARE_READER` `USAGE` on a warehouse in the consumer account and select that warehouse.
- **B.** Grant `USAGE` on the provider’s warehouse to the share.
- **C.** Add the provider’s warehouse to the imported database.
- **D.** Re-import the share so it picks up the provider’s warehouse.

<details>
<summary>Correct answer and explanation</summary>

**A.** The consumer account supplies the warehouse and incurs query compute credits. The provider continues to pay for storage of the source data. [Secure Data Sharing costs](https://docs.snowflake.com/en/user-guide/data-sharing-intro)

</details>

## Question 17

A retailer and an ad platform want to count customer overlap. Each controls which fields can be matched, and the agreed output is only the aggregate count. Which setup fits?

- **A.** Share both raw customer lists directly.
- **B.** Publish both raw datasets as private listings for the other party.
- **C.** Use a Data Clean Room with an approved overlap analysis and policies for the inputs and output.
- **D.** Replicate both databases into an account where both parties can read the tables.

<details>
<summary>Correct answer and explanation</summary>

**C.** An authorized analysis runner can execute the approved overlap analysis and see its allowed aggregate output. The collaboration controls access to the input fields. [Snowflake Data Clean Rooms](https://docs.snowflake.com/en/user-guide/cleanrooms/overview)

</details>

## Question 18

Your account runs on AWS in Virginia. A partner uses Azure in Virginia. Only that partner should get your approved orders views, plus a description and sample SQL. Which setup fits?

- **A.** Create a direct share because both accounts are in Virginia.
- **B.** Publish a public Marketplace listing because the partner uses another cloud.
- **C.** Target the external partner’s account with a replication group.
- **D.** Offer a private listing with Cross-Cloud Auto-Fulfillment.

<details>
<summary>Correct answer and explanation</summary>

**D.** AWS and Azure in the same geographic area are still separate Snowflake regions. A private listing targets the named partner. Auto-fulfillment can deliver the data product to their region. [Cross-Cloud Auto-Fulfillment](https://docs.snowflake.com/en/collaboration/provider-listings-auto-fulfillment)

</details>

## Question 19

You want anyone browsing Marketplace to be able to discover and get your weather data for free. You also want to offer premium retail benchmarks for payment to three named partners only. Assume paid private listings are supported. Which setup fits?

- **A.** Free public weather listing and paid private benchmark listing.
- **B.** Free private weather listing and paid public benchmark listing.
- **C.** Paid public weather listing and free private benchmark listing.
- **D.** Direct share for weather and paid public benchmark listing.

<details>
<summary>Correct answer and explanation</summary>

**A.** Public and private describe visibility. Free and paid describe product pricing. A consumer can still incur compute costs when querying a free dataset. [Listing visibility and pricing](https://docs.snowflake.com/en/collaboration/collaboration-listings-about)

</details>

## Question 20

A named partner wants to install an Orders dashboard with a UI and processing logic inside its Snowflake account. You want to offer it only to that partner. What do you publish?

- **A.** A direct share of the orders views, which creates an application when imported.
- **B.** A private listing with a Native App application package, which the partner installs as an application.
- **C.** A private listing with a data share, whose sample SQL becomes the dashboard UI.
- **D.** A replication group with the source tables, which installs the app when refreshed.

<details>
<summary>Correct answer and explanation</summary>

**B.** The provider attaches an application package to a private listing. Installation creates an application in the consumer account. [Snowflake Native App Framework](https://docs.snowflake.com/en/developer-guide/native-apps/native-apps-about)

</details>

## Question 21

A new version of a Native App must create a reporting view and stored procedure in the installed app. Where should you put the SQL that runs at install or upgrade?

- **A.** In the listing’s sample SQL.
- **B.** In the manifest itself.
- **C.** In a provider worksheet that you run before publishing.
- **D.** In the setup script, which the manifest points to.

<details>
<summary>Correct answer and explanation</summary>

**D.** The manifest identifies the setup script. The setup script contains the SQL that creates or updates application objects during installation or upgrade. [Native App packages, manifests, and setup scripts](https://docs.snowflake.com/en/developer-guide/native-apps/native-apps-about)

</details>

## Question 22

A cross-region private listing last refreshed successfully with data through 9:00. The provider adds an order at 9:10. The consumer queries the imported database at 9:12 before another successful refresh. What should they expect?

- **A.** The order appears immediately because the listing is private.
- **B.** The order appears after disabling persisted query result reuse.
- **C.** The data reflects the 9:00 refresh. The new order can appear after a successful refresh that includes it.
- **D.** The consumer must drop and re-import the listing to get changes.

<details>
<summary>Correct answer and explanation</summary>

**C.** Cross-Cloud Auto-Fulfillment syncs source changes to the consumer’s region according to its refresh configuration. The latest successful refresh determines the data available there. [Auto-fulfillment refreshes](https://docs.snowflake.com/en/collaboration/provider-listings-auto-fulfillment)

</details>

## Question 23

A partner wants to reshare your private listing among its Snowflake accounts. You want to permit resharing only within the partner’s organization. Which setup fits?

- **A.** Disable resharing and grant the partner’s account role access to your source tables.
- **B.** Enable listing resharing and restrict it to the resharing consumer’s organization.
- **C.** Enable resharing and leave cross-organization resharing allowed.
- **D.** Make the listing public.

<details>
<summary>Correct answer and explanation</summary>

**B.** Enable resharing and set the organization restriction. In a listing manifest, the settings are `resharing.enabled: true` and `resharing.only_within_organization: true`. The organization is the resharing consumer’s. [Listing resharing controls](https://docs.snowflake.com/en/collaboration/resharing-as-provider)

</details>

## Question 24

A share has `USAGE` on `PUBLISH_DB` and its `REPORTING` schema. A secure view there joins `ORDERS_DB` and `CUSTOMERS_DB`. You already gave the share `REFERENCE_USAGE` on `ORDERS_DB`, and `GRANT SELECT` on the view fails because of the reference to `CUSTOMERS_DB`. What should you do?

- **A.** Grant `USAGE` on `CUSTOMERS_DB` to the share.
- **B.** Grant `REFERENCE_USAGE` on `CUSTOMERS_DB` to the consumer’s account role.
- **C.** Grant `REFERENCE_USAGE` on `CUSTOMERS_DB` directly to the share, then retry the view grant.
- **D.** Grant `SELECT` on the underlying customer table directly to the share.

<details>
<summary>Correct answer and explanation</summary>

**C.** Each additional source database referenced by the secure view needs `REFERENCE_USAGE` on the share before the `SELECT` grant on the view. [Multi-database secure views](https://docs.snowflake.com/en/user-guide/data-sharing-multiple-db)

</details>

## Question 25

QA needs a new writable clone of `PROD.SALES.ORDERS` just before a bad `UPDATE`. The production table has an explicit `SELECT` grant to `PROD_REPORTER`. The destination schema `DEV.QA` has a future `SELECT` grant to `QA_ANALYST`. You want the QA grant without copying the production grant. Which approach fits?

- **A.** Clone with `BEFORE (STATEMENT => '<bad_query_id>')` and omit `COPY GRANTS`.
- **B.** Clone with `BEFORE (STATEMENT => '<bad_query_id>')` and include `COPY GRANTS`.
- **C.** Clone with `AT (STATEMENT => '<bad_query_id>')` and omit `COPY GRANTS`.
- **D.** Clone the current table and omit `COPY GRANTS`.

<details>
<summary>Correct answer and explanation</summary>

**A.** `BEFORE` selects the snapshot just before the bad update completed. Omitting `COPY GRANTS` on the new clone lets the applicable future grant in `DEV.QA` apply. Including it would copy explicit source grants. [CREATE CLONE](https://docs.snowflake.com/en/sql-reference/sql/create-clone)

</details>
