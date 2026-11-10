# 1.6 AI/ML and Application Development

[Domain 1 index](readme.md)

- **C03 objective:** 1.6. Read the definitions, work through the scenario, then answer recall questions.
- **Practice:** [ordered lab guide](exercises/readme.md); start with its setup.
- **SQL status:** examples reviewed against official documentation; not executed in your account.

<a id="choose-by-the-problem"></a>

## 1.6.1 Choose by the problem

| Need | Feature | Why it fits |
| --- | --- | --- |
| Explore data through SQL/Python cells and explanations | Snowflake Notebooks | Interactive analysis, experiments, and documented workflows. |
| Give business users an interactive Python web application | Streamlit in Snowflake | Widgets, charts, and data-backed applications hosted in Snowflake. |
| Transform data using Python, Java, or Scala APIs close to the data | Snowpark | DataFrame operations and supported handler code execute in Snowflake. |
| Summarize, classify, translate, extract, or generate using managed AI | Cortex AI SQL functions | Invoke supported managed models/functions from SQL. |
| Retrieve relevant text using keyword and semantic similarity | Cortex Search | Search service suited to retrieval and RAG applications. |
| Ask business questions about structured data in natural language | Cortex Analyst | Uses semantic definitions to help produce SQL grounded in business concepts. |
| Develop, register, and operate predictive models | Snowflake ML | Model development and model lifecycle tools. |

<a id="snowflake-notebooks"></a>

## 1.6.2 Snowflake Notebooks

- **Snowflake Notebooks** combine:
  - SQL cells.
  - Python cells.
  - Markdown cells.
- Use notebooks for exploration and experiments that keep code, results, and explanations together. Current Snowflake materials include **Notebooks in Workspaces**; older course demonstrations may show **Legacy Notebooks**.

- A notebook needs a configured runtime. SQL and Python can use different compute resources, depending on that environment:
  - Local Python work in the notebook.
  - Warehouse SQL.
  - Container/GPU workloads.

- The supplied C03 guide makes the default-notebook-warehouse topic conditional on global GA.
- Until the applicable exam scope confirms that default is testable, focus on:
  - Selecting suitable compute.
  - Understanding cost.

<a id="streamlit-in-snowflake"></a>

## 1.6.3 Streamlit in Snowflake

- **Streamlit** turns Python into an interactive application.
- An app can provide:
  - Tables.
  - Charts.
  - Filters.
  - Other controls.
- Choose Streamlit when end users need an app rather than editing analysis cells.
- The app runs inside Snowflake's governed environment.
- Check its:
  - Configured runtime.
  - Owner/caller privileges.
  - Data access.
  - Compute.

- A Streamlit app is not automatically a distributed **Snowflake Native App**.
- Native Apps add packaging and installation for consumers.
- **Related note:** [sharing course chapter](../../study-notes/9-Storage-Data-Protection-and-sharing/readme.md).

<a id="snowpark"></a>

## 1.6.4 Snowpark

- **Snowpark** provides APIs for data processing in Snowflake.
- Its **DataFrames** represent relational operations.
- Transformations are generally **lazy**:
  - An action triggers execution.

```python
# Requires an authenticated Snowpark session with source-table access.
from snowflake.snowpark.functions import col

apac_orders = (
    session.table("D1_STUDY.LAB.ORDERS")
    .filter(col("REGION") == "APAC")
    .select("ORDER_ID", "AMOUNT")
)
apac_orders.show()  # Action: execute and display a small result.
```

- Use supported operations to process data in Snowflake before bringing results into local Python. `collect()` transfers results to the client and can be unsuitable for very large outputs.
- **Snowpark-optimized** compute is a workload choice, not a requirement for every Snowpark program.

<a id="cortex-ai-sql-functions"></a>

## 1.6.5 Cortex AI SQL functions

- Managed AI functions apply model capabilities without you operating model-serving infrastructure.
- Recognize these use cases:
  - Summarization.
  - Classification.
  - Extraction.
  - Translation.
  - Text generation.
