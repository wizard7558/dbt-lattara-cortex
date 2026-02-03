



WITH facebook_ad_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS STRING) as creative_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

facebook_ads AS (
  SELECT
    id,
    name,
    adset_id,
    campaign_id,
    creative_id
  FROM facebook_ad_latest
  WHERE rn = 1
),



google_ad_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

google_ads AS (
  SELECT
    id,
    name,
    adset_id,
    campaign_id
  FROM google_ad_latest
  WHERE rn = 1
),




linkedin_creative_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

linkedin_ads AS (
  SELECT
    id,
    name,
    adset_id,
    campaign_id
  FROM linkedin_creative_latest
  WHERE rn = 1
),



tiktok_ad_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

tiktok_ads AS (
  SELECT
    id,
    name,
    adset_id,
    campaign_id
  FROM tiktok_ad_latest
  WHERE rn = 1
),



bing_ad_latest AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  
),

bing_ads AS (
  SELECT
    id,
    name,
    adset_id,
    campaign_id
  FROM bing_ad_latest
  WHERE rn = 1
),

-- Google Performance Max synthetic ads (PMax has no ad-level data, only campaign-level)


google_pmax_campaigns AS (
  
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as account_id
  FROM (SELECT 1) WHERE FALSE
  
),

google_pmax_ads AS (
  SELECT
    id,
    name,
    id AS adset_id,  -- For PMax, adset = campaign (synthetic)
    id AS campaign_id
  FROM google_pmax_campaigns
),

all_ads AS (
  SELECT
    CONCAT('facebook_ads_', CAST(id AS STRING)) AS id,
    name AS ad_name,
    CONCAT('facebook_ads_', CAST(adset_id AS STRING)) AS adset_id,
    CONCAT('facebook_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    CONCAT('facebook_ads_', CAST(creative_id AS STRING)) AS creative_id,
    'facebook_ads' AS ad_network_id
  FROM facebook_ads

  UNION ALL

  SELECT
    CONCAT('google_ads_', CAST(id AS STRING)) AS id,
    name AS ad_name,
    CONCAT('google_ads_', CAST(adset_id AS STRING)) AS adset_id,
    CONCAT('google_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    CAST(NULL AS STRING) AS creative_id,
    'google_ads' AS ad_network_id
  FROM google_ads

  UNION ALL

  SELECT
    CONCAT('linkedin_ads_', CAST(id AS STRING)) AS id,
    name AS ad_name,
    CONCAT('linkedin_ads_', CAST(adset_id AS STRING)) AS adset_id,
    CONCAT('linkedin_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    CAST(NULL AS STRING) AS creative_id,
    'linkedin_ads' AS ad_network_id
  FROM linkedin_ads

  UNION ALL

  SELECT
    CONCAT('tiktok_ads_', CAST(id AS STRING)) AS id,
    name AS ad_name,
    CONCAT('tiktok_ads_', CAST(adset_id AS STRING)) AS adset_id,
    CONCAT('tiktok_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    CAST(NULL AS STRING) AS creative_id,
    'tiktok_ads' AS ad_network_id
  FROM tiktok_ads

  UNION ALL

  SELECT
    CONCAT('bingads_', CAST(id AS STRING)) AS id,
    name AS ad_name,
    CONCAT('bingads_', CAST(adset_id AS STRING)) AS adset_id,
    CONCAT('bingads_', CAST(campaign_id AS STRING)) AS campaign_id,
    CAST(NULL AS STRING) AS creative_id,
    'bingads' AS ad_network_id
  FROM bing_ads

  UNION ALL

  -- Google Performance Max synthetic ads (campaign-level)
  SELECT
    CONCAT('google_ads_', CAST(id AS STRING), '_pmax') AS id,
    CONCAT(name, ' (PMax)') AS ad_name,
    CONCAT('google_ads_', CAST(adset_id AS STRING), '_pmax') AS adset_id,
    CONCAT('google_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    CAST(NULL AS STRING) AS creative_id,
    'google_ads' AS ad_network_id
  FROM google_pmax_ads
)

SELECT
  a.id,
  a.ad_name,
  a.adset_id,
  a.campaign_id,
  a.creative_id,
  a.ad_network_id,
  c.account_id,
  c.organization_id,
  c.product_id
FROM all_ads a
LEFT JOIN `res-analytics`.`com_allied`.`campaigns` c
  ON a.campaign_id = c.id

