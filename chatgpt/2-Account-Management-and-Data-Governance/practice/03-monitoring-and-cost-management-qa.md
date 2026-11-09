# 2.3 Monitoring and Cost Management: Practice Questions and Answers

These 25 questions were recovered from our completed chat practice round. Answer each question before opening its answer. The explanations and official Snowflake links are lightly edited from the original feedback. These are practice questions, not official exam questions.

## Question 1: Resource monitors

An ETL warehouse has a monthly quota of **100 credits**. The team wants to:

- Receive a notification at **80%**.
- Suspend the warehouse at **100%**, while allowing running queries to finish.

Which configuration meets these requirements?

**A.** Resource monitor: `NOTIFY` at 80%, `SUSPEND_IMMEDIATE` at 100%.  
**B.** Resource monitor: `NOTIFY` at 80%, `SUSPEND` at 100%.  
**C.** Budget with a 100-credit spending limit; the limit automatically suspends the warehouse.  
**D.** Set `AUTO_SUSPEND = 100` to suspend after consuming 100 credits.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

**Correct — B.** `SUSPEND` allows running queries to finish before suspending the warehouse. `SUSPEND_IMMEDIATE` cancels them.

The final usage can exceed 100 credits because running queries can continue and the monitor’s action can take time. [Official reference](https://docs.snowflake.com/en/user-guide/resource-monitors#actions)

</details>

## Question 2: Monitoring serverless costs

A team uses **virtual warehouses, Snowpipe, and Automatic Clustering**. They want to monitor expected monthly credit consumption and receive notifications when spending is projected to exceed their limit.

Which option best fits?

**A.** An account-level resource monitor, because it covers every service in the account.  
**B.** `AUTO_SUSPEND`, because it controls warehouse and serverless spending.  
**C.** A budget covering the supported warehouse and serverless resources.  
**D.** A warehouse-level resource monitor assigned to Snowpipe.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

**Correct — C.** Resource monitors don’t cover Snowpipe or Automatic Clustering. Budgets support these services and can notify you when monthly spending is **projected to exceed the limit**. [Official reference](https://docs.snowflake.com/en/user-guide/budgets#supported-services)

</details>

## Question 3: Budget limits

An administrator sets a budget’s monthly spending limit to **100 credits** and configures notifications. They configure **no custom actions**.

Actual consumption reaches 100 credits. What happens?

**A.** All warehouses and serverless services automatically stop.  
**B.** Only virtual warehouses automatically suspend.  
**C.** Snowflake automatically increases the spending limit.  
**D.** Workloads can continue; the spending limit alone does not automatically stop them.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

**Correct — D.** A budget’s spending limit alone doesn’t stop workloads.

One distinction: **`SUSPEND` and `SUSPEND_IMMEDIATE` are resource-monitor actions.** A budget can trigger a custom stored procedure to suspend warehouses, but that requires extra configuration. [Official reference](https://docs.snowflake.com/en/user-guide/budgets#creating-user-defined-actions)

</details>

## Question 4: Resource monitor assignment

An administrator runs:

```sql
CREATE RESOURCE MONITOR practice_limit
  WITH CREDIT_QUOTA = 20
  TRIGGERS
    ON 100 PERCENT DO SUSPEND;
```

They do **nothing else**. A warehouse with no other resource monitor consumes 25 credits.

Why hasn’t this monitor suspended the warehouse?

**A.** The monitor hasn’t been assigned to the warehouse or account.  
**B.** `100 PERCENT` means 100 credits, regardless of the quota.  
**C.** Resource monitors only work with Enterprise Edition.  
**D.** The trigger must use `SUSPEND_IMMEDIATE`; `SUSPEND` only sends notifications.

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

**The correct answer is A.** The monitor was created, but it wasn’t assigned to anything.

The point about `SUSPEND_IMMEDIATE` is right, but **both actions can stop a warehouse**:

- `SUSPEND`: lets running queries finish, then suspends.
- `SUSPEND_IMMEDIATE`: cancels running queries and suspends.

Neither action affects a warehouse until the monitor is assigned:

```sql
ALTER WAREHOUSE practice_wh
  SET RESOURCE_MONITOR = practice_limit;
```

[Reference: Assigning resource monitors](https://docs.snowflake.com/en/user-guide/resource-monitors#assignment-of-resource-monitors)

</details>

## Question 5: Credit calculation

A standard virtual warehouse consumes **4 credits per hour**. It resumes, runs a query for **20 seconds**, and then suspends immediately.

This happens **three separate times**, with a suspension between each run.

Considering only warehouse compute charges, approximately how many credits are billed?

**A.** 0.0667 credits  
**B.** 0.2000 credits  
**C.** 4.0000 credits  
**D.** 0.0222 credits

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

**Correct — B: 0.2 credits.**

Each resume has a **60-second minimum charge**, so:

`4 credits/hour × 3 billed minutes ÷ 60 = 0.2 credits`

[Official reference](https://docs.snowflake.com/en/user-guide/cost-understanding-compute#virtual-warehouse-credit-usage)

</details>

## Question 6: Cloud services billing

During one **UTC day**, an account consumes:

- **100 credits** for virtual warehouse compute.
- **15 credits** for cloud services.

There is no other usage. After the daily cloud-services adjustment, how many total credits are billed?

**A.** 100 credits  
**B.** 115 credits  
**C.** 105 credits  
**D.** 101.5 credits

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

**The correct answer is C — 105 credits.** 115 credits is the usage **before** the cloud-services adjustment.

Snowflake deducts up to **10% of that day’s warehouse compute usage** from cloud-services usage:

```text
Cloud-services allowance = 100 × 10% = 10 credits
Billable cloud services  = 15 − 10 = 5 credits
Total billed             = 100 + 5 = 105 credits
```

This is calculated **daily in UTC**, rather than across the whole month. [Official reference](https://docs.snowflake.com/en/user-guide/cost-understanding-compute#understanding-billing-for-cloud-services-usage)

</details>

## Question 7: Finding the cost breakdown

Your account’s total consumption is higher than the warehouse usage alone. You want a **daily breakdown by service type**, including **credits billed after the cloud-services adjustment**.

Which view is the best fit?

**A.** `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY`  
**B.** `SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY`  
**C.** `SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY`  
**D.** `SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY`

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

**Correct — D.** `METERING_DAILY_HISTORY` provides the daily breakdown by `SERVICE_TYPE`. Use **`CREDITS_BILLED`** for credits after the cloud-services adjustment. [Official reference](https://docs.snowflake.com/en/sql-reference/account-usage/metering_daily_history)

</details>

## Question 8: Historical usage versus current state

You suspended a notebook’s compute pool five minutes ago. `METERING_DAILY_HISTORY` still shows credits consumed by `SNOWPARK_CONTAINER_SERVICES` today.

What is the best conclusion?

**A.** The suspension failed because usage should immediately become zero.  
**B.** Historical consumption remains after suspension; check `SHOW COMPUTE POOLS` for its current state.  
**C.** The compute pool automatically restarted because its historical usage is visible.  
**D.** Suspending a virtual warehouse will clear the compute pool’s historical charges.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

**Correct — B.** Those credits represent **usage already consumed**, so they remain after suspension. Historical usage doesn’t prove the pool is still running; check its current state with `SHOW COMPUTE POOLS`. The metering view can also lag by up to three hours. [Official reference](https://docs.snowflake.com/en/sql-reference/account-usage/metering_daily_history)

</details>

## Question 9: Warehouse usage

A team wants to compare **hourly credit consumption for each virtual warehouse** over the last 30 days.

Which view best fits?

**A.** `SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY`  
**B.** `SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY`  
**C.** `SNOWFLAKE.ACCOUNT_USAGE.METERING_DAILY_HISTORY`  
**D.** `SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY`

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

**Correct — A.** It provides **hourly credit usage per warehouse**. One distinction: its `CREDITS_USED` value is **before** the daily cloud-services adjustment. [Official reference](https://docs.snowflake.com/en/sql-reference/account-usage/warehouse_metering_history)

</details>

## Question 10: Investigating slow queries

A BI dashboard becomes slow during peak hours. In `QUERY_HISTORY`, you find:

```text
EXECUTION_TIME       = 2,000 ms
QUEUED_OVERLOAD_TIME = 45,000 ms
```

What does this suggest?

**A.** The query spent 45 seconds compiling.  
**B.** The query spent 45 seconds waiting for a transaction lock.  
**C.** The warehouse was overloaded; investigate concurrency and available cluster capacity.  
**D.** The query itself required 47 seconds of execution.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

**The correct answer is C.** The query was **waiting for most of that time**.

- `EXECUTION_TIME = 2,000 ms` → **2 seconds executing**.
- `QUEUED_OVERLOAD_TIME = 45,000 ms` → **45 seconds waiting because the warehouse was overloaded**.

These two components add up to 47 seconds, but **waiting time isn’t execution time**. Investigate concurrency—for example, whether additional clusters or separate warehouses would help. [Official reference](https://docs.snowflake.com/en/sql-reference/account-usage/query_history#columns)

</details>

## Question 11: Failed login investigation

A user cannot sign in to Snowflake. An administrator wants to investigate **failed authentication attempts and their error messages**. The user never reached a SQL session.

Which view should the administrator check?

**A.** `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY`  
**B.** `SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY`  
**C.** `SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY`  
**D.** `SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY`

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

**Correct — D.** `LOGIN_HISTORY` includes login success or failure, authentication methods, error codes, and error messages. [Official reference](https://docs.snowflake.com/en/sql-reference/account-usage/login_history)

</details>

## Question 12: Giving access to cost reports

A custom role, `COST_REVIEWER`, needs to query:

- `METERING_DAILY_HISTORY`
- `WAREHOUSE_METERING_HISTORY`

It already has access to a warehouse for running these queries. The administrator wants to grant the appropriate Snowflake database role **without giving account administration privileges**.

Which role best fits?

**A.** `ACCOUNTADMIN`  
**B.** `SNOWFLAKE.SECURITY_VIEWER`  
**C.** `SNOWFLAKE.USAGE_VIEWER`  
**D.** `SNOWFLAKE.OBJECT_VIEWER`

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

**Correct — C.** `SNOWFLAKE.USAGE_VIEWER` grants access to those usage views. The administrator can run:

```sql
GRANT DATABASE ROLE SNOWFLAKE.USAGE_VIEWER
  TO ROLE COST_REVIEWER;
```

[Official reference](https://docs.snowflake.com/en/sql-reference/snowflake-db-roles)

</details>

## Question 13: Two resource monitors

An ETL warehouse is covered by:

- A **warehouse-level monitor**: 300-credit quota, `SUSPEND` at 100%.
- An **account-level monitor**: 1,000-credit quota, `SUSPEND` at 100%.

The ETL warehouse has consumed **100 credits**, but all warehouses combined have reached **1,000 credits**.

What happens to the ETL warehouse?

**A.** It continues because it hasn’t reached its own 300-credit quota.  
**B.** It suspends after running statements finish because the account monitor reached its threshold.  
**C.** It continues because warehouse-level monitors override account-level monitors.  
**D.** This configuration is invalid; a warehouse cannot be covered by both.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

**Correct — B.** Either applicable monitor can suspend the warehouse when its suspension threshold is reached. The warehouse-level monitor doesn’t override the account-level monitor. [Official reference](https://docs.snowflake.com/en/user-guide/resource-monitors#assignment-of-resource-monitors)

</details>

## Question 14: Multi-cluster credit calculation

A multi-cluster warehouse consumes **4 credits per hour per active cluster**.

It runs with:

- **2 active clusters for 15 minutes**.
- Then **1 active cluster for another 15 minutes**.

Considering only warehouse compute, how many credits are consumed?

**A.** 1 credit  
**B.** 2 credits  
**C.** 4 credits  
**D.** 3 credits

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

**Correct — D: 3 credits.**

The calculation works because both intervals are 15 minutes:

`4 × ¼ × 2 + 4 × ¼ × 1 = 3 credits`

Each active cluster contributes to consumption. [Official reference](https://docs.snowflake.com/en/user-guide/cost-understanding-compute#virtual-warehouse-credit-usage)

</details>

## Question 15: Is smaller always cheaper?

The same query is tested on two warehouses:

| Warehouse | Consumption rate | Runtime |
|---|---:|---:|
| A | 2 credits/hour | 30 minutes |
| B | 4 credits/hour | 10 minutes |

Each warehouse suspends immediately after the query finishes. Consider only warehouse compute.

Which statement is correct?

**A.** A is cheaper because its hourly rate is lower.  
**B.** B is cheaper because its shorter runtime outweighs its higher hourly rate.  
**C.** Both consume the same credits because they execute the same query.  
**D.** Credit consumption cannot be compared without knowing the dollar price per credit.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

**Correct — B.** The calculations are:

- A: **1 credit**
- B: **⅔ credit ≈ 0.667 credits**

Compare **rate × runtime**, rather than hourly rate alone. [Official reference](https://docs.snowflake.com/en/user-guide/cost-understanding-compute#virtual-warehouse-credit-usage)

</details>

## Question 16: Limiting query runtime

A team wants queries on a warehouse to be canceled if they run longer than **five minutes**. They want a **statement time limit**, rather than a credit quota or an idle timeout.

Which warehouse setting fits?

**A.** `STATEMENT_TIMEOUT_IN_SECONDS = 300`  
**B.** `AUTO_SUSPEND = 300`  
**C.** `STATEMENT_QUEUED_TIMEOUT_IN_SECONDS = 300`  
**D.** `CREDIT_QUOTA = 300`

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

**Correct — A.** One detail: this timeout covers the statement’s **overall time**, including queuing, compilation, execution, and time waiting for locks.

- `STATEMENT_TIMEOUT_IN_SECONDS`: overall statement time limit.
- `STATEMENT_QUEUED_TIMEOUT_IN_SECONDS`: time limit for waiting in the warehouse queue.
- `AUTO_SUSPEND`: warehouse inactivity timeout.

[Official reference](https://docs.snowflake.com/en/sql-reference/parameters#statement-timeout-in-seconds)

</details>

## Question 17: Auto-suspend

A warehouse has:

```sql
AUTO_SUSPEND = 60
```

A query starts and runs continuously for **five minutes**. No other timeout or resource monitor stops it.

What happens?

**A.** The query is canceled after 60 seconds.  
**B.** The warehouse suspends after 60 seconds, but the query continues executing.  
**C.** The warehouse stops after consuming 60 credits.  
**D.** The query continues; auto-suspend waits until the warehouse becomes inactive.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

**Correct — D.** `AUTO_SUSPEND` responds to warehouse inactivity. It doesn’t limit how long an active query can run. [Official reference](https://docs.snowflake.com/en/sql-reference/sql/create-warehouse#optional-parameters)

</details>

## Question 18: Independent compute

After finishing a notebook session, an engineer suspends `COMPUTE_WH`.

They then check:

```text
Virtual warehouse: SUSPENDED
Compute pool:      ACTIVE
Notebook service:  RUNNING
```

Why can compute charges continue?

**A.** A suspended warehouse still incurs its normal compute charge.  
**B.** The notebook service runs for free whenever its SQL warehouse is suspended.  
**C.** The notebook service uses the compute pool independently of the warehouse; its running resources can still incur charges.  
**D.** All remaining compute charges must be cloud-services charges.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

**Correct — C.** The warehouse and compute pool are separate compute resources. Suspending the warehouse doesn’t stop the running notebook service on the pool. [Official reference](https://docs.snowflake.com/en/user-guide/cost-understanding-compute#compute-pool-credit-usage)

</details>

## Question 19: Finding compute pool costs

An administrator wants to identify **which compute pool consumed the most credits over the last seven days**, with an hourly breakdown.

Which view best fits?

**A.** `SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY`  
**B.** `SNOWFLAKE.ACCOUNT_USAGE.SNOWPARK_CONTAINER_SERVICES_HISTORY`  
**C.** `SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY`  
**D.** `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY`

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

**Correct — B.** That view includes `COMPUTE_POOL_NAME`, hourly time intervals, and `CREDITS_USED`. [Official reference](https://docs.snowflake.com/en/sql-reference/account-usage/snowpark_container_services_history)

</details>

## Question 20: Is a resource monitor an exact spending cap?

A warehouse has a resource monitor with:

```sql
CREDIT_QUOTA = 100
TRIGGERS
  ON 100 PERCENT DO SUSPEND_IMMEDIATE
```

The monitor is correctly assigned. After suspension, recorded consumption is **slightly above 100 credits**.

Which explanation is best?

**A.** The quota is measured in dollars, so 100 credits is irrelevant.  
**B.** `SUSPEND_IMMEDIATE` only sends a notification.  
**C.** Monitoring and suspension can take time, allowing some additional consumption before the warehouse stops.  
**D.** Any usage above 100 credits proves the monitor was configured incorrectly.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

**Correct — C.** There can be a delay before suspension takes effect, so a resource monitor isn’t an exact spending cap—even with `SUSPEND_IMMEDIATE`. [Official reference](https://docs.snowflake.com/en/user-guide/resource-monitors#warehouse-suspension-and-resumption)

</details>

## Question 21: Credits versus dollars

Assume an account’s agreed price is **$3 per credit** for both warehouse and compute pool usage.

Its usage is:

- Warehouse: **1.5 credits**
- Compute pool: **2 credits**
- Storage: **$0.25**

There are no other charges or adjustments. What is the total cost?

**A.** $10.75  
**B.** $4.75  
**C.** $6.25  
**D.** $3.75

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

**Correct — A: $10.75.** Add the warehouse and compute pool credits, multiply by the given price, then add storage charges separately. [Official reference](https://docs.snowflake.com/en/user-guide/cost-understanding-compute)

</details>

## Question 22: Does serverless usage increase the cloud-services allowance?

During one **UTC day**, an account consumes:

- **100 credits** for virtual warehouse compute.
- **200 credits** for serverless compute.
- **25 credits** for cloud services.

There are no other charges or adjustments.

After applying the daily cloud-services adjustment, how many total credits are billed?

**A.** 300 credits  
**B.** 325 credits  
**C.** 305 credits  
**D.** 315 credits

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

**Correct — D: 315 credits.** The 10% allowance uses **warehouse compute only**. Serverless consumption doesn’t increase it. [Official reference](https://docs.snowflake.com/en/user-guide/cost-understanding-compute#understanding-billing-for-cloud-services-usage)

</details>

## Question 23: One monitor, multiple warehouses

A single resource monitor is assigned to **two warehouses**:

```sql
CREDIT_QUOTA = 200
TRIGGERS
  ON 80 PERCENT DO NOTIFY
  ON 100 PERCENT DO SUSPEND
```

The monitor’s tracked usage is:

- ETL warehouse: **90 credits**
- BI warehouse: **70 credits**

No account-level monitor applies. Which threshold has been reached?

**A.** None—each warehouse has its own separate 200-credit allowance.  
**B.** The notification threshold—their combined usage is 160 credits, or 80% of the shared quota.  
**C.** The suspension threshold—`80 PERCENT` means 80 credits.  
**D.** This setup is invalid; a monitor can cover only one warehouse.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

**The correct answer is B.** The relationship works this way:

- **One resource monitor can cover multiple warehouses.** They share its quota.
- **One warehouse can have only one warehouse-level monitor**, while also being covered by an account-level monitor.

Here, combined usage is:

```text
90 + 70 = 160 credits
160 ÷ 200 × 100 = 80%
```

So the **notification threshold** has been reached. Suspension is configured at **200 credits**. [Official reference](https://docs.snowflake.com/en/user-guide/resource-monitors#monitor-type)

</details>

## Question 24: Monitored usage versus billed usage

A resource monitor has a **100-credit quota** and `SUSPEND` at 100%.

Its assigned warehouse consumes:

- **90 credits** for warehouse compute.
- **15 credits** for supporting cloud services.

The daily cloud-services billing adjustment is **−9 credits**, giving **96 billed credits**.

Which statement is correct?

**A.** The monitor counts 105 credits before the billing adjustment, so its suspension threshold has been reached.  
**B.** The monitor counts only 96 billed credits, so its threshold hasn’t been reached.  
**C.** Resource monitors exclude all cloud-services consumption, so usage is 90 credits.  
**D.** The monitor automatically raises its quota to cover cloud-services usage.

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

**A is correct.** Resource monitors count:

**Warehouse compute + supporting cloud-services usage, before the daily billing adjustment.**

```text
Monitor tracks: 90 + 15     = 105 credits → threshold reached
Final billing:  90 + 15 − 9 =  96 credits
```

They exclude **serverless features such as Snowpipe**, but supporting cloud services still count. Also, **D is incorrect because the monitor doesn’t automatically increase its quota**. [Official reference](https://docs.snowflake.com/en/user-guide/resource-monitors#credit-quota)

</details>

## Question 25: Idle warehouse costs

A standard warehouse has **auto-suspend disabled**. It remains started for ten minutes after its last query finishes, with **zero running or queued queries**.

Why does it continue consuming warehouse compute credits?

**A.** Snowflake charges only for query execution, so these must be historical charges.  
**B.** Idle compute is free after the initial 60-second minimum.  
**C.** Zero running queries means the warehouse must already be suspended.  
**D.** A running warehouse consumes credits even while idle; enabling auto-suspend can reduce this idle consumption.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

**Correct — D.** With auto-suspend disabled, it keeps running until manually suspended or another control stops it.

Small syntax correction: use **`AUTO_SUSPEND = NULL` or `0`**, rather than `FALSE`. [Official reference](https://docs.snowflake.com/en/sql-reference/sql/create-warehouse#optional-parameters)

</details>

## Follow-up checks from the quiz

1. **A resource monitor was created but never assigned. Can it suspend a warehouse?** No. Assign it to the warehouse or account before its triggers can apply. [Resource monitor assignment](https://docs.snowflake.com/en/user-guide/resource-monitors#assignment-of-resource-monitors)
2. **Warehouse compute is 100 credits and cloud services are 8 credits for one UTC day. What is billed?** **100 credits.** The allowance is up to 10% of warehouse compute, but it can only offset the 8 cloud-services credits used. If warehouse compute is 200 and cloud services are 30, the total is **210 credits**. [Cloud-services billing](https://docs.snowflake.com/en/user-guide/cost-understanding-compute#understanding-billing-for-cloud-services-usage)
3. **`EXECUTION_TIME = 6,000 ms` and `QUEUED_OVERLOAD_TIME = 30,000 ms`. How long did the query execute?** **6 seconds**; it waited **30 seconds** for warehouse capacity. [Query history columns](https://docs.snowflake.com/en/sql-reference/account-usage/query_history#columns)
4. **Two warehouses share a 100-credit resource monitor. Does each get 100 credits?** No. They share **100 credits combined**. [Monitor types](https://docs.snowflake.com/en/user-guide/resource-monitors#monitor-type)
5. **Warehouse compute is 80 credits and supporting cloud services are 25 credits. What counts toward the monitor before the billing adjustment?** **105 credits.** [Monitor credit quota](https://docs.snowflake.com/en/user-guide/resource-monitors#credit-quota)

