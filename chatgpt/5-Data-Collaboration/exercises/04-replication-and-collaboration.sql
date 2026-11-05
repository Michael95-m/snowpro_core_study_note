-- Read-only inspection in your current account.
SELECT CURRENT_ORGANIZATION_NAME() AS ORG_NAME,
       CURRENT_ACCOUNT_NAME() AS ACCOUNT_NAME,
       CURRENT_REGION() AS ACCOUNT_REGION;

-- Optional read-only discovery. Results depend on the active role and account.
-- SHOW SHARES;
-- SHOW REPLICATION GROUPS;
-- SHOW FAILOVER GROUPS;
-- SHOW APPLICATION PACKAGES;
-- SHOW APPLICATIONS;

-- OPTIONAL MULTI-ACCOUNT TEMPLATES.
-- Use test accounts in the same organization with replication enabled.
-- Choose one example below. The source contains D5_STUDY.
-- Keep the D5_STUDY database name available in the target account.
-- Substitute the org and account names. Refreshes can consume credits.

-- A. Replicate a database to a read-only target.
-- SOURCE:
-- USE ROLE ACCOUNTADMIN;
-- CREATE REPLICATION GROUP D5_LAB_REPLICATION
--   OBJECT_TYPES = DATABASES
--   ALLOWED_DATABASES = D5_STUDY
--   ALLOWED_ACCOUNTS = my_org.target_account;
-- TARGET, in a separate connection:
-- USE ROLE ACCOUNTADMIN;
-- CREATE REPLICATION GROUP D5_LAB_REPLICATION
--   AS REPLICA OF my_org.source_account.D5_LAB_REPLICATION;
-- ALTER REPLICATION GROUP D5_LAB_REPLICATION REFRESH;
-- SHOW DATABASES LIKE 'D5_STUDY';

-- B. Practice the failover commands on paper or in a dedicated DR lab.
-- Business Critical or higher. Promotion is a separate operational decision.
-- SOURCE:
-- USE ROLE ACCOUNTADMIN;
-- CREATE FAILOVER GROUP D5_LAB_FAILOVER
--   OBJECT_TYPES = DATABASES
--   ALLOWED_DATABASES = D5_STUDY
--   ALLOWED_ACCOUNTS = my_org.target_account;
-- TARGET, in a separate connection:
-- USE ROLE ACCOUNTADMIN;
-- CREATE FAILOVER GROUP D5_LAB_FAILOVER
--   AS REPLICA OF my_org.source_account.D5_LAB_FAILOVER;
-- ALTER FAILOVER GROUP D5_LAB_FAILOVER REFRESH;
-- SHOW FAILOVER GROUPS;
-- In an authorized drill, only after confirming the target:
-- ALTER FAILOVER GROUP D5_LAB_FAILOVER PRIMARY;
