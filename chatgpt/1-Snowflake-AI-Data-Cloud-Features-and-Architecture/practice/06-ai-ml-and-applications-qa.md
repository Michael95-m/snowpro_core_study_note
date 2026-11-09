# 1.6 AI, ML, and Applications: Practice Questions and Answers

These 15 questions were recovered from our completed chat practice round. Answer each question before opening its answer. The explanations and official Snowflake links are lightly edited from the original feedback. These are practice questions, not official exam questions.

## Question 1

A team wants to build an **interactive Python web app** inside Snowflake. Business users should select filters, explore charts, and view data without editing code or notebook cells.

Which feature best fits?

A. Snowflake Notebooks.  
B. Streamlit in Snowflake.  
C. Cortex Search.  
D. Snowflake Model Registry.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct —**B**. Streamlit lets users interact with an app through filters, charts, forms, and other controls instead of editing code. It’s broader than visualization: it builds **interactive, data-backed Python web apps**. [Reference: Streamlit in Snowflake](https://docs.snowflake.com/en/developer-guide/streamlit/about-streamlit)

</details>

## Question 2

A data scientist wants to explore data using **SQL and Python cells**, inspect intermediate results, and add **Markdown explanations** alongside the code.

Which feature best fits?

A. Snowflake Notebooks.  
B. Streamlit in Snowflake.  
C. Cortex Search.  
D. An application package.

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

Correct—**A**. Notebooks combine SQL, Python, and Markdown cells for exploration and documentation.

Small correction: you normally select the **cell type/language**; `%` commands are not required to switch between SQL and Python. Notebooks in Workspaces also support Jupyter magics such as `%run`, but that’s a separate feature. [References: Cell types](https://docs.snowflake.com/en/user-guide/ui-snowsight/notebooks-develop-run), [Jupyter magics](https://docs.snowflake.com/en/user-guide/ui-snowsight/notebooks-in-workspaces/notebooks-in-workspaces-edit-run)

</details>

## Question 3

An engineer wants to write **Python DataFrame transformations** over large Snowflake tables, executing supported operations inside Snowflake instead of downloading the entire dataset to their laptop.

Which feature best fits?

A. Streamlit.  
B. Cortex Analyst.  
C. Snowpark.  
D. Model Registry.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct—**C**. Snowpark provides APIs to query and transform Snowflake data, including DataFrame operations that execute inside Snowflake rather than requiring the entire dataset locally. [Reference: Snowpark DataFrames](https://docs.snowflake.com/en/developer-guide/snowpark/python/working-with-dataframes)

</details>

## Question 4

A developer runs this in a Python script with a valid Snowpark session:

```python
from snowflake.snowpark.functions import col

df = (
    session.table("ORDERS")
    .filter(col("REGION") == "APAC")
    .select("ORDER_ID", "AMOUNT")
)
```

No action or automatic display has occurred. Which statement is correct?

A. All matching rows have already been downloaded into Python memory.  
B. The filter permanently removes non-APAC rows from `ORDERS`.  
C. The code requires a Snowpark-optimized warehouse.  
D. It defines a lazy transformation; an action such as `show()` or `collect()` triggers evaluation.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

Exactly, —**D**. `filter()` and `select()` build the transformation plan; `show()` and `collect()` are actions that trigger evaluation. Other actions include `count()` and saving the result as a table. [Reference: DataFrame actions](https://docs.snowflake.com/en/developer-guide/snowpark/python/working-with-dataframes#performing-an-action-to-evaluate-a-dataframe)

</details>

## Question 5

A developer needs **total sales by region** from a table containing 500 million orders. Their laptop has limited memory.

Which approach best avoids unnecessary data movement and client-memory problems?

A. Call `collect()` on the entire table, then aggregate using Python loops.  
B. Aggregate by region using Snowpark, then collect only the small summary result.  
C. Convert the entire table to a local pandas DataFrame before aggregating.  
D. Add warehouse clusters so `collect()` no longer transfers results to the laptop.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct—**B**. Snowflake performs the aggregation, and `collect()` transfers only the resulting summary to your Python client. Collecting the entire table first would create unnecessary transfer and memory pressure. [Reference: Snowpark DataFrame actions](https://docs.snowflake.com/en/developer-guide/snowpark/python/working-with-dataframes#performing-an-action-to-evaluate-a-dataframe)

</details>

## Question 6

A company wants to **summarize support tickets and translate customer feedback using SQL**. It does not want to train a model or operate model-serving infrastructure.

Which feature best fits?

A. Snowflake Model Registry alone.  
B. Cortex Search.  
C. A larger standard warehouse alone.  
D. Cortex AI SQL functions.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

Correct —**D**. Cortex AI functions provide managed capabilities such as summarization and translation directly through SQL, without requiring you to train or host the model yourself. [Reference: Cortex AI functions](https://docs.snowflake.com/en/user-guide/snowflake-cortex/aisql)

</details>

## Question 7

A company is building a support chatbot. It needs to **retrieve relevant passages from product manuals**, matching both keywords and meaning—even when the user’s wording differs from the manual.

Which feature best fits this **retrieval step**?

A. Cortex Search.  
B. Cortex Analyst.  
C. Model Registry.  
D. Snowflake Notebooks alone.

<details>
<summary>Correct answer and explanation</summary>

**Answer: A.**

Correct—**A**. Cortex Search combines **semantic/vector and keyword search** to retrieve relevant content. In a RAG chatbot, it supplies passages that a language model can use to generate an answer. [Reference: Cortex Search](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview)

</details>

## Question 8

A business user asks:

> “What was our net revenue by region last quarter?”

The data lives in structured Snowflake tables. The team wants natural-language questions translated into SQL using trusted business definitions and relationships.

Which feature specializes in this task?

A. Cortex Search.  
B. Model Registry.  
C. Cortex Analyst.  
D. Streamlit alone.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct —**C**. The workflow is **natural-language question → generated SQL → execution against Snowflake → results**. Cortex Analyst uses semantic definitions to connect business terms to the underlying data. [Reference: Cortex Analyst](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)

</details>

## Question 9

Users ask Cortex Analyst about “net revenue,” but the team hasn’t defined whether that excludes refunds, discounts, or taxes.

What is the most appropriate improvement?

A. Increase the warehouse size so Analyst interprets the term correctly.  
B. Define trusted metrics, relationships, and business terminology in a semantic view or supported semantic model.  
C. Replace the structured tables with a Cortex Search index.  
D. Collect all source rows into local Python memory.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

The reasoning describes **B**, the correct choice, not C.

A semantic view/model defines what “net revenue” means, including calculation rules and relationships. A Cortex Search index would not resolve that business-definition ambiguity. [Reference: Semantic views for Analyst](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst#understanding-semantic-views)

</details>

## Question 10

A data science team has trained several versions of a customer-churn model. It wants to manage **model artifacts, versions, metadata, and callable prediction methods** within Snowflake.

Which feature best fits?

A. Feature Store.  
B. Cortex Search.  
C. A semantic view.  
D. Model Registry.

<details>
<summary>Correct answer and explanation</summary>

**Answer: D.**

Correct—**D**. Model Registry manages model versions, artifacts, metrics, and metadata. It also lets authorized users invoke model methods, such as `predict()`—so it does more than simply store objects. [Reference: Model Registry](https://docs.snowflake.com/en/developer-guide/snowflake-ml/model-registry/overview)

</details>

## Question 11

Several ML teams use inputs such as **customer spending over the last 30 days** and **purchase frequency**.

They want reusable, governed feature definitions and consistent inputs for model training and prediction—not a place to store trained model weights.

Which feature best fits?

A. Model Registry.  
B. Feature Store.  
C. Cortex Search.  
D. A semantic view for Cortex Analyst.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct choice—**B**. More precisely, Feature Store manages reusable **features—model inputs—for both training and prediction**, including their definitions and refresh pipelines. It isn’t simply a general store for raw training data. [Reference: Feature Store](https://docs.snowflake.com/en/developer-guide/snowflake-ml/feature-store/overview)

</details>

## Question 12

A Cortex Search service indexes confidential documents. An employee has the required `USAGE` privileges on the service, database, and schema, but **no `SELECT` privilege on the source table**.

The team assumes the employee cannot retrieve the indexed content. Which statement is correct?

A. Correct—every search requires the caller’s `SELECT` privilege on the source table.  
B. The employee can retrieve only filenames, never document content.  
C. The employee may retrieve indexed content because searches use owner’s rights; service access must be carefully controlled.  
D. The service automatically filters results according to each caller’s source-table privileges.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct—**C**. Cortex Search uses **owner’s rights**, so access to the service can expose indexed content even when the caller cannot query the source table directly. Granting service access is therefore a data-access decision. [Reference: Cortex Search access control](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview#access-control-requirements)

</details>

## Question 13

A developer builds a Streamlit app inside their Snowflake account. They say:

> “It’s now automatically a Snowflake Native App that customers can install in their own accounts.”

Which response is correct?

A. Yes—every Streamlit app is automatically a Native App.  
B. No—Streamlit provides the interactive app; Native App packaging, distribution, and installation require the appropriate framework and setup.  
C. Yes—sharing the app’s URL automatically installs it in another account.  
D. No—the app must first be registered in Model Registry.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct—**B**. Streamlit builds the interactive application. Distributing it as a Native App requires additional packaging and setup for installation in consumer accounts. [Reference: Streamlit in a Native App](https://docs.snowflake.com/en/developer-guide/native-apps/adding-streamlit)

</details>

## Question 14

A notebook uses a **compute pool for its Python runtime** and a **separate query warehouse for SQL**.

An analyst suspends the query warehouse and assumes all notebook compute charges have stopped. Which statement is correct?

A. Yes—suspending the query warehouse stops every compute resource used by the notebook.  
B. Yes—Python execution is always free inside Snowflake.  
C. No—the Python runtime’s compute pool may still be running and consuming credits independently.  
D. Yes—the warehouse’s auto-suspend setting automatically suspends the compute pool too.

<details>
<summary>Correct answer and explanation</summary>

**Answer: C.**

Correct—**C**. The query warehouse and Python runtime use separate compute resources. Suspending the warehouse does not automatically suspend the notebook service or its compute pool. [Reference: Notebook compute and credit usage](https://docs.snowflake.com/en/user-guide/ui-snowsight/notebooks-in-workspaces/notebooks-in-workspaces-compute-setup)

</details>

## Question 15

A team uses Cortex AI functions to summarize customer complaints. A manager says:

> “Snowflake manages the AI, so its answers are guaranteed correct, and we don’t need to review access or costs.”

Which response is best?

A. Correct—managed AI guarantees factual accuracy and free inference.  
B. Incorrect—check required access, function/model availability, inference costs, and output quality before production use.  
C. Correct—as long as the SQL executes without an error.  
D. Incorrect—but increasing warehouse size alone guarantees accurate answers.

<details>
<summary>Correct answer and explanation</summary>

**Answer: B.**

Correct: successful SQL execution does not prove that an AI-generated answer is accurate. Check access, availability, inference costs, and output quality. [References: Evaluation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/ai-function-studio), [Costs](https://docs.snowflake.com/en/user-guide/snowflake-cortex/aisql-cost)

</details>

## Recall questions

1. **Cortex Search versus Cortex Analyst?** Search retrieves relevant indexed content, such as passages for RAG. Analyst uses semantic definitions to turn natural-language business questions into SQL over structured data. [Search](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview) · [Analyst](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
2. **What does Snowpark lazy evaluation mean, and why can `collect()` be risky?** Transformations build a plan; an action such as `show()` or `collect()` runs it. `collect()` transfers all result rows into Python memory. Aggregate or filter in Snowflake first when appropriate. [Snowpark actions](https://docs.snowflake.com/en/developer-guide/snowpark/python/working-with-dataframes#performing-an-action-to-evaluate-a-dataframe)
3. **Feature Store versus Model Registry?** Feature Store manages reusable model inputs; Model Registry manages trained models, their versions, and related metadata. [Feature Store](https://docs.snowflake.com/en/developer-guide/snowflake-ml/feature-store/overview) · [Model Registry](https://docs.snowflake.com/en/developer-guide/snowflake-ml/model-registry/overview)
4. **Can a Cortex Search user without source-table `SELECT` retrieve indexed content?** Yes, if they have the required service access. Search uses the service owner's rights, so control service access and the content indexed. [Search access control](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview#access-control-requirements)
5. **Can notebook compute charges continue after suspending its SQL warehouse?** Yes. The Python runtime's compute pool is separate; check the notebook service and compute-pool state. [Notebook compute](https://docs.snowflake.com/en/user-guide/ui-snowsight/notebooks-in-workspaces/notebooks-in-workspaces-compute-setup)

