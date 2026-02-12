{{
  config(
    materialized='view'
  )
}}

/*
 * Unified TikTok Ads Report across all customers
 * Source: Fivetran ad_report_daily table
 *
 * This staging model unions the ad_report_daily table from all customer
 * Fivetran schemas, adding user_id extracted from the schema name pattern.
 */

{% set schemas = get_customer_schemas('TIKTOK_ADS') %}
{% if schemas | length > 0 %}

WITH unioned AS (
  {{ union_all_schemas('TIKTOK_ADS', 'ad_report_daily') }}
),

transformed AS (
  SELECT
    -- Extract user_id from schema name (cortex_{userId}_{platform})
    REGEXP_EXTRACT(source_schema, r'cortex_([^_]+)_') AS user_id,

    -- IDs
    CAST(advertiser_id AS STRING) AS account_id,
    CAST(campaign_id AS STRING) AS campaign_id,
    CAST(adgroup_id AS STRING) AS adset_id,
    CAST(ad_id AS STRING) AS ad_id,

    -- Date
    CAST(stat_time_day AS DATE) AS date,

    -- Metrics
    COALESCE(impressions, 0) AS impressions,
    COALESCE(clicks, 0) AS clicks,
    COALESCE(clicks, 0) AS link_clicks,
    COALESCE(spend, 0) AS spend,
    COALESCE(complete_payment, 0) AS conversions,
    COALESCE(complete_payment_value, 0) AS conversion_value,

    -- Metadata
    'TIKTOK_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at

  FROM unioned
  WHERE stat_time_day IS NOT NULL
)

SELECT * FROM transformed

{% else %}

SELECT
  CAST(NULL AS STRING) AS user_id,
  CAST(NULL AS STRING) AS account_id,
  CAST(NULL AS STRING) AS campaign_id,
  CAST(NULL AS STRING) AS adset_id,
  CAST(NULL AS STRING) AS ad_id,
  CAST(NULL AS DATE) AS date,
  CAST(0 AS INT64) AS impressions,
  CAST(0 AS INT64) AS clicks,
  CAST(0 AS INT64) AS link_clicks,
  CAST(0 AS FLOAT64) AS spend,
  CAST(0 AS FLOAT64) AS conversions,
  CAST(0 AS FLOAT64) AS conversion_value,
  CAST('TIKTOK_ADS' AS STRING) AS platform,
  CAST(NULL AS STRING) AS source_schema,
  CAST(NULL AS TIMESTAMP) AS _dbt_loaded_at
FROM (SELECT 1) WHERE FALSE

{% endif %}
