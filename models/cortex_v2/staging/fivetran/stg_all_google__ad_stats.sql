{{
  config(
    materialized='view'
  )
}}

/*
 * Unified Google Ads Stats across all customers
 * Source: Fivetran keyword_stats table (daily keyword-level metrics)
 *
 * Google Ads uses keyword-level reporting (not ad-level like Meta/LinkedIn).
 * This staging model unions keyword_stats from all customer Fivetran schemas.
 *
 * Key transformation: Convert cost_micros to dollars (Google stores cost in micros).
 */

WITH unioned AS (
  {{ union_all_schemas('GOOGLE_ADS', 'keyword_stats') }}
),

transformed AS (
  SELECT
    -- Extract user_id from schema name (cortex_{userId}_{platform})
    REGEXP_EXTRACT(source_schema, r'cortex_([^_]+)_') AS user_id,

    -- IDs (Google uses INT64 IDs)
    CAST(customer_id AS STRING) AS account_id,
    CAST(campaign_id AS STRING) AS campaign_id,
    CAST(ad_group_id AS STRING) AS adset_id,  -- Normalize to adset_id
    CAST(ad_group_criterion_criterion_id AS STRING) AS ad_id,  -- keyword criterion_id as ad_id equivalent

    -- Date
    CAST(date AS DATE) AS date,

    -- Metrics
    COALESCE(impressions, 0) AS impressions,
    COALESCE(clicks, 0) AS clicks,
    COALESCE(clicks, 0) AS link_clicks,  -- Google clicks are link clicks
    COALESCE(cost_micros, 0) / 1000000.0 AS spend,  -- Convert micros to dollars
    COALESCE(conversions, 0) AS conversions,
    COALESCE(conversions_value, 0) AS conversion_value,

    -- Metadata
    'GOOGLE_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at

  FROM unioned
  WHERE date IS NOT NULL
)

SELECT * FROM transformed
