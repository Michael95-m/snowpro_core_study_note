# Lab 04 · Test data quality with DMFs

[Additional exercises](../../readme.md#additional-exercises) · [Domain 2 notes](../../2-Account-Management-and-Data-Governance/readme.md)

Use a small customer table to practise **Data Metric Functions (DMFs)**. First predict the measurements, then run the SQL, repair the data, and measure again. Keep the [solutions](solutions.md) closed until you finish.

## Before you start

- Use an **Enterprise Edition** Snowflake account and a role that can create a database and table. The setup uses `SYSADMIN`; change the role if your account uses a different lab role.
- The setup uses your existing `COMPUTE_WH`. If your warehouse has another name, change that line in the setup file.
- The main test calls DMFs directly. It creates **no recurring DMF schedule**. Your warehouse still consumes credits while running.
- The optional attachment test can incur data quality monitoring credits. Run its cleanup in the same sitting.
- Run the setup once. Rerunning it replaces only the lab table and resets its six rows.

## Run in order

1. Run [00-setup.sql](00-setup.sql) in a Snowflake worksheet. Confirm six rows appear.
2. Read [01-challenges.sql](01-challenges.sql). Answer each prediction before running your query. Tasks 1–5 use direct DMF calls and a data repair.
3. If you want to try an attached DMF with a pass/fail expectation, follow [02-optional-attachment.sql](02-optional-attachment.sql). This is separate because attached DMFs can run on a schedule.
4. Check your work with [solutions.md](solutions.md).
5. Run [99-cleanup.sql](99-cleanup.sql) when finished. It removes only the `D2_DMF_LAB` database. Let your existing warehouse auto-suspend according to its own setting.

## What you should understand afterward

- A DMF returns a **measurement**. An expectation decides whether that value **passes**.
- Direct calls are useful for one-time checks. An attached DMF can monitor an object on a schedule.
- `DUPLICATE_COUNT` counts values that belong to duplicate groups, not the number of extra rows you would delete.
- Some DMFs, such as `ROW_COUNT`, can only be attached and cannot be called directly.

References: [DMF overview](https://docs.snowflake.com/en/user-guide/data-quality-intro), [NULL_COUNT](https://docs.snowflake.com/en/sql-reference/functions/dmf_null_count), [DUPLICATE_COUNT](https://docs.snowflake.com/en/sql-reference/functions/dmf_duplicate_count), [expectations](https://docs.snowflake.com/en/user-guide/data-quality-expectations).

The SQL was checked against Snowflake's documentation. I could not execute it in your account; send me the exact error if a statement fails.
