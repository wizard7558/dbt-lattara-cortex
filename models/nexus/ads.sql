{{
  config(
    materialized='incremental',
    unique_key='id',
    schema='nexus'
  )
}}

WITH facebook_ad_latest AS (
  SELECT
    id,
    name,
    ad_set_id,
    campaign_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_time DESC) AS rn
  FROM `mavan-analytics.facebook_ads_v2.ad_history`
),

facebook_ads AS (
  SELECT
    id,
    name,
    ad_set_id AS adset_id,
    campaign_id
  FROM facebook_ad_latest
  WHERE rn = 1
),

google_ad_latest AS (
  SELECT
    ad.id,
    ad.name,
    ad.ad_group_id AS adset_id,
    ag.campaign_id,
    ROW_NUMBER() OVER (PARTITION BY ad.id ORDER BY ad.updated_at DESC) AS rn
  FROM `mavan-analytics.google_ads_v2.ad_history` ad
  INNER JOIN `mavan-analytics.google_ads_v2.ad_group_history` ag
    ON ad.ad_group_id = ag.id
    AND ag._fivetran_active = TRUE
  WHERE ad._fivetran_active = TRUE
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
    cr.id,
    cr.name,
    cr.campaign_id,
    c.campaign_group_id,
    ROW_NUMBER() OVER (PARTITION BY cr.id ORDER BY cr.last_modified_at DESC) AS rn
  FROM `mavan-analytics.linkedin_ads.creative_history` cr
  INNER JOIN `mavan-analytics.linkedin_ads.campaign_history` c
    ON cr.campaign_id = c.id
),

linkedin_ads AS (
  SELECT
    id,
    name,
    campaign_id,
    campaign_group_id
  FROM linkedin_creative_latest
  WHERE rn = 1
),

tiktok_ad_latest AS (
  SELECT
    ad_id AS id,
    ad_name AS name,
    adgroup_id AS adset_id,
    campaign_id,
    ROW_NUMBER() OVER (PARTITION BY ad_id ORDER BY updated_at DESC) AS rn
  FROM `mavan-analytics.tiktok_ads.ad_history`
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
    ad.id,
    ad.title AS name,
    ad.ad_group_id AS adset_id,
    ag.campaign_id,
    ROW_NUMBER() OVER (PARTITION BY ad.id ORDER BY ad.modified_time DESC) AS rn
  FROM `mavan-analytics.bingads.ad_history` ad
  INNER JOIN `mavan-analytics.bingads.ad_group_history` ag
    ON ad.ad_group_id = ag.id
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
    c.id,
    c.name,
    c.customer_id AS account_id
  FROM `mavan-analytics.google_ads_v2.campaign_history` c
  WHERE c.advertising_channel_type = 'PERFORMANCE_MAX'
    AND c._fivetran_active = TRUE
  QUALIFY ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY c.updated_at DESC) = 1
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
    'facebook_ads' AS ad_network_id
  FROM facebook_ads

  UNION ALL

  SELECT
    CONCAT('google_ads_', CAST(id AS STRING)) AS id,
    name AS ad_name,
    CONCAT('google_ads_', CAST(adset_id AS STRING)) AS adset_id,
    CONCAT('google_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    'google_ads' AS ad_network_id
  FROM google_ads

  UNION ALL

  SELECT
    CONCAT('linkedin_ads_', CAST(id AS STRING)) AS id,
    name AS ad_name,
    CONCAT('linkedin_ads_', CAST(campaign_id AS STRING)) AS adset_id,
    CONCAT('linkedin_ads_', CAST(campaign_group_id AS STRING)) AS campaign_id,
    'linkedin_ads' AS ad_network_id
  FROM linkedin_ads

  UNION ALL

  SELECT
    CONCAT('tiktok_ads_', CAST(id AS STRING)) AS id,
    name AS ad_name,
    CONCAT('tiktok_ads_', CAST(adset_id AS STRING)) AS adset_id,
    CONCAT('tiktok_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    'tiktok_ads' AS ad_network_id
  FROM tiktok_ads

  UNION ALL

  SELECT
    CONCAT('bingads_', CAST(id AS STRING)) AS id,
    name AS ad_name,
    CONCAT('bingads_', CAST(adset_id AS STRING)) AS adset_id,
    CONCAT('bingads_', CAST(campaign_id AS STRING)) AS campaign_id,
    'bingads' AS ad_network_id
  FROM bing_ads

  UNION ALL

  -- Google Performance Max synthetic ads (campaign-level)
  SELECT
    CONCAT('google_ads_', CAST(id AS STRING), '_pmax') AS id,
    CONCAT(name, ' (PMax)') AS ad_name,
    CONCAT('google_ads_', CAST(adset_id AS STRING), '_pmax') AS adset_id,
    CONCAT('google_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
    'google_ads' AS ad_network_id
  FROM google_pmax_ads
)

SELECT
  a.id,
  a.ad_name,
  a.adset_id,
  a.campaign_id,
  a.ad_network_id,
  c.account_id,
  c.organization_id,
  c.product_id
FROM all_ads a
LEFT JOIN {{ ref('campaigns') }} c
  ON a.campaign_id = c.id

{% if is_incremental() %}
WHERE a.id NOT IN (SELECT id FROM {{ this }})
{% endif %}