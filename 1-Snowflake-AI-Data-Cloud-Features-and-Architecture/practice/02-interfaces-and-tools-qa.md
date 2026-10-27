# 1.2 Practice: Interfaces and Tools

[Practice index](readme.md) | [Study note](../02-interfaces-and-tools.md)

This records our six multiple-choice questions and four follow-up questions. You revised question 2 from A to B before feedback. The main corrections were distinguishing Snowflake CLI from SnowSQL and understanding background SQL statements in VS Code.

## Question 1: Running a SQL file without a browser

A developer keeps a SQL file in Git and wants to run it from a terminal or deployment script without opening a browser. Which tool fits?

A. Snowsight  
B. Query Profile  
C. Snowflake CLI  
D. Snowsight Object Explorer

<details>
<summary>Your answer and explanation</summary>

**Your answer:** "C. snowflake SQL file. Because the requirement is don't want to open the browser tab and Snowflake CLI can execute the query file by running in terminal"

**Correct choice: C.** The tool is **Snowflake CLI**; the SQL file is its input.

```bash
snow sql -c learning -f deployment.sql
```

This uses the configured `learning` connection to execute the file. The connection and authentication must already be configured appropriately.

[Reference: Execute SQL with Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/sql/execute-sql)

</details>

## Question 2: Working in a browser

A user wants to run SQL, inspect Query Profile, and review warehouse activity through a browser. Which interface fits?

A. Snowflake CLI  
B. Snowsight  
C. A named internal stage  
D. A Snowpark DataFrame

<details>
<summary>Your answer and explanation</summary>

**Your answers:** A, then **B before feedback**. Your revised answer was correct.

Snowsight is Snowflake's browser interface. Snowflake CLI is a command-line interface.

