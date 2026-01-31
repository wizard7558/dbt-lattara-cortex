{{
  config(
    materialized='incremental',
    unique_key='id',
    database=var("bq_project_id"),
    schema=var("bq_dataset_id"),
  )
}}


{% set facebook_ad_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_facebook_ads",
      identifier="ad_history"
) %}
WITH facebook_ad_latest AS (
  {% if facebook_ad_history is not none %}
  SELECT
    id,
    name,
    ad_set_id as adset_id,
    campaign_id,
    creative_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_time DESC) AS rn
  FROM {{ facebook_ad_history }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS STRING) as creative_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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

{% set google_ad_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_google_ads",
      identifier="ad_history"
) %}
{% set google_ad_group_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_google_ads",
      identifier="ad_group_history"
) %}
google_ad_latest AS (
  {% if google_ad_history is not none and google_ad_group_history is not none %}
  SELECT
    ad.id,
    ad.name,
    ad.ad_group_id AS adset_id,
    ag.campaign_id,
    ROW_NUMBER() OVER (PARTITION BY ad.id ORDER BY ad.updated_at DESC) AS rn
  FROM {{ google_ad_history }} ad
  INNER JOIN {{ google_ad_group_history }} ag
    ON ad.ad_group_id = ag.id
    AND ag._fivetran_active = TRUE
  WHERE ad._fivetran_active = TRUE
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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


{% set linkedin_creative_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_linkedin_ads",
      identifier="creative_history"
) %}
{% set linkedin_campaign_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_linkedin_ads",
      identifier="campaign_history"
) %}
linkedin_creative_latest AS (
  {% if linkedin_creative_history is not none and linkedin_campaign_history is not none %}
  SELECT
    cr.id,
    cr.name,
    cr.campaign_id as adset_id,
    c.campaign_group_id as campaign_id,
    ROW_NUMBER() OVER (PARTITION BY cr.id ORDER BY cr.last_modified_at DESC) AS rn
  FROM {{ linkedin_creative_history }} cr
  INNER JOIN {{ linkedin_campaign_history }} c
    ON cr.campaign_id = c.id
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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


{% set tiktok_ad_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_tiktok_ads",
      identifier="ad_history"
) %}
tiktok_ad_latest AS (
  {% if tiktok_ad_history is not none %}
  SELECT
    ad_id AS id,
    ad_name AS name,
    adgroup_id AS adset_id,
    campaign_id,
    ROW_NUMBER() OVER (PARTITION BY ad_id ORDER BY updated_at DESC) AS rn
  FROM {{ tiktok_ad_history }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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

{% set bing_ad_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_bing_ads",
      identifier="ad_history"
) %}
{% set bing_ad_group_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_bing_ads",
      identifier="ad_group_history"
) %}
bing_ad_latest AS (
  {% if bing_ad_history is not none and bing_ad_group_history is not none %}
  SELECT
    ad.id,
    ad.title AS name,
    ad.ad_group_id AS adset_id,
    ag.campaign_id,
    ROW_NUMBER() OVER (PARTITION BY ad.id ORDER BY ad.modified_time DESC) AS rn
  FROM {{ bing_ad_history }} ad
  INNER JOIN {{ bing_ad_group_history }} ag
    ON ad.ad_group_id = ag.id
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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
LEFT JOIN {{ ref('campaigns') }} c
  ON a.campaign_id = c.id

{% if is_incremental() %}
WHERE a.id NOT IN (SELECT id FROM {{ this }})
{% endif %}
