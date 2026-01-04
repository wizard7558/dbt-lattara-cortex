{{
  config(
    materialized='incremental',
    unique_key='id',
    schema='cortex'
  )
}}

WITH facebook_adset_latest AS (
  SELECT
    id,
    name,
    campaign_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_time DESC) AS rn
  FROM `facebook_ads.ad_set_history`
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
    id,
    name,
    campaign_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) AS rn
  FROM `google_ads_v2.ad_group_history`
  WHERE _fivetran_active = TRUE
),

google_adsets AS (
  SELECT
    id,
    name,
    campaign_id
  FROM google_adgroup_latest
  WHERE rn = 1
),

-- linkedin_campaign_latest AS (
--   SELECT
--     id,
--     name,
--     campaign_group_id,
--     ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_time DESC) AS rn
--   FROM `mavan-analytics.linkedin_ads.campaign_history`
-- ),

-- linkedin_adsets AS (
--   SELECT
--     id,
--     name,
--     campaign_group_id
--   FROM linkedin_campaign_latest
--   WHERE rn = 1
-- ),

-- tiktok_adgroup_latest AS (
--   SELECT
--     adgroup_id AS id,
--     adgroup_name AS name,
--     campaign_id,
--     ROW_NUMBER() OVER (PARTITION BY adgroup_id ORDER BY updated_at DESC) AS rn
--   FROM `mavan-analytics.tiktok_ads.adgroup_history`
-- ),

-- tiktok_adsets AS (
--   SELECT
--     id,
--     name,
--     campaign_id
--   FROM tiktok_adsets_latest
--   WHERE rn = 1
-- ),

-- bing_adgroup_latest AS (
--   SELECT
--     id,
--     name,
--     campaign_id,
--     ROW_NUMBER() OVER (PARTITION BY id ORDER BY modified_time DESC) AS rn
--   FROM `mavan-analytics.bingads.ad_group_history`
-- ),

-- bing_adsets AS (
--   SELECT
--     id,
--     name,
--     campaign_id
--   FROM bing_adgroup_latest
--   WHERE rn = 1
-- ),

-- Google Performance Max synthetic adsets (PMax has no adset-level data, only campaign-level)
google_pmax_campaigns AS (
  SELECT
    c.id,
    c.name,
    c.customer_id AS account_id
  FROM `google_ads_v2.campaign_history` c
  WHERE c.advertising_channel_type = 'PERFORMANCE_MAX'
    AND c._fivetran_active = TRUE
  QUALIFY ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY c.updated_at DESC) = 1
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

--   UNION ALL

--   SELECT
--     CONCAT('linkedin_ads_', CAST(id AS STRING)) AS id,
--     name AS adset_name,
--     CONCAT('linkedin_ads_', CAST(campaign_group_id AS STRING)) AS campaign_id,
--     'linkedin_ads' AS ad_network_id
--   FROM linkedin_adsets

--   UNION ALL

--   SELECT
--     CONCAT('tiktok_ads_', CAST(id AS STRING)) AS id,
--     name AS adset_name,
--     CONCAT('tiktok_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
--     'tiktok_ads' AS ad_network_id
--   FROM tiktok_adsets

--   UNION ALL

--   SELECT
--     CONCAT('bingads_', CAST(id AS STRING)) AS id,
--     name AS adset_name,
--     CONCAT('bingads_', CAST(campaign_id AS STRING)) AS campaign_id,
--     'bingads' AS ad_network_id
--   FROM bing_adsets

--   UNION ALL

--   -- Google Performance Max synthetic adsets (campaign-level)
--   SELECT
--     CONCAT('google_ads_', CAST(id AS STRING), '_pmax') AS id,
--     CONCAT(name, ' (PMax)') AS adset_name,
--     CONCAT('google_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
--     'google_ads' AS ad_network_id
--   FROM google_pmax_adsets
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
LEFT JOIN {{ ref('campaigns') }} c
  ON a.campaign_id = c.id

{% if is_incremental() %}
WHERE a.id NOT IN (SELECT id FROM {{ this }})
{% endif %}
