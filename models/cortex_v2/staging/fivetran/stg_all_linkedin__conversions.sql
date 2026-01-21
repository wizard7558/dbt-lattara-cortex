{{
  config(
    materialized='view'
  )
}}

/*
 * Unified LinkedIn Ads Conversions across all customers
 * Source: Fivetran ad_analytics_by_creative table
 *
 * LinkedIn provides conversion metrics at the creative (ad) level:
 * - external_website_conversions: Total external conversions
 * - lead_generation_mail_contact_info_shares: Lead gen form submissions
 * - one_click_leads: One-click lead submissions
 * - landing_page_clicks: Clicks to landing page (ViewContent proxy)
 *
 * LinkedIn hierarchy mapping to unified schema:
 * - Campaign Group = Campaign (parent container)
 * - Campaign = AdSet (targeting configuration)
 * - Creative = Ad (the actual ad content)
 *
 * This staging model unpivots conversion columns to rows for unified format.
 */

WITH unioned AS (
  {{ union_all_schemas('LINKEDIN_ADS', 'ad_analytics_by_creative') }}
),

-- Extract user_id and base fields
base AS (
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

    -- Conversion metrics for unpivoting
    COALESCE(external_website_conversions, 0) AS external_website_conversions,
    COALESCE(lead_generation_mail_contact_info_shares, 0) + COALESCE(one_click_leads, 0) AS lead_conversions,
    COALESCE(landing_page_clicks, 0) AS landing_page_clicks,
    COALESCE(conversion_value_in_local_currency, 0) AS conversion_value,

    -- Metadata
    source_schema

  FROM unioned
  WHERE day IS NOT NULL
),

-- Unpivot conversion types to rows
-- ExternalConversions: Total external website conversions
external_conversions AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    'ExternalConversions' AS event_name,
    external_website_conversions AS event_count,
    conversion_value AS event_value,
    'LINKEDIN_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at
  FROM base
  WHERE external_website_conversions > 0
),

-- Lead: Lead gen form submissions
lead_conversions AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    'Lead' AS event_name,
    lead_conversions AS event_count,
    0 AS event_value,
    'LINKEDIN_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at
  FROM base
  WHERE lead_conversions > 0
),

-- ViewContent: Landing page clicks as content view proxy
view_content AS (
  SELECT
    user_id,
    account_id,
    campaign_id,
    adset_id,
    ad_id,
    date,
    'ViewContent' AS event_name,
    landing_page_clicks AS event_count,
    0 AS event_value,
    'LINKEDIN_ADS' AS platform,
    source_schema,
    CURRENT_TIMESTAMP() AS _dbt_loaded_at
  FROM base
  WHERE landing_page_clicks > 0
),

-- Union all conversion types
unified AS (
  SELECT * FROM external_conversions
  UNION ALL
  SELECT * FROM lead_conversions
  UNION ALL
  SELECT * FROM view_content
)

SELECT * FROM unified