- Exact function names and model availability can change.
- For a staged PDF, `AI_PARSE_DOCUMENT` can extract its content from a `FILE` value. The [Domain 4 document example](../4-Performance-Optimization-Querying-and-Transformation/readme.md#read-the-contents-of-a-staged-document) shows how `DIRECTORY`, `TO_FILE`, and parsing fit together.

```sql
-- Requires access to the relevant Cortex function/model in your account.
-- Replace the model identifier with one supported in your account/region.
SELECT AI_COMPLETE('supported-model-name', 'Explain micro-partition pruning briefly.');
```

- The example shows the function-call shape.
- It does not provision a model.
- Before using it, check:
  1. Access roles.
  2. Supported model and region.
  3. Inference charges.
  4. Result quality.
- Generated output can be wrong.
- Validate it for its intended use.

<a id="cortex-search-versus-cortex-analyst"></a>

## 1.6.6 Cortex Search versus Cortex Analyst

### Cortex Search: retrieve relevant content

- **Cortex Search** combines vector/semantic and keyword retrieval over indexed content.
- Use it to retrieve relevant:
  - Documentation passages.
  - Support articles.
- It is often the retrieval step in **RAG**.
- Maintaining and serving the search service has costs.
- The service refreshes as its source query's data changes; a suitable `TARGET_LAG` is a freshness target, not an exact refresh timer.
- An optional **Cortex Search primary key** identifies each source-query row. Its columns must be text and the key values must be unique per row.
  - This is a key configured on the **search service**; it does not create an enforced primary-key constraint on the source table.
  - With a primary key, Snowflake can use an optimized refresh path that processes changed rows instead of re-embedding all unchanged documents on every refresh.
  - The service can still periodically rebuild its search index; that does not mean it must re-embed unchanged data.
- During development, test a service from SQL with `SNOWFLAKE.CORTEX.SEARCH_PREVIEW`. It accepts the service name and a JSON string containing the search request. It is intended for testing; use the API for a low-latency application.

```sql
-- Illustrative: replace the name with a Cortex Search service you created.
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
  'D1_STUDY.LAB.DOC_SEARCH',
  '{"query":"device fails to boot","limit":3}'
);
```

- [Cortex Search refresh and primary keys](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview#refreshes) · [SEARCH_PREVIEW](https://docs.snowflake.com/en/sql-reference/functions/search_preview-snowflake-cortex)
- Design service access carefully:
  - Cortex Search uses **owner's rights**.
  - Service access can expose indexed content even when the caller lacks direct source-table access.

### Cortex Analyst: answer questions about structured data

- **Cortex Analyst** helps turn natural-language questions into SQL over structured data. It uses a semantic model or view with business definitions, relationships, and metrics.
- Current documentation recommends **semantic views** for new implementations. Legacy **YAML semantic models** remain supported, so recognize both terms in course material.

### Choose between Search and Analyst

- **“Revenue by region last quarter”** needs trusted metric definitions and SQL execution: use Cortex Analyst.
- **“Find the manual's warranty clause”** is a text-retrieval problem: use Cortex Search.
- Do not assume either will return correct results without the appropriate:
  - Data preparation.
  - Semantic definitions.
  - Validation.

<a id="snowflake-ml-and-model-objects"></a>

## 1.6.7 Snowflake ML and model objects

- **Snowflake ML** supports:
  - Feature preparation.
  - Model development and training.
  - Operational tools such as the **Model Registry** and **Feature Store**.
- Registered model versions provide a managed way to track and invoke models.
- A registered model is not just a Python variable in a notebook.

| Step | Purpose |
| --- | --- |
| Prepare features | Build consistent model inputs. |
| Train and evaluate | Fit the model and assess quality on appropriate data. |
| Register a version | Store model artifacts, metadata, and callable methods. |
| Deploy/infer and monitor | Produce predictions and evaluate behavior over time. |

- **Traditional ML:** predicts from learned patterns, such as churn probabilities.
- **Cortex generative functions:** use managed models for tasks such as summarization.
- **Notebooks and Snowpark:**
  - Can support either workflow.
  - Are development/processing tools, not one particular model family.

<a id="a-practical-ai-workflow-and-exercise-checkpoints"></a>

## 1.6.8 A practical AI workflow and exercise checkpoints

1. Start with a small governed dataset and a clear question.
2. Choose the tool from the task: analysis cells, user-facing app, relational transformation, document search, or structured natural-language analysis.
3. Choose the runtime/warehouse and required roles explicitly.
4. Reduce data in Snowflake before transferring it to Python.
5. Inspect generated/model output before relying on it.
6. Stop both query compute and independent runtime services when appropriate.

### Analyst definitions versus evaluation

- A semantic view/model describes tables, relationships, dimensions, and business metrics such as net revenue.
- A verified query pairs a natural-language question with a reviewed SQL answer.
- Evaluations use selected verified queries as expected answers to test generated SQL and detect regressions as definitions change.
- Useful test set: a regional total, a date range, a join-sensitive question, and a metric with a business exclusion.
- Use fixed dates for repeatable tests; “last month” changes over time.
- Evaluation has warehouse/inference/storage costs and is optional implementation depth beyond choosing Analyst for a structured-data question.
- Reference: [Cortex Analyst evaluations](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst-evaluations).

### Feature Store versus Model Registry

- **Feature Store:** governed reusable inputs, such as 30-day spend and purchase frequency, used in training/inference.
- **Model Registry:** trained model artifacts, versions, metadata, and supported callable methods.
- Reusing a feature definition helps keep training and prediction inputs consistent. Registering a model does not itself prove quality, retrain it, or grant every user prediction access.
- **Practice:** [05-ai-and-applications.sql](exercises/05-ai-and-applications.sql), then optional [06-snowpark.py](exercises/06-snowpark.py).
- **Checkpoint:** aggregate in Snowflake, then Python receives only **3 regional summary rows**.
- **Remember:** killing a Python kernel is not proof the notebook service/compute pool stopped. Inspect its runtime/service controls and current compute state.
- **Exam clue:** Cortex Search retrieves relevant indexed content; Cortex Analyst supports natural-language questions over structured business data.

## What to recall



1. When is a notebook more suitable than a Streamlit app?
2. What triggers a lazy Snowpark DataFrame to execute?
3. Why can collecting a large DataFrame to a client be a problem?
4. How does using a managed AI function differ from training your own model?
5. Which service fits document retrieval versus structured business questions?
6. Why does a Cortex Search service's owner's-rights model matter?
7. What are the Model Registry and Feature Store for?
8. Which runtime, privileges, costs, and quality checks apply to the chosen workflow?
9. How do semantic definitions and verified queries support Analyst development and evaluation?
10. Does killing a notebook kernel prove that its service/compute pool stopped?
11. Which function extracts content from a staged document, and what value type does it accept?
12. How can a Cortex Search primary key reduce refresh work, and which SQL function tests the service during development?

<details>
<summary>Open the recall answer key</summary>

1. Notebook for exploratory SQL/Python/Markdown; Streamlit for an interactive application intended for end users.
2. An action such as show(), collect(), or an appropriate write triggers execution of a lazy DataFrame plan.
3. It transfers results into client memory/network; large results can exhaust resources. Filter/aggregate first.
4. Managed AI calls available model capabilities; custom ML training fits and evaluates your own model and inputs.
5. Cortex Search for relevant indexed content; Cortex Analyst for structured-data questions using semantic definitions and SQL.
6. Search uses service-owner rights, so service usage can expose indexed content without direct source-table access; control service access.
7. Feature Store manages reusable governed inputs; Model Registry manages trained model artifacts, versions, and callable methods.
8. Check selected runtime/compute, source/service/model privileges, ongoing charges, and output/model quality.
9. Semantic definitions describe the business data; verified question/SQL pairs provide reviewed expected answers for guidance/evaluation.
10. No. Check/stop the actual notebook service/runtime and independent compute resources, not just the kernel or SQL warehouse.
11. `AI_PARSE_DOCUMENT` accepts a `FILE` value, which you can construct with `TO_FILE` from a stage path or file URL.
12. A unique text primary key lets the service use an optimized path for changed rows; test with `SNOWFLAKE.CORTEX.SEARCH_PREVIEW`.

</details>

## Official references

- [AI and ML overview](https://docs.snowflake.com/en/guides-overview-ai-features)
- [Notebooks and current Snowsight interfaces](https://docs.snowflake.com/en/user-guide/ui-snowsight-quick-tour)
- [Legacy Notebook transition](https://docs.snowflake.com/en/user-guide/ui-snowsight/notebooks)
- [Streamlit in Snowflake](https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit)
- [Snowpark DataFrames](https://docs.snowflake.com/en/developer-guide/snowpark/python/working-with-dataframes)
- [Cortex AI functions](https://docs.snowflake.com/en/user-guide/snowflake-cortex/aisql)
- [Cortex Search](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview)
- [Cortex Analyst](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
- [Model Registry](https://docs.snowflake.com/en/developer-guide/snowpark-ml/model-registry/overview)
