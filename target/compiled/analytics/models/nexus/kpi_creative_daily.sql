

WITH
inputs AS (
  SELECT at_date
  FROM UNNEST(
    GENERATE_DATE_ARRAY(
      -- Default to 7 days lookback to catch retroactive API corrections from ad networks
      -- DATE('2026-01-25'),
      DATE('2022-01-01'),
      DATE('2026-02-01'),
      INTERVAL 1 DAY
    )
  ) AS at_date
),

--------------------------------------------------------------------
-- Facebook Performance
--------------------------------------------------------------------


facebook_dates AS (
  
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date
  FROM (SELECT 1) WHERE FALSE
  
),


facebook_conversion_names AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_count
  FROM (SELECT 1) WHERE FALSE
  
),


facebook_conversion_values AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_value
  FROM (SELECT 1) WHERE FALSE
  
),

facebook_conversions AS (
  SELECT
    fcn.date AS date,
    fcn.ad_id AS ad_id,
    fcn.conversion_name AS conversion_name,
    fcn.conversion_count AS conversion_count,
    fcv.conversion_value AS conversion_value
  FROM facebook_conversion_names fcn
  LEFT JOIN facebook_conversion_values fcv
  ON fcn.ad_id = fcv.ad_id
    AND fcn.date = fcv.date
    AND fcn.conversion_name = fcv.conversion_name
),



facebook_base AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS FLOAT64) as spend,
    CAST(NULL AS INTEGER) as impressions,
    CAST(NULL AS INTEGER) as clicks
  FROM (SELECT 1) WHERE FALSE
  
),

facebook_performance AS (
  SELECT
    fb.date,
    fb.earliest_date,
    fb.latest_date,
    fb.ad_id,
    fb.adset_id,
    fb.campaign_id,
    fb.account_id as account_id,
    MAX(fb.spend) as spend,
    MAX(fb.impressions) as impressions,
    MAX(fb.clicks) as clicks,

    MAX(a.kpi_1) AS kpi_1_name,
    SUM(CASE WHEN fc.conversion_name = a.kpi_1 THEN fc.conversion_count ELSE 0 END) AS kpi_1_count,
    SUM(CASE WHEN fc.conversion_name = a.kpi_1 THEN fc.conversion_value ELSE 0 END) AS kpi_1_value,
    MAX(a.kpi_2) AS kpi_2_name,
    SUM(CASE WHEN fc.conversion_name = a.kpi_2 THEN fc.conversion_count ELSE 0 END) AS kpi_2_count,
    SUM(CASE WHEN fc.conversion_name = a.kpi_2 THEN fc.conversion_value ELSE 0 END) AS kpi_2_value,
    MAX(a.kpi_3) AS kpi_3_name,
    SUM(CASE WHEN fc.conversion_name = a.kpi_3 THEN fc.conversion_count ELSE 0 END) AS kpi_3_count,
    SUM(CASE WHEN fc.conversion_name = a.kpi_3 THEN fc.conversion_value ELSE 0 END) AS kpi_3_value,
    MAX(a.kpi_4) AS kpi_4_name,
    SUM(CASE WHEN fc.conversion_name = a.kpi_4 THEN fc.conversion_count ELSE 0 END) AS kpi_4_count,
    SUM(CASE WHEN fc.conversion_name = a.kpi_4 THEN fc.conversion_value ELSE 0 END) AS kpi_4_value,
    MAX(a.kpi_5) AS kpi_5_name,
    SUM(CASE WHEN fc.conversion_name = a.kpi_5 THEN fc.conversion_count ELSE 0 END) AS kpi_5_count,
    SUM(CASE WHEN fc.conversion_name = a.kpi_5 THEN fc.conversion_value ELSE 0 END) AS kpi_5_value,
    MAX(a.kpi_6) AS kpi_6_name,
    SUM(CASE WHEN fc.conversion_name = a.kpi_6 THEN fc.conversion_count ELSE 0 END) AS kpi_6_count,
    SUM(CASE WHEN fc.conversion_name = a.kpi_6 THEN fc.conversion_value ELSE 0 END) AS kpi_6_value,
    MAX(a.kpi_7) AS kpi_7_name,
    SUM(CASE WHEN fc.conversion_name = a.kpi_7 THEN fc.conversion_count ELSE 0 END) AS kpi_7_count,
    SUM(CASE WHEN fc.conversion_name = a.kpi_7 THEN fc.conversion_value ELSE 0 END) AS kpi_7_value,
    MAX(a.kpi_8) AS kpi_8_name,
    SUM(CASE WHEN fc.conversion_name = a.kpi_8 THEN fc.conversion_count ELSE 0 END) AS kpi_8_count,
    SUM(CASE WHEN fc.conversion_name = a.kpi_8 THEN fc.conversion_value ELSE 0 END) AS kpi_8_value,
    MAX(a.kpi_9) AS kpi_9_name,
    SUM(CASE WHEN fc.conversion_name = a.kpi_9 THEN fc.conversion_count ELSE 0 END) AS kpi_9_count,
    SUM(CASE WHEN fc.conversion_name = a.kpi_9 THEN fc.conversion_value ELSE 0 END) AS kpi_9_value,
    MAX(a.kpi_10) AS kpi_10_name,
    SUM(CASE WHEN fc.conversion_name = a.kpi_10 THEN fc.conversion_count ELSE 0 END) AS kpi_10_count,
    SUM(CASE WHEN fc.conversion_name = a.kpi_10 THEN fc.conversion_value ELSE 0 END) AS kpi_10_value

  FROM facebook_base fb
  LEFT JOIN facebook_conversions fc
    ON fb.date = fc.date
    AND fb.ad_id = fc.ad_id
  LEFT JOIN `res-analytics.com_allied.accounts` a

    ON fb.account_id = a.id
  GROUP BY fb.date, fb.earliest_date, fb.latest_date, fb.ad_id, fb.adset_id, fb.campaign_id, fb.account_id
),

