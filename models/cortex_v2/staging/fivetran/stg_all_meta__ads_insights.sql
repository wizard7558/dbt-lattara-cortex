{{
  config(
    materialized='view'
  )
}}

/*
 * Unified Meta Ads Insights across all customers
 * Uses inline_link_clicks for accurate link click tracking (not total clicks which includes engagement)
 *
 * This staging model unions the ads_insights table from all customer
 * Fivetran schemas, adding user_id extracted from the schema name pattern.
 */

WITH unioned AS (
  {{ union_all_schemas('META_ADS', 'ads_insights') }}
),

transformed AS (
  SELECT
    -- Extract user_id from schema name (cortex_{userId}_{platform})
    REGEXP_EXTRACT(source_schema, r'cortex_([^_]+)_') AS user_id,

    -- IDs
    CAST(account_id AS STRING) AS account_id,
    CAST(campaign_id AS STRING) AS campaign_id,
    CAST(adset_id AS STRING) AS adset_id,
    CAST(ad_id AS STRING) AS ad_id,

    -- Date
    CAST(date AS DATE) AS date,

    -- Metrics
    COALESCE(impressions, 0) AS impressions,
    COALESCE(clicks, 0) AS clicks,
    COALESCE(inline_link_clicks, clicks, 0) AS link_clicks,  -- Prefer inline_link_clicks
    COALESCE(spend, 0) AS spend,
    COALESCE(reach, 0) AS reach,

    -- Metadata
    'META_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at

  FROM unioned
  WHERE date IS NOT NULL
)

SELECT * FROM transformed
