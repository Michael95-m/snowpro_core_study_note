# 1.6 AI/ML and Application Development

[Domain 1 index](readme.md)

## Choose by the problem

| Need | Feature | Why it fits |
| --- | --- | --- |
| Explore data through SQL/Python cells and explanations | Snowflake Notebooks | Interactive analysis, experiments, and documented workflows. |
| Give business users an interactive Python web application | Streamlit in Snowflake | Widgets, charts, and data-backed applications hosted in Snowflake. |
| Transform data using Python, Java, or Scala APIs close to the data | Snowpark | DataFrame operations and supported handler code execute in Snowflake. |
| Summarize, classify, translate, extract, or generate using managed AI | Cortex AI SQL functions | Invoke supported managed models/functions from SQL. |
| Retrieve relevant text using keyword and semantic similarity | Cortex Search | Search service suited to retrieval and RAG applications. |
| Ask business questions about structured data in natural language | Cortex Analyst | Uses semantic definitions to help produce SQL grounded in business concepts. |
| Develop, register, and operate predictive models | Snowflake ML | Model development and model lifecycle tools. |

## Snowflake Notebooks

Notebooks combine SQL, Python, and Markdown cells for exploration and experimentation. They suit work where code, results, and explanation belong together. The current experience includes Notebooks in Workspaces; older course demonstrations may show Legacy Notebooks.

Notebook execution needs a configured runtime/compute environment. SQL and Python execution requirements depend on that environment. Do not assume the notebook's local Python work, warehouse SQL, and a container/GPU workload always use the same compute resource.

The supplied C03 guide's default-notebook-warehouse bullet is conditional on global GA. Focus on selecting suitable compute and understanding cost until the applicable exam scope confirms that default is testable.

## Streamlit in Snowflake

Streamlit turns Python into an interactive application with tables, charts, filters, and other controls. Choose it when end users need an app rather than editing analysis cells. The app runs inside Snowflake's governed environment; its configured runtime, owner/caller privileges, data access, and compute still matter.

A Streamlit app is not automatically a distributed Snowflake Native App. Native Apps add packaging and installation for consumers; see the [sharing course chapter](../9-Storage-Data-Protection-and-sharing/readme.md).

## Snowpark

Snowpark provides APIs for data processing in Snowflake. Its DataFrames represent relational operations. Transformations are generally lazy: an action triggers execution.

```python
# Requires an authenticated Snowpark session with source-table access.
from snowflake.snowpark.functions import col

apac_orders = (
    session.table("ANALYTICS.MART.ORDERS")
    .filter(col("REGION") == "APAC")
    .select("ORDER_ID", "AMOUNT")
)
apac_orders.show()  # Action: execute and display a small result.
```

Use supported operations to push work to Snowflake rather than retrieving an entire table to local Python. `collect()` transfers results to the client; it can be unsuitable for very large outputs. Snowpark-optimized compute is a workload choice, not a mandatory requirement for every Snowpark program.

## Cortex AI SQL functions

Managed AI functions apply model capabilities without you operating model-serving infrastructure. Recognize tasks such as summarization, classification, extraction, translation, and text generation; exact function names and model availability evolve.

```sql
-- Requires access to the relevant Cortex function/model in your account.
-- Replace the model identifier with one supported in your account/region.
SELECT AI_COMPLETE('supported-model-name', 'Explain micro-partition pruning briefly.');
```

This illustrates the function call shape, not a provisioned model. Inspect access roles, supported model/region, inference charges, and result quality before using it. Generated output can be wrong; validate it for its intended use.

## Cortex Search versus Cortex Analyst

**Cortex Search** combines vector/semantic and keyword retrieval over indexed content. Use it to retrieve relevant documentation passages or support articles, often as the retrieval step of RAG. Maintaining and serving the search service has costs. Service access requires deliberate design: Cortex Search serves through owner's rights, so access to the service can expose its indexed content even when a caller lacks direct source-table access.

**Cortex Analyst** uses a semantic model/view containing business definitions, relationships, and metrics to help turn natural-language questions into SQL over structured data. For example, “revenue by region last quarter” needs trusted metric definitions and SQL execution, while “find the manual's warranty clause” is a text-retrieval problem.

Current documentation recommends semantic views for new Analyst implementations; legacy YAML semantic models remain supported. Recognize both terms in course material and choose the current supported approach for new work.

Search retrieves relevant content; Analyst supports structured business analysis. Neither should be assumed to return correct results without suitable data preparation, semantic definitions, and validation.

## Snowflake ML and model objects

Snowflake ML supports feature preparation, model development/training, and operational tools such as the Model Registry and Feature Store. Registered model versions provide a managed way to track and invoke models; a registered model is not just a Python variable in a notebook.

| Step | Purpose |
| --- | --- |
| Prepare features | Build consistent model inputs. |
| Train and evaluate | Fit the model and assess quality on appropriate data. |
| Register a version | Store model artifacts, metadata, and callable methods. |
| Deploy/infer and monitor | Produce predictions and evaluate behavior over time. |

Traditional ML predicts from learned patterns, such as churn probabilities. Cortex generative functions use managed models for tasks such as summarization. Notebooks and Snowpark can support either workflow; they are development/processing tools rather than one particular model family.

## What to recall

1. When is a notebook more suitable than a Streamlit app?
2. What triggers a lazy Snowpark DataFrame to execute?
3. Why can collecting a large DataFrame to a client be a problem?
4. How does using a managed AI function differ from training your own model?
5. Which service fits document retrieval versus structured business questions?
6. Why does a Cortex Search service's owner's-rights model matter?
7. What are the Model Registry and Feature Store for?
8. Which runtime, privileges, costs, and quality checks apply to the chosen workflow?

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
