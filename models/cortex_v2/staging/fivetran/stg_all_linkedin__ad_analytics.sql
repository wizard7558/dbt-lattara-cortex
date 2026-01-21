{{
  config(
    materialized='view'
  )
}}

/*
 * Unified LinkedIn Ads Analytics across all customers
 * Source: Fivetran ad_analytics_by_creative table
 *
 * LinkedIn hierarchy mapping to unified schema:
 * - Campaign Group = Campaign (parent container)
 * - Campaign = AdSet (targeting configuration)
 * - Creative = Ad (the actual ad content)
 *
 * This staging model unions the ad_analytics_by_creative table from all customer
 * Fivetran schemas, adding user_id extracted from the schema name pattern.
 */

WITH unioned AS (
  {{ union_all_schemas('LINKEDIN_ADS', 'ad_analytics_by_creative') }}
),

transformed AS (
  SELECT
    -- Extract user_id from schema name (cortex_{userId}_{platform})
    REGEXP_EXTRACT(source_schema, r'cortex_([^_]+)_') AS user_id,

    -- IDs (LinkedIn hierarchy: campaign_group = campaign, campaign = adset, creative = ad)
    CAST(account AS STRING) AS account_id,
    CAST(campaign_group_id AS STRING) AS campaign_id,
    CAST(campaign AS STRING) AS adset_id,
    CAST(creative_id AS STRING) AS ad_id,

    -- Date
    CAST(day AS DATE) AS date,

    -- Metrics
    COALESCE(impressions, 0) AS impressions,
    COALESCE(clicks, 0) AS clicks,
    COALESCE(clicks, 0) AS link_clicks,
    COALESCE(cost_in_local_currency, 0) AS spend,
    COALESCE(external_website_conversions, 0) AS conversions,
    COALESCE(conversion_value_in_local_currency, 0) AS conversion_value,

    -- Metadata
    'LINKEDIN_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at

  FROM unioned
  WHERE day IS NOT NULL
)

SELECT * FROM transformed