[Reference: Snowsight](https://docs.snowflake.com/en/user-guide/ui-snowsight-quick-tour)

</details>

## Question 3: SQL development inside VS Code

A developer wants to edit version-controlled SQL files and run them without leaving VS Code. Which choice fits?

A. The official Snowflake extension for VS Code  
B. Snowsight in a separate browser  
C. A file format  
D. A larger warehouse

<details>
<summary>Your answer and explanation</summary>

**Your answer:** A. **Correct.**

The extension integrates Snowflake connections and SQL execution into the editor. Warehouse size changes compute capacity, not the development interface.

[Reference: Snowflake extension for VS Code](https://docs.snowflake.com/en/user-guide/vscode-ext#work-with-sql-files)

</details>

## Question 4: A query works in one interface but not another

A query works in Snowsight but reports an object-not-found or authorization error in VS Code. What should you check first?

A. Upgrade the account edition  
B. Increase warehouse size  
C. Compare account, active role, database, and schema  
D. Copy the table to the laptop

<details>
<summary>Your answer and explanation</summary>

**Your answer:** C. **Correct.**

Different sessions can use different connections, roles, or namespaces. Check those before assuming the object is missing. Also check warehouse context and access when the operation requires warehouse compute.

```sql
SELECT CURRENT_ACCOUNT(), CURRENT_ROLE(), CURRENT_DATABASE(),
       CURRENT_SCHEMA(), CURRENT_WAREHOUSE();
```

[Reference: Session commands and context](https://docs.snowflake.com/en/sql-reference/ddl-session)

</details>

## Question 5: Selecting a database versus receiving access

A role has no privileges on the tables in `ANALYTICS`. Does selecting that database in the interface grant table access?

A. Yes, to every table  
B. No; it sets context, but privileges are still required  
C. Yes, but only in VS Code  
D. No, because only ACCOUNTADMIN can query tables

<details>
<summary>Your answer and explanation</summary>

**Your answer:** B. **Correct.**

Choosing a database or issuing `USE DATABASE` does not grant privileges. The active authorization context still needs the appropriate access, including privileges on the relevant containers and objects.

[Reference: Access control overview](https://docs.snowflake.com/en/user-guide/security-access-control-overview)

</details>

## Question 6: Uploading a local CSV

A developer wants to upload a CSV from their laptop into an internal stage using `PUT`. Which approach fits?

A. Run `PUT` in a Snowsight SQL worksheet  
B. Use a supported client, such as Snowflake CLI  
C. Run `COPY INTO` directly against the laptop's local path  
D. Treat the local folder as a schema

<details>
<summary>Your answer and explanation</summary>

**Your answer:** B. **Correct.**

`PUT` uploads local files to an internal stage through a supported client. A subsequent `COPY INTO` loads the staged file into a table. A browser upload feature is different from executing `PUT` in a SQL worksheet.

```bash
# Illustrative local path; requires the stage and a configured connection.
snow sql -c learning -q "PUT file:///tmp/orders.csv @orders_stage"
```

[Reference: PUT](https://docs.snowflake.com/en/sql-reference/sql/put)

</details>

## Question 7: Terminal command versus SQL statement

Where would you run each of these?

```bash
snow sql -c learning -f exercise.sql
```

```sql
SELECT * FROM analytics.mart.orders;
```

<details>
<summary>Your answer and correction</summary>

**Your answer:** "The first one is bash command that must be run in terminal after connected to snowsql CLI session. The second one is sql statement and can be run in snowsight."

**Partly correct.** The first is a terminal command, but it belongs to **Snowflake CLI** (`snow`), not an interactive **SnowSQL** (`snowsql`) session. You run it directly in your shell; you do not first enter SnowSQL. `-c` selects a configured connection and `-f` selects a SQL file.

The second is SQL. It can run in Snowsight, through the VS Code extension, or through a supported command-line client. It is not limited to Snowsight.

[Reference: Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index) · [SnowSQL migration](https://docs.snowflake.com/en/user-guide/snowsql-migrate)

</details>

## Question 8: Recall the checks for different query results

If SQL works in Snowsight but fails in VS Code, what session settings should you compare?

<details>
<summary>Your answer and explanation</summary>

**Your answer:** "I think the active role, the database and schmea need to be checked first."

**Correct.** Also verify that both sessions connect to the same intended account. Check the warehouse when required. The same short table name can resolve differently under a different database or schema.

[Reference: Session commands](https://docs.snowflake.com/en/sql-reference/ddl-session)

</details>

## Question 9: Does a different client grant more permissions?

Does switching from Snowsight to Snowflake CLI give you additional table permissions?

<details>
<summary>Your answer and explanation</summary>

**Your answer:** "No. I don't think it give us additional table permission. Because we are trying to access the same sets of objects that is available in given role and account permission."

**Correct.** Switching clients does not itself grant privileges. Apparent differences can come from different accounts, users, active roles, or session configuration.

[Reference: Access control overview](https://docs.snowflake.com/en/user-guide/security-access-control-overview)

</details>

## Question 10: An unexpected LAST_QUERY_ID()

Why might `LAST_QUERY_ID()` in the VS Code extension identify a different statement than the one you intended? How can you locate the intended query?

<details>
<summary>Your answer and correction</summary>

**Your answer:** "Because snowflake creates background task for that query so that's give unexpected query ID. In order to get the exact query ID, should find in snowsight."

**Partly correct.** Looking in Query History is useful. The correction is that the **extension can issue additional background SQL statements**, such as result-description statements. This is not Snowflake creating a scheduled Task object for your query.

Find the intended statement in Query History, using its SQL text and execution time, and use that statement's query ID. You can inspect history through the extension or Snowsight. Do not assume that the last statement in a session must be your last manually submitted query.

[Reference: Working with SQL in VS Code](https://docs.snowflake.com/en/user-guide/vscode-ext#work-with-sql-files)

</details>

## Review targets

1. Say which commands belong in a terminal and which are SQL.
2. Distinguish Snowflake CLI (`snow`) from SnowSQL (`snowsql`).
3. Compare account, role, database, schema, and warehouse before troubleshooting across clients.
4. Explain why background SQL statements can affect `LAST_QUERY_ID()` without calling them scheduled tasks.
