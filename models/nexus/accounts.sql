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

-- The `product_id` and `kpi_1`..`kpi_10` columns on this table are owned by
-- the Cortex app, not by dbt. The app writes them via
-- `updateBigQueryAccountMappings()` in supabase/functions/accounts/index.ts
-- whenever a user configures an account in the UI.
--
-- Under a normal incremental run, `merge_update_columns = ['name']` protects
-- these app-owned columns because only `name` is overwritten in the MERGE.
-- BUT under `dbt run --full-refresh` (or `dbt build --full-refresh`) dbt
-- rebuilds the table from scratch via `CREATE OR REPLACE TABLE ... AS SELECT`,
-- and every column in the SELECT is taken literally — which meant
-- `kpi_1..kpi_10` and `product_id` were being reset to NULL every full refresh.
-- On 2026-04-08 this wiped custom KPI mappings for every org and broke the
-- dashboard (custom KPI columns showed empty labels with all-zero values).
--
-- The fix below reads the existing table (via `adapter.get_relation`) and
-- COALESCEs the app-owned columns into the rebuild, so full-refresh becomes
-- idempotent for app state. First-ever run is handled by the empty fallback.
{% set existing_accounts = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id"),
      identifier="accounts"
) %}

{% set facebook_account_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_facebook_dataset"),
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
      schema=var("source_google_dataset"),
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
      schema=var("source_linkedin_dataset"),
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
      schema=var("source_tiktok_dataset"),
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
),

existing_app_owned AS (
  {% if existing_accounts is not none %}
  SELECT
    id,
    product_id,
    kpi_1, kpi_2, kpi_3, kpi_4, kpi_5, kpi_6, kpi_7, kpi_8, kpi_9, kpi_10
  FROM {{ existing_accounts }}
  {% else %}
  SELECT
    CAST(NULL AS STRING) AS id,
    CAST(NULL AS STRING) AS product_id,
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
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
)

SELECT
  a.id,
  a.name,
  a.ad_network_id,
  a.organization_id,
  COALESCE(e.product_id, a.product_id) AS product_id,
  COALESCE(e.kpi_1,  a.kpi_1)  AS kpi_1,
  COALESCE(e.kpi_2,  a.kpi_2)  AS kpi_2,
  COALESCE(e.kpi_3,  a.kpi_3)  AS kpi_3,
  COALESCE(e.kpi_4,  a.kpi_4)  AS kpi_4,
  COALESCE(e.kpi_5,  a.kpi_5)  AS kpi_5,
  COALESCE(e.kpi_6,  a.kpi_6)  AS kpi_6,
  COALESCE(e.kpi_7,  a.kpi_7)  AS kpi_7,
  COALESCE(e.kpi_8,  a.kpi_8)  AS kpi_8,
  COALESCE(e.kpi_9,  a.kpi_9)  AS kpi_9,
  COALESCE(e.kpi_10, a.kpi_10) AS kpi_10
FROM all_accounts a
LEFT JOIN existing_app_owned e USING (id)
