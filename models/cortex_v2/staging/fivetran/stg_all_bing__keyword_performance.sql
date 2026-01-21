{{
  config(
    materialized='view'
  )
}}

/*
 * Unified Microsoft/Bing Ads Keyword Performance across all customers
 * Source: Fivetran keyword_performance_daily_report table
 *
 * This staging model unions the keyword_performance_daily_report table from all customer
 * Fivetran schemas, adding user_id extracted from the schema name pattern.
 *
 * Note: Bing uses keyword-level reporting, so ad_id is replaced with keyword_id.
 */

WITH unioned AS (
  {{ union_all_schemas('MICROSOFT_ADS', 'keyword_performance_daily_report') }}
),

transformed AS (
  SELECT
    -- Extract user_id from schema name (cortex_{userId}_{platform})
    REGEXP_EXTRACT(source_schema, r'cortex_([^_]+)_') AS user_id,

    -- IDs
    CAST(account_id AS STRING) AS account_id,
    CAST(campaign_id AS STRING) AS campaign_id,
    CAST(ad_group_id AS STRING) AS adset_id,
    CAST(keyword_id AS STRING) AS keyword_id,  -- Bing uses keyword-level, not ad-level

    -- Date
    CAST(date AS DATE) AS date,

    -- Metrics
    COALESCE(impressions, 0) AS impressions,
    COALESCE(clicks, 0) AS clicks,
    COALESCE(clicks, 0) AS link_clicks,
    COALESCE(spend, 0) AS spend,
    COALESCE(conversions, 0) AS conversions,
    COALESCE(revenue, 0) AS conversion_value,

    -- Metadata
    'MICROSOFT_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at

  FROM unioned
  WHERE date IS NOT NULL
)

SELECT * FROM transformed
