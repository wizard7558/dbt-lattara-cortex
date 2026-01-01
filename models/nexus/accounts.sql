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

-- google_latest AS (
--   SELECT
--     CAST(id AS STRING) as id,
--     CAST(descriptive_name AS STRING) as name,
--     ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) AS rn
--   FROM {{ source('google_ads_v2', 'account_history') }}
--   WHERE _fivetran_active = TRUE
-- ),

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

all_accounts AS (
  SELECT
    CONCAT('facebook_ads_', id) AS id,
    name AS name,
    'facebook_ads' AS ad_network_id,
    CAST(NULL AS STRING) AS product_id,
    CAST(NULL AS STRING) AS organization_id,
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

--   UNION ALL

--   SELECT
--     CONCAT('google_ads_', id) AS id,
--     name AS name,
--     'google_ads' AS ad_network_id,
--     CAST(NULL AS STRING) AS product_id,
--     CAST(NULL AS STRING) AS organization_id,
--     CAST(NULL AS STRING) AS kpi_1,
--     CAST(NULL AS STRING) AS kpi_2,
--     CAST(NULL AS STRING) AS kpi_3,
--     CAST(NULL AS STRING) AS kpi_4,
--     CAST(NULL AS STRING) AS kpi_5,
--     CAST(NULL AS STRING) AS kpi_6,
--     CAST(NULL AS STRING) AS kpi_7,
--     CAST(NULL AS STRING) AS kpi_8,
--     CAST(NULL AS STRING) AS kpi_9,
--     CAST(NULL AS STRING) AS kpi_10
--   FROM google_latest
--   WHERE rn = 1

--   UNION ALL

--   SELECT
--     CONCAT('linkedin_ads_', id) AS id,
--     name AS name,
--     'linkedin_ads' AS ad_network_id,
--     CAST(NULL AS STRING) AS product_id,
--     CAST(NULL AS STRING) AS organization_id,
--     CAST(NULL AS STRING) AS kpi_1,
--     CAST(NULL AS STRING) AS kpi_2,
--     CAST(NULL AS STRING) AS kpi_3,
--     CAST(NULL AS STRING) AS kpi_4,
--     CAST(NULL AS STRING) AS kpi_5,
--     CAST(NULL AS STRING) AS kpi_6,
--     CAST(NULL AS STRING) AS kpi_7,
--     CAST(NULL AS STRING) AS kpi_8,
--     CAST(NULL AS STRING) AS kpi_9,
--     CAST(NULL AS STRING) AS kpi_10
--   FROM linkedin_latest
--   WHERE rn = 1

--   UNION ALL

--   SELECT
--     CONCAT('tiktok_ads_', id) AS id,
--     name AS name,
--     'tiktok_ads' AS ad_network_id,
--     CAST(NULL AS STRING) AS product_id,
--     CAST(NULL AS STRING) AS organization_id,
--     CAST(NULL AS STRING) AS kpi_1,
--     CAST(NULL AS STRING) AS kpi_2,
--     CAST(NULL AS STRING) AS kpi_3,
--     CAST(NULL AS STRING) AS kpi_4,
--     CAST(NULL AS STRING) AS kpi_5,
--     CAST(NULL AS STRING) AS kpi_6,
--     CAST(NULL AS STRING) AS kpi_7,
--     CAST(NULL AS STRING) AS kpi_8,
--     CAST(NULL AS STRING) AS kpi_9,
--     CAST(NULL AS STRING) AS kpi_10
--   FROM tiktok_latest
--   WHERE rn = 1
)

SELECT * FROM all_accounts