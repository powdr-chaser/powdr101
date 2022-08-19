USE ROLE ACCOUNTADMIN;
ALTER ACCOUNT SET quoted_identifiers_ignore_case = false;

--CREATE DATABASE AND SCHEMA CREATION (DEV)
CREATE DATABASE IF NOT EXISTS DEV;
USE DATABASE DEV;

--CREATE TAG
CREATE TAG IF NOT EXISTS env COMMENT='Environment';
CREATE TAG IF NOT EXISTS db COMMENT='Database Area';

CREATE SCHEMA IF NOT EXISTS STG
    WITH MANAGED ACCESS
    DATA_RETENTION_TIME_IN_DAYS = 3
    MAX_DATA_EXTENSION_TIME_IN_DAYS = 3
    TAG(env='DEV', db='STG');
    
    
CREATE SCHEMA IF NOT EXISTS INT
    WITH MANAGED ACCESS
    DATA_RETENTION_TIME_IN_DAYS = 3
    MAX_DATA_EXTENSION_TIME_IN_DAYS = 3 
    TAG(env='DEV', db='INT');
    
CREATE SCHEMA IF NOT EXISTS DIM
    WITH MANAGED ACCESS
    DATA_RETENTION_TIME_IN_DAYS = 3
    MAX_DATA_EXTENSION_TIME_IN_DAYS = 3 
    TAG(env='DEV', db='DIM');
   
--CREATE DATABASE AND SCHEMA CREATION (TST)
CREATE DATABASE IF NOT EXISTS TST;
USE DATABASE TST;
CREATE TAG IF NOT EXISTS env COMMENT='Environment';
CREATE TAG IF NOT EXISTS db COMMENT='Database Area';

CREATE SCHEMA IF NOT EXISTS STG
    WITH MANAGED ACCESS
    DATA_RETENTION_TIME_IN_DAYS = 3
    MAX_DATA_EXTENSION_TIME_IN_DAYS = 3 
    TAG(env='TST', db='STG');
    
CREATE SCHEMA IF NOT EXISTS INT
    WITH MANAGED ACCESS
    DATA_RETENTION_TIME_IN_DAYS = 3
    MAX_DATA_EXTENSION_TIME_IN_DAYS = 3 
    TAG(env='TST', db='INT');
    
CREATE SCHEMA IF NOT EXISTS DIM
    WITH MANAGED ACCESS
    DATA_RETENTION_TIME_IN_DAYS = 3
    MAX_DATA_EXTENSION_TIME_IN_DAYS = 3 
    TAG(env='TST', db='DIM');

   
--CREATE DATABASE AND SCHEMA CREATION (PRD)
CREATE DATABASE IF NOT EXISTS PRD;
USE DATABASE PRD;
CREATE TAG IF NOT EXISTS env COMMENT='Environment';
CREATE TAG IF NOT EXISTS db COMMENT='Database Area';

CREATE SCHEMA IF NOT EXISTS STG
    WITH MANAGED ACCESS
    DATA_RETENTION_TIME_IN_DAYS = 30
    MAX_DATA_EXTENSION_TIME_IN_DAYS = 14
    TAG(env='PRD', db='STG');
    
CREATE SCHEMA IF NOT EXISTS INT
    WITH MANAGED ACCESS
    DATA_RETENTION_TIME_IN_DAYS = 30
    MAX_DATA_EXTENSION_TIME_IN_DAYS = 14 
    TAG(env='PRD', db='INT');
    
CREATE SCHEMA IF NOT EXISTS DIM
    WITH MANAGED ACCESS
    DATA_RETENTION_TIME_IN_DAYS = 45
    MAX_DATA_EXTENSION_TIME_IN_DAYS = 14 
    TAG(env='PRD', db='DIM');
    
