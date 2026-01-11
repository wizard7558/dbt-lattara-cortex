

-- Unified campaign-level geographic performance across all ad networks
-- Phase 1: TikTok + Bing (ready)
-- Phase 2: Facebook + Google (custom reports)
-- Phase 3: LinkedIn (monthly-to-daily WEIGHTED distribution)
--
-- Note: LinkedIn geo data is ESTIMATED using weighted distribution based on actual
-- daily campaign spend patterns. This reduces estimation error by ~69% vs uniform.
-- Check is_estimated column to identify estimated vs actual data

-- WITH tiktok_geo AS (
--     -- TikTok: country_code is ISO format, just needs LOWER()
--     -- Note: Only includes campaigns with explicit geo targeting (~20-100% coverage)
--     SELECT
--         DATE(stat_time_day) AS date,
--         CONCAT('tiktok_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
--         LOWER(country_code) AS country_code,
--         COALESCE(spend, 0) AS spend,
--         COALESCE(impressions, 0) AS impressions,
--         COALESCE(clicks, 0) AS clicks,
--         COALESCE(conversion, 0) AS conversions,
--         FALSE AS is_estimated
--     FROM {{ source('tiktok_ads', 'campaign_country_report') }}
--     WHERE country_code IS NOT NULL
--       AND country_code != 'None'
-- ),

-- bing_geo AS (
--     -- Bing: country is full name, needs mapping via seed
--     -- Aggregates away device_type, device_os, network, goal dimensions
--     SELECT
--         date_day AS date,
--         CONCAT('bingads_', CAST(b.campaign_id AS STRING)) AS campaign_id,
--         cc.country_code,
--         SUM(COALESCE(b.spend, 0)) AS spend,
--         SUM(COALESCE(b.impressions, 0)) AS impressions,
--         SUM(COALESCE(b.clicks, 0)) AS clicks,
--         SUM(COALESCE(b.conversions, 0)) AS conversions,
--         FALSE AS is_estimated
--     FROM {{ source('bingads_microsoft_ads', 'microsoft_ads__campaign_country_report') }} b
--     LEFT JOIN {{ ref('country_codes') }} cc
--         ON LOWER(b.country) = LOWER(cc.country_name)
--     WHERE b.country IS NOT NULL
--     GROUP BY 1, 2, 3
-- ),

-- facebook_geo AS (
--     SELECT
--         date AS date,
--         CONCAT('facebook_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
--         LOWER(country) AS country_code,
--         COALESCE(spend, 0) AS spend,
--         COALESCE(impressions, 0) AS impressions,
--         COALESCE(clicks, 0) AS clicks,
--         0 AS conversions,
--         FALSE AS is_estimated
--     FROM {{ source('facebook_ads', 'campaign_country_daily') }}
--     WHERE country IS NOT NULL
-- ),

with google_geo AS (
    SELECT
        date AS date,
        CONCAT('google_ads_', CAST(campaign_id AS STRING)) AS campaign_id,
        gt.country_code,
        COALESCE(cost_micros / 1000000.0, 0) AS spend,
        COALESCE(impressions, 0) AS impressions,
        COALESCE(clicks, 0) AS clicks,
        COALESCE(all_conversions, 0) AS conversions,
        FALSE AS is_estimated
    FROM {{ source('google_ads_v2', 'campaign_country_report') }} g
    LEFT JOIN {{ ref('google_geo_targets') }} gt
        ON g.country_criterion_id = gt.criterion_id
    WHERE gt.country_code IS NOT NULL
),

-- -- LinkedIn: Monthly geo data distributed to daily estimates using WEIGHTED distribution
-- -- Weighted by actual daily campaign spend patterns (not uniform)
-- -- This reduces daily estimation error by ~69% compared to uniform distribution
-- -- Note: LinkedIn campaign_id maps to campaign_group_id for nexus.campaigns join
-- linkedin_campaign_to_group AS (
--     SELECT
--         id AS campaign_id,
--         campaign_group_id
--     FROM {{ source('linkedin_ads', 'campaign_history') }}
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_time DESC) = 1
-- ),

-- linkedin_monthly_geo AS (
--     SELECT
--         m.campaign_id,
--         cg.campaign_group_id,
--         m.member_country AS geo_urn,
--         m.month,
--         CAST(m.cost_in_local_currency AS FLOAT64) AS monthly_spend,
--         m.impressions AS monthly_impressions,
--         m.clicks AS monthly_clicks,
--         COALESCE(m.external_website_conversions, 0) AS monthly_conversions
--     FROM {{ source('linkedin_ads', 'monthly_ad_analytics_by_member_country') }} m
--     LEFT JOIN linkedin_campaign_to_group cg ON m.campaign_id = cg.campaign_id
--     WHERE CAST(m.cost_in_local_currency AS FLOAT64) > 0
-- ),

-- -- Daily campaign spend for weighted distribution
-- linkedin_daily_campaign_spend AS (
--     SELECT
--         campaign_id,
--         DATE(day) AS date,
--         CONCAT(CAST(EXTRACT(YEAR FROM DATE(day)) AS STRING), '-', CAST(EXTRACT(MONTH FROM DATE(day)) AS STRING)) AS month_key,
--         CAST(cost_in_local_currency AS FLOAT64) AS daily_spend,
--         impressions AS daily_impressions,
--         clicks AS daily_clicks,
--         COALESCE(external_website_conversions, 0) AS daily_conversions
--     FROM {{ source('linkedin_ads', 'ad_analytics_by_campaign') }}
--     WHERE cost_in_local_currency > 0
-- ),

-- -- Monthly totals from daily campaign data (for calculating weight ratios)
-- linkedin_monthly_campaign_totals AS (
--     SELECT
--         campaign_id,
--         month_key,
--         SUM(daily_spend) AS monthly_campaign_spend,
--         SUM(daily_impressions) AS monthly_campaign_impressions,
--         SUM(daily_clicks) AS monthly_campaign_clicks,
--         SUM(daily_conversions) AS monthly_campaign_conversions
--     FROM linkedin_daily_campaign_spend
--     GROUP BY 1, 2
-- ),

-- -- LinkedIn geo data before aggregation (one row per campaign within group)
-- -- Uses WEIGHTED distribution: monthly_geo × (daily_campaign / monthly_campaign)
-- linkedin_geo_raw AS (
--     SELECT
--         d.date,
--         -- Use campaign_group_id to match nexus.campaigns (LinkedIn hierarchy)
--         CONCAT('linkedin_ads_', CAST(g.campaign_group_id AS STRING)) AS campaign_id,
--         u.country_code,
--         -- Weighted distribution formula: monthly_geo × (daily / monthly)
--         ROUND(g.monthly_spend * SAFE_DIVIDE(d.daily_spend, m.monthly_campaign_spend), 4) AS spend,
--         ROUND(g.monthly_impressions * SAFE_DIVIDE(d.daily_impressions, m.monthly_campaign_impressions), 0) AS impressions,
--         ROUND(g.monthly_clicks * SAFE_DIVIDE(d.daily_clicks, m.monthly_campaign_clicks), 0) AS clicks,
--         ROUND(g.monthly_conversions * SAFE_DIVIDE(d.daily_conversions, m.monthly_campaign_conversions), 0) AS conversions
--     FROM linkedin_monthly_geo g
--     JOIN linkedin_monthly_campaign_totals m
--         ON g.campaign_id = m.campaign_id
--         AND g.month = m.month_key
--     JOIN linkedin_daily_campaign_spend d
--         ON g.campaign_id = d.campaign_id
--         AND m.month_key = d.month_key
--     LEFT JOIN {{ ref('linkedin_geo_urn') }} u
--         ON g.geo_urn = u.geo_urn
--     WHERE u.country_code IS NOT NULL
--       AND g.campaign_group_id IS NOT NULL
-- ),

-- -- Aggregate to campaign_group level (multiple campaigns roll up to one group)
-- linkedin_geo AS (
--     SELECT
--         date,
--         campaign_id,
--         country_code,
--         SUM(spend) AS spend,
--         SUM(impressions) AS impressions,
--         SUM(clicks) AS clicks,
--         SUM(conversions) AS conversions,
--         TRUE AS is_estimated
--     FROM linkedin_geo_raw
--     GROUP BY date, campaign_id, country_code
-- ),

all_geo AS (
    -- SELECT * FROM tiktok_geo
    -- UNION ALL
    -- SELECT * FROM bing_geo
    -- UNION ALL
    -- SELECT * FROM facebook_geo  -- Uncomment when campaign_country_daily exists
    -- UNION ALL
    SELECT * FROM google_geo
    -- UNION ALL
    -- SELECT * FROM linkedin_geo
)

SELECT
    g.date,
    c.organization_id,
    c.product_id,
    c.ad_network_id,
    c.account_id,
    g.campaign_id,
    c.campaign_name,
    g.country_code,
    g.spend,
    g.impressions,
    g.clicks,
    g.conversions,
    g.is_estimated
FROM all_geo g
LEFT JOIN {{ ref('campaigns') }} c
    ON g.campaign_id = c.id
WHERE g.country_code IS NOT NULL
