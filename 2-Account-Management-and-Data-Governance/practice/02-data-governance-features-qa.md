# 2.2 Practice: Data Governance Features

[Study note](../readme.md#22-data-governance-features)

The 25 questions from our practice round, edited for clarity. Each answer includes an explanation and an official Snowflake reference. Follow-up clarifications are included with the relevant question. SQL examples use illustrative names and require suitable privileges and existing objects.

## Question 1: Protecting customer emails

Analysts and support staff can query a customer table. Analysts should see every customer row with emails displayed as `***MASKED***`; support staff should see the original emails. Stored email values must remain unchanged. Which feature fits?

<details>
<summary>Correct answer and explanation</summary>

**Answer: A dynamic masking policy.**

The policy returns different column values according to the query context, such as active roles. It changes the query result rather than the stored email. Row access policies instead control which rows are returned.

[Reference: Dynamic masking and column-level security](https://docs.snowflake.com/en/user-guide/security-column-intro)

</details>

## Question 2: Regional data access

A shared `ORDERS` table contains APAC, EMEA, and AMERICAS orders. APAC analysts must receive only APAC rows; global managers must receive all rows. All required query privileges already exist. Which approach fits?

<details>
<summary>Correct answer and explanation</summary>

**Answer: A row access policy that checks the relevant active roles and each row's region.**

The policy returns only permitted records. Masking a region value would not remove its row; a tag labels an object, and a separate warehouse supplies compute rather than row filtering.

[Reference: Understanding row access policies](https://docs.snowflake.com/en/user-guide/security-row-intro)

</details>

## Question 3: Row access and masking together

A customer table contains these rows:

| Customer ID | Region | Email |
| --- | --- | --- |
| 1 | APAC | `a@example.com` |
| 2 | EMEA | `b@example.com` |
| 3 | APAC | `c@example.com` |

A row access policy permits an APAC analyst to see only APAC rows. An email masking policy returns `***MASKED***` unless the active role hierarchy includes `PII_FULL_ACCESS`. The analyst has query privileges but no such unmasking role. What does `SELECT *` return, and which policy is evaluated first?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Customers 1 and 3, with their emails masked. The row access policy is evaluated first.**

Row filtering removes the EMEA record. Masking protects the email values in the remaining records. `PII_FULL_ACCESS` is a role in this example, not a tag.

[Reference: Row access policies with masking policies](https://docs.snowflake.com/en/user-guide/security-row-intro#masking-policies)

</details>

## Question 4: Does a tag automatically mask data?

An administrator tags an email column:

```sql
ALTER TABLE customers
  MODIFY COLUMN email
  SET TAG data_classification = 'PII';
```

No masking policy is attached directly or through the tag. An analyst has all required query privileges. What is returned when they select the email column?

<details>
<summary>Correct answer and explanation</summary>

**Answer: The original emails. The tag alone is metadata.**

A label such as `PII` does not automatically create a protection rule. Associate the appropriate policy to enforce masking. Remember: **tag = label; policy = enforcement**.

[Reference: Introduction to object tagging](https://docs.snowflake.com/en/user-guide/object-tagging/introduction)

</details>

## Question 5: Masking many columns consistently

Hundreds of `STRING` columns already have a `SENSITIVE_DATA` tag. The team wants one centrally maintained masking rule without attaching a policy individually to every column. What should it do?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Attach a compatible `STRING` masking policy to the tag.**

Tag-based masking protects tagged columns when the policy's data type matches the column's type. The policy can then be managed centrally.

```sql
ALTER TAG sensitive_data SET MASKING POLICY string_mask;
```

This assumes both objects already exist and the administrator has the required privileges.

[Reference: Tag-based masking policies](https://docs.snowflake.com/en/user-guide/tag-based-masking-policies)

</details>

## Question 6: CURRENT_ROLE versus active secondary roles

An email masking policy contains:

```sql
CASE
  WHEN CURRENT_ROLE() = 'PII_FULL_ACCESS' THEN val
  ELSE '***MASKED***'
END
```

The primary role is `ANALYST`, and `PII_FULL_ACCESS` is an active secondary role. All query privileges are available. What email value is returned?

<details>
<summary>Correct answer and explanation</summary>

**Answer: `***MASKED***`, because `CURRENT_ROLE()` returns the primary role, `ANALYST`.**

To include the active primary and secondary role hierarchies in this ordinary query context, use:

```sql
CASE
  WHEN IS_ROLE_IN_SESSION('PII_FULL_ACCESS') THEN val
  ELSE '***MASKED***'
END
```

Having a secondary role available does not change the string returned by `CURRENT_ROLE()`.

[Reference: IS_ROLE_IN_SESSION](https://docs.snowflake.com/en/sql-reference/functions/is_role_in_session)

</details>

## Question 7: Permission to read a policy's mapping table

A row access policy on `ORDERS` looks up permitted regions in `ROLE_REGION_MAP`. The policy owner can read the mapping table. An analyst has all required privileges on `ORDERS` but no direct access to the map. The mapping permits APAC orders. Can the policy return those orders?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Yes. The policy can read the mapping table using its owner's privileges and return the analyst's permitted APAC orders.**

These are separate checks:

| Identity | Required access |
| --- | --- |
| Analyst | Permission to query `ORDERS`. |
| Policy owner | Permission to read `ROLE_REGION_MAP`. |

The analyst does not inherit the owner's privileges. Successfully querying `ORDERS` does not authorize a direct `SELECT * FROM ROLE_REGION_MAP`; that requires a separate applicable grant.

[Reference: How a row access policy works](https://docs.snowflake.com/en/user-guide/security-row-intro#how-does-a-row-access-policy-work)

</details>

## Question 8: Protecting people from repeated aggregate analysis

A healthcare team allows aggregate patient analysis but wants to prevent repeated, slightly different queries from revealing too much about individuals. It needs controlled noise and a limit on cumulative information disclosure. Which feature fits, and what does its budget measure?

<details>
<summary>Correct answer and explanation</summary>

**Answer: A privacy policy using differential privacy. Its privacy budget measures cumulative privacy loss.**

The budget limits how much queries may reveal. It is not a Snowflake credit budget, so buying credits or increasing warehouse size does not remove that restriction. The configured privacy limits and reset window govern further usage. Hiding patient names alone does not prevent inference through repeated aggregate queries.

[Reference: Privacy policies and privacy budgets](https://docs.snowflake.com/en/sql-reference/sql/create-privacy-policy)

</details>

## Question 9: Finding account security risks

A security team wants scanners to evaluate account configurations, identify risks such as excessive role privileges, and present findings with recommended fixes. Which feature fits?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Trust Center.**

It helps evaluate security posture. Scanner runs can incur serverless compute costs, although scheduled Security Essentials runs are free. Audit history and classification tags do not provide the same scanning workflow.

[Reference: Trust Center](https://docs.snowflake.com/en/user-guide/trust-center/overview)

</details>

## Question 10: Muting a security finding

Trust Center identifies excessive role privileges. An administrator mutes the violation but makes no changes to the grants. What changes?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Periodic email notifications for the violation stop, but the risky grants remain and scheduled scanning continues.**

Muting is a way to manage findings. Remediation requires changing the underlying configuration; muting does not revoke privileges or disable the scanner.

[Reference: Changing a violation finding's status](https://docs.snowflake.com/en/user-guide/trust-center/using-the-trust-center#change-the-status-of-a-violation-finding)

</details>

## Question 11: Customer-controlled encryption keys

A company wants a customer-managed cloud encryption key to work together with a Snowflake-managed key to protect its data. Which feature and minimum edition meet the requirement?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Tri-Secret Secure, available from Business Critical Edition.**

The two keys form a composite master key that protects the account's encryption-key hierarchy. Key-pair authentication is a separate login mechanism; periodic rekeying is a separate encryption-key lifecycle feature.

[Reference: Tri-Secret Secure](https://docs.snowflake.com/en/user-guide/security-encryption-tss)

</details>

## Question 12: Losing access to the customer-managed key

A company uses Tri-Secret Secure. Its cloud administrator revokes Snowflake's access to the required customer-managed key. What is the main risk if Snowflake cannot use that key?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Protected data can become inaccessible because Snowflake cannot decrypt it without the required key.**

This can affect existing data, not just new loads. Switching to `ACCOUNTADMIN` does not bypass encryption. The statement describes the risk; it does not imply every temporary key-service interruption instantly makes all data unavailable.

[Reference: Tri-Secret Secure key responsibility](https://docs.snowflake.com/en/user-guide/security-encryption-tss)

</details>

## Question 13: Rotation versus periodic rekeying

How do rotation and periodic rekeying differ for Snowflake-managed encryption keys?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Rotation introduces new active keys while retired keys can decrypt older data. Periodic rekeying re-encrypts older protected data using new keys.**

Rotation does not automatically mean all existing data is immediately re-encrypted. Periodic rekeying is an optional Enterprise-or-higher feature. Neither process changes a user's login password or automatically activates Tri-Secret Secure.

[Reference: Encryption key management](https://docs.snowflake.com/en/user-guide/security-encryption-manage)

</details>

## Question 14: Enabling scheduled alert execution

An engineer creates `ORDER_CHECK` with a five-minute schedule. The owner has all required privileges, and the condition and action are valid. Which SQL enables its scheduled executions?

<details>
<summary>Correct answer and explanation</summary>

**Answer: `ALTER ALERT ORDER_CHECK RESUME;`**

```sql
ALTER ALERT ORDER_CHECK RESUME;
```

Newly created alerts are suspended. `EXECUTE ALERT ORDER_CHECK` requests a single execution; it does not enable the schedule. Resuming the warehouse alone does not resume the alert.

[References: CREATE ALERT](https://docs.snowflake.com/en/sql-reference/sql/create-alert) · [EXECUTE ALERT](https://docs.snowflake.com/en/sql-reference/sql/execute-alert)

</details>

## Question 15: EXISTS with an aggregate count

An engineer wants an alert to act only when no orders were loaded today. They write this condition:

```sql
IF (EXISTS (
  SELECT COUNT(*)
  FROM orders
  WHERE order_date = CURRENT_DATE()
))
```

Assuming the query succeeds, how does the condition behave, and how should it be corrected?

<details>
<summary>Correct answer and explanation</summary>

**Answer: It is true for both zero orders and many orders, because the aggregate query returns one row. Add `HAVING COUNT(*) = 0`.**

`EXISTS` checks for returned rows, not whether a value inside a row is positive.

| Orders today | Count value | Result rows without HAVING | EXISTS |
| --- | --- | --- | --- |
| 0 | `0` | 1 | `TRUE` |
| 25 | `25` | 1 | `TRUE` |

The corrected condition is:

```sql
IF (EXISTS (
  SELECT COUNT(*)
  FROM orders
  WHERE order_date = CURRENT_DATE()
  HAVING COUNT(*) = 0
))
```

With 25 orders, `HAVING` removes the result row: zero rows remain, `EXISTS` is false, and the action does not run. With zero orders, the count row remains and the action runs. These are condition fragments for an alert definition.

[References: EXISTS](https://docs.snowflake.com/en/sql-reference/operators-subquery#not-exists) · [Alert conditions](https://docs.snowflake.com/en/sql-reference/sql/create-alert)

</details>

## Question 16: Additional privilege for a serverless alert

An alert omits `WAREHOUSE` and therefore uses serverless compute. Its owner already has `CREATE ALERT` on the schema, `EXECUTE ALERT` on the account, and all condition/action privileges. Which additional account privilege is required?

<details>
<summary>Correct answer and explanation</summary>

**Answer: `EXECUTE MANAGED ALERT`.**

Serverless execution requires this privilege in addition to `EXECUTE ALERT`. A warehouse-backed alert instead requires access to its specified warehouse. Neither `CREATE WAREHOUSE` nor `MANAGE GRANTS` substitutes for the missing privilege.

[Reference: Alert access-control requirements](https://docs.snowflake.com/en/sql-reference/sql/create-alert#access-control-requirements)

</details>

## Question 17: Eligible email notification recipients

An administrator wants to put an analyst's address in an email notification integration's `ALLOWED_RECIPIENTS`. Which recipient requirement applies?

<details>
<summary>Correct answer and explanation</summary>

**Answer: The address must belong to a user in the current Snowflake account and must be verified.**

Using `ACCOUNTADMIN` does not bypass this requirement. The recipient does not need table `SELECT` merely to receive the email, and an object tag does not verify an address.

[Reference: Email integration recipient requirements](https://docs.snowflake.com/en/sql-reference/sql/create-notification-integration-email#optional-parameters)

</details>

## Question 18: Replication plus promotion

A company needs to replicate databases and supported account objects to another account, then promote the secondary group to primary during an outage. Which feature provides this capability, and how does it differ from a replication group?

<details>
<summary>Correct answer and explanation</summary>

**Answer: A failover group supports replication and promotion. A replication group alone does not support promotion to primary.**

Failover/failback requires Business Critical Edition or higher. A share or zero-copy clone does not provide this cross-account synchronization and promotion workflow. Do not assume promotion happens automatically merely because the group exists.

[Reference: Account replication and failover](https://docs.snowflake.com/en/user-guide/account-replication-intro)

</details>

## Question 19: Changes that have not reached the replica

The secondary contains all source changes committed through 10:00. New orders are committed to the primary at 10:06. The primary becomes unavailable at 10:08 before another refresh. No refresh is in progress. The secondary is promoted without another recovery process. Are the 10:06 orders present?

<details>
<summary>Correct answer and explanation</summary>

**Answer: No. Those orders were not replicated to the secondary.**

Promotion does not reconstruct unreplicated changes or automatically fetch unavailable source data. Asynchronous replication permits lag. Increasing warehouse size or assuming automatic Fail-safe recovery does not fill that gap.

[Reference: Asynchronous replication and disaster recovery](https://docs.snowflake.com/en/user-guide/replication-intro)

</details>

## Question 20: RPO versus RTO

A company accepts no more than five minutes of lost data and requires application service to be restored within thirty minutes of an outage. What are its RPO and RTO targets?

<details>
<summary>Correct answer and explanation</summary>

**Answer: RPO = 5 minutes; RTO = 30 minutes.**

| Objective | Measures | Target |
| --- | --- | --- |
| Recovery point objective (RPO) | Acceptable data-loss window. | 5 minutes |
| Recovery time objective (RTO) | Target time to restore service. | 30 minutes |

Remember: **RPO → lost data; RTO → downtime.** These are requirements; configuring replication alone does not prove they are met.

[Reference: Snowflake recovery objectives example](https://www.snowflake.com/en/blog/how-dtcc-achieves-data-resiliency/)

</details>

## Question 21: Finding the impact of a table change

An engineer plans to change `ORDERS` and wants to identify views and derived tables that may be affected. Which direction of lineage should they investigate?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Downstream lineage.**

Downstream asks what depends on or receives data from the object. Upstream asks where its data came from. Lineage supports impact analysis; login history and warehouse metering answer different questions. Visibility and captured relationships limit what the graph can show.

[Reference: Data lineage](https://docs.snowflake.com/en/user-guide/ui-snowsight-lineage)

</details>

## Question 22: Object dependency versus data movement

An engineer runs:

```sql
CREATE TABLE orders_copy AS
SELECT order_id, amount FROM orders;

CREATE VIEW orders_view AS
SELECT order_id, amount FROM orders;
```

Assume supported objects and available metadata. Which relationship is recorded in `ACCOUNT_USAGE.OBJECT_DEPENDENCIES`?

<details>
<summary>Correct answer and explanation</summary>

**Answer: The view's reference to `ORDERS`, not the CTAS table's data-movement relationship.**

| Object | Relationship | In OBJECT_DEPENDENCIES? |
| --- | --- | --- |
| `orders_copy` | CTAS copies query results into a separate table. | No |
| `orders_view` | The stored query references the source. | Yes |

Data lineage can capture both kinds. `OBJECT_DEPENDENCIES` excludes data movement through CTAS, `INSERT`, and `MERGE`.

Later inserts into `ORDERS` do not automatically update `orders_copy`. This example uses CTAS, not `CLONE`; a zero-copy clone is a different creation mechanism.

[Reference: OBJECT_DEPENDENCIES](https://docs.snowflake.com/en/sql-reference/account-usage/object_dependencies)

</details>

## Question 23: Does a masking policy grant SELECT?

A masking policy returns original emails when `PII_FULL_ACCESS` is active. A user activates that role and has warehouse, database, and schema `USAGE`, but the session has no applicable table `SELECT` privilege. Can the user read the customer table?

<details>
<summary>Correct answer and explanation</summary>

**Answer: No. The query fails because the required table privilege is missing.**

The policy controls visible values; it does not supply object privileges. Recognizing an unmasking role inside a policy is not equivalent to granting that role permission to query the table.

[Reference: Column-level security and masking policies](https://docs.snowflake.com/en/user-guide/security-column-intro)

</details>

## Question 24: A masking tag on a whole table

A table has `CUSTOMER_ID NUMBER`, `EMAIL STRING`, and `CITY STRING`. A tag carries a `STRING` masking policy that always returns `***MASKED***`. The tag is applied to the whole table. Assume no direct masking policies or conflicts. Which columns are masked?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Both `EMAIL` and `CITY`.**

The table-level tag extends protection to matching-type columns. `CUSTOMER_ID` is numeric, so it does not match this string policy. Column names do not determine which values this policy masks.

To protect only email, use a column-level assignment. If the table-level assignment already exists, remove that broader assignment as well:

```sql
ALTER TABLE customers UNSET TAG sensitive_data;

ALTER TABLE customers
  MODIFY COLUMN email
  SET TAG sensitive_data = 'PII';
```

This assumes the tag and its policy already exist and no other inherited assignments affect the columns.

[Reference: Tag-based masking and inheritance](https://docs.snowflake.com/en/user-guide/tag-based-masking-policies)

</details>

## Question 25: Direct masking versus tag-based masking

An email column has a directly assigned masking policy returning `DIRECT_MASK`. Its tag also carries a masking policy returning `TAG_MASK`. Both policies match the column's type and are otherwise valid. Which result is returned?

<details>
<summary>Correct answer and explanation</summary>

**Answer: `DIRECT_MASK`. The directly assigned masking policy takes precedence.**

Both are masking policies, but the direct column assignment overrides tag-based masking for that column. They do not run sequentially and combine results, and this supported coexistence does not always cause an error.

[Reference: Direct and tag-based masking precedence](https://docs.snowflake.com/en/user-guide/tag-based-masking-policies)

</details>
