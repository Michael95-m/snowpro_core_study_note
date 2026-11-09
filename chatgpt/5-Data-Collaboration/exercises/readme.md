# Domain 5 SQL exercises

[Back to the study note](../readme.md)

## 1. Run the single-account lab

- Use Snowsight or the Snowflake extension in VS Code. Use `SYSADMIN` or an equivalent lab role with privileges to create the warehouse and database and own the lab objects.
- Reserve `D5_STUDY` and `D5_STUDY_WH` for this lab. The scripts replace or drop named fixture objects inside that database.
- The X-Small warehouse can consume credits while running. It starts suspended, auto-resumes for queries, and auto-suspends after 60 seconds of inactivity.

| Order | File | Checkpoint |
| --- | --- | --- |
| 1 | [00-setup.sql](00-setup.sql) | Session uses `D5_STUDY.LAB` and `D5_STUDY_WH`. |
| 2 | [01-time-travel-and-undrop.sql](01-time-travel-and-undrop.sql) | Before the delete, the table has 3 rows totaling **600**. The current and restored table has 2 rows totaling **400**. |
| 3 | [02-zero-copy-cloning.sql](02-zero-copy-cloning.sql) | After independent writes, the source totals **350** and the clone **325**. Then compare `SHOW GRANTS` on two new clones with and without `COPY GRANTS`. |
| 4 | [03-secure-sharing.sql](03-secure-sharing.sql) | The private base has 3 rows. The secure view has orders **1 and 3**, exposes only approved columns, and totals **400**. |
| 5 | [04-replication-and-collaboration.sql](04-replication-and-collaboration.sql) | Read your current account identity and work through which statements belong in each account. |
| 6 | [99-stop-lab.sql](99-stop-lab.sql) | Warehouse is suspended. Study data stays available. |

- Run the delete and historical query in **the same session**, one immediately after the other. If your editor sends an intervening query, copy the delete's query ID from Query History and replace `LAST_QUERY_ID()` in the historical query with that quoted ID. [AT and BEFORE](https://docs.snowflake.com/en/sql-reference/constructs/at-before)
- The secure-view exercise previews the provider-side output. An actual consumer query requires a second account and a separate share.
- SQL was reviewed against Snowflake documentation. The examples have not been executed in your account.

## 2. Walk through the optional multi-account steps

### Direct share

1. Use two test accounts in the same region and confirm their organization and account names.
2. Follow the commented provider steps in exercise 03 with `ACCOUNTADMIN` or a role with delegated share permissions. Add only your intended test consumer.
3. Connect to the consumer separately. Import the share into a new database. Grant `IMPORTED PRIVILEGES` to a local query role that can use a consumer warehouse.
4. Query the view and compare it with the provider's preview. Clean up the lab share and imported database separately when finished. [Direct share provider setup](https://docs.snowflake.com/en/user-guide/data-sharing-provider) · [Consumer setup](https://docs.snowflake.com/en/user-guide/data-share-consumers)

### Internal Marketplace listing

This optional exercise uses the same two accounts to practice **internal sharing through an organizational listing**. It is separate from the direct-share steps above. Your organization needs the organizational-listing prerequisites and your provider role needs the required share and listing privileges. [Create an organizational listing](https://docs.snowflake.com/en/user-guide/collaboration/listings/organizational/org-listing-create)

1. In the provider account, run `00-setup.sql` and `03-secure-sharing.sql` through the secure-view preview. Do not run the optional direct-share commands. Check that `D5_STUDY.LAB.D5_PARTNER_ORDERS_V` shows only orders **1 and 3**.
2. In Snowsight, open **Data sharing → Internal sharing → Create Listing**. Select that secure view as the data product and generate the listing. Use a lab name such as `D5_INTERNAL_ORDERS`.
3. In **Access Control**, choose **Selected accounts and roles** and select only your test consumer account, `SHARE_LAB`. Review the access settings and publish the listing. Avoid **Entire organization** for this lab.
4. Sign in to `SHARE_LAB`. Open **Catalog → Internal Marketplace**, find the lab listing, and copy its **Uniform Listing Locator (ULL)**. Use a role allowed by the listing and an available consumer warehouse. Query the view by using the copied ULL in place of the database name:

```sql
-- Paste the exact ULL copied from the listing in place of <copied_ull>.
SELECT ORDER_ID, REGION, AMOUNT
FROM <copied_ull>.LAB.D5_PARTNER_ORDERS_V
ORDER BY ORDER_ID;
-- Expected: orders 1 and 3; no INTERNAL_NOTE column.
```

5. Compare the result with the provider's secure-view preview. When finished, **unpublish and delete** the lab listing from **Data sharing → Internal sharing**. Check the provider's generated share and any consumer database you mounted before removing the underlying lab data. [Query an organizational listing](https://docs.snowflake.com/en/user-guide/collaboration/listings/organizational/org-listing-query) · [Manage organizational listings](https://docs.snowflake.com/en/user-guide/collaboration/listings/organizational/org-listing-manage)

- **What to explain afterward:** a direct share targets a known same-region account; an organizational listing also gives people in your organization a discoverable data product in the Internal Marketplace. Neither workflow requires a Data Exchange.

### Replication and failover

1. Review exercise 04 with two accounts from the same organization, configured for replication. Use either the replication-group example or the failover-group example.
2. Check that the target does not already have a database called `D5_STUDY`. Create the primary in the source and the secondary in the target.
3. Refresh the secondary and verify the data there. Business Critical or higher and appropriate privileges are required for the failover example. Promotion changes which account is primary, so leave it for an isolated drill. [Replication setup](https://docs.snowflake.com/en/user-guide/account-replication-intro) · [Failover and failback](https://docs.snowflake.com/en/user-guide/account-replication-failover-failback)

## 3. Review listings, clean rooms, and applications

- **Listings.** Open an available Marketplace listing in Snowsight and identify its data product, provider, terms, and any sample queries. Explain what would make a private listing a better fit for a single partner. [About listings](https://docs.snowflake.com/en/collaboration/collaboration-listings-about)
- **Clean rooms.** Sketch a retailer and ad platform counting audience overlap. Identify the two inputs, the permitted join column, the aggregate they can return, and whether saving results requires activation. [Clean Rooms overview](https://docs.snowflake.com/en/user-guide/cleanrooms/overview)
- **Native Apps.** If your account exposes any apps or packages, compare the read-only `SHOW APPLICATIONS` and `SHOW APPLICATION PACKAGES` outputs in exercise 04. An empty list simply means there are no matching objects visible to your role. [Native App objects](https://docs.snowflake.com/en/developer-guide/native-apps/native-apps-about)
