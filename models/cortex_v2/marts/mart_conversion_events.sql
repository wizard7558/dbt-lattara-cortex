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
 * Conversion Events Mart
 *
 * Aggregates conversion events to campaign-day-event level for efficient
 * KPI selection and dashboard queries.
 *
 * Clustered by user_id for efficient multi-tenant filtering.
 *
 * App queries should always filter by user_id:
 * SELECT * FROM mart_conversion_events
 * WHERE user_id = 'abc123'
 *   AND date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
 *   AND event_name = 'Purchase'
 */

WITH conversions AS (
  SELECT * FROM {{ ref('int_all_conversions_unified') }}
  WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL 18 MONTH)  -- 18 month retention
),

-- Aggregate to campaign-day-event level
aggregated AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    platform,
    date,
    event_name,

    -- Aggregated metrics
    SUM(event_count) AS event_count,
    SUM(event_value) AS event_value,

    -- Count distinct ads with this conversion (when available)
    COUNT(DISTINCT CASE WHEN ad_id != '' THEN ad_id END) AS ad_count,

    -- Metadata
    CURRENT_TIMESTAMP() AS _dbt_loaded_at

  FROM conversions
  GROUP BY
    user_id,
    account_id,
    campaign_id,
    platform,
    date,
    event_name
)

SELECT
  user_id,
  account_id,
  campaign_id,
  platform,
  date,
  event_name,
  event_count,
  event_value,
  ad_count,

  -- Calculated metrics
  SAFE_DIVIDE(event_value, event_count) AS avg_value_per_event,

  _dbt_loaded_at

FROM aggregated
WHERE event_count > 0
