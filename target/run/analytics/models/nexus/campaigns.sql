
  
    

    create or replace table `res-analytics`.`com_allied`.`campaigns`
        
  (
    id STRING,
    campaign_name STRING,
    account_id STRING,
    ad_network_id STRING,
    product_id STRING,
    organization_id STRING
    
    )

      
    
    

    
    OPTIONS()
    as (
      
    select id, campaign_name, account_id, ad_network_id, product_id, organization_id
    from (
        


WITH facebook_campaign_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),


facebook_account_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

facebook_campaigns AS (
  SELECT
    c.id,
    c.name,
    a.id AS account_id
  FROM facebook_campaign_latest c
  INNER JOIN facebook_account_latest a
    ON c.account_id = a.id
    AND a.rn = 1
  WHERE c.rn = 1
),


google_campaign_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),


google_account_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

google_campaigns AS (
  SELECT
    c.id,
    c.name,
    a.id AS account_id
  FROM google_campaign_latest c
  INNER JOIN google_account_latest a
    ON c.account_id = a.id
    AND a.rn = 1
  WHERE c.rn = 1
),

-- LinkedIn hierarchy: Campaign Group = Nexus Campaign, Campaign = Nexus AdSet
-- Using campaign_group_history as the source for campaigns (not campaign_history)


linkedin_campaign_group_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),


linkedin_account_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

linkedin_campaigns AS (
  SELECT
    cg.id,
    cg.name,
    a.id AS account_id
  FROM linkedin_campaign_group_latest cg
  INNER JOIN linkedin_account_latest a
    ON cg.account_id = a.id
    AND a.rn = 1
  WHERE cg.rn = 1
),


tiktok_campaign_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),


tiktok_account_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

tiktok_campaigns AS (
  SELECT
    c.id,
    c.name,
    a.id AS account_id
  FROM tiktok_campaign_latest c
  INNER JOIN tiktok_account_latest a
    ON c.account_id = a.id
    AND a.rn = 1
  WHERE c.rn = 1
),

all_campaigns AS (
  SELECT
    CONCAT('facebook_ads_', CAST(id AS STRING)) AS id,
    name AS campaign_name,
    CONCAT('facebook_ads_', account_id) AS account_id,
    'facebook_ads' AS ad_network_id
  FROM facebook_campaigns

  UNION ALL

  SELECT
    CONCAT('google_ads_', CAST(id AS STRING)) AS id,
    name AS campaign_name,
    CONCAT('google_ads_', account_id) AS account_id,
    'google_ads' AS ad_network_id
  FROM google_campaigns

  UNION ALL

  SELECT
    CONCAT('linkedin_ads_', CAST(id AS STRING)) AS id,
    name AS campaign_name,
    CONCAT('linkedin_ads_', account_id) AS account_id,
    'linkedin_ads' AS ad_network_id
  FROM linkedin_campaigns

  UNION ALL

  SELECT
    CONCAT('tiktok_ads_', CAST(id AS STRING)) AS id,
    name AS campaign_name,
    CONCAT('tiktok_ads_', account_id) AS account_id,
    'tiktok_ads' AS ad_network_id
  FROM tiktok_campaigns
)

SELECT
  c.id,
  c.campaign_name,
  c.account_id,
  c.ad_network_id,
  a.product_id,
  a.organization_id
FROM all_campaigns c
LEFT JOIN `res-analytics`.`com_allied`.`accounts` a
  ON c.account_id = a.id


    ) as model_subq
    );
  