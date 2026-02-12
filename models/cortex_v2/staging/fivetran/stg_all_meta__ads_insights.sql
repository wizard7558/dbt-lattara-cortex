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
 * Note: ads_insights is a Fivetran custom report at Ad level, which doesn't
 * include account_id as a column. We derive it from ad_history via schema join.
 */

WITH unioned AS (
  {{ union_all_schemas('META_ADS', 'ads_insights') }}
),

-- ads_insights custom report doesn't include account_id;
-- derive it from ad_history (one account per Fivetran schema)
ad_accounts AS (
  SELECT DISTINCT
    source_schema,
    CAST(account_id AS STRING) AS account_id
  FROM ({{ union_all_schemas('META_ADS', 'ad_history') }})
),

transformed AS (
  SELECT
    -- Extract user_id from schema name (cortex_{userId}_{platform})
    REGEXP_EXTRACT(u.source_schema, r'cortex_([^_]+)_') AS user_id,

    -- IDs (account_id from ad_history join)
    aa.account_id,
    CAST(u.campaign_id AS STRING) AS campaign_id,
    CAST(u.adset_id AS STRING) AS adset_id,
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
  LEFT JOIN ad_accounts aa ON u.source_schema = aa.source_schema
  WHERE u.date IS NOT NULL
)

SELECT * FROM transformed
