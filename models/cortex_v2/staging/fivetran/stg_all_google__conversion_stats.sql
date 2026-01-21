{{
  config(
    materialized='view'
  )
}}

/*
 * Unified Google Ads Conversion Stats across all customers
 * Source: Fivetran campaign_conversion_action_stats table joined with conversion_action
 *
 * This staging model unions conversion data from all customer Fivetran schemas,
 * joining with conversion_action table to get human-readable conversion names.
 *
 * Google stores conversions as FLOAT64 for data-driven attribution (fractional).
 *
 * Conversion categories are normalized to standard event names:
 * - PURCHASE -> Purchase
 * - LEAD -> Lead
 * - SIGNUP -> Registration
 * - ADD_TO_CART -> AddToCart
 * - Others use conversion_action.name as event_name
 */

WITH conversion_stats_unioned AS (
  {{ union_all_schemas('GOOGLE_ADS', 'campaign_conversion_action_stats') }}
),

conversion_actions_unioned AS (
  {{ union_all_schemas('GOOGLE_ADS', 'conversion_action') }}
),

-- Join conversion stats with conversion actions to get names and categories
joined AS (
  SELECT
    -- Extract user_id from schema name (cortex_{userId}_{platform})
    REGEXP_EXTRACT(cs.source_schema, r'cortex_([^_]+)_') AS user_id,

    -- IDs
    CAST(cs.customer_id AS STRING) AS account_id,
    CAST(cs.campaign_id AS STRING) AS campaign_id,

    -- Date
    CAST(cs.date AS DATE) AS date,

    -- Conversion details
    CAST(cs.conversion_action_id AS STRING) AS conversion_action_id,
    ca.name AS conversion_action_name,
    ca.category AS conversion_category,

    -- Normalize conversion category to standard event names
    CASE
      WHEN ca.category = 'PURCHASE' THEN 'Purchase'
      WHEN ca.category = 'LEAD' THEN 'Lead'
      WHEN ca.category = 'SIGNUP' THEN 'Registration'
      WHEN ca.category = 'ADD_TO_CART' THEN 'AddToCart'
      WHEN ca.category = 'BEGIN_CHECKOUT' THEN 'InitiateCheckout'
      WHEN ca.category = 'PAGE_VIEW' THEN 'ViewContent'
      WHEN ca.category = 'CONTACT' THEN 'Contact'
      WHEN ca.category = 'SUBSCRIBE_PAID' THEN 'Subscribe'
      WHEN ca.category = 'DOWNLOAD' THEN 'Download'
      WHEN ca.category = 'BOOK_APPOINTMENT' THEN 'BookAppointment'
      WHEN ca.category = 'REQUEST_QUOTE' THEN 'RequestQuote'
      WHEN ca.category = 'GET_DIRECTIONS' THEN 'GetDirections'
      WHEN ca.category = 'OUTBOUND_CLICK' THEN 'OutboundClick'
      ELSE COALESCE(ca.name, 'CustomConversion')
    END AS event_name,

    -- Metrics (Google uses FLOAT64 for data-driven attribution)
    COALESCE(cs.conversions, 0) AS event_count,
    COALESCE(cs.conversions_value, 0) AS event_value,

    -- Metadata
    'GOOGLE_ADS' AS platform,
    cs.source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at

  FROM conversion_stats_unioned cs
  LEFT JOIN conversion_actions_unioned ca
    ON cs.conversion_action_id = ca.id
    AND cs.source_schema = ca.source_schema  -- Same customer schema
  WHERE cs.date IS NOT NULL
)

SELECT * FROM joined
