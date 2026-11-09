# 1.4 Virtual Warehouses: Practice Questions and Answers

These 15 questions were recovered from our completed chat practice round. Answer each question before opening its answer. The explanations and official Snowflake links are lightly edited from the original feedback. These are practice questions, not official exam questions.

## Question 1

A company uses Enterprise Edition. Its BI queries run quickly individually, but during busy mornings, many users submit queries simultaneously and queries start queuing.

They want capacity to increase during peak demand and decrease afterward. Which approach best fits?

A. Increase the warehouse’s auto-suspend timeout.  
B. Configure a multi-cluster warehouse in auto-scale mode.  
C. Create a separate database for each user.  
D. Increase Time Travel retention.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct. **B — scale out for concurrency.**

The key clues are that individual queries are fast, but simultaneous queries cause queues. Auto-scale adds clusters as demand increases, up to the configured maximum, and removes extra clusters as demand falls.

[Reference: Multi-cluster warehouses](https://docs.snowflake.com/en/user-guide/warehouses-multicluster)

</details>

## Question 2

A single complex query runs slowly even when nobody else uses the warehouse. Query Profile shows substantial spilling to remote storage because intermediate results exceed available memory.

Assuming the SQL is already reasonably optimized, which change is most appropriate?

A. Increase the maximum cluster count from 1 to 3.  
B. Change the scaling policy to Economy.  
C. Increase the warehouse size.  
D. Increase the auto-suspend timeout.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct. **C — increase the warehouse size.**

A larger warehouse provides more memory, which can reduce spilling and improve this query’s performance. Adding clusters mainly helps concurrent queries; it does not combine their memory for one query. Changing the scaling policy or auto-suspend timeout does not solve this memory bottleneck.

[Reference: Resolving memory spillage](https://docs.snowflake.com/en/user-guide/performance-query-warehouse-memory)

</details>

## Question 3

A reporting warehouse uses:

```sql
MIN_CLUSTER_COUNT = 1
MAX_CLUSTER_COUNT = 4
SCALING_POLICY = 'ECONOMY'
```

Users complain about waiting during demand spikes. The company prioritizes responsiveness over minimizing credits.

Which change best fits?

A. Change the scaling policy to `STANDARD`.  
B. Set `MAX_CLUSTER_COUNT = 1`.  
C. Disable auto-resume.  
D. Increase Time Travel retention.

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

Correct. **A — use `STANDARD`.**

Standard favors starting additional clusters more readily to reduce queuing. Economy favors keeping existing clusters busy to save credits, accepting more waiting. Standard still respects `MAX_CLUSTER_COUNT = 4`; it does not guarantee zero queues.

[Reference: Multi-cluster scaling policies](https://docs.snowflake.com/en/user-guide/warehouses-multicluster#setting-the-scaling-policy-for-a-multi-cluster-warehouse)

</details>

## Question 4

A developer runs:

```sql
CREATE WAREHOUSE study_wh
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;
```

Assuming appropriate privileges, which statement is correct?

A. The warehouse immediately starts because `AUTO_RESUME = TRUE`.  
B. It automatically suspends after 60 minutes of inactivity.  
C. Suspending the warehouse deletes its tables.  
D. It starts suspended but can automatically resume when a query needs its compute.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

**D is correct.** Option B needs a correction:

- **A:** Correct reasoning—`INITIALLY_SUSPENDED = TRUE` creates it suspended.
- **B:** Wrong because `60` means **60 seconds of inactivity**, not 60 minutes. It does not force the warehouse to run for exactly one minute. [Parameter reference](https://docs.snowflake.com/en/sql-reference/sql/create-warehouse#optional-properties-objectproperties)
- **C:** Right idea—you suspend the **warehouse**, not the table. Persistent table data remains.

Auto-suspend is separate from the **60-second minimum billing charge** when warehouse compute starts. Minimum billing does not mean mandatory runtime. [Billing reference](https://docs.snowflake.com/en/user-guide/warehouses-considerations#how-are-credits-charged-for-warehouses)

</details>

## Question 5

A single-cluster standard warehouse:

1. Resumes, runs for **20 seconds**, then is manually suspended.
2. Later resumes, runs for **20 seconds**, then is manually suspended again.

How much warehouse runtime is billed in total?

A. 40 seconds  
B. 60 seconds  
C. 120 seconds  
D. 3,600 seconds

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct. **C — 120 seconds billed.**

Each resume starts a new **60-second minimum billing period**, even if the warehouse runs for only 20 seconds. So: `60 + 60 = 120 seconds`. After the first minute of continuous operation, billing is per second. [Reference: Warehouse billing](https://docs.snowflake.com/en/user-guide/warehouses-considerations#how-are-credits-charged-for-warehouses)

</details>

## Question 6

A multi-cluster warehouse is configured with:

```sql
MIN_CLUSTER_COUNT = 3
MAX_CLUSTER_COUNT = 3
```

While the warehouse is running, which statement is correct?

A. It automatically scales between one and three clusters.  
B. It uses maximized mode, maintaining three clusters regardless of query demand.  
C. Every query is divided across all three clusters.  
D. Two clusters automatically stop when demand falls.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct —**B, maximized mode.**

One wording adjustment: three clusters remain active **while the warehouse is running**, not “for all time.” The whole warehouse can still be suspended. Equal minimum and maximum counts prevent demand-based scaling between different cluster counts. [Reference: Maximized versus auto-scale](https://docs.snowflake.com/en/user-guide/warehouses-multicluster#maximized-vs-auto-scale)

</details>

## Question 7

A BI warehouse is suspended overnight. After it resumes, queries that scan the same tables are slower initially, then become faster. Assume persisted query results are **not** being reused.

What is the most likely explanation?

A. Suspension cleared the warehouse’s local data cache, which must warm up again.  
B. Suspension deleted the tables, so Snowflake must restore them from Fail-safe.  
C. Resuming automatically reduces the warehouse size.  
D. Permanent tables move into the cloud services layer during suspension.

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

Correct —**A**. Suspension clears the warehouse’s **local table-data cache**, while persistent tables remain. Persisted query results are a separate cache; suspension does not automatically clear them. [Reference: Warehouse cache](https://docs.snowflake.com/en/user-guide/performance-query-warehouse-cache)

</details>

## Question 8

A team runs a Snowpark Python stored procedure for ML training. It needs substantial memory on a **single node**, and memory capacity is the bottleneck.

Which choice best fits?

A. Add more clusters to a standard warehouse.  
B. Increase Time Travel retention.  
C. Consider a Snowpark-optimized warehouse with suitable memory resources.  
D. Use an external stage as compute.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct —**C**. A Snowpark-optimized warehouse fits this workload’s **high per-node memory requirement**.

Small distinction: not every memory-intensive query requires Snowpark-optimized compute. Snowpark also runs on standard warehouses; choose based on the workload’s needs. [Reference: Snowpark-optimized warehouses](https://docs.snowflake.com/en/user-guide/warehouses-snowpark-optimized)

</details>

## Question 9

An administrator runs this on a supported standard warehouse:

```sql
ALTER WAREHOUSE analytics_wh
  SET GENERATION = '2';
```

What does this change?

A. The account edition becomes Enterprise.  
B. The warehouse uses generation 2 standard compute resources.  
C. The warehouse automatically runs two clusters.  
D. The warehouse becomes Snowpark-optimized.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct —**B**. It changes the standard warehouse’s **compute generation**, not its edition, cluster count, or warehouse type. [Reference: GENERATION setting](https://docs.snowflake.com/en/sql-reference/sql/create-warehouse#optional-properties-objectproperties)

</details>

## Question 10

A team runs heavy bulk `COPY INTO` loads and interactive BI queries on the same warehouse. During loading, BI response times worsen.

They want independent compute sizing and scheduling **without duplicating the tables**. Which approach best fits?

A. Move the tables into separate schemas but keep the same warehouse.  
B. Increase Time Travel retention.  
C. Switch the scaling policy to Economy to prioritize BI queries.  
D. Use separate warehouses for bulk loading and BI, accessing the same persistent tables.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

Correct —**D**. Separate warehouses let you size and schedule each workload independently while avoiding direct competition for the same warehouse’s CPU and memory. Both can access the same persistent tables—no duplicate tables required. [Reference: Warehouse considerations](https://docs.snowflake.com/en/user-guide/warehouses-considerations)

</details>

## Question 11

The same optimized query is tested on two single-cluster warehouses:

| Warehouse | Credit rate | Runtime |
| --- | --- | --- |
| A | 2 credits/hour | 10 minutes |
| B | 4 credits/hour | 5 minutes |

Assume no additional idle time or other charges. How does their compute cost compare?

A. Warehouse B costs twice as much.  
B. Warehouse A costs twice as much.  
C. Both consume the same credits.  
D. Warehouse B consumes no credits because it finishes faster.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct—**C**.

- A: `2 × 10/60 = ⅓ credit`
- B: `4 × 5/60 = ⅓ credit`

A higher hourly rate does not necessarily mean a higher total query cost; runtime matters too. A larger warehouse won’t always achieve this exact speedup. [Reference: Warehouse billing](https://docs.snowflake.com/en/user-guide/warehouses-considerations#how-are-credits-charged-for-warehouses)

</details>

## Question 12

A Snowpark Python procedure runs successfully on a standard warehouse. Its memory usage is modest and performance meets requirements.

A developer says, “Because it uses Python, we must switch to a Snowpark-optimized warehouse.”

Which response is correct?

A. No—Snowpark can run on standard warehouses; choose optimized compute when workload requirements justify it.  
B. Yes—all Python procedures require Snowpark-optimized warehouses.  
C. Yes—standard warehouses support only SQL, never Snowpark.  
D. No—but Python requires at least three clusters.

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

Correct —**A**. Using Python alone is not a reason to switch. Snowpark-optimized warehouses are useful when requirements such as high per-node memory justify them. [Reference: Snowpark-optimized warehouses](https://docs.snowflake.com/en/user-guide/warehouses-snowpark-optimized)

</details>

## Question 13

A warehouse is suspended and has:

```sql
AUTO_RESUME = FALSE
```

A user submits a query that needs warehouse compute. Assume they have the necessary privileges.

What must happen before the query can execute successfully?

A. `USE WAREHOUSE` automatically overrides `AUTO_RESUME = FALSE`.  
B. Snowflake executes it using the storage layer alone.  
C. The warehouse must be explicitly resumed through SQL or the interface.  
D. The tables must be restored from Time Travel.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct —**C**. With `AUTO_RESUME = FALSE`, explicitly resume it:

```sql
ALTER WAREHOUSE study_wh RESUME;
```

There is no need to change `AUTO_RESUME` to resume it manually. [Reference: AUTO_RESUME](https://docs.snowflake.com/en/sql-reference/sql/create-warehouse#optional-properties-objectproperties)

</details>

## Question 14

A multi-cluster warehouse handles non-urgent reporting. Users can tolerate some queuing, and the company wants to favor keeping existing clusters busy before starting additional ones.

Which configuration best matches that priority?

A. `SCALING_POLICY = 'STANDARD'`  
B. `SCALING_POLICY = 'ECONOMY'`  
C. Set minimum and maximum cluster counts to 5.  
D. Increase Time Travel retention.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct —**B**. Economy prioritizes credit conservation by favoring fuller use of existing clusters, accepting more queuing. It is not a fixed spending limit. [Reference: Scaling policies](https://docs.snowflake.com/en/user-guide/warehouses-multicluster#setting-the-scaling-policy-for-a-multi-cluster-warehouse)

</details>

## Question 15

A multi-cluster warehouse has:

```sql
WAREHOUSE_SIZE = MEDIUM
MIN_CLUSTER_COUNT = 1
MAX_CLUSTER_COUNT = 3
```

Currently, two clusters are running. An administrator changes its size:

```sql
ALTER WAREHOUSE reporting_wh
  SET WAREHOUSE_SIZE = LARGE;
```

Which statement is correct?

A. The warehouse must immediately start its third cluster.  
B. Each query now executes across all three clusters.  
C. Only one running cluster changes size; the others remain Medium.  
D. The new size applies to all running clusters and any subsequently started clusters; the cluster-count limits remain unchanged.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

Correct: changing `WAREHOUSE_SIZE` applies the new size to all running clusters and clusters started later. The minimum and maximum cluster counts stay at 1 and 3; resizing does not force a third cluster to start. [Reference: Multi-cluster sizing](https://docs.snowflake.com/en/user-guide/warehouses-multicluster#multi-cluster-size-and-credit-usage)

</details>

## Recall questions

1. **How do warehouse type, generation, size, and cluster count differ?** Type selects standard or Snowpark-optimized compute; generation selects the standard warehouse compute generation; size sets resources per cluster; cluster count sets how many clusters handle concurrent work. [Warehouse settings](https://docs.snowflake.com/en/sql-reference/sql/create-warehouse)
2. **How does `AUTO_SUSPEND = 60` differ from the 60-second minimum billing charge?** The former makes the warehouse eligible to suspend after 60 idle seconds; the latter is the minimum billed on each resume. An active query is not stopped after 60 seconds. [Warehouse billing](https://docs.snowflake.com/en/user-guide/warehouses-considerations#how-are-credits-charged-for-warehouses)
3. **What is the trade-off for a BI warehouse queried about every two minutes?** A short suspend timeout reduces idle compute cost, but suspending clears its local data cache. A longer timeout can retain useful cached data while consuming credits during idle time. [Warehouse cache](https://docs.snowflake.com/en/user-guide/performance-query-warehouse-cache)
4. **Standard versus Economy scaling policy, and how is that different from auto-suspend?** Standard favors responsiveness; Economy favors credit savings and may allow more queuing. Auto-suspend controls when the whole warehouse stops after inactivity. [Multi-cluster warehouses](https://docs.snowflake.com/en/user-guide/warehouses-multicluster)
5. **One query spills because it lacks memory. Increase size or cluster count?** Increase warehouse size to give its cluster more resources. More clusters mainly serve more concurrent queries; they do not pool memory for one query. [Multi-cluster warehouses](https://docs.snowflake.com/en/user-guide/warehouses-multicluster)