-- SELECT * from facebook_performance
-- ORDER BY ad_id;

--------------------------------------------------------------------
-- Google Performance
--------------------------------------------------------------------



google_dates AS (
  
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date
  FROM (SELECT 1) WHERE FALSE
  
),


google_conversions AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_count,
    CAST(NULL AS FLOAT64) as conversion_value
  FROM (SELECT 1) WHERE FALSE
  

),

google_base AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS FLOAT64) as spend,
    CAST(NULL AS INTEGER) as impressions,
    CAST(NULL AS INTEGER) as clicks
  FROM (SELECT 1) WHERE FALSE
  
),

google_performance AS (
  SELECT
    gb.date,
    gb.earliest_date,
    gb.latest_date,
    gb.ad_id,
    gb.adset_id,
    gb.campaign_id,
    gb.account_id AS account_id,
    MAX(gb.spend) AS spend,
    MAX(gb.impressions) as impressions,
    MAX(gb.clicks) as clicks,

    MAX(a.kpi_1) AS kpi_1_name,
    SUM(CASE WHEN gc.conversion_name = a.kpi_1 THEN gc.conversion_count ELSE 0 END) AS kpi_1_count,
    SUM(CASE WHEN gc.conversion_name = a.kpi_1 THEN gc.conversion_value ELSE 0 END) AS kpi_1_value,
    MAX(a.kpi_2) AS kpi_2_name,
    SUM(CASE WHEN gc.conversion_name = a.kpi_2 THEN gc.conversion_count ELSE 0 END) AS kpi_2_count,
    SUM(CASE WHEN gc.conversion_name = a.kpi_2 THEN gc.conversion_value ELSE 0 END) AS kpi_2_value,
    MAX(a.kpi_3) AS kpi_3_name,
    SUM(CASE WHEN gc.conversion_name = a.kpi_3 THEN gc.conversion_count ELSE 0 END) AS kpi_3_count,
    SUM(CASE WHEN gc.conversion_name = a.kpi_3 THEN gc.conversion_value ELSE 0 END) AS kpi_3_value,
    MAX(a.kpi_4) AS kpi_4_name,
    SUM(CASE WHEN gc.conversion_name = a.kpi_4 THEN gc.conversion_count ELSE 0 END) AS kpi_4_count,
    SUM(CASE WHEN gc.conversion_name = a.kpi_4 THEN gc.conversion_value ELSE 0 END) AS kpi_4_value,
    MAX(a.kpi_5) AS kpi_5_name,
    SUM(CASE WHEN gc.conversion_name = a.kpi_5 THEN gc.conversion_count ELSE 0 END) AS kpi_5_count,
    SUM(CASE WHEN gc.conversion_name = a.kpi_5 THEN gc.conversion_value ELSE 0 END) AS kpi_5_value,
    MAX(a.kpi_6) AS kpi_6_name,
    SUM(CASE WHEN gc.conversion_name = a.kpi_6 THEN gc.conversion_count ELSE 0 END) AS kpi_6_count,
    SUM(CASE WHEN gc.conversion_name = a.kpi_6 THEN gc.conversion_value ELSE 0 END) AS kpi_6_value,
    MAX(a.kpi_7) AS kpi_7_name,
    SUM(CASE WHEN gc.conversion_name = a.kpi_7 THEN gc.conversion_count ELSE 0 END) AS kpi_7_count,
    SUM(CASE WHEN gc.conversion_name = a.kpi_7 THEN gc.conversion_value ELSE 0 END) AS kpi_7_value,
    MAX(a.kpi_8) AS kpi_8_name,
    SUM(CASE WHEN gc.conversion_name = a.kpi_8 THEN gc.conversion_count ELSE 0 END) AS kpi_8_count,
    SUM(CASE WHEN gc.conversion_name = a.kpi_8 THEN gc.conversion_value ELSE 0 END) AS kpi_8_value,
    MAX(a.kpi_9) AS kpi_9_name,
    SUM(CASE WHEN gc.conversion_name = a.kpi_9 THEN gc.conversion_count ELSE 0 END) AS kpi_9_count,
    SUM(CASE WHEN gc.conversion_name = a.kpi_9 THEN gc.conversion_value ELSE 0 END) AS kpi_9_value,
    MAX(a.kpi_10) AS kpi_10_name,
    SUM(CASE WHEN gc.conversion_name = a.kpi_10 THEN gc.conversion_count ELSE 0 END) AS kpi_10_count,
    SUM(CASE WHEN gc.conversion_name = a.kpi_10 THEN gc.conversion_value ELSE 0 END) AS kpi_10_value



  FROM google_base gb
  LEFT JOIN google_conversions gc
    ON gb.date = gc.date
    AND gb.ad_id = gc.ad_id
  LEFT JOIN `res-analytics.com_allied.accounts` a
    ON gb.account_id = a.id
  GROUP BY gb.date, gb.earliest_date, gb.latest_date, gb.ad_id, gb.adset_id, gb.campaign_id, gb.account_id
),

