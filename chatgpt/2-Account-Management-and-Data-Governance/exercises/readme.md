# Domain 2 SQL exercises

- **Objectives:** 2.1 security, 2.2 governance, 2.3 monitoring/costs.
- **Status:** reviewed against official SQL references; not executed in your account.
- **Lab objects:** `D2_STUDY`, `D2_STUDY_WH`, and roles prefixed `D2_STUDY_`.
- **Setup privilege:** `ACCOUNTADMIN` is used once to delegate lab roles to your current user; ordinary exercises switch to narrower roles.
- **Data:** three synthetic customers and three orders. No new human/service user is created.
- **Fresh session:** tests change the active primary/secondary roles. Finish in an administrative lab role before closing.

## Run order and checkpoints

| Order | File | Prerequisites | Expected observation |
| --- | --- | --- | --- |
| 0 | [00-setup.sql](00-setup.sql) | Authorized account administration for lab role grants. | 3 orders totaling 350; 3 customers. |
| 1 | [01-roles-and-grants.sql](01-roles-and-grants.sql) | Setup. | Analyst inherits reader; database-role access flows through an account role; FUTURE grants do not backfill earlier tables. |
| 2 | [02-masking-row-access-and-tags.sql](02-masking-row-access-and-tags.sql) | **Enterprise+**; lab data and policy ownership. | APAC: 2 masked rows; full-access: 3 original rows; ordinary analyst: 0 rows. |
| 3 | [03-monitoring-and-credit-math.sql](03-monitoring-and-credit-math.sql) | Setup; own-session history visibility. | 3 credits; 0.133333 credits for two short resumes at 4/hour; daily totals 105/100/210/315 for the named scenarios. |
| Optional | [04-optional-admin-templates.sql](04-optional-admin-templates.sql) | Per-block privileges/features. | Commented templates for a lab monitor, unassigned policies, alert, and lineage. |
| Optional | [05-data-lineage.sql](05-data-lineage.sql) | Enterprise+ and lineage visibility; setup. | Two CTAS steps form a movement chain; inspect downstream and upstream lineage after capture. |
| 99 | [99-stop-lab.sql](99-stop-lab.sql) | Lab ownership. | Lab warehouse and optional alert are stopped; unrelated resources are untouched. |

## Read these distinctions before testing roles

1. A higher role inherits lower roles' privileges, not the other way around.
2. Disable secondary roles for a restricted-reader comparison.
3. An administrative role can inherit full-access roles, so it is a poor test of what an APAC reader sees.
4. A masking/row access policy restricts a query after authorization; it does not grant `SELECT`.
5. A tag without an associated policy is metadata, not an access denial.
6. Exercise 02 resets only its synthetic `CUSTOMERS` table using `COPY GRANTS` before attaching policies.

## Optional features and real prerequisites

- **Standard Edition:** run setup, roles, monitoring/math; skip the Enterprise governance file.
- **Network/authentication policies:** templates create definitions only; they are not assigned to an account or administrator.
- **Resource monitor:** the template assigns only `D2_STUDY_WH`, never the entire account.
- **Alert:** the template records into a lab table, starts suspended, and has no real email action.
- **Email:** the note's separate pattern needs a verified account recipient and notification integration. No exercise sends mail.
- **Replication/failover:** needs eligible real source/target accounts; read the note's two-account template.
- **Trust Center, privacy domains, customer-managed keys, and SSO:** need their actual feature/account configuration; there is no fake local substitute.
- **Historical views:** `ACCOUNT_USAGE` may lag or be hidden by privileges. Empty historical results are not a failed arithmetic checkpoint.
- **Lineage lab:** the optional CTAS chain is runnable in the lab; `GET_LINEAGE` needs Enterprise+, `VIEW LINEAGE`, object access, and captured relationships. `VIEW LINEAGE` is granted to `PUBLIC` by default unless your administrator changed it. `OBJECT_DEPENDENCIES` is a narrower object-reference view and can lag.

## Stop and review

1. Run `99-stop-lab.sql` after practice.
2. If you enabled an optional resource monitor, remove its lab assignment using the paired commands in its template.
3. Stop independent notebook/container services separately; they were not created here.
4. Use commented DROP statements only when you want to permanently remove the lab and its role grants.
5. Return to the domain's recall questions and open the answer key only after attempting them.

References: [role hierarchy](https://docs.snowflake.com/en/user-guide/security-access-control-overview), [masking](https://docs.snowflake.com/en/sql-reference/sql/create-masking-policy), [row access](https://docs.snowflake.com/en/user-guide/security-row-using), [resource monitors](https://docs.snowflake.com/en/user-guide/resource-monitors), [compute billing](https://docs.snowflake.com/en/user-guide/cost-understanding-compute).

[Back to Domain 2](../readme.md)
