"""Run as Python cells in a Snowflake notebook after 00-setup.sql.

Requires an active Snowpark session and access to D1_STUDY.LAB.ORDERS.
This is not a standalone laptop authentication script.
"""
from snowflake.snowpark.context import get_active_session
from snowflake.snowpark.functions import col, sum as sum_

session = get_active_session()
orders = session.table("D1_STUDY.LAB.ORDERS")
apac_orders = orders.filter(col("REGION") == "APAC").select("ORDER_ID", "AMOUNT")
# Above builds a lazy plan. The action below executes it.
apac_orders.sort("ORDER_ID").show()
# Expected IDs: 1, 2, 5.

regional = orders.group_by("REGION").agg(sum_("AMOUNT").alias("TOTAL"))
summary_rows = regional.sort("REGION").collect()
# Python receives just 3 aggregated rows: AMER 300, APAC 175, EMEA 275.
print(summary_rows)
# Avoid collect() on an entire large table. Aggregation runs in Snowflake.
# End the notebook's service/runtime separately after finishing the exercise.