-- TEMP DISABLE Google PMax See Note Below


--------------------------------------------------------------------
-- Linkedin Performance
-- NOTE: LinkedIn hierarchy: Account -> Campaign Group (=Nexus Campaign) -> Campaign (=Nexus AdSet) -> Creative (=Nexus Ad)
-- Conversion data comes from ad_analytics_by_creative_with_conversion_breakdown joined with conversion_history
--------------------------------------------------------------------


linkedin_dates AS (
  
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date
  FROM (SELECT 1) WHERE FALSE
  
),

-- Conversion data from breakdown table joined with conversion_history for names


linkedin_conversions AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_count,
    CAST(NULL AS FLOAT64) as conversion_value
  FROM (SELECT 1) WHERE FALSE
  
),

-- Base metrics with hierarchy from creative_history and campaign_history




linkedin_base AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS FLOAT64) as spend,
    CAST(NULL AS INTEGER) as impressions,
    CAST(NULL AS INTEGER) as clicks
  FROM (SELECT 1) WHERE FALSE
  
),

linkedin_performance AS (
  SELECT
    lb.date,
    lb.earliest_date,
    lb.latest_date,
    lb.ad_id,
    lb.adset_id,
    lb.campaign_id,
    lb.account_id,
    MAX(lb.spend) as spend,
    MAX(lb.impressions) as impressions,
    MAX(lb.clicks) as clicks,

    MAX(a.kpi_1) AS kpi_1_name,
    SUM(CASE WHEN lc.conversion_name = a.kpi_1 THEN lc.conversion_count ELSE 0 END) AS kpi_1_count,
    SUM(CASE WHEN lc.conversion_name = a.kpi_1 THEN lc.conversion_value ELSE 0 END) AS kpi_1_value,
    MAX(a.kpi_2) AS kpi_2_name,
    SUM(CASE WHEN lc.conversion_name = a.kpi_2 THEN lc.conversion_count ELSE 0 END) AS kpi_2_count,
    SUM(CASE WHEN lc.conversion_name = a.kpi_2 THEN lc.conversion_value ELSE 0 END) AS kpi_2_value,
    MAX(a.kpi_3) AS kpi_3_name,
    SUM(CASE WHEN lc.conversion_name = a.kpi_3 THEN lc.conversion_count ELSE 0 END) AS kpi_3_count,
    SUM(CASE WHEN lc.conversion_name = a.kpi_3 THEN lc.conversion_value ELSE 0 END) AS kpi_3_value,
    MAX(a.kpi_4) AS kpi_4_name,
    SUM(CASE WHEN lc.conversion_name = a.kpi_4 THEN lc.conversion_count ELSE 0 END) AS kpi_4_count,
    SUM(CASE WHEN lc.conversion_name = a.kpi_4 THEN lc.conversion_value ELSE 0 END) AS kpi_4_value,
    MAX(a.kpi_5) AS kpi_5_name,
    SUM(CASE WHEN lc.conversion_name = a.kpi_5 THEN lc.conversion_count ELSE 0 END) AS kpi_5_count,
    SUM(CASE WHEN lc.conversion_name = a.kpi_5 THEN lc.conversion_value ELSE 0 END) AS kpi_5_value,
    MAX(a.kpi_6) AS kpi_6_name,
    SUM(CASE WHEN lc.conversion_name = a.kpi_6 THEN lc.conversion_count ELSE 0 END) AS kpi_6_count,
    SUM(CASE WHEN lc.conversion_name = a.kpi_6 THEN lc.conversion_value ELSE 0 END) AS kpi_6_value,
    MAX(a.kpi_7) AS kpi_7_name,
    SUM(CASE WHEN lc.conversion_name = a.kpi_7 THEN lc.conversion_count ELSE 0 END) AS kpi_7_count,
    SUM(CASE WHEN lc.conversion_name = a.kpi_7 THEN lc.conversion_value ELSE 0 END) AS kpi_7_value,
    MAX(a.kpi_8) AS kpi_8_name,
    SUM(CASE WHEN lc.conversion_name = a.kpi_8 THEN lc.conversion_count ELSE 0 END) AS kpi_8_count,
    SUM(CASE WHEN lc.conversion_name = a.kpi_8 THEN lc.conversion_value ELSE 0 END) AS kpi_8_value,
    MAX(a.kpi_9) AS kpi_9_name,
    SUM(CASE WHEN lc.conversion_name = a.kpi_9 THEN lc.conversion_count ELSE 0 END) AS kpi_9_count,
    SUM(CASE WHEN lc.conversion_name = a.kpi_9 THEN lc.conversion_value ELSE 0 END) AS kpi_9_value,
    MAX(a.kpi_10) AS kpi_10_name,
    SUM(CASE WHEN lc.conversion_name = a.kpi_10 THEN lc.conversion_count ELSE 0 END) AS kpi_10_count,
    SUM(CASE WHEN lc.conversion_name = a.kpi_10 THEN lc.conversion_value ELSE 0 END) AS kpi_10_value

  FROM linkedin_base lb
  LEFT JOIN linkedin_conversions lc
    ON lb.date = lc.date
    AND lb.ad_id = lc.ad_id
  LEFT JOIN `res-analytics.com_allied.accounts` a
    ON lb.account_id = a.id

  GROUP BY lb.date, lb.earliest_date, lb.latest_date, lb.ad_id, lb.adset_id, lb.campaign_id, lb.account_id
),

