{{
  config(
    materialized='incremental',
    unique_key='id',
    schema='cortex'
  )
}}

WITH facebook_campaign_latest AS (
  SELECT
    id,
    name,
    account_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_time DESC) AS rn
  FROM `facebook_ads.campaign_history`
),

facebook_account_latest AS (
  SELECT
    id,
    name,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) AS rn
  FROM `facebook_ads.account_history`
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
    id,
    name,
    customer_id AS account_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) AS rn
  FROM `google_ads_v2.campaign_history`
  WHERE _fivetran_active = TRUE
),

google_account_latest AS (
  SELECT
    id,
    descriptive_name,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) AS rn
  FROM `google_ads_v2.account_history`
  WHERE _fivetran_active = TRUE
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

-- -- LinkedIn hierarchy: Campaign Group = Nexus Campaign, Campaign = Nexus AdSet
-- -- Using campaign_group_history as the source for campaigns (not campaign_history)
-- linkedin_campaign_group_latest AS (
--   SELECT
--     id,
--     name,
--     account_id,
--     ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_time DESC) AS rn
--   FROM {{ source('linkedin_ads', 'campaign_group_history') }}
-- ),

-- linkedin_account_latest AS (
--   SELECT
--     id,
--     name,
--     ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_time DESC) AS rn
--   FROM {{ source('linkedin_ads', 'account_history') }}
-- ),

-- linkedin_campaigns AS (
--   SELECT
--     cg.id,
--     cg.name,
--     a.id AS account_id
--   FROM linkedin_campaign_group_latest cg
--   INNER JOIN linkedin_account_latest a
--     ON cg.account_id = a.id
--     AND a.rn = 1
--   WHERE cg.rn = 1
-- ),

-- tiktok_campaign_latest AS (
--   SELECT
--     campaign_id AS id,
--     campaign_name AS name,
--     advertiser_id AS account_id,
--     ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY updated_at DESC) AS rn
--   FROM {{ source('tiktok_ads', 'campaign_history') }}
-- ),

-- tiktok_account_latest AS (
--   SELECT
--     id,
--     name,
--     ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) AS rn
--   FROM {{ source('tiktok_ads', 'advertiser') }}
-- ),

-- tiktok_campaigns AS (
--   SELECT
--     c.id,
--     c.name,
--     a.id AS account_id
--   FROM tiktok_campaign_latest c
--   INNER JOIN tiktok_account_latest a
--     ON c.account_id = a.id
--     AND a.rn = 1
--   WHERE c.rn = 1
-- ),

-- bing_campaign_latest AS (
--   SELECT
--     id,
--     name,
--     account_id,
--     ROW_NUMBER() OVER (PARTITION BY id ORDER BY modified_time DESC) AS rn
--   FROM {{ source('bingads', 'campaign_history') }}
-- ),

-- bing_account_latest AS (
--   SELECT
--     id,
--     name,
--     ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_time DESC) AS rn
--   FROM {{ source('bingads', 'account_history') }}
-- ),

-- bing_campaigns AS (
--   SELECT
--     c.id,
--     c.name,
--     a.id AS account_id
--   FROM bing_campaign_latest c
--   INNER JOIN bing_account_latest a
--     ON c.account_id = a.id
--     AND a.rn = 1
--   WHERE c.rn = 1
-- ),

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

--   UNION ALL

--   SELECT
--     CONCAT('linkedin_ads_', CAST(id AS STRING)) AS id,
--     name AS campaign_name,
--     CONCAT('linkedin_ads_', account_id) AS account_id,
--     'linkedin_ads' AS ad_network_id
--   FROM linkedin_campaigns

--   UNION ALL

--   SELECT
--     CONCAT('tiktok_ads_', CAST(id AS STRING)) AS id,
--     name AS campaign_name,
--     CONCAT('tiktok_ads_', account_id) AS account_id,
--     'tiktok_ads' AS ad_network_id
--   FROM tiktok_campaigns

--   UNION ALL

--   SELECT
--     CONCAT('bingads_', CAST(id AS STRING)) AS id,
--     name AS campaign_name,
--     CONCAT('bingads_', account_id) AS account_id,
--     'bingads' AS ad_network_id
--   FROM bing_campaigns
)


SELECT
  c.id,
  c.campaign_name,
  c.account_id,
  c.ad_network_id,
  a.product_id,
  a.organization_id
FROM all_campaigns c
LEFT JOIN {{ ref('accounts') }} a
  ON c.account_id = a.id

{% if is_incremental() %}
WHERE c.id NOT IN (SELECT id FROM {{ this }})
{% endif %}