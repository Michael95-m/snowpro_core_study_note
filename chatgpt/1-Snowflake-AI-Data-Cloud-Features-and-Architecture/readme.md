# Domain 1.0: Snowflake AI Data Cloud Features and Architecture

- **Exam outline:** supplied [C03 guide](https://learn.snowflake.com/en/certifications/snowpro-core-c03/), pages 5-7; **31%** weighting.
- **Format and exercise update:** November 5, 2026.
- **Study cycle:** numbered topic -> Remember line/scenario -> exercise -> expected result -> click a recall question to reveal its answer.
- **SQL status:** reviewed against official documentation; not executed in your account.

This folder follows all **six Domain 1 objectives** in the supplied SnowPro Core C03 study guide. Read the topics in order; each ends with clickable recall questions and official references.

| C03 objective | Study topic |
| --- | --- |
| 1.1 Architecture and editions | [Architecture and editions](01-architecture-and-editions.md) |
| 1.2 Interfaces and tools | [Snowsight, CLI, and IDE integrations](02-interfaces-and-tools.md) |
| 1.3 Object hierarchy, types, and context | [Objects, sessions, and parameters](03-objects-sessions-and-parameters.md) |
| 1.4 Virtual warehouses | [Warehouse configuration and workload choices](04-virtual-warehouses.md) |
| 1.5 Storage concepts | [Micro-partitions, clustering, table types, views, and supplemental hybrid tables](05-storage-tables-and-views.md) |
| 1.6 AI/ML and application development | [Notebooks, Streamlit, Snowpark, Cortex, and Snowflake ML](06-ai-ml-and-applications.md) |

## Practice setup and exercise files

- Follow the [ordered lab guide](exercises/readme.md) for runnable examples and prerequisites.
- Start with [00-setup.sql](exercises/00-setup.sql), which creates `D1_STUDY.LAB` and a small warehouse.
- The fixture has **6 orders totaling 750**; use those checks before interpreting a result.
- Run [architecture/context](exercises/01-architecture-and-context.sql), [objects/parameters](exercises/02-objects-and-parameters.sql), [warehouses](exercises/03-virtual-warehouses.sql), [storage/views](exercises/04-storage-and-views.sql), and [AI inputs](exercises/05-ai-and-applications.sql) in order.
- Optional [Snowpark notebook cells](exercises/06-snowpark.py) aggregate in Snowflake before collecting three summary rows.
- Finish with [99-stop-lab.sql](exercises/99-stop-lab.sql), and stop any independent notebook runtime separately.
- Basic labs use synthetic data. Extended retention, multi-cluster settings, Dynamic Tables, and paid AI calls are marked optional with their prerequisites.

## Scenario decision guide

| Requirement | Feature/reasoning |
| --- | --- |
| ETL and BI must not compete for warehouse memory/CPU | Separate virtual warehouses reading shared persistent tables. |
| One optimized query needs more memory | Evaluate scale up; adding clusters primarily helps concurrency. |
| A burst of concurrent small queries causes overload queues | Evaluate scale out or workload isolation. |
| Session-local work table | Temporary table. |
| Rebuildable table that survives sessions, without Fail-safe | Transient table. |
| Repeated supported single-table result with maintenance cost justified | Materialized view. |
| SQL-defined pipeline with a freshness target | Dynamic Table; target lag is a goal. |
| Application needs fast point lookups and frequent small row updates | Hybrid table, where available; required enforced primary key and row-store indexing. |
| Documents need relevant-passage retrieval | Cortex Search. |
| Business users ask revenue questions in natural language | Cortex Analyst with semantic definitions and validation. |
| Govern reusable ML inputs versus trained versions | Feature Store versus Model Registry. |

## Related domains

Some concepts appear in more than one domain. Use these notes for the related details:

| Topic | Domain note |
| --- | --- |
| RBAC, ownership, authentication, governance, and cost controls | [Domain 2](../2-Account-Management-and-Data-Governance/readme.md) |
| Stage operations, file formats, loading, unloading, and pipes | [Domain 3](../3-Data-Loading-Unloading-and-Connectivity/readme.md) |
| Clustering-key selection, materialized-view tuning, caching, and SQL optimization | [Domain 4](../4-Performance-Optimization-Querying-and-Transformation/readme.md) |
| Time Travel, Fail-safe, cloning, replication, and collaboration | [Domain 5](../5-Data-Collaboration/readme.md) |
| Unstructured files and transformation functions | [Domain 4](../4-Performance-Optimization-Querying-and-Transformation/readme.md#44-perform-data-transformation-techniques) |

## Scope and practice

Completed chat practice is in the [practice Q&A folder](practice/readme.md). Sections **1.1, 1.2, and 1.3** have separate files with your answers, corrections, and follow-up explanations. Answers are collapsible for self-testing.

Examples are study patterns reviewed against official documentation; they have **not been executed in your account**.
- SQL that references existing objects requires:
  1. Those objects to exist.
  2. A suitable role.
  3. Warehouse access.
- Creating or resuming compute and maintained objects can consume credits.

- The supplied guide has a footnote about the default warehouse for Notebooks:
  - It will not be tested until globally **Generally Available (GA)**.
  - Preserve this condition when using the guide.

Availability in one account does not prove that a feature is testable on the exam. Notebook experiences and warehouse defaults can change, so focus on purpose, compute selection, and cost rather than memorizing an old default name.

## Whole-domain recall

<details>
<summary><strong>1. Q:</strong> Which architecture layer handles storage, SQL execution, authentication, and query optimization?</summary>

<br>

**A:** Storage retains managed data; compute executes; cloud services coordinates authentication, metadata, parsing, and optimization.

</details>

<hr>

<details>
<summary><strong>2. Q:</strong> Why can two warehouses query the same data without sharing their compute resources?</summary>

<br>

**A:** They have independent compute resources and access shared persistent storage.

</details>

<hr>

<details>
<summary><strong>3. Q:</strong> Which edition would you choose for multi-cluster compute, extended Time Travel, or Tri-Secret Secure?</summary>

<br>

**A:** Enterprise+ for multi-cluster and extended permanent-object retention; Business Critical+ for Tri-Secret Secure.

</details>

<hr>

<details>
<summary><strong>4. Q:</strong> When would you use Snowsight, Snowflake CLI, or a VS Code integration?</summary>

<br>

**A:** Snowsight for browser workflows, CLI for terminal scripting, VS Code for IDE development.

</details>

<hr>

<details>
<summary><strong>5. Q:</strong> Which objects are account-level, and which live inside a database schema?</summary>

<br>

**A:** Warehouses/users/roles/shares/integrations are account-level; named stages/file formats/tables/views/functions/pipes/Git repository objects are schema-level.

</details>

<hr>

<details>
<summary><strong>6. Q:</strong> How do stages, file formats, pipes, UDFs, procedures, sequences, ML models, and applications differ?</summary>

<br>

**A:** Stages reference files; formats parse; pipes define ingestion; UDFs calculate; procedures run workflows; sequences allocate values; model objects store registered versions; applications are installed app objects.

</details>

<hr>

<details>
<summary><strong>7. Q:</strong> How do session variables, context functions, and session parameters differ?</summary>

<br>

**A:** Variables store values, context functions report state, and parameters configure behavior.

</details>

<hr>

<details>
<summary><strong>8. Q:</strong> Which session parameter wins: account, user, or session? Do all object parameters follow that hierarchy?</summary>

<br>

**A:** Explicit session settings win for session parameters. Object/account-only parameters have their own supported inheritance rules.

</details>

<hr>

<details>
<summary><strong>9. Q:</strong> When should you scale up instead of out? What do Standard and Economy scaling policies trade off?</summary>

<br>

**A:** Scale up for per-query resources, out for concurrency. Standard favors responsiveness; Economy favors utilization/cost.

</details>

<hr>

<details>
<summary><strong>10. Q:</strong> Why can auto-suspend reduce cost but make the next query slower?</summary>

<br>

**A:** It reduces idle time but loses local table cache and introduces resume/startup work.

</details>

<hr>

<details>
<summary><strong>11. Q:</strong> What is the difference between Standard Gen1/Gen2 and Snowpark-optimized warehouses?</summary>

<br>

**A:** Gen1/Gen2 are Standard generations; Snowpark-optimized is a memory-oriented type, not a requirement for all Python.

</details>

<hr>

<details>
<summary><strong>12. Q:</strong> What metadata enables micro-partition pruning? When is natural clustering sufficient?</summary>

<br>

**A:** Value ranges and related micro-partition metadata. Natural organization may be sufficient when representative filters already prune well.

</details>

<hr>

<details>
<summary><strong>13. Q:</strong> How do permanent, temporary, transient, external, Iceberg, and dynamic tables differ?</summary>

<br>

**A:** Permanent/temporary/transient define lifetimes/protection; external/Iceberg describe external/open-table access/storage/catalog; dynamic describes maintained query results.

</details>

<hr>

<details>
<summary><strong>14. Q:</strong> How do standard, materialized, and secure views differ?</summary>

<br>

**A:** Standard stores SQL; materialized stores maintained results; secure controls definition/security behavior and may apply to either.

</details>

<hr>

<details>
<summary><strong>15. Q:</strong> When would you choose Notebooks, Streamlit, Snowpark, Cortex Search, Cortex Analyst, or Snowflake ML?</summary>

<br>

**A:** Notebook for interactive analysis; Streamlit for apps; Snowpark for APIs near data; Search for retrieval; Analyst for semantic structured questions; ML for model development/lifecycle.

</details>

<hr>

<details>
<summary><strong>16. Q:</strong> What costs and access controls must you consider before running an AI or ML workload?</summary>

<br>

**A:** Check runtime/warehouse/pool resources, permissions, service/model availability, storage/maintenance/inference charges, and output quality.

</details>