-- SELECT * from linkedin_performance
-- ORDER BY ad_id;

--------------------------------------------------------------------
-- TikTok Performance (using ad_report_hourly - aggregated to daily)
--------------------------------------------------------------------


tiktok_dates AS (
  
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date
  FROM (SELECT 1) WHERE FALSE
  
),

-- Unpivot TikTok conversion columns to rows
-- NOTE: TikTok stores conversions as inline columns (not rows like Facebook's basic_ad_actions table)
tiktok_conversion_counts AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_count
  FROM (SELECT 1) WHERE FALSE
  
),

tiktok_conversion_values AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_value
  FROM (SELECT 1) WHERE FALSE
  
),

tiktok_conversions AS (
  SELECT
    tc.date,
    tc.ad_id,
    tc.conversion_name,
    tc.conversion_count,
    COALESCE(tv.conversion_value, 0.0) AS conversion_value
  FROM tiktok_conversion_counts tc
  LEFT JOIN tiktok_conversion_values tv
    ON tc.date = tv.date
    AND tc.ad_id = tv.ad_id
    AND tc.conversion_name = tv.conversion_name
  WHERE tc.conversion_count > 0 OR tv.conversion_value > 0
),


tiktok_base AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS FLOAT64) as spend,
    CAST(NULL AS INTEGER) as impressions,
    CAST(NULL AS INTEGER) as clicks
  FROM (SELECT 1) WHERE FALSE
  
),

