# Lab 05 · Snowpipe Streaming SDK and replay

- **What this adds:** the course has a Python SDK demo, while our Domain 3 SQL labs explain Snowpipe Streaming without sending live rows through the SDK.
- **Goal:** send a bounded, replayable set of five records through a Named Channel; restart the producer and observe that it resumes after the last committed offset.
- **Cost:** Snowpipe Streaming ingestion uses Snowflake-managed compute. The script sends at most five rows and exits; it does not run forever.
- **Status:** code checked against current Snowflake documentation; it has not been run in your account.

## Before you start

1. Use a Snowflake account and network environment that support the current high-performance Snowpipe Streaming SDK.
2. Install Python 3.9+ and `snowpipe-streaming` in a local environment. The [official SDK tutorial](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-high-performance-getting-started) has the current installation and key-pair setup steps.
3. Prepare a dedicated key-pair-authenticated user and role. The role needs `USAGE` on `D3_STREAMING_LAB` and its `LAB` schema, plus `INSERT` on `EVENTS`. The default pipe does **not** need an `OPERATE` grant. See [streaming access control](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-access-control).
4. Put the SDK connection profile and private key **outside this repository**. Pass the profile path with `--profile`. Never commit or paste their contents. The local `.gitignore` also excludes common profile/key filenames if you accidentally create them here.
5. Run [00-setup.sql](00-setup.sql) with a role allowed to create a database, schema, and table. Grant your producer role access to the new objects before starting Python.

## Run the replay exercise

1. In a terminal, run `python ingest.py --profile /your/private/path/profile.json --max-seq 2`. This sends source offsets **1 and 2**, then exits after Snowflake commits offset 2.
2. Select a small warehouse for the check queries, then run [01-check.sql](01-check.sql). Expect **2 rows**. The default pipe name is `EVENTS-STREAMING`.
3. Run `python ingest.py --profile /your/private/path/profile.json --max-seq 5`. The same channel starts after the committed offset and sends **3, 4, 5**.
4. Run the same command again, then [01-check.sql](01-check.sql). Expect **5 rows and 5 distinct `SEQ` values** (which match the source offsets); the third run should say there is nothing left to send.
5. Run [99-cleanup.sql](99-cleanup.sql) when finished. It drops only the dedicated lab database.

## What to explain afterward

- A **Named Channel** remembers the last offset Snowflake committed. The producer must keep or be able to replay the original source records after a crash. The hard-coded `EVENTS` list plays that role here.
- The stable channel name and source offsets matter; a new random channel name or regenerated business events would not demonstrate correct recovery.
- The SDK uses the system-managed **default pipe** for this table, so no staged file or manually created pipe is needed. A custom named pipe is useful when you need transformations or other supported pipe settings.
- `wait_for_commit` marks the checkpoint. Merely calling `append_row` or flushing a buffer is not proof the rows were committed.
- This small lab demonstrates the mechanism. Production ingestion also needs durable source storage, retry handling, monitoring of channel errors, and appropriate deduplication for business events.

References: [Named Channel tutorial](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-high-performance-getting-started), [offset tokens and recovery](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-channels), [default pipe](https://docs.snowflake.com/en/user-guide/snowpipe-streaming/snowpipe-streaming-pipe-object), [Python SDK API](https://docs.snowflake.com/en/user-guide/snowpipe-streaming-sdk-python/reference/latest/api/snowflake/ingest/streaming/index).

[Back to Domain 3](../../3-Data-Loading-Unloading-and-Connectivity/readme.md)
