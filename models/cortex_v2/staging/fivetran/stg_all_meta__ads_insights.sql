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
 *
 * Note: ads_insights is a Fivetran custom report at Ad level. Custom reports
 * only include the level identifier (ad_id) and metrics — not the hierarchy
 * IDs (account_id, campaign_id, adset_id). We derive those from ad_history.
 */

WITH unioned AS (
  {{ union_all_schemas('META_ADS', 'ads_insights') }}
),

-- Get latest ad record per ad to derive hierarchy IDs
-- (ad_history has account_id, campaign_id, ad_set_id)
ad_dim AS (
  SELECT
    source_schema,
    CAST(id AS STRING) AS ad_id,
    CAST(account_id AS STRING) AS account_id,
    CAST(campaign_id AS STRING) AS campaign_id,
    CAST(ad_set_id AS STRING) AS adset_id,
    ROW_NUMBER() OVER (PARTITION BY source_schema, id ORDER BY updated_time DESC) AS rn
  FROM ({{ union_all_schemas('META_ADS', 'ad_history') }})
),

ad_latest AS (
  SELECT source_schema, ad_id, account_id, campaign_id, adset_id
  FROM ad_dim
  WHERE rn = 1
),

transformed AS (
  SELECT
    -- Extract user_id from schema name (cortex_{userId}_{platform})
    REGEXP_EXTRACT(u.source_schema, r'cortex_([^_]+)_') AS user_id,

    -- IDs (hierarchy from ad_history, ad_id from insights)
    a.account_id,
    a.campaign_id,
    a.adset_id,
    CAST(u.ad_id AS STRING) AS ad_id,

    -- Date
    CAST(u.date AS DATE) AS date,

    -- Metrics
    COALESCE(u.impressions, 0) AS impressions,
    COALESCE(u.clicks, 0) AS clicks,
    COALESCE(u.inline_link_clicks, u.clicks, 0) AS link_clicks,  -- Prefer inline_link_clicks
    COALESCE(u.spend, 0) AS spend,
    COALESCE(u.reach, 0) AS reach,

    -- Metadata
    'META_ADS' AS platform,
    u.source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at

  FROM unioned u
  LEFT JOIN ad_latest a
    ON u.source_schema = a.source_schema
    AND CAST(u.ad_id AS STRING) = a.ad_id
  WHERE u.date IS NOT NULL
)

SELECT * FROM transformed
