{{
  config(
    materialized='view'
  )
}}

/*
 * Unified TikTok Ads Conversions across all customers
 * Source: Fivetran ad_report_daily table
 *
 * TikTok stores standard conversion events as dedicated columns:
 * - complete_payment -> Purchase (with value)
 * - registration -> Registration
 * - add_to_cart -> AddToCart
 * - initiate_checkout -> InitiateCheckout
 * - product_details_page_browse -> ViewContent
 *
 * This staging model unpivots these columns to rows for unified format.
 */

{% set schemas = get_customer_schemas('TIKTOK_ADS') %}
{% if schemas | length > 0 %}

WITH unioned AS (
  {{ union_all_schemas('TIKTOK_ADS', 'ad_report_daily') }}
),

-- Extract user_id and base fields
base AS (
  SELECT
    -- Extract user_id from schema name (cortex_{userId}_{platform})
    REGEXP_EXTRACT(source_schema, r'cortex_([^_]+)_') AS user_id,

    -- IDs
    CAST(advertiser_id AS STRING) AS account_id,
    CAST(campaign_id AS STRING) AS campaign_id,
    CAST(adgroup_id AS STRING) AS adset_id,
    CAST(ad_id AS STRING) AS ad_id,

    -- Date
    CAST(stat_time_day AS DATE) AS date,

    -- Standard conversion columns for unpivoting
    COALESCE(complete_payment, 0) AS complete_payment,
    COALESCE(complete_payment_value, 0) AS complete_payment_value,
    COALESCE(registration, 0) AS registration,
    COALESCE(add_to_cart, 0) AS add_to_cart,
    COALESCE(initiate_checkout, 0) AS initiate_checkout,
    COALESCE(product_details_page_browse, 0) AS product_details_page_browse,

    -- Metadata
    source_schema

  FROM unioned
  WHERE stat_time_day IS NOT NULL
),

-- Unpivot conversion types to rows
-- Purchase: complete_payment with value
purchase AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    'Purchase' AS event_name,
    complete_payment AS event_count,
    complete_payment_value AS event_value,
    'TIKTOK_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at
  FROM base
  WHERE complete_payment > 0
),

-- Registration
registration AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    'Registration' AS event_name,
    registration AS event_count,
    0 AS event_value,
    'TIKTOK_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at
  FROM base
  WHERE registration > 0
),

-- AddToCart
add_to_cart AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    'AddToCart' AS event_name,
    add_to_cart AS event_count,
    0 AS event_value,
    'TIKTOK_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at
  FROM base
  WHERE add_to_cart > 0
),

-- InitiateCheckout
initiate_checkout AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    'InitiateCheckout' AS event_name,
    initiate_checkout AS event_count,
    0 AS event_value,
    'TIKTOK_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at
  FROM base
  WHERE initiate_checkout > 0
),

-- ViewContent: product_details_page_browse
view_content AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    'ViewContent' AS event_name,
    product_details_page_browse AS event_count,
    0 AS event_value,
    'TIKTOK_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at
  FROM base
  WHERE product_details_page_browse > 0
),

-- Union all conversion types
unified AS (
  SELECT * FROM purchase
  UNION ALL
  SELECT * FROM registration
  UNION ALL
  SELECT * FROM add_to_cart
  UNION ALL
  SELECT * FROM initiate_checkout
  UNION ALL
  SELECT * FROM view_content
)

SELECT * FROM unified

{% else %}

SELECT
  CAST(NULL AS STRING) AS user_id,
  CAST(NULL AS STRING) AS account_id,
  CAST(NULL AS STRING) AS campaign_id,
  CAST(NULL AS STRING) AS adset_id,
  CAST(NULL AS STRING) AS ad_id,
  CAST(NULL AS DATE) AS date,
  CAST(NULL AS STRING) AS event_name,
  CAST(0 AS FLOAT64) AS event_count,
  CAST(0 AS FLOAT64) AS event_value,
  CAST('TIKTOK_ADS' AS STRING) AS platform,
  CAST(NULL AS STRING) AS source_schema,
  CAST(NULL AS TIMESTAMP) AS _dbt_loaded_at
FROM (SELECT 1) WHERE FALSE

{% endif %}
