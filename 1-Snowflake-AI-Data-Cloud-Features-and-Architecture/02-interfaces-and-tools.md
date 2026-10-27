# 1.2 Interfaces and Tools

[Domain 1 index](readme.md)

## Choose the interface

| Tool | Main purpose | Typical task |
| --- | --- | --- |
| Snowsight | Snowflake's browser interface for development, exploration, monitoring, and administration. | Query data, inspect Query Profile, manage warehouses, or review costs. |
| Snowflake CLI | Command-line SQL and management of supported Snowflake workloads. | Run SQL files, script operations, and integrate development workflows. |
| Snowflake VS Code extension | Work with SQL and supported Snowpark development inside an IDE. | Keep SQL in version control and execute it against Snowflake. |

The interface does not bypass authentication or role privileges. Selecting a database or warehouse in a tool sets session context; it does not grant access.

## Snowsight: worksheets and workspaces

Use SQL editing surfaces for queries and scripts, object exploration for databases/schemas/tables, Query History and Query Profile for performance, and administration pages for security and compute. Workspaces support a broader project experience; notebook and editor naming can differ from older course recordings.

For an unexpected “object not found” or “no warehouse selected” error, inspect the role, database, schema, warehouse, and identifier spelling before changing privileges.

## CLI example

```bash
# Uses an existing named connection; does not define credentials.
snow connection test -c learning
snow sql -c learning -q "SELECT CURRENT_VERSION();"
snow sql -c learning -f exercise.sql
```

These are shell commands. `SELECT`, `CREATE TABLE`, and `USE WAREHOUSE` are SQL statements submitted through the client. Keep secrets in supported credential configuration, rather than embedding passwords in scripts.

For local files, `PUT` transfers files to internal stages through supported clients such as the CLI; typing `PUT` in a browser worksheet is not the same workflow. See the [loading chapter](../7-Data-Loading-and-Unloading/readme.md).

## IDE integrations

The official VS Code extension provides connections, object browsing, query execution, results, and query history. Local code still executes against the selected Snowflake account and context. Be careful with query-ID workflows: clients may issue background statements, so copy the intended query ID from history instead of assuming the most recent ID always belongs to your SQL.

## What to recall

1. Which tool suits browser administration, scripted SQL, or local IDE development?
2. Why does the same SQL work in one session and fail in another?
3. What distinguishes a shell command from Snowflake SQL?
4. Which client workflow uploads a local file to an internal stage?

## Official references

- [Connecting tools](https://docs.snowflake.com/en/guides-overview-connecting)
- [Snowsight tour](https://docs.snowflake.com/en/user-guide/ui-snowsight-quick-tour)
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index)
- [VS Code extension](https://docs.snowflake.com/en/user-guide/vscode-ext)

## Two distinctions to remember from practice

### 1. Snowflake CLI versus SnowSQL

These are separate command-line clients:

- **Snowflake CLI** uses the `snow` command.
- **SnowSQL** uses the `snowsql` command.

Run the following directly in your terminal using Snowflake CLI; you do not first enter a SnowSQL session:

```bash
snow sql -c learning -f exercise.sql
```

Here, `-c learning` selects an existing named connection, and `-f exercise.sql` selects the SQL file to execute. The command connects and authenticates using the selected connection's configuration.

See [executing SQL with Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/sql/execute-sql) and [migrating from SnowSQL](https://docs.snowflake.com/en/user-guide/snowsql-migrate).

### 2. Background SQL statements versus Snowflake tasks

A client such as the Snowflake VS Code extension can submit additional SQL statements after your query, for example `DESC RESULT` to inspect the result. These are **background SQL statements submitted by the client**, not scheduled Snowflake task objects.

Because those statements also have query IDs, `LAST_QUERY_ID()` can refer to a different statement from the one you intended to inspect. To find the intended ID, open **Query History in VS Code or Snowsight** and locate the matching SQL statement and execution time.

See [VS Code query execution](https://docs.snowflake.com/en/user-guide/vscode-ext#work-with-sql-files).
