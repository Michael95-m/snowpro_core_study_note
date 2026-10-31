# Domain 1.0: Snowflake AI Data Cloud Features and Architecture

- This folder follows all **six Domain 1 objectives** in the supplied SnowPro Core C03 study guide.
- Read the topics in order.
- Each topic ends with recall questions and official references.

| C03 objective | Study topic |
| --- | --- |
| 1.1 Architecture and editions | [Architecture and editions](01-architecture-and-editions.md) |
| 1.2 Interfaces and tools | [Snowsight, CLI, and IDE integrations](02-interfaces-and-tools.md) |
| 1.3 Object hierarchy, types, and context | [Objects, sessions, and parameters](03-objects-sessions-and-parameters.md) |
| 1.4 Virtual warehouses | [Warehouse configuration and workload choices](04-virtual-warehouses.md) |
| 1.5 Storage concepts | [Micro-partitions, clustering, table types, and views](05-storage-tables-and-views.md) |
| 1.6 AI/ML and application development | [Notebooks, Streamlit, Snowpark, Cortex, and Snowflake ML](06-ai-ml-and-applications.md) |

## How your existing notes fit

- **Topic 1.1:** includes your original architecture explanations and images.
- **Topic 1.5:** expands the table and view comparisons.
- **Topic 1.5:** also includes the micro-partition and natural-clustering explanation from the storage course chapter.

- Some concepts appear in more than one domain.
- This folder explains **what each object or service is**.
- Use the related notes below for operational details.

| Related material | Where to study the detail |
| --- | --- |
| RBAC, ownership, authentication, governance, and cost controls | [Domain 2](../2-Account-Management-and-Data-Governance/readme.md) |
| Stage operations, file formats, loading, unloading, and pipes | [Loading course chapter](../../study-notes/7-Data-Loading-and-Unloading/readme.md) |
| Clustering-key selection, materialized-view tuning, caching, and SQL optimization | [Domain 4](../4-Performance-Optimization-Querying-and-Transformation/readme.md) |
| Time Travel, Fail-safe, cloning, replication, and collaboration examples | [Storage and sharing course chapter](../../study-notes/9-Storage-Data-Protection-and-sharing/readme.md) |
| Unstructured files and additional transformation functions | [Transformation course chapter](../../study-notes/8-Data-transformation/readme.md) |

- Folder numbers **7, 8, and 9** are course chapter numbers, not C03 exam domains.
- The separate Level Up Accounts and Assurances file currently contains only a heading.
- It had no lesson content to relocate.

## Scope and practice

- Completed chat practice is saved in the [practice Q&A folder](practice/readme.md).
- Sections **1.1, 1.2, and 1.3** have separate files.
- Each records your answers, corrections, and follow-up explanations.
- Answers are collapsible for self-testing.

- Examples are study patterns reviewed against official documentation.
- They have **not been executed in your account**.
- SQL that references existing objects requires:
  1. Those objects to exist.
  2. A suitable role.
  3. Warehouse access.
- Creating or resuming compute and maintained objects can consume credits.

- The supplied guide has a footnote about the default warehouse for Notebooks:
  - It will not be tested until globally **Generally Available (GA)**.
  - Preserve this condition when using the guide.
- Availability in one account does not prove that the feature is currently testable.
- Notebook experiences and warehouse defaults change.
- Focus on purpose, compute selection, and cost rather than memorizing a changing default name.

## Whole-domain recall

1. Which architecture layer handles storage, SQL execution, authentication, and query optimization?
2. Why can two warehouses query the same data without sharing their compute resources?
3. Which edition would you choose for multi-cluster compute, extended Time Travel, or Tri-Secret Secure?
4. When would you use Snowsight, Snowflake CLI, or a VS Code integration?
5. Which objects are account-level, and which live inside a database schema?
6. How do stages, file formats, pipes, UDFs, procedures, sequences, ML models, and applications differ?
7. How do session variables, context functions, and session parameters differ?
8. Which session parameter wins: account, user, or session? Do all object parameters follow that hierarchy?
9. When should you scale up instead of out? What do Standard and Economy scaling policies trade off?
10. Why can auto-suspend reduce cost but make the next query slower?
11. What is the difference between Standard Gen1/Gen2 and Snowpark-optimized warehouses?
12. What metadata enables micro-partition pruning? When is natural clustering sufficient?
13. How do permanent, temporary, transient, external, Iceberg, and dynamic tables differ?
14. How do standard, materialized, and secure views differ?
15. When would you choose Notebooks, Streamlit, Snowpark, Cortex Search, Cortex Analyst, or Snowflake ML?
16. What costs and access controls must you consider before running an AI or ML workload?
