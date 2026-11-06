# Lab 01 · Share unstructured files across two Snowflake accounts

[Study notes index](../../readme.md) · [Domain 5 notes](../../5-Data-Collaboration/readme.md)

You’ll upload two sample text documents to a stage in your main account, then give `SHARE_LAB` access to **one** of them through a direct share.

1. The **internal stage** holds both files.
2. The **directory table** lists both files and their metadata.
3. A **secure view** filters the inventory to one approved file and returns a **scoped URL** for it.
4. The **direct share** exposes the secure view. The consumer queries the view and opens the scoped URL with the identity that generated it. [Sharing unstructured data with a secure view](https://docs.snowflake.com/en/user-guide/unstructured-data-sharing)

## Before you start

- Use two Snowsight tabs in the **same Snowflake region**. Your main account is the **provider**, and `SHARE_LAB` is the **consumer**.
- The scripts use `ACCOUNTADMIN` for the lab's database, stage, share, and import steps. Choose an existing warehouse that role can use in each account for the directory refresh and queries. Warehouse usage can consume credits.
- Keep `UD_SHARE_STUDY`, `UD_LAB_FILES_SHARE`, and `UD_IMPORTED_FILES` reserved for this lab. These names are separate from the Domain 5 orders lab.

## 1. Provider · Create the stage and upload the files

1. In your main account, run [01-provider-stage.sql](01-provider-stage.sql). Save the **provider locator** from the first query for step 3.
2. In the same account and role, go to **Ingestion → Add Data → Load files into a Stage**. Select [partner-brief.txt](sample-files/partner-brief.txt) and [internal-draft.txt](sample-files/internal-draft.txt) from the local `sample-files` folder.
3. Select **`UD_SHARE_STUDY.LAB.DOCS_STAGE`**. Upload both files to the root of the stage. Keep their exact names. [Upload files in Snowsight](https://docs.snowflake.com/en/user-guide/data-load-local-file-system-stage-ui)

The stage uses **`SNOWFLAKE_SSE`** so its files can be read through URLs. Its directory table is the file inventory. The next script refreshes that inventory after the upload. [Internal stages and file URLs](https://docs.snowflake.com/en/user-guide/unstructured-intro) · [Refreshing a directory table](https://docs.snowflake.com/en/user-guide/data-load-dirtables-manage)

## 2. Provider · Expose only the approved document

1. Open [02-provider-share.sql](02-provider-share.sql) in the provider tab. Replace `MY_ORG.SHARE_LAB` with the consumer’s actual organization and account names. Run the script after selecting your provider warehouse.
2. In the **directory query**, expect both files. In the **secure view query**, expect only `partner-brief.txt`.
3. The final grants give the share access to the database, schema, and secure view. The secure view’s owner has stage access. The consumer gets access through the view.

## 3. Consumer · Import the share and open the file

1. In `SHARE_LAB`, run the first statements in [03-consumer.sql](03-consumer.sql). Confirm `CURRENT_ACCOUNT_NAME()` and check that `UD_LAB_FILES_SHARE` appears as an inbound share.
2. Replace `PROVIDER_LOCATOR` in `CREATE DATABASE … FROM SHARE` with the **main account’s locator** from step 1. Run the import. If you already imported this share, start with the query against its existing database.
3. Select your consumer warehouse. Query the view and click the **`SCOPED_FILE_URL`** in your own Snowsight results. The URL is generated when you query the view. Open it while signed in as the same user. [Import a share](https://docs.snowflake.com/en/user-guide/data-share-consumers) · [Open a scoped URL](https://docs.snowflake.com/en/user-guide/unstructured-intro)
4. Expect one row for **`partner-brief.txt`**. The downloaded file begins with **Partner shipping brief**. The last query checks that the view returns zero rows for `internal-draft.txt`.

## What to remember

- `DIRECTORY(@stage)` returns metadata. The file contents stay on the stage.
- `BUILD_SCOPED_FILE_URL` generates a link tied to the user who queried the secure view. A pre-signed URL is usable by whoever holds it until it expires. This lab uses scoped URLs for the approved consumer. [Snowflake file URL types](https://docs.snowflake.com/en/user-guide/unstructured-intro)
- If the stage has both uploads but the directory query is empty, run `ALTER STAGE UD_SHARE_STUDY.LAB.DOCS_STAGE REFRESH;`. If the directory has both files but the secure view returns zero rows, check `RELATIVE_PATH` against the allowlist in the view.

## Optional cleanup

When you’re done, run each block only in the account indicated. The provider database contains the lab stage and its uploaded sample files.

~~~sql
-- Consumer account
DROP DATABASE IF EXISTS UD_IMPORTED_FILES;
~~~

~~~sql
-- Provider account
DROP SHARE IF EXISTS UD_LAB_FILES_SHARE;
DROP DATABASE IF EXISTS UD_SHARE_STUDY;
~~~

The SQL was reviewed against Snowflake documentation. The two-account workflow still needs to be run in your accounts.