--Create SnowMonitor Database
CREATE DATABASE IF NOT EXISTS SNOWMONITOR;
USE DATABASE SNOWMONITOR;
CREATE TAG IF NOT EXISTS env COMMENT='Environment';
CREATE TAG IF NOT EXISTS db COMMENT='Database Area';

CREATE SCHEMA IF NOT EXISTS USAGE
WITH MANAGED ACCESS
    DATA_RETENTION_TIME_IN_DAYS = 45
    MAX_DATA_EXTENSION_TIME_IN_DAYS = 14 
    TAG(env='GLOBAL', db='SNOWMONITOR');
   
--CREATE COMPUTE WAREHOUSES FOR SERVICES AND ANALYSIS
CREATE OR REPLACE WAREHOUSE ANALYSIS
AUTO_SUSPEND = 30
COMMENT = 'Analysis and Profiling';

CREATE OR REPLACE WAREHOUSE SNOWDQ
AUTO_SUSPEND = 30
COMMENT = 'SnowDQ - Service by Powdr Solutions';

CREATE OR REPLACE WAREHOUSE DEV
AUTO_SUSPEND = 30
COMMENT = 'Development Services';

CREATE OR REPLACE WAREHOUSE TST
AUTO_SUSPEND = 30
COMMENT = 'Test Services';

CREATE OR REPLACE WAREHOUSE PRD
AUTO_SUSPEND = 30
COMMENT = 'Prodution Services';

CREATE OR REPLACE WAREHOUSE REPORTING
AUTO_SUSPEND = 30
COMMENT = 'REPORTING Reporting';

USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWMONITOR;
USE SCHEMA USAGE;
--SNOWMONITOR OBJECTS
--Create the Snowmonitor objects
CREATE OR REPLACE TASK REPLICATE_RATE_SHEET
  WAREHOUSE = ANALYSIS
  SCHEDULE = '60 MINUTE'
AS
CREATE OR REPLACE TABLE ORG_RATE_SHEET AS SELECT * FROM "SNOWFLAKE"."ORGANIZATION_USAGE"."RATE_SHEET_DAILY";

CREATE OR REPLACE TASK REPLICATE_REMAINING_BALANCE
  WAREHOUSE = ANALYSIS
  SCHEDULE = '60 MINUTE'
AS
CREATE OR REPLACE TABLE ORG_REMAINING_BALANCE AS SELECT * FROM "SNOWFLAKE"."ORGANIZATION_USAGE"."REMAINING_BALANCE_DAILY";

CREATE OR REPLACE TASK REPLICATE_WAREHOUSE_METERING
  WAREHOUSE = ANALYSIS
  SCHEDULE = '60 MINUTE'
AS
CREATE OR REPLACE TABLE ORG_WAREHOUSE_METERING AS SELECT * FROM "SNOWFLAKE"."ORGANIZATION_USAGE"."WAREHOUSE_METERING_HISTORY";

CREATE OR REPLACE TASK REPLICATE_USAGE_IN_CURRENCY
  WAREHOUSE = ANALYSIS
  SCHEDULE = '60 MINUTE'
AS
CREATE OR REPLACE TABLE ORG_USAGE_IN_CURRENCY AS SELECT * FROM "SNOWFLAKE"."ORGANIZATION_USAGE"."USAGE_IN_CURRENCY_DAILY";
        
--ENABLE AND EXECUTE CREATION OF SNOWMONITOR OBJECTS
ALTER TASK REPLICATE_RATE_SHEET RESUME;
ALTER TASK REPLICATE_REMAINING_BALANCE RESUME;
ALTER TASK REPLICATE_WAREHOUSE_METERING RESUME;
ALTER TASK REPLICATE_USAGE_IN_CURRENCY RESUME;

EXECUTE TASK REPLICATE_RATE_SHEET;
EXECUTE TASK REPLICATE_REMAINING_BALANCE;
EXECUTE TASK REPLICATE_WAREHOUSE_METERING;
EXECUTE TASK REPLICATE_USAGE_IN_CURRENCY;
        
