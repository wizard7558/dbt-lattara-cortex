
  
    

    create or replace table `res-analytics`.`com_allied`.`adsets`
        
  (
    id STRING,
    adset_name STRING,
    campaign_id STRING,
    ad_network_id STRING,
    account_id STRING,
    organization_id STRING,
    product_id STRING
    
    )

      
    
    

    
    OPTIONS()
    as (
      
    select id, adset_name, campaign_id, ad_network_id, account_id, organization_id, product_id
    from (
        


WITH facebook_adset_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

facebook_adsets AS (
  SELECT
    id,
    name,
    campaign_id
  FROM facebook_adset_latest
  WHERE rn = 1
),



google_adgroup_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

google_adsets AS (
  SELECT
    id,
    name,
    campaign_id
  FROM google_adgroup_latest
  WHERE rn = 1
),


linkedin_campaign_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

linkedin_adsets AS (
  SELECT
    id,
    name,
    campaign_id
  FROM linkedin_campaign_latest
  WHERE rn = 1
),


tiktok_adgroup_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

tiktok_adsets AS (
  SELECT
    id,
    name,
    campaign_id
  FROM tiktok_adgroup_latest
  WHERE rn = 1
),


bing_adgroup_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

bing_adsets AS (
  SELECT
    id,
    name,
    campaign_id
  FROM bing_adgroup_latest
  WHERE rn = 1
),

-- Google Performance Max synthetic adsets (PMax has no adset-level data, only campaign-level)


google_pmax_campaigns AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as account_id
  FROM (SELECT 1) WHERE FALSE
  
),

google_pmax_adsets AS (
  SELECT
    id,
    name,
    id AS campaign_id  -- For PMax, adset = campaign (synthetic)
  FROM google_pmax_campaigns
),

all_adsets AS (
  SELECT
    CONCAT('facebook_ads_', CAST(id AS STRING)) AS id,
    name AS adset_name,
    CONCAT('facebook_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    'facebook_ads' AS ad_network_id
  FROM facebook_adsets

  UNION ALL

  SELECT
    CONCAT('google_ads_', CAST(id AS STRING)) AS id,
    name AS adset_name,
    CONCAT('google_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    'google_ads' AS ad_network_id
  FROM google_adsets

  UNION ALL

  SELECT
    CONCAT('linkedin_ads_', CAST(id AS STRING)) AS id,
    name AS adset_name,
    CONCAT('linkedin_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    'linkedin_ads' AS ad_network_id
  FROM linkedin_adsets

  UNION ALL

  SELECT
    CONCAT('tiktok_ads_', CAST(id AS STRING)) AS id,
    name AS adset_name,
    CONCAT('tiktok_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    'tiktok_ads' AS ad_network_id
  FROM tiktok_adsets

  UNION ALL

  SELECT
    CONCAT('bingads_', CAST(id AS STRING)) AS id,
    name AS adset_name,
    CONCAT('bingads_', CAST(campaign_id AS STRING)) AS campaign_id,
    'bingads' AS ad_network_id
  FROM bing_adsets

  UNION ALL

  -- Google Performance Max synthetic adsets (campaign-level)
  SELECT
    CONCAT('google_ads_', CAST(id AS STRING), '_pmax') AS id,
    CONCAT(name, ' (PMax)') AS adset_name,
    CONCAT('google_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    'google_ads' AS ad_network_id
  FROM google_pmax_adsets
)

SELECT
  a.id,
  a.adset_name,
  a.campaign_id,
  a.ad_network_id,
  c.account_id,
  c.organization_id,
  c.product_id
FROM all_adsets a
LEFT JOIN `res-analytics`.`com_allied`.`campaigns` c
  ON a.campaign_id = c.id


    ) as model_subq
    );
  