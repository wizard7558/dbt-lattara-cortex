{{
  config(
    materialized='view'
  )
}}

/*
 * Unified conversion events across all platforms and all customers
 *
 * This intermediate model unions conversion data from Meta, Google, LinkedIn,
 * and TikTok with standardized event names and consistent schema.
 *
 * Standard event names:
 * - Purchase: Completed purchase/transaction
 * - Lead: Lead form submission
 * - Registration: Account signup/registration
 * - AddToCart: Added item to cart
 * - InitiateCheckout: Started checkout process
 * - ViewContent: Viewed product/content page
 * - Contact: Contact form submission or call
 * - Subscribe: Subscription signup
 * - ExternalConversions: External website conversions (LinkedIn)
 * - CustomConversion: Platform-specific custom events
 *
 * All queries should filter by user_id for multi-tenant isolation.
 */

WITH meta_conversions AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    event_name,
    event_count,
    COALESCE(event_value_7d, event_value_1d, 0) AS event_value,  -- Prefer 7d attribution
    platform,
    source_schema,
    _dbt_loaded_at
  FROM {{ ref('stg_all_meta__ad_actions') }}
),

google_conversions AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    '' AS adset_id,  -- Google conversion stats don't have adset/ad level
    '' AS ad_id,
    date,
    event_name,
    event_count,
    event_value,
    platform,
    source_schema,
    _dbt_loaded_at
  FROM {{ ref('stg_all_google__conversion_stats') }}
),

linkedin_conversions AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    event_name,
    event_count,
    event_value,
    platform,
    source_schema,
    _dbt_loaded_at
  FROM {{ ref('stg_all_linkedin__conversions') }}
),

tiktok_conversions AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    event_name,
    event_count,
    event_value,
    platform,
    source_schema,
    _dbt_loaded_at
  FROM {{ ref('stg_all_tiktok__conversions') }}
),

-- Union all platform conversions
unified AS (
  SELECT * FROM meta_conversions
  UNION ALL
  SELECT * FROM google_conversions
  UNION ALL
  SELECT * FROM linkedin_conversions
  UNION ALL
  SELECT * FROM tiktok_conversions
)

SELECT
  user_id,
  account_id,
  campaign_id,
  adset_id,
  ad_id,
  date,
  event_name,
  event_count,
  event_value,
  platform,
  source_schema,
  _dbt_loaded_at
FROM unified
WHERE event_count > 0  -- Only include rows with actual conversions