--CREATE DEVOPS, DEVREAD, QAOPS, QAREAD, PRODOPS,PRODREAD, MASKINGADMIN
/* The role structure will be as follows:
 * -DEVOPS
 * ----CREATE, READ, WRITE, DELETE, DROP, ALTER)
 * -DEVREAD
 * ----READ
 * 
 * -TSTOPS
 * ----CREATE, READ, WRITE, DELETE, DROP, ALTER)
 * -TSTREAD
 * ----READ
 * 
 * -PRDOPS
 * ----CREATE, READ, WRITE, DELETE, DROP, ALTER)
 * -PRDREAD
 * ----READ
 * 
 * -REPORTING
 * ----SELECT ON ALL OBJECTS IN ALL DATABASES THROUGH INHERITIED ROLES
 * 
 * -MASKINGADMIN
 * ----CREATE MASKING POLICY
 * 
 * -PRIVATE
 * ----ACCESS TO MASKED CONTENT
 * 
 * -SNOWDQ
 * ----ROLE FOR SNOWDQ APPLICATION
 */

--CREATE THE ROLES FOR THE ACCOUNT
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS DEVOPS
COMMENT = 'Development Operations';
CREATE ROLE IF NOT EXISTS DEVREAD
COMMENT = 'Development Read Only';

CREATE ROLE IF NOT EXISTS TSTOPS
COMMENT = 'Test Operations';
CREATE ROLE IF NOT EXISTS TSTREAD
COMMENT = 'Test Read Only';

CREATE ROLE IF NOT EXISTS PRDOPS
COMMENT = 'Production Operations';
CREATE ROLE IF NOT EXISTS PRDREAD
COMMENT = 'Production Read Only';

CREATE OR REPLACE ROLE REPORTING
COMMENT = 'REPORTING Reporting Read-Only Access';

CREATE ROLE IF NOT EXISTS MASKINGADMIN
COMMENT = 'Masking Policy Administrator';

CREATE ROLE IF NOT EXISTS PRIVATE
COMMENT = 'Role to Access Masked Data';

CREATE ROLE IF NOT EXISTS SNOWDQ
COMMENT = 'SnowDQ Application Access';

--GRANT WAREHOUSE ACCESS TO THE RESPECTIVE SERVICE ROLES
--ANALYSIS WAREHOUSE
GRANT USAGE ON WAREHOUSE ANALYSIS TO ROLE DEVOPS;
GRANT USAGE ON WAREHOUSE ANALYSIS TO ROLE DEVREAD;
GRANT USAGE ON WAREHOUSE ANALYSIS TO ROLE TSTOPS;
GRANT USAGE ON WAREHOUSE ANALYSIS TO ROLE TSTREAD;
GRANT USAGE ON WAREHOUSE ANALYSIS TO ROLE PRDOPS;
GRANT USAGE ON WAREHOUSE ANALYSIS TO ROLE PRDREAD;

--SNOWDQ WAREHOUSE
GRANT USAGE ON WAREHOUSE SNOWDQ TO ROLE SNOWDQ;

--REPORTING WAREHOUSE
GRANT USAGE ON WAREHOUSE REPORTING TO ROLE REPORTING;

--GRANT DATABASE ACCESS TO THE ROLES
--DEV
GRANT USAGE ON DATABASE DEV TO ROLE DEVOPS;
GRANT USAGE ON DATABASE DEV TO ROLE DEVREAD;
GRANT USAGE ON DATABASE DEV TO ROLE SNOWDQ;
GRANT USAGE ON DATABASE DEV TO ROLE REPORTING;

--TST
GRANT USAGE ON DATABASE TST TO ROLE TSTOPS;
GRANT USAGE ON DATABASE TST TO ROLE TSTREAD;
GRANT USAGE ON DATABASE TST TO ROLE SNOWDQ;
GRANT USAGE ON DATABASE TST TO ROLE REPORTING;

