{{
  config(
    materialized='incremental',
    unique_key='id',
    on_schema_change='fail',
    database=var("bq_project_id"),
    schema=var("bq_dataset_id"),
  )
}}

{% set facebook_ad_set_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_facebook_ads",
      identifier="ad_set_history"
) %}
WITH facebook_adset_latest AS (
  {% if facebook_ad_set_history is not none %}
  SELECT
    id,
    name,
    campaign_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_time DESC) AS rn
  FROM {{ facebook_ad_set_history }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

facebook_adsets AS (
  SELECT
    id,
    name,
    campaign_id
  FROM facebook_adset_latest
  WHERE rn = 1
),


{% set google_ad_group_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_google_ads",
      identifier="ad_group_history"
) %}
google_adgroup_latest AS (
  {% if google_ad_group_history is not none %}
  SELECT
    id,
    name,
    campaign_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) AS rn
  FROM {{ google_ad_group_history }}
  WHERE _fivetran_active = TRUE
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

google_adsets AS (
  SELECT
    id,
    name,
    campaign_id
  FROM google_adgroup_latest
  WHERE rn = 1
),

{% set linkedin_campaign_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_linkedin_ads",
      identifier="campaign_history"
) %}
linkedin_campaign_latest AS (
  {% if linkedin_campaign_history is not none %}
  SELECT
    id,
    name,
    campaign_group_id as campaign_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_time DESC) AS rn
  FROM {{ linkedin_campaign_history }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

linkedin_adsets AS (
  SELECT
    id,
    name,
    campaign_id
  FROM linkedin_campaign_latest
  WHERE rn = 1
),

{% set tiktok_adgroup_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_tiktok_ads",
      identifier="adgroup_history"
) %}
tiktok_adgroup_latest AS (
  {% if tiktok_adgroup_history is not none %}
  SELECT
    adgroup_id AS id,
    adgroup_name AS name,
    campaign_id,
    ROW_NUMBER() OVER (PARTITION BY adgroup_id ORDER BY updated_at DESC) AS rn
  FROM {{ tiktok_adgroup_history }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

tiktok_adsets AS (
  SELECT
    id,
    name,
    campaign_id
  FROM tiktok_adgroup_latest
  WHERE rn = 1
),

{% set bing_ad_group_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_bing_ads",
      identifier="ad_group_history"
) %}
bing_adgroup_latest AS (
  {% if bing_ad_group_history is not none %}
  SELECT
    id,
    name,
    campaign_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY modified_time DESC) AS rn
  FROM {{ bing_ad_group_history }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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

{% set google_campaign_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_google_ads",
      identifier="campaign_history"
) %}
google_pmax_campaigns AS (
  {% if google_campaign_history is not none %}
  SELECT
    c.id,
    c.name,
    c.customer_id AS account_id
  FROM {{ google_campaign_history }} c
  WHERE c.advertising_channel_type = 'PERFORMANCE_MAX'
    AND c._fivetran_active = TRUE
  QUALIFY ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY c.updated_at DESC) = 1
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as account_id
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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
LEFT JOIN {{ ref('campaigns') }} c
  ON a.campaign_id = c.id

{% if is_incremental() %}
WHERE a.id NOT IN (SELECT id FROM {{ this }})
{% endif %}
