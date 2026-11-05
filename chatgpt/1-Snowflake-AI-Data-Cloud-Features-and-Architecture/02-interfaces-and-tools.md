# 1.2 Interfaces and Tools

[Domain 1 index](readme.md)

- **C03 objective:** 1.2. Read the definitions, work through the scenario, then answer recall questions.
- **Practice:** [ordered lab guide](exercises/readme.md); start with its setup.
- **SQL status:** examples reviewed against official documentation; not executed in your account.

<a id="choose-the-interface"></a>

## 1.2.1 Choose the interface

| Tool | Main purpose | Typical task |
| --- | --- | --- |
| Snowsight | Snowflake's browser interface for development, exploration, monitoring, and administration. | Query data, inspect Query Profile, manage warehouses, or review costs. |
| Snowflake CLI | Command-line SQL and management of supported Snowflake workloads. | Run SQL files, script operations, and integrate development workflows. |
| Snowflake VS Code extension | Work with SQL and supported Snowpark development inside an IDE. | Keep SQL in version control and execute it against Snowflake. |

- The interface does not bypass authentication or role privileges.
- Selecting a database or warehouse sets the **session context**.
- Selecting it does not grant access.

<a id="snowsight-worksheets-and-workspaces"></a>

## 1.2.2 Snowsight: worksheets and workspaces

- Use the SQL editor for queries and scripts.
- Use object exploration for databases, schemas, and tables.
- Use **Query History** and **Query Profile** to investigate performance.
- Use administration pages for security and compute.
- Workspaces support a broader project experience.
- Notebook and editor names can differ from older course recordings.

- For an unexpected **“object not found”** or **“no warehouse selected”** error, check:
  1. Role.
  2. Database.
  3. Schema.
  4. Warehouse.
  5. Identifier spelling.
- Check these before changing privileges.

<a id="cli-example"></a>

## 1.2.3 CLI example

```bash
# Uses an existing named connection; does not define credentials.
snow connection test -c learning
snow sql -c learning -q "SELECT CURRENT_VERSION();"
snow sql -c learning -f exercise.sql
```

- The examples above are **shell commands**.
- `SELECT`, `CREATE TABLE`, and `USE WAREHOUSE` are **SQL statements** submitted through the client.
- Keep secrets in supported credential configuration.
- Do not embed passwords in scripts.

- `PUT` transfers local files to **internal stages** through supported clients such as the CLI.
- Typing `PUT` in a browser worksheet is not the same workflow.
- **Related note:** [loading chapter](../../study-notes/7-Data-Loading-and-Unloading/readme.md).

<a id="ide-integrations"></a>

## 1.2.4 IDE integrations

- The official VS Code extension provides:
  - Connections.
  - Object browsing.
  - Query execution and results.
  - Query history.
- Local code still executes against the selected Snowflake account and context.
- For query IDs:
  1. Remember that clients may submit background statements.
  2. Find the intended SQL statement in Query History.
  3. Copy its query ID.
- Do not assume the most recent ID always belongs to your SQL.

<a id="two-distinctions-to-remember-from-practice"></a>

## 1.2.5 Two distinctions to remember from practice

### 1. Snowflake CLI versus SnowSQL

- These are separate command-line clients:

- **Snowflake CLI** uses the `snow` command.
- **SnowSQL** uses the `snowsql` command.

- Run the following directly in your terminal using **Snowflake CLI**.
- You do not first enter a SnowSQL session:

```bash
snow sql -c learning -f exercise.sql
```

- `-c learning` selects an existing named connection.
- `-f exercise.sql` selects the SQL file to execute.
- The command connects and authenticates using the selected connection's configuration.

- **References:** [executing SQL with Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/sql/execute-sql) and [migrating from SnowSQL](https://docs.snowflake.com/en/user-guide/snowsql-migrate).

### 2. Background SQL statements versus Snowflake tasks

- A client such as the Snowflake VS Code extension can submit additional SQL after your query.
- Example: `DESC RESULT` inspects the result.
- These are **background SQL statements submitted by the client**.
- They are not scheduled Snowflake Task objects.

- Background statements also have query IDs.
- `LAST_QUERY_ID()` can therefore refer to a different statement from the one you intended.
- To find the intended ID:
  1. Open **Query History in VS Code or Snowsight**.
  2. Find the matching SQL statement and execution time.

- **Reference:** [VS Code query execution](https://docs.snowflake.com/en/user-guide/vscode-ext#work-with-sql-files).

<a id="practical-workflow-and-exercise-checkpoints"></a>

## 1.2.6 Practical workflow and exercise checkpoints

1. Connect using your chosen client.
2. Inspect the selected role, database, schema, and warehouse.
3. Run one intended SQL statement and inspect its result/error.
4. Find that statement in Query History when you need its exact query ID.
5. Use fully qualified object names when session defaults differ.

```sql
SELECT CURRENT_ROLE(), CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_WAREHOUSE();
SELECT COUNT(*) FROM D1_STUDY.LAB.ORDERS;
```

- **Expected after setup:** the count is **6**, regardless of the editor used, if authorization and compute are suitable.
- A local `.sql` file does not execute merely because it was saved; a connected client must submit its statements.
- A local Python file using a connector runs in that local application's process; Snowpark SQL operations are submitted to Snowflake for execution.
- A client timeout or error is not proof that the server rolled back a statement; inspect status/query history before blindly retrying DML.
- **Shell example:** from this repository root, use an existing named connection:

```bash
snow sql -c learning -f "chatgpt/1-Snowflake-AI-Data-Cloud-Features-and-Architecture/exercises/01-architecture-and-context.sql"
```

- **Practice:** [01-architecture-and-context.sql](exercises/01-architecture-and-context.sql).
- **Remember:** client = where you submit work; active roles and session context determine what that work can access.
- **Exam clue:** browser administration -> Snowsight; repeatable terminal script -> CLI; SQL development beside code -> IDE integration.

## What to recall



1. Which tool suits browser administration, scripted SQL, or local IDE development?
2. Why does the same SQL work in one session and fail in another?
3. What distinguishes a shell command from Snowflake SQL?
4. Which client workflow uploads a local file to an internal stage?
5. Does changing the client from Snowsight to VS Code grant additional table privileges?

<details>
<summary>Open the recall answer key</summary>

1. Snowsight for browser work, Snowflake CLI for scripted terminal operations, and the VS Code extension for IDE work.
2. Different active roles, database/schema context, warehouse, identifier case, or parameters can change behavior.
3. A shell command invokes a client such as snow; SQL is submitted to Snowflake by that client.
4. Use PUT through a supported client to an internal stage, then COPY INTO to load rows.
5. No. The client still needs authentication, role privileges, correct context, and query compute.

</details>

## Official references

- [Connecting tools](https://docs.snowflake.com/en/guides-overview-connecting)
- [Snowsight tour](https://docs.snowflake.com/en/user-guide/ui-snowsight-quick-tour)
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index)
- [VS Code extension](https://docs.snowflake.com/en/user-guide/vscode-ext)