tiktok_performance AS (
  SELECT
    tb.date,
    tb.earliest_date,
    tb.latest_date,
    tb.ad_id,
    tb.adset_id,
    tb.campaign_id,
    tb.account_id,
    MAX(tb.spend) AS spend,
    MAX(tb.impressions) AS impressions,
    MAX(tb.clicks) AS clicks,

    -- KPI mapping from accounts (same pattern as FB/Google/LinkedIn)
    MAX(a.kpi_1) AS kpi_1_name,
    SUM(CASE WHEN tc.conversion_name = a.kpi_1 THEN tc.conversion_count ELSE 0 END) AS kpi_1_count,
    SUM(CASE WHEN tc.conversion_name = a.kpi_1 THEN tc.conversion_value ELSE 0 END) AS kpi_1_value,
    MAX(a.kpi_2) AS kpi_2_name,
    SUM(CASE WHEN tc.conversion_name = a.kpi_2 THEN tc.conversion_count ELSE 0 END) AS kpi_2_count,
    SUM(CASE WHEN tc.conversion_name = a.kpi_2 THEN tc.conversion_value ELSE 0 END) AS kpi_2_value,
    MAX(a.kpi_3) AS kpi_3_name,
    SUM(CASE WHEN tc.conversion_name = a.kpi_3 THEN tc.conversion_count ELSE 0 END) AS kpi_3_count,
    SUM(CASE WHEN tc.conversion_name = a.kpi_3 THEN tc.conversion_value ELSE 0 END) AS kpi_3_value,
    MAX(a.kpi_4) AS kpi_4_name,
    SUM(CASE WHEN tc.conversion_name = a.kpi_4 THEN tc.conversion_count ELSE 0 END) AS kpi_4_count,
    SUM(CASE WHEN tc.conversion_name = a.kpi_4 THEN tc.conversion_value ELSE 0 END) AS kpi_4_value,
    MAX(a.kpi_5) AS kpi_5_name,
    SUM(CASE WHEN tc.conversion_name = a.kpi_5 THEN tc.conversion_count ELSE 0 END) AS kpi_5_count,
    SUM(CASE WHEN tc.conversion_name = a.kpi_5 THEN tc.conversion_value ELSE 0 END) AS kpi_5_value,
    MAX(a.kpi_6) AS kpi_6_name,
    SUM(CASE WHEN tc.conversion_name = a.kpi_6 THEN tc.conversion_count ELSE 0 END) AS kpi_6_count,
    SUM(CASE WHEN tc.conversion_name = a.kpi_6 THEN tc.conversion_value ELSE 0 END) AS kpi_6_value,
    MAX(a.kpi_7) AS kpi_7_name,
    SUM(CASE WHEN tc.conversion_name = a.kpi_7 THEN tc.conversion_count ELSE 0 END) AS kpi_7_count,
    SUM(CASE WHEN tc.conversion_name = a.kpi_7 THEN tc.conversion_value ELSE 0 END) AS kpi_7_value,
    MAX(a.kpi_8) AS kpi_8_name,
    SUM(CASE WHEN tc.conversion_name = a.kpi_8 THEN tc.conversion_count ELSE 0 END) AS kpi_8_count,
    SUM(CASE WHEN tc.conversion_name = a.kpi_8 THEN tc.conversion_value ELSE 0 END) AS kpi_8_value,
    MAX(a.kpi_9) AS kpi_9_name,
    SUM(CASE WHEN tc.conversion_name = a.kpi_9 THEN tc.conversion_count ELSE 0 END) AS kpi_9_count,
    SUM(CASE WHEN tc.conversion_name = a.kpi_9 THEN tc.conversion_value ELSE 0 END) AS kpi_9_value,
    MAX(a.kpi_10) AS kpi_10_name,
    SUM(CASE WHEN tc.conversion_name = a.kpi_10 THEN tc.conversion_count ELSE 0 END) AS kpi_10_count,
    SUM(CASE WHEN tc.conversion_name = a.kpi_10 THEN tc.conversion_value ELSE 0 END) AS kpi_10_value

  FROM tiktok_base tb
  LEFT JOIN tiktok_conversions tc
    ON tb.date = tc.date
    AND tb.ad_id = tc.ad_id
  LEFT JOIN `res-analytics.com_allied.accounts` a
    ON tb.account_id = a.id
  GROUP BY tb.date, tb.earliest_date, tb.latest_date, tb.ad_id, tb.adset_id, tb.campaign_id, tb.account_id
),

--------------------------------------------------------------------
-- Bing/Microsoft Performance (using raw Fivetran table with SUM aggregation)
--------------------------------------------------------------------

bing_dates AS (
  
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date
  FROM (SELECT 1) WHERE FALSE
  
),

-- Ad-level conversions with goal names (same pattern as Google's ads_conversions)

bing_conversions AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_count,
    CAST(NULL AS FLOAT64) as conversion_value
  FROM (SELECT 1) WHERE FALSE
  
),

bing_base AS (
  
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as adset_id,
    CAST(NULL AS STRING) as campaign_id,
    CAST(NULL AS STRING) as account_id,
    CAST(NULL AS FLOAT64) as spend,
    CAST(NULL AS INTEGER) as impressions,
    CAST(NULL AS INTEGER) as clicks
  FROM (SELECT 1) WHERE FALSE

    
),

