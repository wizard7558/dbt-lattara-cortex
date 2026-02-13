{{
  config(
    materialized='incremental',
    unique_key='id',
    on_schema_change='fail',
    database=var("bq_project_id"),
    schema=var("bq_dataset_id"),
  )
}}

{% set facebook_campaign_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_facebook_dataset"),
      identifier="campaign_history"
) %}
WITH facebook_campaign_latest AS (
  {% if facebook_campaign_history is not none %}
  SELECT
    id,
    name,
    account_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_time DESC) AS rn
  FROM {{ facebook_campaign_history }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

{% set facebook_account_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_facebook_dataset"),
      identifier="account_history"
) %}
facebook_account_latest AS (
  {% if facebook_account_history %}
  SELECT
    id,
    name,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) AS rn
  FROM {{ facebook_account_history }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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

{% set google_campaign_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_google_dataset"),
      identifier="campaign_history"
) %}
google_campaign_latest AS (
  {% if google_campaign_history is not none %}
  SELECT
    id,
    name,
    customer_id AS account_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) AS rn
  FROM {{ google_campaign_history }}
  WHERE _fivetran_active = TRUE
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

{% set google_account_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_google_dataset"),
      identifier="account_history"
) %}
google_account_latest AS (
  {% if google_account_history is not none %}
  SELECT
    id,
    descriptive_name as name,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) AS rn
  FROM {{ google_account_history }}
  WHERE _fivetran_active = TRUE
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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

{% set linkedin_campaign_group_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_linkedin_dataset"),
      identifier="campaign_group_history"
) %}
linkedin_campaign_group_latest AS (
  {% if linkedin_campaign_group_history is not none %}
  SELECT
    id,
    name,
    account_id,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_time DESC) AS rn
  FROM {{ linkedin_campaign_group_history }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

{% set linkedin_account_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_linkedin_dataset"),
      identifier="account_history"
) %}
linkedin_account_latest AS (
  {% if linkedin_account_history is not none %}
  SELECT
    id,
    name,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_time DESC) AS rn
  FROM {{ linkedin_account_history }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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

{% set tiktok_campaign_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_tiktok_dataset"),
      identifier="campaign_history"
) %}
tiktok_campaign_latest AS (
  {% if tiktok_campaign_history %}
  SELECT
    campaign_id AS id,
    campaign_name AS name,
    advertiser_id AS account_id,
    ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY updated_at DESC) AS rn
  FROM {{ tiktok_campaign_history }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

{% set tiktok_advertiser = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_tiktok_dataset"),
      identifier="advertiser"
) %}
tiktok_account_latest AS (
  {% if tiktok_advertiser is not none %}
  SELECT
    id,
    name,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) AS rn
  FROM {{ tiktok_advertiser }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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
LEFT JOIN {{ ref('accounts') }} a
  ON c.account_id = a.id

{% if is_incremental() %}
WHERE c.id NOT IN (SELECT id FROM {{ this }})
{% endif %}
