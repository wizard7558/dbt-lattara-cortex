{{
  config(
    materialized='table',
    partition_by={
      "field": "date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=['user_id', 'account_id', 'platform']
  )
}}

/*
 * Daily KPI metrics at ad level
 *
 * This is the primary table for Cortex app dashboards.
 * Clustered by user_id for efficient multi-tenant queries.
 *
 * App queries should always filter by user_id:
 * SELECT * FROM mart_kpi_daily WHERE user_id = 'abc123' AND date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
 */

WITH base AS (
  SELECT * FROM {{ ref('int_all_ads_unified') }}
),

-- Aggregate to campaign-day level for dashboard performance
campaign_daily AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    platform,
    date,

    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks,
    SUM(link_clicks) AS link_clicks,
    SUM(spend) AS spend,
    SUM(conversions) AS conversions,
    SUM(conversion_value) AS conversion_value,

    -- Recalculate metrics at aggregated level
    SAFE_DIVIDE(SUM(link_clicks), SUM(impressions)) * 100 AS ctr,
    SAFE_DIVIDE(SUM(spend), SUM(link_clicks)) AS cpc,
    SAFE_DIVIDE(SUM(spend), SUM(impressions)) * 1000 AS cpm,
    SAFE_DIVIDE(SUM(spend), SUM(conversions)) AS cpa,
    SAFE_DIVIDE(SUM(conversion_value), SUM(spend)) AS roas

  FROM base
  GROUP BY user_id, account_id, campaign_id, platform, date
)

SELECT
  -- Primary keys for filtering
  user_id,
  account_id,
  campaign_id,
  platform,
  date,

  -- Volume metrics
  impressions,
  clicks,
  link_clicks,
  spend,
  conversions,
  conversion_value,

  -- Efficiency metrics
  ctr,
  cpc,
  cpm,
  cpa,
  roas,

  -- Metadata
  CURRENT_TIMESTAMP() AS _dbt_updated_at

FROM campaign_daily
WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL 18 MONTH)  -- 18 month retention
