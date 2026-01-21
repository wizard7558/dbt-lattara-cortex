{{
  config(
    materialized='table',
    cluster_by=['user_id', 'account_id']
  )
}}

/*
 * Campaign dimension table with metadata
 * Provides campaign names, status, and other attributes
 */

-- TODO: Join with Fivetran campaign_history tables for metadata
-- For now, extract distinct campaigns from metrics

WITH campaigns_from_metrics AS (
  SELECT DISTINCT
    user_id,
    account_id,
    campaign_id,
    platform
  FROM {{ ref('int_all_ads_unified') }}
),

-- Add placeholder columns for campaign attributes
-- These will be populated when we add campaign_history tables
enriched AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    platform,
    NULL AS campaign_name,  -- TODO: join from campaign_history
    NULL AS status,         -- TODO: join from campaign_history
    NULL AS objective,      -- TODO: join from campaign_history
    CURRENT_TIMESTAMP() AS _dbt_updated_at
  FROM campaigns_from_metrics
)

SELECT * FROM enriched