--PRD
GRANT USAGE ON DATABASE PRD TO ROLE PRDOPS;
GRANT USAGE ON DATABASE PRD TO ROLE PRDREAD;
GRANT USAGE ON DATABASE PRD TO ROLE SNOWDQ;
GRANT USAGE ON DATABASE PRD TO ROLE REPORTING;

--GRANT SCHEMA ACCESS TO ROLES
--DEV
GRANT USAGE ON ALL SCHEMAS IN DATABASE DEV TO ROLE DEVOPS;
GRANT USAGE ON ALL SCHEMAS IN DATABASE DEV TO ROLE DEVREAD;
GRANT USAGE ON ALL SCHEMAS IN DATABASE DEV TO ROLE SNOWDQ;
GRANT USAGE ON ALL SCHEMAS IN DATABASE DEV TO ROLE REPORTING;

--TST
GRANT USAGE ON ALL SCHEMAS IN DATABASE TST TO ROLE TSTOPS;
GRANT USAGE ON ALL SCHEMAS IN DATABASE TST TO ROLE TSTREAD;
GRANT USAGE ON ALL SCHEMAS IN DATABASE TST TO ROLE SNOWDQ;
GRANT USAGE ON ALL SCHEMAS IN DATABASE TST TO ROLE REPORTING;

--PRD
GRANT USAGE ON ALL SCHEMAS IN DATABASE PRD TO ROLE PRDOPS;
GRANT USAGE ON ALL SCHEMAS IN DATABASE PRD TO ROLE PRDREAD;
GRANT USAGE ON ALL SCHEMAS IN DATABASE PRD TO ROLE SNOWDQ;
GRANT USAGE ON ALL SCHEMAS IN DATABASE PRD TO ROLE REPORTING;

--FUTURE SCHEMA ACCESS TO 
--DEV
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE DEV TO ROLE DEVOPS;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE DEV TO ROLE DEVREAD;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE DEV TO ROLE SNOWDQ;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE DEV TO ROLE REPORTING;

--TST
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE TST TO ROLE TSTOPS;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE TST TO ROLE TSTREAD;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE TST TO ROLE SNOWDQ;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE TST TO ROLE REPORTING;

--PRD
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE PRD TO ROLE PRDOPS;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE PRD TO ROLE PRDREAD;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE PRD TO ROLE SNOWDQ;
GRANT USAGE ON FUTURE SCHEMAS IN DATABASE PRD TO ROLE REPORTING;

--SELECT FROM TABLES
--DEV
GRANT SELECT ON ALL TABLES IN DATABASE DEV TO ROLE DEVREAD;
GRANT SELECT ON ALL TABLES IN DATABASE DEV TO ROLE SNOWDQ;
GRANT SELECT ON ALL TABLES IN DATABASE DEV TO ROLE REPORTING;

--TST
GRANT SELECT ON ALL TABLES IN DATABASE TST TO ROLE TSTREAD;
GRANT SELECT ON ALL TABLES IN DATABASE TST TO ROLE SNOWDQ;
GRANT SELECT ON ALL TABLES IN DATABASE TST TO ROLE REPORTING;

--PRD
GRANT SELECT ON ALL TABLES IN DATABASE PRD TO ROLE PRDREAD;
GRANT SELECT ON ALL TABLES IN DATABASE PRD TO ROLE SNOWDQ;
GRANT SELECT ON ALL TABLES IN DATABASE PRD TO ROLE REPORTING;

--SELECT FROM VIEWS
--DEV
GRANT SELECT ON ALL VIEWS IN DATABASE DEV TO ROLE DEVREAD;
GRANT SELECT ON ALL VIEWS IN DATABASE DEV TO ROLE SNOWDQ;
GRANT SELECT ON ALL VIEWS IN DATABASE DEV TO ROLE REPORTING;

