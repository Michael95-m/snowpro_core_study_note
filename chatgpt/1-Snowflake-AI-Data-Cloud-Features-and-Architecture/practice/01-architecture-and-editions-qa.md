# 1.1 Practice: Architecture and Editions

[Practice index](readme.md) | [Study note](../01-architecture-and-editions.md)

This records our architecture clarification, 15 multiple-choice questions, and follow-up recall exchanges. Your multiple-choice selections were correct, but question 2 used the wrong layer name in the explanation. The recall round exposed misconceptions that we corrected below. A correct letter alone is not proof of understanding.

## Before the round: Shared storage and independent compute

**Your question, condensed:** What does shared persistent storage with independent compute clusters mean? How is Snowflake different from traditional shared-disk architecture?

**Explanation:** Snowflake warehouses access centrally stored persistent table data, while each warehouse has its own compute resources. Suspending a warehouse does not remove the stored table data.

Independent CPUs alone are not what makes Snowflake different: traditional shared-disk systems can also have nodes with their own CPUs and memory. Snowflake combines shared persistent storage with shared-nothing-style, parallel compute clusters. Within a cluster, nodes use their own local resources and cooperate on query execution. Separate warehouses provide compute isolation while accessing the same persistent data.

[Reference: Snowflake architecture](https://docs.snowflake.com/en/user-guide/intro-key-concepts)

## Multiple-choice round

### Question 1: ETL and BI on the same tables

ETL and BI need the same tables but should use independent compute without maintaining two full table copies. What should you choose?

A. Separate databases using one warehouse  
B. Separate warehouses querying the same tables  
C. Only one larger warehouse  
D. Separate schemas, which automatically provide independent compute

<details>
<summary>Your answer and explanation</summary>

**Your answer:** B. **Correct.** Warehouses supply separate compute; they can access the same persistent tables with the appropriate privileges.

[Reference: Architecture](https://docs.snowflake.com/en/user-guide/intro-key-concepts)

</details>

### Question 2: Authentication and query planning

Which layer handles authentication, access-control checks, and query parsing/optimization?

A. Compute  
B. Database storage  
C. Cloud services  
D. Warehouse local data cache

<details>
<summary>Your answer and correction</summary>

**Your answer:** "C. cloud storage layer"

**The letter was correct; the name needed correction.** It is **cloud services**, not cloud storage. Storage maintains table data; cloud services coordinates functions such as authentication and query optimization.

[Reference: Architecture layers](https://docs.snowflake.com/en/user-guide/intro-key-concepts)

</details>

### Question 3: All warehouses are suspended

What happens to permanent table data when all warehouses are suspended?

A. It remains in persistent storage, and storage charges can continue  
B. It becomes unavailable until restored from backup  
C. It moves into Fail-safe  
D. It is deleted

<details>
<summary>Your answer and explanation</summary>

**Your answer:** "A. it's persisent storage"

**Correct.** Suspension stops that warehouse's compute; it does not delete persistent tables or stop storage billing.

[Reference: Warehouses](https://docs.snowflake.com/en/user-guide/warehouses)

</details>

### Question 4: Multi-cluster and extended Time Travel

What is the minimum edition for multi-cluster warehouses and 30-day Time Travel on permanent tables?

A. Standard  
B. Enterprise  
C. Business Critical  
D. Virtual Private Snowflake (VPS)

<details>
<summary>Your answer and explanation</summary>

**Your answer:** B. **Correct.** Enterprise introduces these capabilities. Availability does not automatically configure multiple clusters or extend every table's retention.

[Reference: Editions](https://docs.snowflake.com/en/user-guide/intro-editions)

</details>

### Question 5: Tri-Secret Secure

What is the minimum edition supporting Tri-Secret Secure?

A. Standard  
B. Enterprise  
C. Business Critical  
D. VPS

<details>
<summary>Your answer and explanation</summary>

**Your answer:** "C. Business Critical"

**Correct.** Tri-Secret Secure is a feature; Business Critical is the minimum edition in this comparison.

[Reference: Editions](https://docs.snowflake.com/en/user-guide/intro-editions)

</details>

### Question 6: Does each warehouse own part of the table?

Someone says that shared-nothing compute means each warehouse permanently owns a separate portion of every table. Which correction is best?

A. Every warehouse stores its own complete permanent table copy  
B. Warehouses access shared persistent storage and use parallel compute and local caching  
C. All warehouses share the same CPUs  
D. Tables move into a warehouse whenever it resumes

<details>
<summary>Your answer and explanation</summary>

**Your answer:** B. **Correct.** A warehouse's local cache is not the authoritative persistent table store.

[Reference: Architecture](https://docs.snowflake.com/en/user-guide/intro-key-concepts)

</details>

### Question 7: A separate Snowflake environment

A company requires a dedicated Snowflake environment with hardware isolation beyond Business Critical. Which edition fits?

A. Enterprise  
B. Standard with a larger warehouse  
C. Business Critical with multiple warehouses  
D. VPS

<details>
<summary>Your answer and explanation</summary>

**Your answer:** "D. VPS"

**Correct.** VPS provides a separate environment whose hardware resources are not shared with accounts outside that VPS environment.

[Reference: Editions](https://docs.snowflake.com/en/user-guide/intro-editions)

</details>

### Question 8: Upgrading to Enterprise

Does an Enterprise upgrade automatically turn each warehouse into a multi-cluster warehouse?

A. No; the capability becomes available, but it must be configured  
B. Yes; every warehouse immediately gets two clusters  
C. No; multi-cluster requires Business Critical  
D. Yes; additional clusters never consume additional compute credits

<details>
<summary>Your answer and explanation</summary>

**Your answer:** A. **Correct.** Feature eligibility and warehouse configuration are separate decisions.

[Reference: Multi-cluster warehouses](https://docs.snowflake.com/en/user-guide/warehouses-multicluster)

</details>

### Question 9: Planning versus execution

Which mapping correctly describes authentication/query planning versus scanning data and calculating totals?

A. Authentication: storage; calculation: cloud services  
B. Planning: compute; calculation: storage  
C. Authentication/planning: cloud services; query execution: compute  
D. Both always run entirely in the selected warehouse

<details>
<summary>Your answer and explanation</summary>

**Your answer:** C. **Correct.** Distinguish coordination and optimization from warehouse-backed SQL execution.

[Reference: Architecture layers](https://docs.snowflake.com/en/user-guide/intro-key-concepts)

</details>

### Question 10: Managed-service responsibilities

Which responsibility does Snowflake manage rather than leaving it to the customer?

A. Choosing the user's business access privileges  
B. Choosing every workload's warehouse size  
C. Defining the customer's business logic  
D. Maintaining and upgrading the underlying Snowflake infrastructure

<details>
<summary>Your answer and explanation</summary>

**Your answer:** D. **Correct.** Customers still configure access, workloads, and their own application logic.

[Reference: Key concepts](https://docs.snowflake.com/en/user-guide/intro-key-concepts)

</details>

### Question 11: MPP versus warehouse isolation

ETL and BI use separate warehouses, each with multiple compute nodes. Which explanation is correct?

A. The two warehouses cooperate on every query  
B. Each warehouse must hold a permanent copy of the tables  
C. Nodes within a cluster can process work in parallel; separate warehouses have independent compute  
D. Both warehouses use the same CPU pool

<details>
<summary>Your answer and explanation</summary>

**Your answer:** C. **Correct.** MPP describes parallel processing within a compute cluster. Separate warehouses provide a different benefit: workload compute isolation.

[Reference: Architecture](https://docs.snowflake.com/en/user-guide/intro-key-concepts)

</details>

### Question 12: More compute without moving tables

BI needs more compute capacity while the tables remain unchanged. Why is this possible?

A. Resizing always creates another permanent table copy  
B. Storage and compute can scale independently  
C. All warehouses share one fixed compute pool  
D. Tables must move to a larger database

<details>
<summary>Your answer and explanation</summary>

**Your answer:** B. **Correct.** Warehouse sizing changes compute capacity, not the database's logical table location.

[Reference: Warehouses](https://docs.snowflake.com/en/user-guide/warehouses)

</details>

### Question 13: Larger warehouse versus hardware isolation

A company needs a separate Snowflake environment. Why is choosing a larger warehouse on Enterprise not sufficient?

A. Enterprise cannot use large warehouses  
B. A larger warehouse copies the account automatically  
C. Warehouse capacity is different from VPS environment isolation  
D. Creating more databases provides the required hardware isolation

<details>
<summary>Your answer and explanation</summary>

**Your answer:** C. **Correct.** Edition/environment requirements cannot be replaced by a compute-size change.

[Reference: Editions](https://docs.snowflake.com/en/user-guide/intro-editions)

</details>

### Question 14: Why call the architecture a hybrid?

Which combination describes Snowflake's hybrid architecture?

A. Shared persistent storage plus parallel, shared-nothing-style compute clusters  
B. Half the tables belong to one warehouse and half to another  
C. Every warehouse stores a complete permanent table copy  
D. Warehouses share CPUs but each has a separate persistent database

<details>
<summary>Your answer and explanation</summary>

**Your answer:** A. **Correct.** Shared data and independent parallel compute are complementary parts of the design.

[Reference: Architecture](https://docs.snowflake.com/en/user-guide/intro-key-concepts)

</details>

### Question 15: Does suspension make the entire bill zero?

All virtual warehouses are suspended. Must the account's total cost be zero?

A. Yes; suspension stops all Snowflake services  
B. No; storage and any active serverless services can still incur charges  
C. Yes; persistent storage becomes free  
D. No; suspended warehouses keep consuming their normal running compute rate

<details>
<summary>Your answer and explanation</summary>

**Your answer:** B. **Correct.** Warehouse suspension does not mean the whole account stops using billable resources.

[Reference: Understanding overall cost](https://docs.snowflake.com/en/user-guide/cost-understanding-overall)

</details>

## Follow-up recall and corrections

### Recall 1: Same table, independent warehouses

How can two warehouses query the same table independently, and what happens to the table if both suspend?

<details>
<summary>Your answer and clarification</summary>

**Your answer:** "two warehouses can query the same table independently because snowflake implements MPP technique and storage and compute are said to be separate. If both data warehouse suspend, that table still in the data storage layer sitting in public cloud storage."

**Mostly correct.** Storage/compute separation enables independent warehouses to access the same persistent tables. MPP explains parallel execution inside a cluster, not the independence between warehouses. Suspending both does not delete the tables; storage charges can continue.

</details>

### Recall 2: Why separate ETL and BI?

Why use separate warehouses instead of one larger warehouse?

<details>
<summary>Your answer and explanation</summary>

**Your answer:** "Because the workloads for ETL and BI can be different. So, it's efficient to use the different data warehouse size."

**Correct.** They can have different sizes, schedules, and suspension settings. Separate compute also reduces direct CPU/memory contention between the workloads. This flexibility does not automatically guarantee a lower bill.

</details>

### Recall 3: What does MPP mean?

What is MPP, and how does it help execute a query?

<details>
<summary>Your answer, correction, and requested explanation</summary>

**Your answer:** "MPP means massively parallel processing and it helps different virtual warehouse execute a query on a shared persistent storage."

**The expansion was correct; the explanation needed correction.** MPP distributes query work among multiple nodes **within a compute cluster**. It does not mean multiple independent warehouses join together to execute each query.

When asked to retry, you said: "i don't get. can you explain me the concept"

**Explanation we used:** Think of a warehouse cluster as a team and its nodes as workers. For a large `SUM(amount)` query, different nodes can process different work in parallel. If their partial totals are 100, 200, and 300, those results can be combined into 600. This is a simplified illustration, not a promise about the exact execution plan or linear speedup for every query.

```text
One query → work distributed across nodes → partial results combined
```

Separate ETL and BI warehouses are separate teams. Each team can use parallel processing internally.

</details>

### Recall 4: Name the three layers

Give one responsibility for each architecture layer.

<details>
<summary>Your answer and clarification</summary>

**Your answer:**

1. "Data storage layer --> maintains persisent data in snowflake native compressed columnar format"
2. "Compute --> Execute query, transformation and data loading workload"
3. "Cloud Services --> Do authentication, query planning"

**Correct.** Your storage description applies to Snowflake-managed native table storage. Warehouses handle warehouse-backed loading and transformations; services such as Snowpipe use Snowflake-managed serverless compute rather than your selected warehouse.

</details>

### Recall 5: Edition versus warehouse size

What is the difference?

<details>
<summary>Your answer and explanation</summary>

**Your answer:** "Snowflake edition represents the sets of features that can be used by the account while a warehouse size refers to the compute size and capacity."

**Correct.** For example, Enterprise is an edition; Large is a warehouse size. Changing size does not unlock Business Critical features.

</details>

### Recall 6: Does upgrading automatically set 90-day retention?

What is the minimum edition for 30-day Time Travel, and does upgrading automatically set every table to 90 days?

<details>
<summary>Your answer and correction</summary>

**Your answer:** "Minimum edition for 30-day time travel is enterprise edition and upgrading automatically set every table’s retention to 90 days"

**First part correct; second part incorrect.** Enterprise permits extended retention on permanent tables, but the upgrade does not automatically set every table to 90 days. Configure `DATA_RETENTION_TIME_IN_DAYS` at the appropriate level. The default is 1 day unless configuration/inheritance specifies otherwise.

```sql
-- Existing permanent table and sufficient privileges required.
ALTER TABLE analytics.mart.orders
  SET DATA_RETENTION_TIME_IN_DAYS = 30;
```

Increasing retention cannot recover history that has already expired.

[Reference: Time Travel](https://docs.snowflake.com/en/user-guide/data-time-travel)

</details>

### Recall 7: Configure the existing table

After upgrading, how do you enable 30-day Time Travel for an existing permanent table?

<details>
<summary>Your revised answer</summary>

**Your answer, formatting normalized:** "After upgrading to Enterprise, an existing permanent table 30 days of Time Travel is enabled by configuring DATA_RETENTION_TIME_IN_DAYS"

**Correct.** Set the parameter to `30`, as in the preceding SQL. The feature must be configured, not merely made available by the edition.

</details>

### Recall 8: What disappears when a warehouse suspends?

Does warehouse suspension remove persistent table data or the warehouse's local data cache?

<details>
<summary>Your answer and explanation</summary>

**Your answer:** "the warehouse's local data cache"

**Correct.** The persistent table remains. Local warehouse data cache is distinct from persisted query results; do not treat all caches as the same mechanism.

[Reference: Warehouse cache](https://docs.snowflake.com/en/user-guide/performance-query-warehouse-cache)

</details>

### Recall 9: Name the edition, not the feature

A company needs customer-managed key participation through Tri-Secret Secure but not a dedicated VPS environment. What is the minimum edition?

<details>
<summary>Your answer and correction</summary>

**Your answer:** "minimum edition for that purpose is tri-secret secure. Because Enterprise edition didn't support tri-secret secure which combines customer-managed encryption and snowflake managed keys"

**The feature reasoning was on track, but the edition name was wrong.** The minimum edition is **Business Critical**. Tri-Secret Secure is the feature, combining a customer-managed key with Snowflake-managed key protection; it is not an edition.

[Reference: Editions](https://docs.snowflake.com/en/user-guide/intro-editions)

</details>

### Recall 10: Business Critical versus VPS

What does VPS add beyond Business Critical?

<details>
<summary>Your answer and correction</summary>

**Your answer:** "Business Critical didn't support virtual private connections while VPS supports that features"

**Incorrect.** Private connectivity is available with Business Critical; it is not the distinguishing reason to require VPS. VPS adds a separate Snowflake environment with hardware resources not shared with accounts outside that VPS environment.

[Reference: Editions](https://docs.snowflake.com/en/user-guide/intro-editions)

</details>

### Recall 11: Private connectivity without dedicated hardware

If the requirement is private connectivity, not a separate VPS environment, what minimum edition should you identify?

<details>
<summary>Your revised answer</summary>

**Your answer:** "Business critical right?"

**Correct.** Match the requirement to Business Critical rather than automatically selecting VPS.

</details>

### Recall 12: Hardware isolation

If hardware isolation from accounts outside the company's Snowflake environment is required, what edition and additional capability apply?

<details>
<summary>Your revised answer</summary>

**Your answer:** "if required hardware isolation, the company must choose VPS edition. It adds the features of a separate snowflake environment whose hardware resources are not shared with accounts outside that VPS environment."

**Correct.** This distinguishes VPS environment isolation from private network connectivity and ordinary warehouse compute isolation.

</details>

### Recall 13: Does public cloud mean public access?

Why does using public cloud storage not mean anyone can read a Snowflake-managed table?

<details>
<summary>Your answer and clarification</summary>

**Your answer:** "Because snowflake did encryption on its own?"

**Partly correct, but incomplete.** Encryption protects data, but public cloud describes the infrastructure model, not public permission to read table contents. Snowflake-managed table access requires authentication and appropriate authorization. Users do not receive unrestricted access to the underlying managed storage files.

[Reference: Access control](https://docs.snowflake.com/en/user-guide/security-access-control-overview)

</details>

### Recall 14: Restate the public-cloud distinction

Explain in one sentence why the table is not publicly readable.

<details>
<summary>Your revised answer</summary>

**Your answer:** "Because for snowflake-managed table, it is not publicy accessible. users need to authenticate first and their active roles needs the appropriate access privileges"

**Correct for the scenario.** Infrastructure hosted in a public cloud is not the same thing as anonymously accessible table data.

</details>

### Recall 15: MPP and workload isolation in your own words

Distinguish parallel query processing from using separate ETL and BI warehouses.

<details>
<summary>Your revised answer</summary>

**Your answer:** "MPP help execute the query by distributing the work load between the nodes insides the cluster. Using separate warehouses for ETL and BI means two computation is done indepently without interrupting each other by running on separate compute"

**Correct distinction.** MPP is parallelism inside a cluster; separate warehouses isolate their compute resources. Here, "without interrupting" means avoiding direct competition for the same warehouse's CPU/memory, not a guarantee that workloads can never interact through shared data or other limits.

</details>

## End-of-round assessment

You asked whether you clearly understood 1.1. Your revised explanations showed that you could distinguish the key concepts in your own words. However, repeated multiple-choice recognition is weaker evidence than delayed, closed-book recall. This practice round does not establish exam readiness by itself.

The three distinctions we added to your study note were:

1. **MPP versus independent warehouses:** parallel work inside a cluster versus compute isolation between warehouses.
2. **Feature availability versus configuration:** an Enterprise upgrade does not automatically configure extended retention or multiple clusters.
3. **Business Critical versus VPS:** private connectivity/Tri-Secret Secure versus a separate hardware-isolated Snowflake environment.

For your next review, explain those three without opening the answers, then explain public-cloud hosting versus public access.
