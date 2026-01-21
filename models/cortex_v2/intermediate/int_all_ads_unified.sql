{{
  config(
    materialized='view'
  )
}}

/*
 * Unified ad metrics across all platforms and all customers
 * This is the foundation for all analytics queries
 */

WITH meta AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    impressions,
    clicks,
    link_clicks,
    spend,
    0 AS conversions,
    0.0 AS conversion_value,
    platform
  FROM {{ ref('stg_all_meta__ads_insights') }}
),

google AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    impressions,
    clicks,
    link_clicks,
    spend,
    conversions,
    conversion_value,
    platform
  FROM {{ ref('stg_all_google__ad_stats') }}
),

linkedin AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    impressions,
    clicks,
    link_clicks,
    spend,
    conversions,
    conversion_value,
    platform
  FROM {{ ref('stg_all_linkedin__ad_analytics') }}
),

tiktok AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    impressions,
    clicks,
    link_clicks,
    spend,
    conversions,
    conversion_value,
    platform
  FROM {{ ref('stg_all_tiktok__ad_report') }}
),

-- Note: Bing is keyword-level, handle separately or include with NULL ad_id
-- Omitting for now as it's a different grain

unioned AS (
  SELECT * FROM meta
  UNION ALL
  SELECT * FROM google
  UNION ALL
  SELECT * FROM linkedin
  UNION ALL
  SELECT * FROM tiktok
)

SELECT
  user_id,
  account_id,
  campaign_id,
  adset_id,
  ad_id,
  date,
  impressions,
  clicks,
  link_clicks,
  spend,
  conversions,
  conversion_value,
  platform,

  -- Calculated metrics
  SAFE_DIVIDE(link_clicks, impressions) * 100 AS ctr,
  SAFE_DIVIDE(spend, link_clicks) AS cpc,
  SAFE_DIVIDE(spend, impressions) * 1000 AS cpm,
  SAFE_DIVIDE(spend, conversions) AS cpa,
  SAFE_DIVIDE(conversion_value, spend) AS roas

FROM unioned