bing_performance AS (
  SELECT
    bb.date,
    bb.earliest_date,
    bb.latest_date,
    bb.ad_id,
    bb.adset_id,
    bb.campaign_id,
    bb.account_id,
    MAX(bb.spend) AS spend,
    MAX(bb.impressions) AS impressions,
    MAX(bb.clicks) AS clicks,

    -- KPI mapping by goal name (same pattern as Google)
    -- Conversions joined via ad_id (ad level - same as Google)
    MAX(a.kpi_1) AS kpi_1_name,
    SUM(CASE WHEN bc.conversion_name = a.kpi_1 THEN bc.conversion_count ELSE 0 END) AS kpi_1_count,
    SUM(CASE WHEN bc.conversion_name = a.kpi_1 THEN bc.conversion_value ELSE 0 END) AS kpi_1_value,
    MAX(a.kpi_2) AS kpi_2_name,
    SUM(CASE WHEN bc.conversion_name = a.kpi_2 THEN bc.conversion_count ELSE 0 END) AS kpi_2_count,
    SUM(CASE WHEN bc.conversion_name = a.kpi_2 THEN bc.conversion_value ELSE 0 END) AS kpi_2_value,
    MAX(a.kpi_3) AS kpi_3_name,
    SUM(CASE WHEN bc.conversion_name = a.kpi_3 THEN bc.conversion_count ELSE 0 END) AS kpi_3_count,
    SUM(CASE WHEN bc.conversion_name = a.kpi_3 THEN bc.conversion_value ELSE 0 END) AS kpi_3_value,
    MAX(a.kpi_4) AS kpi_4_name,
    SUM(CASE WHEN bc.conversion_name = a.kpi_4 THEN bc.conversion_count ELSE 0 END) AS kpi_4_count,
    SUM(CASE WHEN bc.conversion_name = a.kpi_4 THEN bc.conversion_value ELSE 0 END) AS kpi_4_value,
    MAX(a.kpi_5) AS kpi_5_name,
    SUM(CASE WHEN bc.conversion_name = a.kpi_5 THEN bc.conversion_count ELSE 0 END) AS kpi_5_count,
    SUM(CASE WHEN bc.conversion_name = a.kpi_5 THEN bc.conversion_value ELSE 0 END) AS kpi_5_value,
    MAX(a.kpi_6) AS kpi_6_name,
    SUM(CASE WHEN bc.conversion_name = a.kpi_6 THEN bc.conversion_count ELSE 0 END) AS kpi_6_count,
    SUM(CASE WHEN bc.conversion_name = a.kpi_6 THEN bc.conversion_value ELSE 0 END) AS kpi_6_value,
    MAX(a.kpi_7) AS kpi_7_name,
    SUM(CASE WHEN bc.conversion_name = a.kpi_7 THEN bc.conversion_count ELSE 0 END) AS kpi_7_count,
    SUM(CASE WHEN bc.conversion_name = a.kpi_7 THEN bc.conversion_value ELSE 0 END) AS kpi_7_value,
    MAX(a.kpi_8) AS kpi_8_name,
    SUM(CASE WHEN bc.conversion_name = a.kpi_8 THEN bc.conversion_count ELSE 0 END) AS kpi_8_count,
    SUM(CASE WHEN bc.conversion_name = a.kpi_8 THEN bc.conversion_value ELSE 0 END) AS kpi_8_value,
    MAX(a.kpi_9) AS kpi_9_name,
    SUM(CASE WHEN bc.conversion_name = a.kpi_9 THEN bc.conversion_count ELSE 0 END) AS kpi_9_count,
    SUM(CASE WHEN bc.conversion_name = a.kpi_9 THEN bc.conversion_value ELSE 0 END) AS kpi_9_value,
    MAX(a.kpi_10) AS kpi_10_name,
    SUM(CASE WHEN bc.conversion_name = a.kpi_10 THEN bc.conversion_count ELSE 0 END) AS kpi_10_count,
    SUM(CASE WHEN bc.conversion_name = a.kpi_10 THEN bc.conversion_value ELSE 0 END) AS kpi_10_value

  FROM bing_base bb
  LEFT JOIN bing_conversions bc
    ON bb.date = bc.date
    AND bb.ad_id = bc.ad_id  -- Join at AD level (same as Google)
  LEFT JOIN `res-analytics.com_allied.accounts` a
    ON bb.account_id = a.id
  GROUP BY bb.date, bb.earliest_date, bb.latest_date, bb.ad_id, bb.adset_id, bb.campaign_id, bb.account_id
),

--------------------------------------------------------------------
-- All Performance
--------------------------------------------------------------------
all_performance AS (
  SELECT * FROM facebook_performance
  UNION ALL
  SELECT * FROM google_performance
  UNION ALL
  -- TEMP DISABLE Google PMax
  -- SELECT * FROM google_pmax_performance
  -- UNION ALL
  SELECT * FROM linkedin_performance
  UNION ALL
  SELECT * FROM tiktok_performance
  UNION ALL
  SELECT * FROM bing_performance
),

--------------------------------------------------------------------
-- Creative Fatigue
--------------------------------------------------------------------
-- Step 1: Compute initial CTR (first 7 days)
initial_ctr AS (
  SELECT
    ap.ad_id,
    SUM(ap.impressions) AS initial_impressions,
    SUM(ap.clicks) AS initial_clicks,
    COALESCE(SAFE_DIVIDE(SUM(ap.clicks), SUM(ap.impressions)), 0) AS initial_ctr_value
  FROM all_performance ap
  WHERE ap.date >= ap.earliest_date
    AND ap.date < DATE_ADD(ap.earliest_date, INTERVAL 7 DAY)
  GROUP BY ap.ad_id
),

