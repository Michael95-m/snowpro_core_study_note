# 1.1 Architecture and Editions

[Domain 1 index](readme.md)

- **C03 objective:** 1.1. Read the definitions, work through the scenario, then answer recall questions.
- **Practice:** [ordered lab guide](exercises/readme.md); start with its setup.
- **SQL status:** examples reviewed against official documentation; not executed in your account.

<a id="what-is-snowflake"></a>

## 1.1.1 What is Snowflake?

**Snowflake** is a cloud data platform for analytics, engineering, applications, collaboration, and AI/ML. It runs on supported public-cloud infrastructure. Customers configure their data, access, and workloads; Snowflake installs and maintains the database servers.

<p align="center"><img src="../../img/what_is_snowflake.png" alt="Snowflake platform overview" width="560"></p>

<a id="shared-disk-shared-nothing-and-snowflake"></a>

## 1.1.2 Shared disk, shared nothing, and Snowflake

| Architecture | Basic idea | Trade-off |
| --- | --- | --- |
| Shared disk | Compute nodes access a shared data repository. | Simpler shared data, but contention can become a concern. |
| Shared nothing | Nodes own their compute and local data. | Parallel work scales, but distributing/rebalancing data is harder. |
| Snowflake multi-cluster shared data | Shared persistent storage with independent compute clusters. | Teams scale compute independently while using the same stored data. |

<p align="center"><img src="../../img/Shared_disk_vs_Shared_nothing.png" alt="Shared disk compared with shared nothing" width="640"></p>

- Snowflake combines **centralized persistent data** with **massively parallel compute**. Independent warehouses can isolate workloads and scale without duplicating their source tables.
- Scaling is configurable within supported capacity and service limits; it is not literally unlimited.

<p align="center"><img src="../../img/Multi-cluster-shared-data-architecture.png" alt="Multi-cluster shared-data architecture" width="640"></p>

<a id="the-three-layers"></a>

## 1.1.3 The three layers

| Layer | Responsibility | Exam example |
| --- | --- | --- |
| Database storage | Persist managed table data in compressed, columnar form and maintain micro-partition metadata. | Tables remain available when a warehouse suspends. |
| Compute | Execute queries, transformations, and warehouse-backed loads using virtual warehouses. | Increase warehouse size for a memory-heavy aggregation. |
| Cloud services | Coordinate authentication, access control, metadata, parsing, and optimization. | Plan a query and check permissions before execution. |

<p align="center"><img src="../../img/Query_Processing_layer_with_storage.png" alt="Compute separated from shared storage" width="600"></p>

<p align="center"><img src="../../img/Services_layer.png" alt="Cloud services coordinating Snowflake activity" width="600"></p>

- **Serverless features** use Snowflake-managed compute, so not every operation runs on your selected warehouse. Storage is charged separately from compute, using average stored bytes over time.
- A cloud-storage durability percentage is not a Snowflake availability guarantee.

<a id="editions"></a>

## 1.1.4 Editions

- Higher editions include lower-edition capabilities and add features.
- Also consider:
  - Region.
  - Feature availability.
  - Commercial terms.

| Edition | Useful distinctions for C03 |
| --- | --- |
| Standard | Core SQL platform, ordinary virtual warehouses, standard Time Travel for supported tables, and Fail-safe for permanent managed tables. |
| Enterprise | Multi-cluster warehouses, up to 90-day Time Travel for supported permanent objects, masking/row access, materialized views, and other advanced features. |
| Business Critical | Additional protection and continuity capabilities such as Tri-Secret Secure, private-connectivity options, and account failover/failback. |
| Virtual Private Snowflake (VPS) | Dedicated Snowflake environment with additional isolation for demanding security requirements. |

- Keep **edition** separate from:
  - Warehouse size.
  - Warehouse generation.
  - Cloud provider.
  - Region.
- Buying a higher edition does not automatically enable or configure every feature.

<a id="three-distinctions-to-remember-from-practice"></a>

## 1.1.5 Three distinctions to remember from practice

### 1. MPP within a cluster versus independent warehouses

**Massively Parallel Processing (MPP)** distributes a query across nodes in one compute cluster. The nodes work in parallel and combine their intermediate results when needed.

- For `SELECT SUM(amount) FROM orders`:
  1. Different nodes process different portions of the data.
  2. Each calculates a partial total.
  3. Those partial totals are combined into the final total.

- **Separate virtual warehouses** provide independent compute for different workloads. An ETL warehouse and a BI warehouse can access the same persistent tables without competing for the same warehouse CPU and memory; each can use parallel processing internally.

- MPP explains how nodes cooperate within a cluster; independent warehouses explain isolation between workloads. Adding clusters to a multi-cluster warehouse primarily increases concurrency capacity, rather than splitting one query across more clusters.

