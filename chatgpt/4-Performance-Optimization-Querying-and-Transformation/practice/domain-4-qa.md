# Domain 4 Practice Q&A

[Domain 4 study note](../readme.md) · [SQL exercises](../exercises/readme.md)

These 25 practice questions cover objectives 4.1 through 4.4. Pick an answer before opening the explanation. Each question has an official Snowflake reference.

| Questions | Topic |
| --- | --- |
| 1–5 | [4.1 Evaluate query performance](#41-evaluate-query-performance) |
| 6–9 | [4.2 Optimize query performance](#42-optimize-query-performance) |
| 10–12 | [4.3 Use Snowflake caching](#43-use-snowflake-caching) |
| 13–21 | [4.4 Perform data transformations](#44-perform-data-transformations) |
| 22–25 | [Mixed review](#mixed-review) |

## 4.1 Evaluate query performance

### Question 1 · Dashboard slowdown during the rush

A dashboard normally loads in 7 seconds on a single-cluster warehouse. At 9 a.m., many analysts open it at once. Execution rises from 6 to 7 seconds, overload queue time rises from 0 to 58 seconds, and remote spill stays at zero. Which change most directly addresses the slowdown?

- **A.** Increase the warehouse size.
- **B.** Configure a multi-cluster warehouse to add clusters during the rush.
- **C.** Enable Query Acceleration Service.
- **D.** Increase the auto-suspend timeout to keep the warehouse cache warm.

<details>
<summary>Correct answer and explanation</summary>

**B. Configure a multi-cluster warehouse.** The query spent 58 seconds waiting for capacity and only 7 seconds executing. Adding clusters lets more queries run concurrently. [Multi-cluster warehouses](https://docs.snowflake.com/en/user-guide/warehouses-multicluster)

</details>

### Question 2 · Exploding join against customer history

A sales report joins 2 million orders to `customer_history` using `customer_id`. The join returns 9 million rows because each customer can have several history records. Each order must count once under the region valid on its order date. Validity periods for each customer do not overlap. Which change fixes the total and reduces the join output?

- **A.** Keep the latest history record for each customer before joining.
- **B.** Apply `DISTINCT` after grouping by region.
- **C.** Join by customer ID and require the order date to fall within the record's validity period.
- **D.** Resize the warehouse.

<details>
<summary>Correct answer and explanation</summary>

**C. Match the customer and the validity period.** The jump from 2 million to 9 million rows shows that orders matched multiple history records. For a customer who moved from APAC to EMEA on July 1, June 30 sales belong to APAC and July 1 sales belong to EMEA. Keeping only the latest record would assign both orders to EMEA. [Query Profile and exploding joins](https://docs.snowflake.com/en/user-guide/ui-snowsight-activity#exploding-joins)

</details>

### Question 3 · Pruning versus join spill

A one-day report scans 57,000 of 60,000 micro-partitions in `events`. Less than 1% of rows pass the date filter. The scan takes 72% of the query time. A join that spills to local storage takes 8%. Where should you focus first?

- **A.** Increase warehouse size to reduce the local spill.
- **B.** Check whether the date predicate and table layout allow effective pruning.
- **C.** Tune the join to build from the smaller input.
- **D.** Add clusters so the query can start sooner.

<details>
<summary>Correct answer and explanation</summary>

**B. Investigate pruning.** The scan dominates runtime and reads 95% of the partitions for a filter that keeps less than 1% of the rows. Inspect the date predicate and how widely each date is spread across partitions. [Query Profile and inefficient pruning](https://docs.snowflake.com/en/user-guide/ui-snowsight-activity#inefficient-pruning)

</details>

### Question 4 · Warehouse totals and individual query costs

Queries overlap on a shared warehouse, which sometimes stays running between jobs. You need yesterday's total warehouse compute credits and the top 10 queries by attributed compute credits. Which sources should you use?

- **A.** Use `QUERY_HISTORY` and estimate credits from each execution time.
- **B.** Use `QUERY_ATTRIBUTION_HISTORY` for both numbers.
- **C.** Use `WAREHOUSE_METERING_HISTORY` for the total and `QUERY_ATTRIBUTION_HISTORY` for the ranking.
- **D.** Use `WAREHOUSE_METERING_HISTORY` for the total and rank queries by bytes scanned.

<details>
<summary>Correct answer and explanation</summary>

**C. Use metering for the total and attribution for the ranking.** `CREDITS_USED_COMPUTE` includes idle warehouse compute. `CREDITS_ATTRIBUTED_COMPUTE` measures compute attributed to individual queries and excludes warehouse idle time. [Warehouse metering history](https://docs.snowflake.com/en/sql-reference/account-usage/warehouse_metering_history) · [Query attribution history](https://docs.snowflake.com/en/sql-reference/account-usage/query_attribution_history)

</details>

### Question 5 · Grouping repeated SQL patterns

An application runs `SELECT order_id, amount FROM orders WHERE customer_id = 101` and repeats it with other customer IDs. Other applications share the warehouse, and queries have no tags. Which `QUERY_HISTORY` column groups these runs as one pattern?

- **A.** `QUERY_HASH`
- **B.** `QUERY_PARAMETERIZED_HASH`
- **C.** `QUERY_ID`
- **D.** `WAREHOUSE_NAME`

<details>
<summary>Correct answer and explanation</summary>

**B. `QUERY_PARAMETERIZED_HASH`.** Snowflake parameterizes supported predicate literals, including the customer ID in this equality predicate. Group by that hash to calculate average execution time for the lookup across customer IDs. [Query hashes](https://docs.snowflake.com/en/user-guide/query-hash)

</details>

## 4.2 Optimize query performance

### Question 6 · Finding one transaction in billions of rows

Support looks up transactions by `transaction_id` and usually has no date. Each lookup returns one row. Finance already gets good performance from the table's date clustering. Which change best targets support while keeping that clustering key?

- **A.** Enable Query Acceleration Service on the support warehouse.
- **B.** Increase the support warehouse size.
- **C.** Create a materialized view that selects the same columns support uses.
- **D.** Enable Search Optimization for equality lookups on `transaction_id`.

<details>
<summary>Correct answer and explanation</summary>

**D. Enable Search Optimization for the ID column.** A point lookup that finds one row in billions is highly selective. The search access path helps Snowflake find the relevant micro-partitions. [Search Optimization Service](https://docs.snowflake.com/en/user-guide/search-optimization-service)

</details>

### Question 7 · Occasional large scans

A reporting warehouse usually runs small queries. A few times a day, a report scans hundreds of millions of rows and aggregates them into a few dozen groups. Reports vary by table and filter. Queue time is nearly zero. Which option would you evaluate while keeping the current warehouse size?

- **A.** Add warehouse clusters.
- **B.** Enable Query Acceleration Service.
- **C.** Enable Search Optimization on the grouping columns.
- **D.** Create a materialized view for the most common report.

<details>
<summary>Correct answer and explanation</summary>

**B. Evaluate Query Acceleration Service.** It can offload eligible parts of large scans and aggregations to additional compute. Look at how many source rows the query processes. A lookup of 20 transaction IDs may benefit from Search Optimization, while a scan that summarizes 200 million records into 20 rows may benefit from QAS. [QAS eligibility](https://docs.snowflake.com/en/user-guide/query-acceleration-service#eligible-queries) · [How QAS and Search Optimization work together](https://docs.snowflake.com/en/user-guide/query-acceleration-service)

</details>

### Question 8 · Reusing daily revenue totals

Dashboards use different date ranges but all calculate daily revenue by region from the same `sales` table. The date filter already prunes well. Most of the remaining time goes into calculating totals. The base table changes a few times a day. Which option stores totals that Snowflake maintains?

- **A.** Refine the clustering key on sale date.
- **B.** Enable Query Acceleration Service.
- **C.** Create a materialized view with `SUM(amount)` grouped by day and region.
- **D.** Rely on persisted query results across different date ranges.

<details>
<summary>Correct answer and explanation</summary>

**C. Create a materialized view.** The view stores the daily totals by region, and Snowflake maintains them as the base table changes. Each dashboard can read the totals for its date range instead of summing individual sales again. [Materialized views](https://docs.snowflake.com/en/user-guide/views-materialized)

</details>

### Question 9 · Choosing a clustering key

A 20 TB `events` table gets frequent queries for one to seven days of `event_ts`. Batches include late arrivals from many event dates. Query Profile shows poor pruning. Which clustering key is the best starting point?

- **A.** `TO_DATE(ingested_at)`
- **B.** `TO_DATE(event_ts)`
- **C.** `event_ts` at full precision
- **D.** The unique `event_id`

<details>
<summary>Correct answer and explanation</summary>

**B. `TO_DATE(event_ts)`.** The reports filter by when events happened. The date expression groups events at the granularity those filters use and has fewer distinct values than the nearly unique full timestamp. [Strategies for choosing clustering keys](https://docs.snowflake.com/en/user-guide/tables-clustering-keys#strategies-for-selecting-clustering-keys)

</details>

## 4.3 Use Snowflake caching

### Question 10 · Reusing a result after warehouse suspension

An analyst calculates revenue by region on `BI_WH_A`. It suspends. Fifteen minutes later, the analyst uses `BI_WH_B` to run the same SQL with the same role. The data is unchanged, and `USE_CACHED_RESULT` is enabled. Which mechanism could return the original totals without scanning the sales table?

- **A.** The persisted query result cache.
- **B.** The local cache from `BI_WH_A`, shared with `BI_WH_B`.
- **C.** Micro-partition metadata.
- **D.** Query Acceleration Service.

<details>
<summary>Correct answer and explanation</summary>

**A. The persisted query result cache.** The saved result can be reused across warehouses when the conditions are met. Suspending `BI_WH_A` clears its local cache, while the saved result is stored separately. [Persisted query results](https://docs.snowflake.com/en/user-guide/querying-persisted-results) · [Warehouse cache](https://docs.snowflake.com/en/user-guide/performance-query-warehouse-cache)

</details>

### Question 11 · A warm warehouse with result reuse disabled

An analyst sets `USE_CACHED_RESULT = FALSE` and runs a report for June, followed by a different report for June 15–30 on the same running warehouse. The second query has a `TableScan`, and 92% of its scanned data came from cache. What does that mean?

- **A.** Snowflake reused the first report's final result.
- **B.** Snowflake pruned 92% of the micro-partitions.
- **C.** The warehouse reused table data it had read during the first report.
- **D.** The first run had already saved the second report's result.

<details>
<summary>Correct answer and explanation</summary>

**C. The warehouse reused locally cached table data.** `USE_CACHED_RESULT = FALSE` disables reuse of final results for the session. The warehouse can still scan cached data and calculate a new result. [Persisted query results](https://docs.snowflake.com/en/user-guide/querying-persisted-results) · [Warehouse cache](https://docs.snowflake.com/en/user-guide/performance-query-warehouse-cache)

</details>

### Question 12 · Pruning on a newly started warehouse

With `USE_CACHED_RESULT = FALSE`, a newly started warehouse runs a one-day sales report. Query Profile shows 0% scanned from the warehouse cache, yet Snowflake scans just 20 of 20,000 micro-partitions. How did Snowflake skip the others?

- **A.** It read all partitions and filtered rows afterward.
- **B.** It used micro-partition metadata, such as minimum and maximum dates.
- **C.** It inherited another warehouse's local cache.
- **D.** It reused part of yesterday's final result.

<details>
<summary>Correct answer and explanation</summary>

**B. Snowflake pruned with micro-partition metadata.** The cache percentage describes where the scanned data came from. The partition counts show how much of the table Snowflake skipped before reading rows. [Micro-partition pruning](https://docs.snowflake.com/en/user-guide/tables-clustering-micropartitions#query-pruning)

</details>

## 4.4 Perform data transformations

### Question 13 · Picking one update when timestamps tie

You need exactly one latest update per order. When two updates have the same `updated_at`, the higher `load_id` wins. Which clause should follow `FROM order_updates`?

- **A.** `QUALIFY RANK() OVER (PARTITION BY order_id ORDER BY updated_at DESC) = 1`
- **B.** `QUALIFY ROW_NUMBER() OVER (ORDER BY updated_at DESC, load_id DESC) = 1`
- **C.** `QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC) = 1 ORDER BY load_id DESC`
- **D.** `QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY updated_at DESC, load_id DESC) = 1`

<details>
<summary>Correct answer and explanation</summary>

**D. Use `ROW_NUMBER()` with both sort keys inside the window.** Partition by order to pick one row per order. The window's `ORDER BY` determines the winner. A final `ORDER BY` sorts the rows that survived `QUALIFY`. [Snowflake `QUALIFY`](https://docs.snowflake.com/en/sql-reference/constructs/qualify)

</details>

### Question 14 · Completed spend while keeping order-level rows

A report must show one row per completed order and each customer's total completed spend. Keep customers with at least $1,000 in completed spend. The input includes cancelled orders. Which approach meets all the requirements?

- **A.** Use `WHERE` for order status, a windowed `SUM` by customer, and `QUALIFY` for the spend threshold.
- **B.** Use `WHERE` for order status, `GROUP BY customer_id`, and `HAVING` for the spend threshold.
- **C.** Window-sum every order, then use `QUALIFY` for both status and spend.
- **D.** Group by customer and order, then apply the spend threshold with `HAVING`.

<details>
<summary>Correct answer and explanation</summary>

**A. Filter completed orders before the window sum.** The window keeps one row per completed order. `QUALIFY` then filters on the completed total. Filtering status only in `QUALIFY` would let cancelled amounts enter the sum. [Snowflake `QUALIFY` execution order](https://docs.snowflake.com/en/sql-reference/constructs/qualify)

```sql
WITH sample_orders (order_id, customer_id, status, amount) AS (
    SELECT * FROM VALUES
        (1, 101, 'COMPLETED', 650),
        (2, 101, 'COMPLETED', 400),
        (3, 101, 'CANCELLED', 200)
)
SELECT
    order_id,
    customer_id,
    amount,
    SUM(amount) OVER (PARTITION BY customer_id) AS completed_total
FROM sample_orders
WHERE status = 'COMPLETED'
QUALIFY completed_total >= 1000
ORDER BY order_id;
```

The query returns orders 1 and 2. Both show a completed total of `1050`.

</details>

### Question 15 · Counting items in empty arrays

Order 101 has `{"items": ["pen", "book"]}` in its `VARIANT` payload, and order 102 has `{"items": []}`. You use `LATERAL FLATTEN` on `payload:items` with alias `f` and group by order ID. Which combination keeps both orders and reports counts of 2 and 0?

- **A.** `OUTER => FALSE` with `COUNT(f.index)`
- **B.** `OUTER => TRUE` with `COUNT(*)`
- **C.** `OUTER => TRUE` with `COUNT(f.index)`
- **D.** `OUTER => FALSE` with `COUNT(*)`

<details>
<summary>Correct answer and explanation</summary>

**C. Keep empty arrays with `OUTER => TRUE` and count the indexes.** The empty array produces one placeholder row with a `NULL` index. `COUNT(f.index)` skips it and returns 0. `COUNT(*)` counts the placeholder and returns 1. [Snowflake `FLATTEN`](https://docs.snowflake.com/en/sql-reference/functions/flatten) · [Snowflake `COUNT`](https://docs.snowflake.com/en/sql-reference/functions/count)

</details>

### Question 16 · Converting JSON values to decimals

A `VARIANT` payload contains `{"invoice": {"Total": "19.95"}}` or `{"invoice": {"Total": "pending"}}`. Which expression keeps both rows and returns `19.95` and SQL `NULL` in a `NUMBER(12,2)` column?

- **A.** `payload:invoice.Total::NUMBER(12,2)`
- **B.** `TRY_TO_DECIMAL(payload:invoice.Total::STRING, 12, 2)`
- **C.** `TRY_TO_DECIMAL(payload:invoice.total::STRING, 12, 2)`
- **D.** `TRY_TO_DECIMAL(payload:invoice.Total::STRING, 12, 0)`

<details>
<summary>Correct answer and explanation</summary>

**B. Match the JSON key and use `TRY_TO_DECIMAL`.** JSON keys are case-sensitive, so the path uses `Total`. The scale of 2 preserves cents. The direct cast raises an error on `pending`, while the `TRY_` function returns SQL `NULL`. [Querying semi-structured data](https://docs.snowflake.com/en/user-guide/querying-semistructured) · [Snowflake `TRY_TO_DECIMAL`](https://docs.snowflake.com/en/sql-reference/functions/try_to_decimal)

</details>

### Question 17 · Temporary links tied to a Snowflake user

Analysts can query a secure view listing their approved PDFs. Their role has `SELECT` on the view and no direct stage privileges. The view owner has the required stage privilege. Which temporary link can each analyst generate and open using their own Snowflake identity?

- **A.** A pre-signed URL from `GET_PRESIGNED_URL`.
- **B.** A permanent file URL from `BUILD_STAGE_FILE_URL`.
- **C.** The file's relative path from the directory table.
- **D.** A scoped URL from `BUILD_SCOPED_FILE_URL`.

<details>
<summary>Correct answer and explanation</summary>

**D. Return a scoped URL.** Only the Snowflake user who generates a scoped URL can use it. Anyone holding a valid pre-signed URL can open the referenced file until the link expires. [File URL types](https://docs.snowflake.com/en/user-guide/unstructured-intro) · [Snowflake `BUILD_SCOPED_FILE_URL`](https://docs.snowflake.com/en/sql-reference/functions/build_scoped_file_url)

</details>

### Question 18 · Extracting text from staged PDFs

A SQL report needs one row per PDF in `@LEGAL_DOCS`, including its path and extracted text. The stage has a directory table. Pick three operations and put them in order.

- **A.** `AI_PARSE_DOCUMENT`
- **B.** `BUILD_SCOPED_FILE_URL`
- **C.** `DIRECTORY(@LEGAL_DOCS)`
- **D.** `TO_FILE`

<details>
<summary>Correct answer and explanation</summary>

**C → D → A.**

1. `DIRECTORY(@LEGAL_DOCS)` lists files and gives you the relative paths.
2. `TO_FILE` uses the stage and path to produce a `FILE` object. [Working with staged files](https://docs.snowflake.com/en/user-guide/unstructured-intro)
3. `AI_PARSE_DOCUMENT` takes that object and extracts document content. [Snowflake `AI_PARSE_DOCUMENT`](https://docs.snowflake.com/en/sql-reference/functions/ai_parse_document)

</details>

### Question 19 · A running sum with tied timestamps

One account has these transactions.

| Transaction ID | Event time | Amount |
| --- | --- | --- |
| 1 | 10:00 | 20 |
| 2 | 10:00 | 30 |
| 3 | 10:01 | 10 |

```sql
SUM(amount) OVER (
    PARTITION BY account_id
    ORDER BY event_time
    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

What totals appear in transaction ID order?

- **A.** `20, 50, 60`
- **B.** `50, 50, 60`
- **C.** `60, 60, 60`
- **D.** `20, 30, 10`

<details>
<summary>Correct answer and explanation</summary>

**B. `50, 50, 60`.** With this `RANGE` frame, both 10:00 rows share the same boundary, so each includes both amounts. For a per-transaction running sum, use a `ROWS` frame and put a tie-breaker such as `transaction_id` in the window's `ORDER BY`. [Snowflake window frames](https://docs.snowflake.com/en/user-guide/functions-window-using)

</details>

### Question 20 · Combining customer totals from two channels

A retailer needs one row per customer with total spend across online and in-store purchases. Every purchase should count. The team wants to reduce how many rows reach the combine step. Which approach meets both goals?

- **A.** Combine raw purchases with `UNION ALL`, then sum by customer.
- **B.** Sum by customer in each channel, combine subtotals with `UNION`, then sum again.
- **C.** Sum by customer in each channel, combine subtotals with `UNION ALL`, then sum again.
- **D.** Deduplicate `(customer_id, amount)` pairs within each channel, then combine and sum.

<details>
<summary>Correct answer and explanation</summary>

**C. Aggregate first, combine with `UNION ALL`, and sum the subtotals.** Pre-aggregating reduces the number of rows passed to the combine step. If a customer spends $80 in each channel, `UNION ALL` keeps both subtotals and the final sum is $160. `UNION` collapses the identical rows and would report $80. [Snowflake set operators](https://docs.snowflake.com/en/sql-reference/operators-query)

</details>

### Question 21 · Reconstructing an average from daily summaries

You need the same result as `AVG(amount)` over the individual orders, using only the summary below.

| Day | `SUM(amount)` | `COUNT(amount)` | `COUNT(*)` |
| --- | --- | --- | --- |
| Monday | 400 | 4 | 6 |
| Tuesday | 900 | 3 | 3 |

- **A.** `(400 / 4 + 900 / 3) / 2`
- **B.** `(400 + 900) / (6 + 3)`
- **C.** `(400 + 900) / (4 + 3)`
- **D.** `(400 + 900) / 2`

<details>
<summary>Correct answer and explanation</summary>

**C. Divide the total amount by the total count of non-`NULL` amounts.** That gives about $185.71. Averaging the daily averages gives equal weight to each day. `AVG(amount)` gives equal weight to each non-`NULL` amount. If Wednesday adds `200, NULL, NULL`, add 200 to the numerator and 1 to the denominator. [Snowflake `AVG`](https://docs.snowflake.com/en/sql-reference/functions/avg) · [Snowflake `COUNT`](https://docs.snowflake.com/en/sql-reference/functions/count)

</details>

## Mixed review

### Question 22 · Heavy remote spill

A nightly query starts immediately and runs for 12 minutes. Its largest join produces the expected number of rows but spends most of its time spilling 45 GB to remote storage. The table scans already prune well. Which change would you test first, and what would you measure?

- **A.** Add clusters.
- **B.** Increase the warehouse size.
- **C.** Add a clustering key to the source tables.
- **D.** Extend the auto-suspend timeout.

<details>
<summary>Correct answer and explanation</summary>

**B. Test a larger warehouse.** A larger warehouse gives the operation more memory. Compare remote spill bytes and query execution time. Set `USE_CACHED_RESULT = FALSE` during the comparison so both tests execute the query. [Query Profile and memory spill](https://docs.snowflake.com/en/user-guide/ui-snowsight-activity)

</details>

### Question 23 · Same query pattern, different result

An analyst runs these queries in order on the same running warehouse. Only the first has run before.

```sql
SELECT SUM(amount) FROM orders WHERE customer_id = 101;
SELECT SUM(amount) FROM orders WHERE customer_id = 202;
```

The queries have the same `QUERY_PARAMETERIZED_HASH`. The second query has a `TableScan` that reads 85% of its scanned data from the warehouse cache. Which **two** statements are accurate?

- **A.** The matching hash groups the queries as one pattern for performance analysis.
- **B.** The matching hash lets the second query reuse the first customer's total.
- **C.** The second query can calculate its own total using cached data from overlapping micro-partitions.
- **D.** Changing the customer ID clears the warehouse cache.

<details>
<summary>Correct answer and explanation</summary>

**A and C.** The hash groups SQL patterns for analysis. Rows for customers 101 and 202 can live in the same micro-partitions. The second query can read cached table data, filter for customer 202, and compute that customer's own total. A persisted result contains the final answer for a particular query and can be reused when Snowflake's conditions are met. [Query hashes](https://docs.snowflake.com/en/user-guide/query-hash) · [Warehouse cache](https://docs.snowflake.com/en/user-guide/performance-query-warehouse-cache) · [Persisted query results](https://docs.snowflake.com/en/user-guide/querying-persisted-results)

</details>

### Question 24 · Keeping customers with zero July orders

Start with `customers` and `LEFT JOIN` to `orders` on `customer_id`. The report must include every customer and show how many orders they placed in July, including zero. Assume `o.order_id` is populated for every real order. Where should the July filter go, and what should you count?

- **A.** Filter in `WHERE` and use `COUNT(*)`.
- **B.** Filter in `WHERE` and use `COUNT(o.order_id)`.
- **C.** Filter in `ON` and use `COUNT(*)`.
- **D.** Filter in `ON` and use `COUNT(o.order_id)`.

<details>
<summary>Correct answer and explanation</summary>

**D. Put the date filter in `ON` and count the order ID.** The join can match only July orders. A customer with no July match still gets a row with `o.order_id = NULL`, so their count is zero. Filtering in `WHERE` removes that row, and `COUNT(*)` would count the placeholder. [Snowflake joins](https://docs.snowflake.com/en/user-guide/querying-joins) · [Snowflake `COUNT`](https://docs.snowflake.com/en/sql-reference/functions/count)

</details>

### Question 25 · Result reuse after a data change

At 9:00, a query returns $10,000 in July sales. A committed update at 9:05 changes the total to $10,200. The analyst runs the exact same SQL at 9:06 and 9:07 with the same role and `USE_CACHED_RESULT = TRUE`. Nothing changes between those two runs. What can happen?

- **A.** Both later runs can reuse the saved $10,000 result.
- **B.** Both later runs must recalculate because the table changed at 9:05.
- **C.** The 9:06 run returns $10,200, and the 9:07 run may reuse that new result.
- **D.** The warehouse must suspend and resume before the query returns $10,200.

<details>
<summary>Correct answer and explanation</summary>

**C. The 9:07 run may reuse the result from 9:06.** The 9:05 update changed data contributing to the original total, so the 9:00 result is ineligible. The 9:06 run returns the updated total, which can be reused at 9:07 if Snowflake's reuse conditions are met. [Persisted query results](https://docs.snowflake.com/en/user-guide/querying-persisted-results)

</details>
