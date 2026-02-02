{{
  config(
    materialized='incremental',
    unique_key='id',
    merge_update_columns = ['name'],
    on_schema_change='fail',
    database=var("bq_project_id"),
    schema=var("bq_dataset_id"),
  )
}}

{% set facebook_account_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_facebook_ads",
      identifier="account_history"
) %}
WITH facebook_latest AS (
  {% if facebook_account_history is not none %}
  SELECT
    CAST(id AS STRING) as id,
    name as name,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY _fivetran_synced DESC) AS rn
  FROM {{facebook_account_history}}
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

{% set google_account_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_google_ads",
      identifier="account_history"
) %}
google_latest AS (
  {% if google_account_history is not none %}
  SELECT
    CAST(id AS STRING) as id,
    CAST(descriptive_name AS STRING) as name,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) AS rn
  FROM {{google_account_history}}
  WHERE _fivetran_active = TRUE
  {% else %}
  SELECT
    CAST(NULL AS STRING) as id,
    CAST(NULL AS STRING) as name,
    CAST(NULL AS INT64) as rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),


{% set linkedin_account_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_linkedin_ads",
      identifier="account_history"
) %}
linkedin_latest AS (
  {% if linkedin_account_history is not none %}
  SELECT
    CAST(id AS STRING) as id,
    CAST(name AS STRING) as name,
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


{% set tiktok_advertiser = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_tiktok_ads",
      identifier="advertiser"
) %}
tiktok_latest AS (
  {% if tiktok_advertiser is not none %}
  SELECT
    CAST(id AS STRING) as id,
    CAST(name AS STRING) as name,
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

all_accounts AS (
  SELECT
    CONCAT('facebook_ads_', id) AS id,
    name AS name,
    'facebook_ads' AS ad_network_id,
    CAST(NULL AS STRING) AS product_id,
    CAST('{{ var("organization_id") }}' AS STRING) AS organization_id,
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

  UNION ALL

  SELECT
    CONCAT('google_ads_', id) AS id,
    name AS name,
    'google_ads' AS ad_network_id,
    CAST(NULL AS STRING) AS product_id,
    CAST('{{ var("organization_id") }}' AS STRING) AS organization_id,
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
  FROM google_latest
  WHERE rn = 1

  UNION ALL

  SELECT
    CONCAT('linkedin_ads_', id) AS id,
    name AS name,
    'linkedin_ads' AS ad_network_id,
    CAST(NULL AS STRING) AS product_id,
    CAST('{{ var("organization_id") }}' AS STRING) AS organization_id,
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
  FROM linkedin_latest
  WHERE rn = 1

  UNION ALL

  SELECT
    CONCAT('tiktok_ads_', id) AS id,
    name AS name,
    'tiktok_ads' AS ad_network_id,
    CAST(NULL AS STRING) AS product_id,
    CAST('{{ var("organization_id") }}' AS STRING) AS organization_id,
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
  FROM tiktok_latest
  WHERE rn = 1
)

SELECT * FROM all_accounts