--TST
GRANT SELECT ON ALL VIEWS IN DATABASE TST TO ROLE TSTREAD;
GRANT SELECT ON ALL VIEWS IN DATABASE TST TO ROLE SNOWDQ;
GRANT SELECT ON ALL VIEWS IN DATABASE TST TO ROLE REPORTING;

--PRD
GRANT SELECT ON ALL VIEWS IN DATABASE PRD TO ROLE PRDREAD;
GRANT SELECT ON ALL VIEWS IN DATABASE PRD TO ROLE REPORTING;
GRANT SELECT ON ALL VIEWS IN DATABASE PRD TO ROLE SNOWDQ;

--SELECT FROM FUTURE TABLES
--DEV
GRANT SELECT ON FUTURE TABLES IN DATABASE DEV TO ROLE DEVREAD;
GRANT SELECT ON FUTURE TABLES IN DATABASE DEV TO ROLE SNOWDQ;
GRANT SELECT ON FUTURE TABLES IN DATABASE DEV TO ROLE REPORTING;

--TST
GRANT SELECT ON FUTURE TABLES IN DATABASE TST TO ROLE TSTREAD;
GRANT SELECT ON FUTURE TABLES IN DATABASE TST TO ROLE SNOWDQ;
GRANT SELECT ON FUTURE TABLES IN DATABASE TST TO ROLE REPORTING;

--PRD
GRANT SELECT ON FUTURE TABLES IN DATABASE PRD TO ROLE PRDREAD;
GRANT SELECT ON FUTURE TABLES IN DATABASE PRD TO ROLE SNOWDQ;
GRANT SELECT ON FUTURE TABLES IN DATABASE PRD TO ROLE REPORTING;

--SELECT FROM FUTURE VIEWS
--DEV
GRANT SELECT ON FUTURE VIEWS IN DATABASE DEV TO ROLE DEVREAD;
GRANT SELECT ON FUTURE VIEWS IN DATABASE DEV TO ROLE SNOWDQ;
GRANT SELECT ON FUTURE VIEWS IN DATABASE DEV TO ROLE REPORTING;

--TST
GRANT SELECT ON FUTURE VIEWS IN DATABASE TST TO ROLE TSTREAD;
GRANT SELECT ON FUTURE VIEWS IN DATABASE TST TO ROLE SNOWDQ;
GRANT SELECT ON FUTURE VIEWS IN DATABASE TST TO ROLE REPORTING;

--PRD
GRANT SELECT ON FUTURE VIEWS IN DATABASE PRD TO ROLE PRDREAD;
GRANT SELECT ON FUTURE VIEWS IN DATABASE PRD TO ROLE SNOWDQ;
GRANT SELECT ON FUTURE VIEWS IN DATABASE PRD TO ROLE REPORTING;

--OPSERATIONS ROLES: ALL PRIVS TO THE ENVIRONMENT
--DEV
GRANT ALL PRIVILEGES ON DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON ALL VIEWS IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON ALL MATERIALIZED VIEWS IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON ALL STREAMS IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON ALL TASKS IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON FUTURE VIEWS IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON FUTURE MATERIALIZED VIEWS IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON FUTURE FUNCTIONS IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON FUTURE PROCEDURES IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON FUTURE STREAMS IN DATABASE DEV TO ROLE DEVOPS;
GRANT ALL PRIVILEGES ON FUTURE TASKS IN DATABASE DEV TO ROLE DEVOPS;


--TST
GRANT ALL PRIVILEGES ON DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON ALL VIEWS IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON ALL MATERIALIZED VIEWS IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON ALL STREAMS IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON ALL TASKS IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON FUTURE VIEWS IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON FUTURE MATERIALIZED VIEWS IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON FUTURE FUNCTIONS IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON FUTURE PROCEDURES IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON FUTURE STREAMS IN DATABASE TST TO ROLE TSTOPS;
GRANT ALL PRIVILEGES ON FUTURE TASKS IN DATABASE TST TO ROLE TSTOPS;

