
  
    

    create or replace table `res-analytics`.`com_allied`.`accounts`
        
  (
    id STRING,
    name STRING,
    ad_network_id STRING,
    product_id STRING,
    organization_id STRING,
    kpi_1 STRING,
    kpi_2 STRING,
    kpi_3 STRING,
    kpi_4 STRING,
    kpi_5 STRING,
    kpi_6 STRING,
    kpi_7 STRING,
    kpi_8 STRING,
    kpi_9 STRING,
    kpi_10 STRING
    
    )

      
    
    

    
    OPTIONS()
    as (
      
    select id, name, ad_network_id, product_id, organization_id, kpi_1, kpi_2, kpi_3, kpi_4, kpi_5, kpi_6, kpi_7, kpi_8, kpi_9, kpi_10
    from (
        


WITH facebook_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),


google_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),



linkedin_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),



tiktok_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

all_accounts AS (
  SELECT
    CONCAT('facebook_ads_', id) AS id,
    name AS name,
    'facebook_ads' AS ad_network_id,
    CAST(NULL AS STRING) AS product_id,
    CAST('allied-empty' AS STRING) AS organization_id,
    CAST(NULL AS STRING) AS kpi_1,
    CAST(NULL AS STRING) AS kpi_2,
    CAST(NULL AS STRING) AS kpi_3,
    CAST(NULL AS STRING) AS kpi_4,
    CAST(NULL AS STRING) AS kpi_5,
    CAST(NULL AS STRING) AS kpi_6,
    CAST(NULL AS STRING) AS kpi_7,
    CAST(NULL AS STRING) AS kpi_8,
    CAST(NULL AS STRING) AS kpi_9,
    CAST(NULL AS STRING) AS kpi_10
  FROM facebook_latest
  WHERE rn = 1

  UNION ALL

  SELECT
    CONCAT('google_ads_', id) AS id,
    name AS name,
    'google_ads' AS ad_network_id,
    CAST(NULL AS STRING) AS product_id,
    CAST('allied-empty' AS STRING) AS organization_id,
    CAST(NULL AS STRING) AS kpi_1,
    CAST(NULL AS STRING) AS kpi_2,
    CAST(NULL AS STRING) AS kpi_3,
    CAST(NULL AS STRING) AS kpi_4,
    CAST(NULL AS STRING) AS kpi_5,
    CAST(NULL AS STRING) AS kpi_6,
    CAST(NULL AS STRING) AS kpi_7,
    CAST(NULL AS STRING) AS kpi_8,
    CAST(NULL AS STRING) AS kpi_9,
    CAST(NULL AS STRING) AS kpi_10
  FROM google_latest
  WHERE rn = 1

  UNION ALL

  SELECT
    CONCAT('linkedin_ads_', id) AS id,
    name AS name,
    'linkedin_ads' AS ad_network_id,
    CAST(NULL AS STRING) AS product_id,
    CAST('allied-empty' AS STRING) AS organization_id,
    CAST(NULL AS STRING) AS kpi_1,
    CAST(NULL AS STRING) AS kpi_2,
    CAST(NULL AS STRING) AS kpi_3,
    CAST(NULL AS STRING) AS kpi_4,
    CAST(NULL AS STRING) AS kpi_5,
    CAST(NULL AS STRING) AS kpi_6,
    CAST(NULL AS STRING) AS kpi_7,
    CAST(NULL AS STRING) AS kpi_8,
    CAST(NULL AS STRING) AS kpi_9,
    CAST(NULL AS STRING) AS kpi_10
  FROM linkedin_latest
  WHERE rn = 1

  UNION ALL

  SELECT
    CONCAT('tiktok_ads_', id) AS id,
    name AS name,
    'tiktok_ads' AS ad_network_id,
    CAST(NULL AS STRING) AS product_id,
    CAST('allied-empty' AS STRING) AS organization_id,
    CAST(NULL AS STRING) AS kpi_1,
    CAST(NULL AS STRING) AS kpi_2,
    CAST(NULL AS STRING) AS kpi_3,
    CAST(NULL AS STRING) AS kpi_4,
    CAST(NULL AS STRING) AS kpi_5,
    CAST(NULL AS STRING) AS kpi_6,
    CAST(NULL AS STRING) AS kpi_7,
    CAST(NULL AS STRING) AS kpi_8,
    CAST(NULL AS STRING) AS kpi_9,
    CAST(NULL AS STRING) AS kpi_10
  FROM tiktok_latest
  WHERE rn = 1
)

SELECT * FROM all_accounts
    ) as model_subq
    );
  