{{
  config(
    materialized='view'
  )
}}

/*
 * Unified Meta Ads Actions (conversions) across all customers
 * Source: Fivetran basic_ad_actions table
 *
 * This staging model unions the basic_ad_actions table from all customer
 * Fivetran schemas, adding user_id extracted from the schema name pattern.
 *
 * Action types are normalized to standard event names:
 * - purchase -> Purchase
 * - lead -> Lead
 * - complete_registration -> Registration
 * - add_to_cart -> AddToCart
 * - initiate_checkout -> InitiateCheckout
 * - view_content -> ViewContent
 * - offsite_conversion.fb_pixel_* -> Custom conversion (keep original name)
 */

{#- Check if any schema has the basic_ad_actions table -#}
{% set schemas = get_customer_schemas('META_ADS') %}
{% set ns = namespace(has_table=false) %}
{% if schemas | length > 0 and execute %}
  {% for schema in schemas %}
    {% if not ns.has_table %}
      {% set rel = adapter.get_relation(database=var('gcp_project'), schema=schema, identifier='basic_ad_actions') %}
      {% if rel is not none %}
        {% set ns.has_table = true %}
      {% endif %}
    {% endif %}
  {% endfor %}
{% endif %}

{% if ns.has_table %}

WITH unioned AS (
  {{ union_all_schemas('META_ADS', 'basic_ad_actions') }}
),

transformed AS (
  SELECT
    -- Extract user_id from schema name (cortex_{userId}_{platform})
    REGEXP_EXTRACT(source_schema, r'cortex_([^_]+)_') AS user_id,

    -- IDs
    CAST(account_id AS STRING) AS account_id,
    CAST(campaign_id AS STRING) AS campaign_id,
    CAST(adset_id AS STRING) AS adset_id,
    CAST(ad_id AS STRING) AS ad_id,

    -- Date
    CAST(date AS DATE) AS date,

    -- Original action type
    action_type,

    -- Normalize action_type to standard event names
    CASE
      WHEN action_type = 'purchase' THEN 'Purchase'
      WHEN action_type = 'lead' THEN 'Lead'
      WHEN action_type = 'complete_registration' THEN 'Registration'
      WHEN action_type = 'add_to_cart' THEN 'AddToCart'
      WHEN action_type = 'initiate_checkout' THEN 'InitiateCheckout'
      WHEN action_type = 'view_content' THEN 'ViewContent'
      WHEN action_type = 'add_payment_info' THEN 'AddPaymentInfo'
      WHEN action_type = 'search' THEN 'Search'
      WHEN action_type = 'contact' THEN 'Contact'
      WHEN action_type = 'subscribe' THEN 'Subscribe'
      WHEN action_type = 'start_trial' THEN 'StartTrial'
      WHEN action_type LIKE 'offsite_conversion.fb_pixel_%' THEN
        REPLACE(REPLACE(action_type, 'offsite_conversion.fb_pixel_', ''), '_', ' ')
      ELSE action_type
    END AS event_name,

    -- Counts and values
    COALESCE(value, 0) AS event_count,
    COALESCE(_1_d_click, 0) AS event_count_1d_click,
    COALESCE(_7_d_click, 0) AS event_count_7d_click,
    COALESCE(action_value_1_d_click, 0) AS event_value_1d,
    COALESCE(action_value_7_d_click, 0) AS event_value_7d,

    -- Metadata
    'META_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at

  FROM unioned
  WHERE action_type IS NOT NULL
    AND date IS NOT NULL
)

SELECT * FROM transformed

{% else %}

SELECT
  CAST(NULL AS STRING) AS user_id,
  CAST(NULL AS STRING) AS account_id,
  CAST(NULL AS STRING) AS campaign_id,
  CAST(NULL AS STRING) AS adset_id,
  CAST(NULL AS STRING) AS ad_id,
  CAST(NULL AS DATE) AS date,
  CAST(NULL AS STRING) AS action_type,
  CAST(NULL AS STRING) AS event_name,
  CAST(0 AS FLOAT64) AS event_count,
  CAST(0 AS FLOAT64) AS event_count_1d_click,
  CAST(0 AS FLOAT64) AS event_count_7d_click,
  CAST(0 AS FLOAT64) AS event_value_1d,
  CAST(0 AS FLOAT64) AS event_value_7d,
  CAST('META_ADS' AS STRING) AS platform,
  CAST(NULL AS STRING) AS source_schema,
  CAST(NULL AS TIMESTAMP) AS _dbt_loaded_at
FROM (SELECT 1) WHERE FALSE

{% endif %}