- **Reference:** [Snowflake architecture](https://docs.snowflake.com/en/user-guide/intro-key-concepts#snowflake-architecture).

### 2. Extended Time Travel availability versus configured retention

**Enterprise or higher** allows up to **90 days** of Time Travel for supported permanent tables, but upgrading does not change every table to 30 or 90 days. The standard default is **1 day**; effective retention comes from an explicit setting or an inherited default.

- Use an authorized role to configure an existing permanent table for 30 days:

```sql
-- Existing permanent table required; Enterprise Edition or higher.
ALTER TABLE D1_STUDY.LAB.ORDERS
  SET DATA_RETENTION_TIME_IN_DAYS = 30;
```

Temporary and transient tables remain limited to **at most one day**, even on higher editions. Increasing retention does not recover history already purged.

- **Reference:** [Time Travel retention](https://docs.snowflake.com/en/user-guide/data-time-travel#data-retention-period).

### 3. Business Critical private connectivity versus VPS isolation

- **Business Critical supports private connectivity**, such as AWS PrivateLink. A private connection controls the network path to Snowflake; it does not create a dedicated Snowflake environment by itself.
- **VPS** includes Business Critical's features and provides a separate Snowflake environment. Its hardware resources are not shared with accounts outside that VPS environment.

- Need AWS PrivateLink without a dedicated environment: **Business Critical is the minimum edition**.
- Need the additional environment and hardware isolation described above: **VPS**.

- **References:** [private connectivity](https://docs.snowflake.com/en/user-guide/private-connectivity-inbound) and [VPS](https://docs.snowflake.com/en/user-guide/intro-editions#virtual-private-snowflake-vps).

<a id="worked-scenario-and-exercise-checkpoints"></a>

## 1.1.6 Worked scenario and exercise checkpoints

- **Scenario:** ETL and BI read the same `ORDERS` table, but ETL should not take BI's warehouse CPU/memory.
  1. Put the workloads on separate virtual warehouses.
  2. Keep one shared persistent table instead of copying it for each warehouse.
  3. Size each warehouse for its own workload.
  4. Remember that each warehouse can use MPP internally.
- **Layer choice:** cloud services parses/optimizes and coordinates authorization; warehouse compute executes the plan; database storage preserves the managed data.
- **Pruning example:** min/max metadata helps identify partitions that cannot match a predicate. Candidate partitions still require execution-time row checks.
- **Edition scenario:** 30-day retention on a permanent table needs Enterprise+ **and** a retention setting. Upgrading alone is insufficient.
- **Protection scenario:** PHI/HIPAA support is associated with Business Critical+ and the required contractual/configuration conditions; the edition alone does not make a deployment compliant.
- **Remember:** account edition = available feature set; warehouse size = compute capacity; a larger warehouse does not upgrade the account edition.
- **Practice:** [01-architecture-and-context.sql](exercises/01-architecture-and-context.sql), after [setup](exercises/00-setup.sql).
- **Checkpoint:** two warehouses both return total **750**; suspending both leaves the table object intact.
- **Exam clue:** workload isolation means separate compute; shared data means independent compute can access the same persistent tables.

## What to recall



<details>
<summary><strong>1. Q:</strong> Why does Snowflake combine characteristics of shared disk and shared nothing?</summary>

<br>

**A:** It combines shared persistent storage with independent compute clusters that use parallel processing.

</details>

<hr>

<details>
<summary><strong>2. Q:</strong> Which layer parses SQL? Which executes it? Which retains data after suspension?</summary>

<br>

**A:** Cloud services parses and optimizes; warehouse compute executes; database storage retains managed data.

</details>

<hr>

<details>
<summary><strong>3. Q:</strong> What is independent compute isolation useful for?</summary>

<br>

**A:** Separating ETL, BI, or teams prevents them competing for the same warehouse CPU/memory and supports separate sizing.

</details>

<hr>

<details>
<summary><strong>4. Q:</strong> Which capabilities suggest Enterprise versus Business Critical?</summary>

<br>

**A:** Enterprise: multi-cluster, extended permanent-object retention, masking/row access, materialized views. Business Critical: features such as Tri-Secret Secure and private connectivity.

</details>

<hr>

<details>
<summary><strong>5. Q:</strong> How is VPS different from merely using a private endpoint?</summary>

<br>

**A:** Private connectivity changes the network path; VPS provides the additional isolated Snowflake environment/hardware boundary.

</details>

<hr>

<details>
<summary><strong>6. Q:</strong> How does MPP within a cluster differ from using separate warehouses for ETL and BI?</summary>

<br>

**A:** MPP splits work among nodes within a cluster; separate warehouses isolate workloads while accessing shared persistent data.

</details>

<hr>

<details>
<summary><strong>7. Q:</strong> After upgrading to Enterprise, what must you configure to give an existing permanent table 30 days of Time Travel?</summary>

<br>

**A:** Set DATA_RETENTION_TIME_IN_DAYS = 30 on the supported permanent table or its applicable parent default; upgrading alone does not set it.

</details>

<hr>

<details>
<summary><strong>8. Q:</strong> Does a partition range containing PRICE = 50 prove that a matching row exists?</summary>

<br>

**A:** No. A partition whose range includes 50 is a candidate; execution still checks actual row values.

</details>


## Official references

- [Architecture](https://docs.snowflake.com/en/user-guide/intro-key-concepts)
- [Editions and feature matrix](https://docs.snowflake.com/en/user-guide/intro-editions)
- [Warehouse overview](https://docs.snowflake.com/en/user-guide/warehouses-overview)
