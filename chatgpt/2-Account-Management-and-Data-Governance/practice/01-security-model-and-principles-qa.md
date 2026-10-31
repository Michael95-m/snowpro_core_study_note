# 2.1 Practice: Security Model and Principles

[Study note](../readme.md#21-security-model-and-principles)

The 25 questions from our practice round, edited for clarity. Each answer includes an explanation and an official Snowflake reference. Follow-up clarifications are included with the relevant question. SQL examples use illustrative names and require suitable privileges and existing objects.

## Question 1: Missing schema access

A role has `USAGE` on a warehouse and database, plus `SELECT` on a table in that database. It has no privileges on the table's schema. What additional privilege normally allows it to query the table with the least access needed?

<details>
<summary>Correct answer and explanation</summary>

**Answer: `USAGE` on the containing schema.**

Table access and access to its parent containers are separate requirements. The existing database and warehouse grants do not provide schema access.

```sql
GRANT USAGE ON SCHEMA SALES_DB.MART TO ROLE ANALYST;
```

[Reference: Accessing database objects](https://docs.snowflake.com/en/user-guide/security-access-control-considerations#accessing-database-objects)

</details>

## Question 2: Direction of role inheritance

Given this grant, which role inherits the other's privileges?

```sql
GRANT ROLE SALES_READER TO ROLE FINANCE_ANALYST;
```

<details>
<summary>Correct answer and explanation</summary>

**Answer: `FINANCE_ANALYST` inherits the privileges of `SALES_READER`.**

The role receiving the grant is the parent. Privilege inheritance flows upward to the parent, not downward to the child.

```text
SALES_READER → FINANCE_ANALYST
child           parent
```

[Reference: GRANT ROLE](https://docs.snowflake.com/en/sql-reference/sql/grant-role)

</details>

## Question 3: Grants in a managed access schema

A role owns a table in a managed access schema. It does not own the schema and does not have `MANAGE GRANTS`. Can it grant `SELECT` on its table to another role?

<details>
<summary>Correct answer and explanation</summary>

**Answer: No. The schema owner or a role with `MANAGE GRANTS` must make the grant.**

Managed access schemas centralize grant management. Owning an individual table there does not authorize its owner to independently grant table access. In a regular schema, the object owner can normally make such grants.

[Reference: Centralizing grant management using managed access schemas](https://docs.snowflake.com/en/user-guide/security-access-control-considerations#centralizing-grant-management-using-managed-access-schemas)

</details>

## Question 4: Owning a role versus inheriting it

`ROLE_MANAGER` owns the role object `SALES_READER`, but `SALES_READER` has not been granted to `ROLE_MANAGER`. Only `SALES_READER` has `SELECT` on a particular table. Does ownership of the role automatically let `ROLE_MANAGER` query that table?

<details>
<summary>Correct answer and explanation</summary>

**Answer: No. Role ownership alone does not provide the owned role's data privileges.**

To establish inheritance, grant the reader role to the manager role:

```sql
GRANT ROLE SALES_READER TO ROLE ROLE_MANAGER;
```

The same pattern applies when `ROLE_A` must inherit `ROLE_B`:

```sql
GRANT ROLE ROLE_B TO ROLE ROLE_A;
```

[Reference: Role privileges and OWNERSHIP](https://docs.snowflake.com/en/user-guide/security-access-control-privileges#role-privileges)

</details>

## Question 5: Least-privileged built-in role for user administration

An administrator needs to create users and custom account roles, without responsibility for creating warehouses and databases or managing grants globally. Which built-in role provides the relevant capabilities with less authority than `SECURITYADMIN` or `ACCOUNTADMIN`?

<details>
<summary>Correct answer and explanation</summary>

**Answer: `USERADMIN`.**

`USERADMIN` has `CREATE USER` and `CREATE ROLE`. It can manage users and roles it owns. `SECURITYADMIN` inherits it and adds broader grant administration.

[Reference: System-defined roles](https://docs.snowflake.com/en/user-guide/security-access-control-overview#system-defined-roles)

</details>

## Question 6: MANAGE GRANTS versus data access

An administrator uses `SECURITYADMIN`, which has `MANAGE GRANTS`. No applicable grant provides `SELECT` on a particular table. Assuming the warehouse and parent containers are accessible, does `MANAGE GRANTS` alone let the administrator query it?

<details>
<summary>Correct answer and explanation</summary>

**Answer: No. Grant administration is separate from the privilege to read data.**

`MANAGE GRANTS` authorizes managing grants; it does not automatically supply `SELECT` on every table. The administrator must obtain an appropriate data-access grant before querying.

[Reference: Global privileges — MANAGE GRANTS](https://docs.snowflake.com/en/user-guide/security-access-control-privileges#global-privileges-account-privileges)

</details>

## Question 7: Combining active roles for SELECT

A session's primary role has warehouse, database, and schema `USAGE`. An active secondary role has `SELECT` on the table. Can an ordinary `SELECT` query use those privileges together?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Yes. The session can combine privileges from active primary and secondary roles and their inherited roles.**

This authorizes the query without transferring the secondary role's privileges to the primary role.

[Reference: USE SECONDARY ROLES](https://docs.snowflake.com/en/sql-reference/sql/use-secondary-roles)

</details>

## Question 8: Primary-role authorization for object creation

The primary role and its inherited roles lack `CREATE TABLE` on a schema. An active secondary role has that privilege. Can the session create a new permanent table there using only the secondary role's grant?

<details>
<summary>Correct answer and explanation</summary>

**Answer: No. Object creation must be authorized through the primary role and its inherited roles.**

Switch to a suitable primary role before creating the table. Ownership of the new table is assigned to the primary role that creates it.

[Reference: USE ROLE](https://docs.snowflake.com/en/sql-reference/sql/use-role)

</details>

## Question 9: Existing tables versus future tables

An administrator executes the following statement. Will a table created in the schema afterward automatically receive the same grant?

```sql
GRANT SELECT ON ALL TABLES IN SCHEMA SALES_DB.MART
  TO ROLE ANALYST;
```

<details>
<summary>Correct answer and explanation</summary>

**Answer: No. `ALL TABLES` covers tables that already exist when the grant is executed.**

Use a future grant for tables created later:

```sql
GRANT SELECT ON FUTURE TABLES IN SCHEMA SALES_DB.MART
  TO ROLE ANALYST;
```

Future grants do not backfill existing tables. Use both statements when both existing and future tables need coverage. Views require their own grants.

[Reference: GRANT privileges — future grants](https://docs.snowflake.com/en/sql-reference/sql/grant-privilege#future-grants)

</details>

## Question 10: Database roles and cross-database access

A company defines reader database roles in `SALES_DB` and `FINANCE_DB`. Analysts must query both databases using `BI_WH`. How should the company combine those database roles with warehouse access in an account-role design?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Grant both database roles to an account role, and grant warehouse `USAGE` to that account role.**

Database roles are database-scoped and cannot be activated directly. Activate the account role to use their inherited privileges.

```sql
GRANT DATABASE ROLE SALES_DB.READER TO ROLE BI_ANALYST;
GRANT DATABASE ROLE FINANCE_DB.READER TO ROLE BI_ANALYST;
GRANT USAGE ON WAREHOUSE BI_WH TO ROLE BI_ANALYST;
GRANT ROLE BI_ANALYST TO USER ANALYST_USER;

USE ROLE BI_ANALYST;
```

The database roles must already contain the necessary schema and object privileges. This illustrates the account-role inheritance pattern; granting a database role is not itself a `USE ROLE` activation.

[Reference: Types of roles](https://docs.snowflake.com/en/user-guide/security-access-control-overview#types-of-roles)

</details>

## Question 11: User-level network policy precedence

An account-level network policy allows only office connections. A policy assigned directly to `ALICE` allows her home IP. She signs in from home using password authentication. All other authentication requirements are satisfied, and no security integration applies. Is her connection allowed?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Yes. Her user-level network policy overrides the account-level policy.**

The policies are not intersected. The applicable user policy replaces the broader account policy for this scenario. OAuth integration flows have additional rules, so do not generalize this password-login example to every token request.

[Reference: Network policy precedence](https://docs.snowflake.com/en/user-guide/network-policies#network-policy-precedence)

</details>

## Question 12: An IP is both allowed and blocked

An active network policy allows an office IPv4 range but explicitly blocks one IPv4 address inside that range. A user connects from the blocked address with valid credentials and appropriate privileges. What happens?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Access is denied because the blocked rule takes precedence.**

Matching an allowed IPv4 range does not override an explicit IPv4 block. Object privileges do not bypass the network restriction.

[Reference: Interaction between allowed lists and blocked lists](https://docs.snowflake.com/en/user-guide/network-policies#interaction-between-allowed-lists-and-blocked-lists)

</details>

## Question 13: Creating a policy versus activating it

An administrator creates an office-only network rule and a policy referencing it, but never assigns the policy to an account, user, or security integration. A user connects from home. All login requirements are satisfied, and no other network policy applies. Is the new policy enforced?

<details>
<summary>Correct answer and explanation</summary>

**Answer: No. The home connection is allowed under these assumptions because the policy has not been assigned.**

Creating a rule or policy defines restrictions; assignment activates enforcement. An account-level assignment can apply the policy to users without a separate assignment to each user.

```sql
-- Example activation for one user, after configuring valid allowed addresses:
ALTER USER ALICE SET NETWORK_POLICY = OFFICE_ONLY_POLICY;
```

Recall: **Create → Assign → Enforce.**

[Reference: Activating a network policy](https://docs.snowflake.com/en/user-guide/network-policies#activating-a-network-policy)

</details>

## Question 14: Authentication versus authorization

An analyst signs in through SSO and completes MFA. Their session has no applicable `SELECT` privilege on a particular table. Can successful authentication alone authorize querying that table?

<details>
<summary>Correct answer and explanation</summary>

**Answer: No. The query fails without the required data privilege.**

Authentication verifies identity; authorization determines permitted actions. SSO and MFA do not automatically grant table access.

[Reference: Access control framework](https://docs.snowflake.com/en/user-guide/security-access-control-overview#access-control-framework)

</details>

## Question 15: Network policy versus authentication policy

A company already restricts connections to its office network. It now wants human users to authenticate through its SAML SSO provider instead of passwords. Which additional control should it configure?

<details>
<summary>Correct answer and explanation</summary>

**Answer: An authentication policy that permits SAML as the authentication method.**

A network policy controls **where** connections originate. An authentication policy controls **how** users authenticate. Configure and assign the authentication policy to the relevant account or users.

The same policy type controls a requirement to permit password authentication while excluding key-pair authentication, subject to other applicable authentication requirements.

[Reference: Authentication policies](https://docs.snowflake.com/en/user-guide/authentication-policies)

</details>

## Question 16: Where public and private keys belong

A scheduled Python application uses key-pair authentication instead of a password. Where should the keys be kept?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Keep the private key securely with the application or its secret store, and register the public key on the Snowflake user.**

The application signs authentication proof with its private key. Snowflake uses the registered public key to verify that proof. The private key itself is not sent to Snowflake.

[Reference: Overview of Snowflake authentication — key-pair authentication](https://docs.snowflake.com/en/user-guide/security-authentication-overview)

</details>

## Question 17: Key rotation without downtime

An application uses a public key registered in a user's `RSA_PUBLIC_KEY` property. How can the team rotate this key pair without interrupting clients during the transition?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Register the new public key in `RSA_PUBLIC_KEY_2`, switch and verify clients with the new private key, then remove the old public key.**

Both public-key properties can hold valid keys simultaneously. Keep the old public key until all affected clients have switched successfully. Removing it first could prevent clients still using the old private key from connecting.

This sequence applies to the `RSA_PUBLIC_KEY` properties specified in the question.

[Reference: Configuring key-pair rotation](https://docs.snowflake.com/en/user-guide/key-pair-auth#configuring-key-pair-rotation)

</details>

## Question 18: Snowflake OAuth versus External OAuth

A company wants Microsoft Entra ID to issue OAuth access tokens for a BI application. Snowflake should validate those tokens and enforce the user's applicable privileges. Which OAuth option fits?

<details>
<summary>Correct answer and explanation</summary>

**Answer: External OAuth, with Entra ID acting as the authorization server.**

External OAuth uses a third-party authorization server to issue tokens. With Snowflake OAuth, Snowflake acts as the authorization server. In either case, using OAuth does not bypass Snowflake authorization checks.

[Reference: External OAuth overview](https://docs.snowflake.com/en/user-guide/oauth-ext-overview)

</details>

## Question 19: Account identifiers and account locators

Which SQL returns an account identifier in `organization_name-account_name` format? What does `CURRENT_ACCOUNT()` return instead?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Concatenate the organization name and account name. `CURRENT_ACCOUNT()` returns the account locator.**

```sql
SELECT CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME()
  AS ACCOUNT_IDENTIFIER;

SELECT CURRENT_ACCOUNT() AS ACCOUNT_LOCATOR;
```

For example, the first expression could return `MYORG-ANALYTICS`, while the locator could be `XY12345`. The locator and account name are different identifiers.

[Reference: Using SQL commands to get connection settings](https://docs.snowflake.com/en/user-guide/gen-conn-config#using-sql-commands-to-get-connection-settings)

</details>

## Question 20: Investigating failed logins

A security administrator needs unsuccessful login attempts, including timestamps, source IP addresses, authentication methods, and error messages. Which history source should they use?

<details>
<summary>Correct answer and explanation</summary>

**Answer: `LOGIN_HISTORY`.**

It records authentication attempts and their outcomes. `QUERY_HISTORY` describes SQL execution; an application event table contains telemetry rather than the account's login audit history.

```sql
SELECT EVENT_TIMESTAMP, USER_NAME, CLIENT_IP,
       FIRST_AUTHENTICATION_FACTOR, ERROR_CODE, ERROR_MESSAGE
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE IS_SUCCESS = 'NO'
ORDER BY EVENT_TIMESTAMP DESC
LIMIT 100;
```

Access to the view is required. The Account Usage view can have up to two hours of latency, so a recent event might not appear immediately.

[Reference: LOGIN_HISTORY view](https://docs.snowflake.com/en/sql-reference/account-usage/login_history)

</details>

## Question 21: Finding custom procedure logs

A Python stored procedure emits custom warning messages. Telemetry collection and the required logging level are configured. Where should the engineer inspect those messages?

<details>
<summary>Correct answer and explanation</summary>

**Answer: The event table configured to receive the procedure's telemetry.**

Snowflake captures emitted messages according to the logging configuration. The engineer can query the event table or use the relevant Snowsight log interface. `LOGIN_HISTORY` is for authentication attempts.

[Reference: Logging messages from functions and procedures](https://docs.snowflake.com/en/developer-guide/logging-tracing/logging)

</details>

## Question 22: Logs, traces, and metrics

An engineer needs custom warning/error messages, execution flow and timing of instrumented operations, and CPU/memory consumption. Which telemetry type matches each need?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Logs → Traces → Metrics.**

| Need | Telemetry type | Explanation |
| --- | --- | --- |
| Custom warning and error messages | Logs | Discrete messages emitted during execution. |
| Execution flow and timing | Traces | Spans and events describing instrumented operations. |
| CPU and memory consumption | Metrics | Numeric measurements of resource consumption. |

Collection depends on the supported handler/runtime and configured telemetry levels.

[Reference: Logging, tracing, and metrics](https://docs.snowflake.com/en/developer-guide/logging-tracing/logging-tracing-overview) · [Reference: Collecting metrics data](https://docs.snowflake.com/en/developer-guide/logging-tracing/metrics)

</details>

## Question 23: Access through PUBLIC with secondary roles disabled

An administrator revokes a table's `SELECT` privilege from `ANALYST`, but `PUBLIC` retains it. All required database, schema, and warehouse privileges remain available. Can the analyst query the table, including after running these statements?

```sql
USE ROLE ANALYST;
USE SECONDARY ROLES NONE;
```

<details>
<summary>Correct answer and explanation</summary>

**Answer: Yes. `ANALYST` inherits privileges from `PUBLIC`, which is automatically granted to every user and role.**

Disabling secondary roles does not remove that inheritance. A secondary role's privilege, by comparison, authorizes the session without being transferred to the primary role.

[Reference: PUBLIC and system-defined roles](https://docs.snowflake.com/en/user-guide/security-access-control-overview#system-defined-roles)

</details>

## Question 24: Removing every access path

A user can obtain table `SELECT` through `ANALYST`, another active role named `REPORT_READER`, and `PUBLIC`. The administrator revokes only the grant to `ANALYST`. What must be checked to ensure the user can no longer query the table?

<details>
<summary>Correct answer and explanation</summary>

**Answer: Check all remaining access paths.**

Review other available roles, role inheritance, `PUBLIC`, ownership, and applicable direct user grants. Revoking one grant does not create an explicit denial overriding other valid grants. Also consider roles the user could activate later.

[Reference: Authorization through primary and secondary roles](https://docs.snowflake.com/en/user-guide/security-access-control-overview#authorization-through-primary-role-and-secondary-roles)

</details>

## Question 25: RBAC versus DAC

In a regular schema, a table owner grants `SELECT` to `SALES_READER`. An administrator grants `SALES_READER` to an analyst. Which access-control models does this illustrate?

<details>
<summary>Correct answer and explanation</summary>

**Answer: The owner's control over grants reflects DAC; assigning access through roles reflects RBAC.**

DAC means **Discretionary Access Control**. RBAC means **Role-Based Access Control**. Both work together here; managed access schemas centralize grant decisions instead.

[Reference: Access control framework](https://docs.snowflake.com/en/user-guide/security-access-control-overview#access-control-framework)

</details>