--PRD
GRANT ALL PRIVILEGES ON DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON ALL VIEWS IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON ALL MATERIALIZED VIEWS IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON ALL PROCEDURES IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON ALL STREAMS IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON ALL TASKS IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON FUTURE VIEWS IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON FUTURE MATERIALIZED VIEWS IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON FUTURE FUNCTIONS IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON FUTURE PROCEDURES IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON FUTURE STREAMS IN DATABASE PRD TO ROLE PRDOPS;
GRANT ALL PRIVILEGES ON FUTURE TASKS IN DATABASE PRD TO ROLE PRDOPS;
        
--SNOWMONITOR ACCESS
GRANT USAGE ON DATABASE SNOWMONITOR TO ROLE REPORTING;
GRANT SELECT ON FUTURE TABLES IN SCHEMA SNOWMONITOR.USAGE TO ROLE REPORTING;
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWMONITOR.USAGE TO ROLE REPORTING;
GRANT SELECT ON FUTURE VIEWS IN SCHEMA SNOWMONITOR.USAGE TO ROLE REPORTING;
GRANT SELECT ON ALL TABLES IN SCHEMA SNOWMONITOR.USAGE TO ROLE REPORTING;
GRANT USAGE ON SCHEMA SNOWMONITOR.USAGE TO ROLE REPORTING;

--GRANT REPORTING ROLE TO CURRENT USER
SET USER_NAME=CURRENT_USER();
GRANT ROLE REPORTING TO USER IDENTIFIER($USER_NAME);

--MASKING POLICY ROLE
USE ROLE ACCOUNTADMIN;

GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE MASKINGADMIN;

--DEV
USE DATABASE DEV;
GRANT CREATE MASKING POLICY ON SCHEMA STG TO ROLE MASKINGADMIN;
GRANT CREATE MASKING POLICY ON SCHEMA INT TO ROLE MASKINGADMIN;
GRANT CREATE MASKING POLICY ON SCHEMA DIM TO ROLE MASKINGADMIN;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA STG TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA INT TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA DIM TO ROLE MASKINGADMIN;

GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA STG TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA INT TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA DIM TO ROLE MASKINGADMIN;

--TST
USE DATABASE TST;
GRANT CREATE MASKING POLICY ON SCHEMA STG TO ROLE MASKINGADMIN;
GRANT CREATE MASKING POLICY ON SCHEMA INT TO ROLE MASKINGADMIN;
GRANT CREATE MASKING POLICY ON SCHEMA DIM TO ROLE MASKINGADMIN;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA STG TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA INT TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA DIM TO ROLE MASKINGADMIN;

GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA STG TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA INT TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA DIM TO ROLE MASKINGADMIN;

--PRD
USE DATABASE PRD;
GRANT CREATE MASKING POLICY ON SCHEMA STG TO ROLE MASKINGADMIN;
GRANT CREATE MASKING POLICY ON SCHEMA INT TO ROLE MASKINGADMIN;
GRANT CREATE MASKING POLICY ON SCHEMA DIM TO ROLE MASKINGADMIN;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA STG TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA INT TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA DIM TO ROLE MASKINGADMIN;

GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA STG TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA INT TO ROLE MASKINGADMIN;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA DIM TO ROLE MASKINGADMIN;

GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE MASKINGADMIN;

