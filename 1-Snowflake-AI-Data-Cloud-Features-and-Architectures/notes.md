# Snowflake AI Data Cloud Features and Architectures

## What is snowflake?

- Traditionally data warehouse; now cloud AI platform.

 ![what is snowflake?](../img/what_is_snowflake.png)



## Table Types


| Table Types | Time Travel | Fail-Safe | Usage | Existence |
|-----| -----| -----| -----| -----|
| Permanent | 90 days | yes | Default table type | Until we drop |
| Temporary | 1 day | no | Used for transitory data | Persist for duration of the session | 
| Transient | 1 day | no | - | Exists until explicity drop |
| External | no | no | Query data outside of snowflake (eg. S3) & read-only | - |

## View Types

**Standard** 

- Does not cost storage cost.
- Used to restrict the content of the table.

**Materialized Views**

- Stores the result of the query and periodically refresh it.
- Incurs the cost as serverless features.

Both views can be secured by adding `secure` keyword in the definition.

## Worksheets and Workspaces