-- Step 2: Compute current CTR (trailing 7 days from at_date)
current_ctr AS (
  SELECT
    i.at_date,
    ap.ad_id,
    SUM(ap.impressions) AS current_impressions,
    SUM(ap.clicks) AS current_clicks,
    COALESCE(SAFE_DIVIDE(SUM(ap.clicks), SUM(ap.impressions)), 0) AS current_ctr_value
  FROM inputs i
  JOIN all_performance ap
    ON ap.date > DATE_SUB(i.at_date, INTERVAL 7 DAY)
    AND ap.date <= i.at_date
  GROUP BY i.at_date, ap.ad_id
),

-- Step 3: Compute total cumulative impressions
cumulative_impressions AS (
  SELECT
    i.at_date,
    ap.ad_id,
    SUM(ap.impressions) AS total_impressions
  FROM inputs i
  JOIN all_performance ap
    ON ap.date >= ap.earliest_date
    AND ap.date <= i.at_date
  GROUP BY i.at_date, ap.ad_id
),

-- Combine all metrics and compute scores
all_performance_with_fatigue AS (
  SELECT
    ap.date,
    ap.earliest_date,
    ap.latest_date,
    DATE_DIFF(ap.date, ap.earliest_date, DAY) AS age_days,

    ap.ad_id,
    ap.adset_id,
    ap.campaign_id,
    ap.account_id,

    ap.spend,
    ap.impressions,
    ap.clicks,

    ap.kpi_1_name,
    ap.kpi_1_count,
    ap.kpi_1_value,

    ap.kpi_2_name,
    ap.kpi_2_count,
    ap.kpi_2_value,

    ap.kpi_3_name,
    ap.kpi_3_count,
    ap.kpi_3_value,

    ap.kpi_4_name,
    ap.kpi_4_count,
    ap.kpi_4_value,

    ap.kpi_5_name,
    ap.kpi_5_count,
    ap.kpi_5_value,

    ap.kpi_6_name,
    ap.kpi_6_count,
    ap.kpi_6_value,

    ap.kpi_7_name,
    ap.kpi_7_count,
    ap.kpi_7_value,

    ap.kpi_8_name,
    ap.kpi_8_count,
    ap.kpi_8_value,

    ap.kpi_9_name,
    ap.kpi_9_count,
    ap.kpi_9_value,

    ap.kpi_10_name,
    ap.kpi_10_count,
    ap.kpi_10_value,

    -- CTR metrics
    ictr.initial_ctr_value,
    COALESCE(cctr.current_ctr_value, 0) as current_ctr_value,

    -- CTR percentage change [0-1]
    CASE
      WHEN ictr.initial_ctr_value IS NULL OR ictr.initial_ctr_value = 0 THEN 0
      ELSE ((cctr.current_ctr_value - ictr.initial_ctr_value) / ictr.initial_ctr_value)
    END AS ctr_change_pct,

    -- Cumulative impressions
    COALESCE(ci.total_impressions, 0) AS cumulative_impressions,

    -- Step 4: CTR Decay Score
    CASE
      WHEN DATE_DIFF(ap.date, ap.earliest_date, DAY) < 7 THEN 0
      WHEN ictr.initial_ctr_value = 0 THEN 0
      WHEN ((cctr.current_ctr_value - ictr.initial_ctr_value) / ictr.initial_ctr_value) <= -.30 THEN 50
      WHEN ((cctr.current_ctr_value - ictr.initial_ctr_value) / ictr.initial_ctr_value) <= -.20 THEN 40
      WHEN ((cctr.current_ctr_value - ictr.initial_ctr_value) / ictr.initial_ctr_value) <= -.10 THEN 25
      WHEN ((cctr.current_ctr_value - ictr.initial_ctr_value) / ictr.initial_ctr_value) <= -.05 THEN 15
      ELSE 0
    END AS ctr_decay_score,

    -- Step 5: Impression Pressure Score
    CASE
      WHEN DATE_DIFF(ap.date, ap.earliest_date, DAY) < 7 THEN 0
      WHEN COALESCE(ci.total_impressions, 0) >= 1000000 THEN 30
      WHEN COALESCE(ci.total_impressions, 0) >= 500000 THEN 18
      WHEN COALESCE(ci.total_impressions, 0) >= 200000 THEN 12
      WHEN COALESCE(ci.total_impressions, 0) >= 50000 THEN 6
      ELSE 0
    END AS impression_pressure_score,

    -- Step 6: Age Pressure Score
    CASE
      WHEN DATE_DIFF(ap.date, ap.earliest_date, DAY) < 7 THEN 0
      WHEN DATE_DIFF(ap.date, ap.earliest_date, DAY) >= 61 THEN 20
      WHEN DATE_DIFF(ap.date, ap.earliest_date, DAY) >= 31 THEN 10
      WHEN DATE_DIFF(ap.date, ap.earliest_date, DAY) >= 15 THEN 5
      ELSE 0
    END AS age_pressure_score

  FROM all_performance ap
  LEFT JOIN initial_ctr ictr
    ON ap.ad_id = ictr.ad_id
  LEFT JOIN current_ctr cctr
    ON ap.ad_id = cctr.ad_id
    AND cctr.at_date = ap.date
  LEFT JOIN cumulative_impressions ci
    ON ap.ad_id = ci.ad_id
    AND ci.at_date = ap.date
),