USE DATABASE SNOWMONITOR;
USE SCHEMA USAGE;
--VIEW FORECASTED CREDIT EXHAUSTION
-- Forecasted Exhaustion
SHOW GRANTS ON VIEW FORECASTED_EXHAUSTION;
CREATE OR REPLACE VIEW FORECASTED_EXHAUSTION AS 
WITH
    rolling_average_15 as (Select USAGE_Date,SUM(IFNULL(USAGE_IN_CURRENCY,0)) as AVG_COMPUTE_15
                        from "SNOWMONITOR"."USAGE"."ORG_USAGE_IN_CURRENCY"
                        WHERE USAGE_DATE >= DATEADD(day,-15,CURRENT_DATE)
                           AND USAGE IS NOT NULL
                        GROUP BY USAGE_DATE),
    rolling_average_30 as (Select USAGE_Date,SUM(IFNULL(USAGE_IN_CURRENCY,0)) as AVG_COMPUTE_30
                        from "SNOWMONITOR"."USAGE"."ORG_USAGE_IN_CURRENCY"
                        WHERE USAGE_DATE >= DATEADD(day,-30,CURRENT_DATE)
                           AND USAGE IS NOT NULL
                        GROUP BY USAGE_DATE),
    rolling_average_60 as (Select USAGE_Date,SUM(IFNULL(USAGE_IN_CURRENCY,0)) as AVG_COMPUTE_60
                        from "SNOWMONITOR"."USAGE"."ORG_USAGE_IN_CURRENCY"
                        WHERE USAGE_DATE >= DATEADD(day,-60,CURRENT_DATE)
                           AND USAGE IS NOT NULL
                        GROUP BY USAGE_DATE),
    rolling_average_90 as (Select USAGE_Date,SUM(IFNULL(USAGE_IN_CURRENCY,0)) as AVG_COMPUTE_90
                        from "SNOWMONITOR"."USAGE"."ORG_USAGE_IN_CURRENCY"
                        WHERE USAGE_DATE >= DATEADD(day,-90,CURRENT_DATE)
                           AND USAGE IS NOT NULL
                        GROUP BY USAGE_DATE),
    remaining_balance as (Select TOP 1 CAPACITY_BALANCE
                          from "SNOWMONITOR"."USAGE"."ORG_REMAINING_BALANCE"
                          Order by DATE DESC)                        
Select AVG(AVG_COMPUTE_15) as AVG_15,
       DATEADD(day, (CAPACITY_BALANCE / AVG(AVG_COMPUTE_15)), CURRENT_DATE) AS Expiration_Date_15_AVG,
       --MAX(AVG_COMPUTE_15) as MAX_15,
       --DATEADD(day, (CAPACITY_BALANCE / MAX(AVG_COMPUTE_15)), CURRENT_DATE) AS Expiration_Date_15_MAX,
       AVG(AVG_COMPUTE_30) as AVG_30,
       DATEADD(day, (CAPACITY_BALANCE / AVG(AVG_COMPUTE_30)), CURRENT_DATE) AS Expiration_Date_30_AVG,
       --MAX(AVG_COMPUTE_30) as MAX_30,
       --DATEADD(day, (CAPACITY_BALANCE / MAX(AVG_COMPUTE_30)), CURRENT_DATE) AS Expiration_Date_30_MAX,
       AVG(AVG_COMPUTE_60) as AVG_60,
       DATEADD(day, (CAPACITY_BALANCE / AVG(AVG_COMPUTE_60)), CURRENT_DATE) AS Expiration_Date_60_AVG,
       --MAX(AVG_COMPUTE_60) as MAX_60,
       --DATEADD(day, (CAPACITY_BALANCE / MAX(AVG_COMPUTE_60)), CURRENT_DATE) AS Expiration_Date_60_MAX,
       AVG(AVG_COMPUTE_90) as AVG_90,
       DATEADD(day, (CAPACITY_BALANCE / AVG(AVG_COMPUTE_90)), CURRENT_DATE) AS Expiration_Date_90_AVG
       --MAX(AVG_COMPUTE_90) as AVG_90,
       --DATEADD(day, (CAPACITY_BALANCE / MAX(AVG_COMPUTE_90)), CURRENT_DATE) AS Expiration_Date_90_MAX
FROM rolling_average_15,rolling_average_30,rolling_average_60,rolling_average_90,remaining_balance
Group by CAPACITY_BALANCE;
