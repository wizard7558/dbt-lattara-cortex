{{
  config(
    materialized='incremental',
    unique_key='id',
    merge_update_columns = ['name'],
  )
}}

WITH facebook_latest AS (
  SELECT
    CAST(id AS STRING) as id,
    name as name,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) AS rn
  FROM `facebook_ads.account_history`
),

google_latest AS (
  SELECT
    CAST(id AS STRING) as id,
    CAST(descriptive_name AS STRING) as name,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) AS rn
  FROM `google_ads_v2.account_history`
  WHERE _fivetran_active = TRUE
),

-- linkedin_latest AS (
--   SELECT
--     CAST(id AS STRING) as id,
--     CAST(name AS STRING) as name,
--     ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_time DESC) AS rn
--   FROM {{ source('linkedin_ads', 'account_history') }}
-- ),

-- tiktok_latest AS (
--   SELECT
--     CAST(id AS STRING) as id,
--     CAST(name AS STRING) as name,
--     ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) AS rn
--   FROM {{ source('tiktok_ads', 'advertiser') }}
-- ),

-- Existing accounts table with KPI mappings set via Supabase/UI
existing_accounts AS (
  SELECT
    id,
    kpi_1,
    kpi_2,
    kpi_3,
    kpi_4,
    kpi_5,
    kpi_6,
    kpi_7,
    kpi_8,
    kpi_9,
    kpi_10
  FROM `cortex.accounts`
),

all_accounts AS (
  SELECT
    CONCAT('facebook_ads_', id) AS id,
    name AS name,
    'facebook_ads' AS ad_network_id
  FROM facebook_latest
  WHERE rn = 1

  UNION ALL

  SELECT
    CONCAT('google_ads_', id) AS id,
    name AS name,
    'google_ads' AS ad_network_id
  FROM google_latest
  WHERE rn = 1

--   UNION ALL

--   SELECT
--     CONCAT('linkedin_ads_', id) AS id,
--     name AS name,
--     'linkedin_ads' AS ad_network_id
--   FROM linkedin_latest
--   WHERE rn = 1

--   UNION ALL

--   SELECT
--     CONCAT('tiktok_ads_', id) AS id,
--     name AS name,
--     'tiktok_ads' AS ad_network_id
--   FROM tiktok_latest
--   WHERE rn = 1
)

SELECT 
    aa.id,
    aa.name,
    aa.ad_network_id,
    prod.id as product_id,
    prod.organization_id,
    ea.kpi_1,
    ea.kpi_2,
    ea.kpi_3,
    ea.kpi_4,
    ea.kpi_5,
    ea.kpi_6,
    ea.kpi_7,
    ea.kpi_8,
    ea.kpi_9,
    ea.kpi_10
FROM all_accounts aa
LEFT JOIN `cortex.products` prod
  ON aa.name = prod.account
  AND aa.ad_network_id = prod.ad_network_id
LEFT JOIN existing_accounts ea
  ON aa.id = ea.id