-- Join creative fatigue with performance
joined_data AS (
  SELECT
    p.date,
    p.earliest_date,
    p.latest_date,
    p.age_days,

    p.ad_id,
    ad.ad_name,
    p.adset_id,
    adset.adset_name,
    p.campaign_id,
    c.campaign_name,
    p.account_id,
    c.ad_network_id,
    c.organization_id,
    c.product_id,

    p.spend,
    p.impressions,
    p.cumulative_impressions,
    p.clicks,
    p.initial_ctr_value,
    p.current_ctr_value,
    p.ctr_change_pct,
    p.ctr_decay_score,
    p.impression_pressure_score,
    p.age_pressure_score,
    (p.ctr_decay_score + p.impression_pressure_score + p.age_pressure_score) AS fatigue_score,

    p.kpi_1_name,
    p.kpi_1_count,
    p.kpi_1_value,

    p.kpi_2_name,
    p.kpi_2_count,
    p.kpi_2_value,

    p.kpi_3_name,
    p.kpi_3_count,
    p.kpi_3_value,

    p.kpi_4_name,
    p.kpi_4_count,
    p.kpi_4_value,

    p.kpi_5_name,
    p.kpi_5_count,
    p.kpi_5_value,

    p.kpi_6_name,
    p.kpi_6_count,
    p.kpi_6_value,

    p.kpi_7_name,
    p.kpi_7_count,
    p.kpi_7_value,

    p.kpi_8_name,
    p.kpi_8_count,
    p.kpi_8_value,

    p.kpi_9_name,
    p.kpi_9_count,
    p.kpi_9_value,

    p.kpi_10_name,
    p.kpi_10_count,
    p.kpi_10_value

  FROM all_performance_with_fatigue p
  -- LEFT JOIN `res-analytics.com_allied.ads` ad
  LEFT JOIN `res-analytics`.`com_allied`.`ads` ad
    ON p.ad_id = ad.id
  -- LEFT JOIN `res-analytics.com_allied.adsets` adset
  LEFT JOIN `res-analytics`.`com_allied`.`adsets` adset
    ON p.adset_id = adset.id
  -- LEFT JOIN `res-analytics.com_allied.campaigns` c
  LEFT JOIN `res-analytics`.`com_allied`.`campaigns` c
    ON p.campaign_id = c.id
),

final AS (
SELECT
  date,
--   COUNT(*) as num_rows,
  earliest_date,
  latest_date,
  organization_id,
  product_id,
  ad_network_id,
  account_id,
  campaign_id,
  campaign_name,
  adset_id,
  adset_name,
  ad_id,
  ad_name,
  spend,
  impressions,
  clicks,
  fatigue_score,

  kpi_1_name,
  kpi_1_count,
  kpi_1_value,

  kpi_2_name,
  kpi_2_count,
  kpi_2_value,

  kpi_3_name,
  kpi_3_count,
  kpi_3_value,

  kpi_4_name,
  kpi_4_count,
  kpi_4_value,

  kpi_5_name,
  kpi_5_count,
  kpi_5_value,

  kpi_6_name,
  kpi_6_count,
  kpi_6_value,

  kpi_7_name,
  kpi_7_count,
  kpi_7_value,

  kpi_8_name,
  kpi_8_count,
  kpi_8_value,

  kpi_9_name,
  kpi_9_count,
  kpi_9_value,

  kpi_10_name,
  kpi_10_count,
  kpi_10_value

FROM joined_data

GROUP BY
  date,
  earliest_date,
  latest_date,
  organization_id,
  product_id,
  ad_network_id,
  account_id,
  campaign_id,
  campaign_name,
  adset_id,
  adset_name,
  ad_id,
  ad_name,
  spend,
  impressions,
  clicks,
  fatigue_score,
  kpi_1_name,
  kpi_1_count,
  kpi_1_value,

  kpi_2_name,
  kpi_2_count,
  kpi_2_value,

  kpi_3_name,
  kpi_3_count,
  kpi_3_value,

  kpi_4_name,
  kpi_4_count,
  kpi_4_value,

  kpi_5_name,
  kpi_5_count,
  kpi_5_value,

  kpi_6_name,
  kpi_6_count,
  kpi_6_value,

  kpi_7_name,
  kpi_7_count,
  kpi_7_value,

  kpi_8_name,
  kpi_8_count,
  kpi_8_value,

  kpi_9_name,
  kpi_9_count,
  kpi_9_value,

  kpi_10_name,
  kpi_10_count,
  kpi_10_value
)

SELECT *
FROM final