{{
  config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
      "field": "date",
      "data_type": "date",
      "granularity": "day"
    },
    database=var("bq_project_id"),
    schema=var("bq_dataset_id"),
  )
}}

WITH
inputs AS (
  SELECT at_date
  FROM UNNEST(
    GENERATE_DATE_ARRAY(
      -- Default to 7 days lookback to catch retroactive API corrections from ad networks
      -- DATE('{{ var("start_date", (modules.datetime.date.today() - modules.datetime.timedelta(days=7)).isoformat()) }}'),
      DATE('2022-01-01'),
      DATE('{{ var("end_date", modules.datetime.date.today().isoformat()) }}'),
      INTERVAL 1 DAY
    )
  ) AS at_date
),

--------------------------------------------------------------------
-- Facebook Performance
--------------------------------------------------------------------

{% set facebook_ads_insights = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_facebook_dataset"),
      identifier="ads_insights"
) %}
facebook_dates AS (
  {% if facebook_ads_insights is not none %}
  SELECT
    inputs.at_date,
    ad_id,
    MIN(CAST(date AS DATE)) AS earliest_date,
    LEAST(MAX(CAST(date AS DATE)), inputs.at_date) AS latest_date
  FROM {{ facebook_ads_insights }}
  CROSS JOIN inputs
  GROUP BY ad_id, inputs.at_date
  {% else %}
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

{% set facebook_ads_insights_actions = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_facebook_dataset"),
      identifier="ads_insights_actions"
) %}
facebook_conversion_names AS (
  {% if facebook_ads_insights_actions is not none %}
  SELECT
    CAST(date AS DATE) AS date,
    CONCAT('facebook_ads_', CAST(ad_id AS STRING)) AS ad_id,
    action_type AS conversion_name,
    SUM(CAST(value AS FLOAT64)) AS conversion_count
  FROM {{ facebook_ads_insights_actions }}
  GROUP BY date, ad_id, action_type
  {% else %}
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_count
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

{% set facebook_ads_insights_action_values = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_facebook_dataset"),
      identifier="ads_insights_action_values"
) %}
facebook_conversion_values AS (
  {% if facebook_ads_insights_action_values is not none %}
  SELECT
    CAST(date AS DATE) AS date,
    CONCAT('facebook_ads_', CAST(ad_id AS STRING)) AS ad_id,
    action_type AS conversion_name,
    SUM(CAST(value AS FLOAT64)) AS conversion_value
  FROM {{ facebook_ads_insights_action_values }}
  GROUP BY date, ad_id, action_type
  {% else %}
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_value
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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
  {% if facebook_ads_insights is not none %}
  SELECT
    CAST(fb.date AS DATE) AS date,
    fd.earliest_date,
    fd.latest_date,
    CONCAT('facebook_ads_', CAST(fb.ad_id AS STRING)) AS ad_id,
    CONCAT('facebook_ads_', CAST(fb.adset_id AS STRING)) AS adset_id,
    CONCAT('facebook_ads_', CAST(fb.campaign_id AS STRING)) AS campaign_id,
    CONCAT('facebook_ads_', CAST(fb.account_id AS STRING)) AS account_id,

    COALESCE(fb.spend, 0) as spend,
    COALESCE(fb.impressions, 0) as impressions,
    COALESCE(fb.inline_link_clicks, 0) AS clicks
  FROM {{ facebook_ads_insights }} fb
  CROSS JOIN inputs
  INNER JOIN facebook_dates fd
    ON fb.ad_id = fd.ad_id
    AND fd.at_date = inputs.at_date
  WHERE CAST(fb.date AS DATE) = inputs.at_date
  {% else %}
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
  {% endif %}
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
  LEFT JOIN `{{ var("bq_project_id") }}.{{ var("bq_dataset_id") }}.accounts` a

    ON fb.account_id = a.id
  GROUP BY fb.date, fb.earliest_date, fb.latest_date, fb.ad_id, fb.adset_id, fb.campaign_id, fb.account_id
),

-- SELECT * from facebook_performance
-- ORDER BY ad_id;

--------------------------------------------------------------------
-- Google Performance
--------------------------------------------------------------------

{% set google_ad_stats = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_google_ads",
      identifier="ad_stats"
) %}

google_dates AS (
  {% if google_ad_stats is not none %}
  SELECT
    inputs.at_date,
    ad_id,
    MIN(CAST(date AS DATE)) AS earliest_date,
    LEAST(MAX(CAST(date AS DATE)), inputs.at_date) AS latest_date
  FROM {{ google_ad_stats }}
  CROSS JOIN inputs
  GROUP BY ad_id, inputs.at_date
  {% else %}
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

{% set google_ads_conversions = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_google_ads",
      identifier="ads_conversions"
) %}
google_conversions AS (
  {% if google_ads_conversions is not none %}
  SELECT
    CAST(date AS DATE) AS date,
    CONCAT('google_ads_', CAST(ad_id AS STRING)) AS ad_id,
    conversion_action_name AS conversion_name,
    SUM(all_conversions) AS conversion_count,
    SUM(all_conversions_value) AS conversion_value
  FROM {{ google_ads_conversions }}
  WHERE conversion_action_name IS NOT NULL
  GROUP BY date, ad_id, conversion_action_name
  {% else %}
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_count,
    CAST(NULL AS FLOAT64) as conversion_value
  FROM (SELECT 1) WHERE FALSE
  {% endif %}

),

google_base AS (
  {% if google_ad_stats is not none %}
  SELECT
    CAST(gs.date AS DATE) AS date,
    gd.earliest_date,
    gd.latest_date,
    CONCAT('google_ads_', CAST(gs.ad_id AS STRING)) AS ad_id,
    CONCAT('google_ads_', gs.ad_group_id) AS adset_id,
    CONCAT('google_ads_', CAST(gs.campaign_id AS STRING)) AS campaign_id,
    CONCAT('google_ads_', CAST(gs.customer_id AS STRING)) AS account_id,
    COALESCE(gs.cost_micros, 0)/1000000.0 AS spend,
    COALESCE(gs.impressions, 0) AS impressions,
    COALESCE(gs.clicks, 0) AS clicks
  FROM {{ google_ad_stats }} gs
  CROSS JOIN inputs
  INNER JOIN google_dates gd
    ON gs.ad_id = gd.ad_id
    AND gd.at_date = inputs.at_date
  WHERE gs.date = inputs.at_date
  {% else %}
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
  {% endif %}
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
  LEFT JOIN `{{ var("bq_project_id") }}.{{ var("bq_dataset_id") }}.accounts` a
    ON gb.account_id = a.id
  GROUP BY gb.date, gb.earliest_date, gb.latest_date, gb.ad_id, gb.adset_id, gb.campaign_id, gb.account_id
),

-- TEMP DISABLE Google PMax See Note Below
{% if false %}
--------------------------------------------------------------------
-- Google Performance Max (PMax) - Campaign-level data
-- PMax campaigns don't have traditional ads/adsets, they use Asset Groups
-- We source from campaign_stats instead of google_ads__ad_report
--------------------------------------------------------------------

{% set google_campaign_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_google_ads",
      identifier="campaign_history"
) %}
google_pmax_campaign_ids AS (
  {% if google_campaign_history is not none %}
  -- Get all Performance Max campaign IDs
  SELECT DISTINCT id as campaign_id
  FROM {{ google_campaign_history }}
  WHERE advertising_channel_type = 'PERFORMANCE_MAX'
  {% else %}
  SELECT
    CAST(NULL AS STRING) as campaign_id
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

{% set google_campaign_stats = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_google_ads",
      identifier="campaign_stats"
) %}
google_pmax_dates AS (
  {% if google_campaign_stats is not none %}
  SELECT
    inputs.at_date,
    cs.id as campaign_id,
    MIN(cs.date) AS earliest_date,
    LEAST(MAX(cs.date), inputs.at_date) AS latest_date
  FROM {{ google_campaign_stats }} cs
  INNER JOIN google_pmax_campaign_ids pmax ON cs.id = pmax.campaign_id
  CROSS JOIN inputs
  GROUP BY cs.id, inputs.at_date
  {% else %}
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

{% set google_campaign_conversions = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_google_ads",
      identifier="campaign_conversions"
) %}
google_pmax_conversions AS (
  {% if google_campaign_conversions is not none %}
  SELECT
    cc.date,
    CONCAT('google_ads_', CAST(cc.id AS STRING), '_pmax') AS ad_id,
    cc.conversion_action_name AS conversion_name,
    SUM(cc.all_conversions) AS conversion_count,
    SUM(cc.all_conversions_value) AS conversion_value
  FROM {{ google_campaign_conversions }} cc
  INNER JOIN google_pmax_campaign_ids pmax ON cc.id = pmax.campaign_id
  WHERE cc.conversion_action_name IS NOT NULL
  GROUP BY cc.date, cc.id, cc.conversion_action_name
  {% else %}
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_count,
    CAST(NULL AS FLOAT64) as conversion_value
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

google_pmax_base AS (
  {% if google_campaign_stats is not none %}
  SELECT
    cs.date,
    pd.earliest_date,
    pd.latest_date,
    -- For PMax, ad_id and adset_id are synthetic (campaign-level)
    CONCAT('google_ads_', CAST(cs.id AS STRING), '_pmax') AS ad_id,
    CONCAT('google_ads_', CAST(cs.id AS STRING), '_pmax') AS adset_id,
    CONCAT('google_ads_', CAST(cs.id AS STRING)) AS campaign_id,
    CONCAT('google_ads_', CAST(cs.customer_id AS STRING)) AS account_id,
    SUM(COALESCE(cs.cost_micros, 0)) / 1000000.0 AS spend,
    SUM(COALESCE(cs.impressions, 0)) AS impressions,
    SUM(COALESCE(cs.clicks, 0)) AS clicks
  FROM {{ google_campaign_stats }} cs
  INNER JOIN google_pmax_campaign_ids pmax ON cs.id = pmax.campaign_id
  CROSS JOIN inputs
  INNER JOIN google_pmax_dates pd
    ON cs.id = pd.campaign_id
    AND pd.at_date = inputs.at_date
  WHERE cs.date = inputs.at_date
  GROUP BY cs.date, pd.earliest_date, pd.latest_date, cs.id, cs.customer_id
  {% else %}
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
  {% endif %}
),

google_pmax_performance AS (
  SELECT
    pb.date,
    pb.earliest_date,
    pb.latest_date,
    pb.ad_id,
    pb.adset_id,
    pb.campaign_id,
    pb.account_id,
    MAX(pb.spend) AS spend,
    MAX(pb.impressions) AS impressions,
    MAX(pb.clicks) AS clicks,

    MAX(a.kpi_1) AS kpi_1_name,
    SUM(CASE WHEN pc.conversion_name = a.kpi_1 THEN pc.conversion_count ELSE 0 END) AS kpi_1_count,
    SUM(CASE WHEN pc.conversion_name = a.kpi_1 THEN pc.conversion_value ELSE 0 END) AS kpi_1_value,
    MAX(a.kpi_2) AS kpi_2_name,
    SUM(CASE WHEN pc.conversion_name = a.kpi_2 THEN pc.conversion_count ELSE 0 END) AS kpi_2_count,
    SUM(CASE WHEN pc.conversion_name = a.kpi_2 THEN pc.conversion_value ELSE 0 END) AS kpi_2_value,
    MAX(a.kpi_3) AS kpi_3_name,
    SUM(CASE WHEN pc.conversion_name = a.kpi_3 THEN pc.conversion_count ELSE 0 END) AS kpi_3_count,
    SUM(CASE WHEN pc.conversion_name = a.kpi_3 THEN pc.conversion_value ELSE 0 END) AS kpi_3_value,
    MAX(a.kpi_4) AS kpi_4_name,
    SUM(CASE WHEN pc.conversion_name = a.kpi_4 THEN pc.conversion_count ELSE 0 END) AS kpi_4_count,
    SUM(CASE WHEN pc.conversion_name = a.kpi_4 THEN pc.conversion_value ELSE 0 END) AS kpi_4_value,
    MAX(a.kpi_5) AS kpi_5_name,
    SUM(CASE WHEN pc.conversion_name = a.kpi_5 THEN pc.conversion_count ELSE 0 END) AS kpi_5_count,
    SUM(CASE WHEN pc.conversion_name = a.kpi_5 THEN pc.conversion_value ELSE 0 END) AS kpi_5_value,
    MAX(a.kpi_6) AS kpi_6_name,
    SUM(CASE WHEN pc.conversion_name = a.kpi_6 THEN pc.conversion_count ELSE 0 END) AS kpi_6_count,
    SUM(CASE WHEN pc.conversion_name = a.kpi_6 THEN pc.conversion_value ELSE 0 END) AS kpi_6_value,
    MAX(a.kpi_7) AS kpi_7_name,
    SUM(CASE WHEN pc.conversion_name = a.kpi_7 THEN pc.conversion_count ELSE 0 END) AS kpi_7_count,
    SUM(CASE WHEN pc.conversion_name = a.kpi_7 THEN pc.conversion_value ELSE 0 END) AS kpi_7_value,
    MAX(a.kpi_8) AS kpi_8_name,
    SUM(CASE WHEN pc.conversion_name = a.kpi_8 THEN pc.conversion_count ELSE 0 END) AS kpi_8_count,
    SUM(CASE WHEN pc.conversion_name = a.kpi_8 THEN pc.conversion_value ELSE 0 END) AS kpi_8_value,
    MAX(a.kpi_9) AS kpi_9_name,
    SUM(CASE WHEN pc.conversion_name = a.kpi_9 THEN pc.conversion_count ELSE 0 END) AS kpi_9_count,
    SUM(CASE WHEN pc.conversion_name = a.kpi_9 THEN pc.conversion_value ELSE 0 END) AS kpi_9_value,
    MAX(a.kpi_10) AS kpi_10_name,
    SUM(CASE WHEN pc.conversion_name = a.kpi_10 THEN pc.conversion_count ELSE 0 END) AS kpi_10_count,
    SUM(CASE WHEN pc.conversion_name = a.kpi_10 THEN pc.conversion_value ELSE 0 END) AS kpi_10_value

  FROM google_pmax_base pb
  LEFT JOIN google_pmax_conversions pc
    ON pb.date = pc.date
    AND pb.ad_id = pc.ad_id
  -- LEFT JOIN `{{ var("bq_project_id") }}.{{ var("bq_dataset_id") }}.accounts` a
  LEFT JOIN {{ ref('accounts') }} a
    ON pb.account_id = a.id
  GROUP BY pb.date, pb.earliest_date, pb.latest_date, pb.ad_id, pb.adset_id, pb.campaign_id, pb.account_id
),

-- SELECT * from google_performance
-- ORDER BY ad_id;

{% endif %}

--------------------------------------------------------------------
-- Linkedin Performance
-- NOTE: LinkedIn hierarchy: Account -> Campaign Group (=Nexus Campaign) -> Campaign (=Nexus AdSet) -> Creative (=Nexus Ad)
-- Conversion data comes from ad_analytics_by_creative_with_conversion_breakdown joined with conversion_history
--------------------------------------------------------------------

{% set linkedin_ad_analytics_by_creative = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_linkedin_ads",
      identifier="ad_analytics_by_creative"
) %}
linkedin_dates AS (
  {% if linkedin_ad_analytics_by_creative is not none %}
  SELECT
    inputs.at_date,
    creative_id,
    MIN(CAST(day AS DATE)) AS earliest_date,
    LEAST(MAX(CAST(day AS DATE)), inputs.at_date) AS latest_date
  FROM {{ linkedin_ad_analytics_by_creative }}
  CROSS JOIN inputs
  GROUP BY creative_id, inputs.at_date
  {% else %}
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

-- Conversion data from breakdown table joined with conversion_history for names
{% set linkedin_ad_analytics_by_creative_with_conversion_breakdown = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_linkedin_ads",
      identifier="ad_analytics_by_creative_with_conversion_breakdown"
) %}
{% set linkedin_conversion_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_linkedin_ads",
      identifier="conversion_history"
) %}
linkedin_conversions AS (
  {% if linkedin_ad_analytics_by_creative_with_conversion_breakdown is not none and linkedin_conversion_history is not none %}
  SELECT
    CAST(cb.day AS DATE) AS date,
    CONCAT('linkedin_ads_', CAST(cb.creative_id AS STRING)) AS ad_id,
    ch.name AS conversion_name,
    SUM(cb.external_website_conversions) AS conversion_count,
    SUM(COALESCE(CAST(cb.conversion_value_in_local_currency AS FLOAT64), 0.0)) AS conversion_value
  FROM {{ linkedin_ad_analytics_by_creative_with_conversion_breakdown }} cb
  LEFT JOIN {{ linkedin_conversion_history }} ch
    ON cb.conversion_id = ch.id
  WHERE ch.name IS NOT NULL
  GROUP BY 1, 2, 3
  {% else %}
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_count,
    CAST(NULL AS FLOAT64) as conversion_value
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

-- Base metrics with hierarchy from creative_history and campaign_history

{% set linkedin_campaign_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_linkedin_ads",
      identifier="campaign_history"
) %}
{% set linkedin_creative_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_linkedin_ads",
      identifier="creative_history"
) %}

linkedin_base AS (
  {% if linkedin_ad_analytics_by_creative is not none and linkedin_creative_history is not none and linkedin_campaign_history is not none %}
  SELECT
    CAST(la.day AS DATE) AS date,
    ld.earliest_date,
    ld.latest_date,
    CONCAT('linkedin_ads_', CAST(la.creative_id AS STRING)) AS ad_id,
    CONCAT('linkedin_ads_', CAST(crh.campaign_id AS STRING)) AS adset_id,
    CONCAT('linkedin_ads_', CAST(cmh.campaign_group_id AS STRING)) AS campaign_id,
    CONCAT('linkedin_ads_', CAST(cmh.account_id AS STRING)) AS account_id,
    COALESCE(CAST(la.cost_in_usd AS FLOAT64), 0) AS spend,
    COALESCE(la.impressions, 0) AS impressions,
    COALESCE(la.clicks, 0) AS clicks
  FROM {{ linkedin_ad_analytics_by_creative }} la
  CROSS JOIN inputs
  INNER JOIN linkedin_dates ld
    ON la.creative_id = ld.creative_id
    AND ld.at_date = inputs.at_date
  -- Get campaign_id from creative_history
  INNER JOIN (
    SELECT
      id,
      campaign_id,
      ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_at DESC) AS rn
    FROM {{ linkedin_creative_history }}
  ) crh
    ON la.creative_id = crh.id
    AND crh.rn = 1
  -- Get campaign_group_id and account_id from campaign_history
  INNER JOIN (
    SELECT
      id,
      campaign_group_id,
      account_id,
      ROW_NUMBER() OVER (PARTITION BY id ORDER BY last_modified_time DESC) AS rn
    FROM {{ linkedin_campaign_history }}
  ) cmh
    ON crh.campaign_id = cmh.id
    AND cmh.rn = 1
  WHERE CAST(la.day AS DATE) = inputs.at_date
  {% else %}
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
  {% endif %}
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
  LEFT JOIN `{{ var("bq_project_id") }}.{{ var("bq_dataset_id") }}.accounts` a
    ON lb.account_id = a.id

  GROUP BY lb.date, lb.earliest_date, lb.latest_date, lb.ad_id, lb.adset_id, lb.campaign_id, lb.account_id
),

-- SELECT * from linkedin_performance
-- ORDER BY ad_id;

--------------------------------------------------------------------
-- TikTok Performance (using ad_report_hourly - aggregated to daily)
--------------------------------------------------------------------

{% set tiktok_ad_report_hourly = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_tiktok_ads",
      identifier="ad_report_hourly"
) %}
tiktok_dates AS (
  {% if tiktok_ad_report_hourly is not none %}
  SELECT
    inputs.at_date,
    ad_id,
    MIN(DATE(stat_time_hour)) AS earliest_date,
    LEAST(MAX(DATE(stat_time_hour)), inputs.at_date) AS latest_date
  FROM {{ tiktok_ad_report_hourly }}
  CROSS JOIN inputs
  GROUP BY ad_id, inputs.at_date
  {% else %}
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

-- Unpivot TikTok conversion columns to rows
-- NOTE: TikTok stores conversions as inline columns (not rows like Facebook's basic_ad_actions table)
tiktok_conversion_counts AS (
  {% if tiktok_ad_report_hourly is not none %}
  SELECT date, ad_id, conversion_name, SUM(conversion_count) AS conversion_count
  FROM (
    SELECT
      DATE(stat_time_hour) AS date,
      CONCAT('tiktok_ads_', CAST(ad_id AS STRING)) AS ad_id,
      conversion_name,
      conversion_count
    FROM {{ tiktok_ad_report_hourly }}
    UNPIVOT (conversion_count FOR conversion_name IN (
      on_web_subscribe, user_registration, purchase, checkout, initiate_checkout,
      complete_payment, view_content, add_to_wishlist, page_event_search, download_start,
      web_event_add_to_cart, app_event_add_to_cart, registration, sales_lead, conversion,
      on_web_add_to_wishlist
    ))
  )
  GROUP BY 1, 2, 3
  {% else %}
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_count
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

tiktok_conversion_values AS (
  {% if tiktok_ad_report_hourly is not none %}
  SELECT date, ad_id, conversion_name, SUM(conversion_value) AS conversion_value
  FROM (
    SELECT
      DATE(stat_time_hour) AS date,
      CONCAT('tiktok_ads_', CAST(ad_id AS STRING)) AS ad_id,
      conversion_name,
      conversion_value
    FROM {{ tiktok_ad_report_hourly }}
    UNPIVOT (conversion_value FOR conversion_name IN (
      total_on_web_subscribe_value AS 'on_web_subscribe',
      total_user_registration_value AS 'user_registration',
      total_purchase_value AS 'purchase',
      total_checkout_value AS 'checkout',
      total_initiate_checkout_value AS 'initiate_checkout',
      total_view_content_value AS 'view_content',
      total_add_to_wishlist_value AS 'add_to_wishlist',
      total_page_event_search_value AS 'page_event_search',
      total_download_start_value AS 'download_start',
      total_web_event_add_to_cart_value AS 'web_event_add_to_cart',
      total_app_event_add_to_cart_value AS 'app_event_add_to_cart',
      total_sales_lead_value AS 'sales_lead',
      total_on_web_add_to_wishlist_value AS 'on_web_add_to_wishlist'
    ))
  )
  GROUP BY 1, 2, 3
  {% else %}
  SELECT
    CAST(NULL AS DATE) as date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS STRING) as conversion_name,
    CAST(NULL AS FLOAT64) as conversion_value
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
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

{% set tiktok_ad_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_tiktok_ads",
      identifier="ad_history"
) %}
tiktok_base AS (
  {% if tiktok_ad_report_hourly is not none and tiktok_ad_history is not none %}
  SELECT
    DATE(tr.stat_time_hour) AS date,
    td.earliest_date,
    td.latest_date,
    CONCAT('tiktok_ads_', CAST(tr.ad_id AS STRING)) AS ad_id,
    CONCAT('tiktok_ads_', CAST(ah.adgroup_id AS STRING)) AS adset_id,
    CONCAT('tiktok_ads_', CAST(ah.campaign_id AS STRING)) AS campaign_id,
    CONCAT('tiktok_ads_', CAST(ah.advertiser_id AS STRING)) AS account_id,
    SUM(tr.spend) AS spend,
    SUM(tr.impressions) AS impressions,
    SUM(tr.clicks) AS clicks
  FROM {{ tiktok_ad_report_hourly }} tr
  INNER JOIN (
    SELECT
      ad_id,
      adgroup_id,
      campaign_id,
      advertiser_id,
      ROW_NUMBER() OVER (PARTITION BY ad_id ORDER BY updated_at DESC) AS rn
    FROM {{ tiktok_ad_history }}
  ) ah
    ON tr.ad_id = ah.ad_id
    AND ah.rn = 1
  CROSS JOIN inputs
  INNER JOIN tiktok_dates td
    ON tr.ad_id = td.ad_id
    AND td.at_date = inputs.at_date
  WHERE DATE(tr.stat_time_hour) = inputs.at_date
  GROUP BY
    DATE(tr.stat_time_hour),
    td.earliest_date,
    td.latest_date,
    tr.ad_id,
    ah.adgroup_id,
    ah.campaign_id,
    ah.advertiser_id
  {% else %}
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
  {% endif %}
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
  LEFT JOIN `{{ var("bq_project_id") }}.{{ var("bq_dataset_id") }}.accounts` a
    ON tb.account_id = a.id
  GROUP BY tb.date, tb.earliest_date, tb.latest_date, tb.ad_id, tb.adset_id, tb.campaign_id, tb.account_id
),

--------------------------------------------------------------------
-- Bing/Microsoft Performance (using raw Fivetran table with SUM aggregation)
--------------------------------------------------------------------
{% set bing_ad_performance_daily_report = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_bing_ads",
      identifier="ad_performance_daily_report"
) %}
bing_dates AS (
  {% if bing_ad_performance_daily_report is not none %}
  SELECT
    inputs.at_date,
    ad_id,
    MIN(date) AS earliest_date,
    LEAST(MAX(date), inputs.at_date) AS latest_date
  FROM {{bing_ad_performance_daily_report}}
  CROSS JOIN inputs
  GROUP BY ad_id, inputs.at_date
  {% else %}
  SELECT
    CAST(NULL AS DATE) as at_date,
    CAST(NULL AS STRING) as ad_id,
    CAST(NULL AS DATE) as earliest_date,
    CAST(NULL AS DATE) as latest_date
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

-- Ad-level conversions with goal names (same pattern as Google's ads_conversions)
{% set bing_destination_url_performance_daily_report = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("bq_dataset_id") ~ "_bing_ads",
      identifier="destination_url_performance_daily_report"
) %}
bing_conversions AS (
  {% if bing_destination_url_performance_daily_report is not none %}
  SELECT
    date AS date,
    CONCAT('bingads_', CAST(ad_id AS STRING)) AS ad_id,
    CONCAT('bingads_', CAST(ad_group_id AS STRING)) AS adset_id,
    CONCAT('bingads_', CAST(campaign_id AS STRING)) AS campaign_id,
    CONCAT('bingads_', CAST(account_id AS STRING)) AS account_id,
    goal AS conversion_name,
    SUM(conversions) AS conversion_count,
    SUM(revenue) AS conversion_value
  FROM {{ bing_destination_url_performance_daily_report }}
  WHERE goal IS NOT NULL AND goal != ''
  GROUP BY date, ad_id, ad_group_id, campaign_id, account_id, goal
  {% else %}
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
  {% endif %}
),

bing_base AS (
  {% if bing_ad_performance_daily_report is not none %}
  SELECT
    br.date AS date,
    bd.earliest_date,
    bd.latest_date,
    CONCAT('bingads_', CAST(br.ad_id AS STRING)) AS ad_id,
    CONCAT('bingads_', CAST(br.ad_group_id AS STRING)) AS adset_id,
    CONCAT('bingads_', CAST(br.campaign_id AS STRING)) AS campaign_id,
    CONCAT('bingads_', CAST(br.account_id AS STRING)) AS account_id,
    -- FIX: Use SUM() to aggregate dimension breakdown rows (device_os, device_type, network)
    -- Raw table has multiple rows per ad per day that need to be summed
    SUM(COALESCE(br.spend, 0)) AS spend,
    SUM(COALESCE(br.impressions, 0)) AS impressions,
    SUM(COALESCE(br.clicks, 0)) AS clicks
  FROM {{ bing_ad_performance_daily_report }} br
  CROSS JOIN inputs
  INNER JOIN bing_dates bd
    ON br.ad_id = bd.ad_id
    AND bd.at_date = inputs.at_date
  WHERE br.date = inputs.at_date
  GROUP BY
    br.date,
    bd.earliest_date,
    bd.latest_date,
    br.ad_id,
    br.ad_group_id,
    br.campaign_id,
    br.account_id
    {% else %}
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

    {% endif %}
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
  LEFT JOIN `{{ var("bq_project_id") }}.{{ var("bq_dataset_id") }}.accounts` a
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
  -- LEFT JOIN `{{ var("bq_project_id") }}.{{ var("bq_dataset_id") }}.ads` ad
  LEFT JOIN {{ ref('ads') }} ad
    ON p.ad_id = ad.id
  -- LEFT JOIN `{{ var("bq_project_id") }}.{{ var("bq_dataset_id") }}.adsets` adset
  LEFT JOIN {{ ref('adsets') }} adset
    ON p.adset_id = adset.id
  -- LEFT JOIN `{{ var("bq_project_id") }}.{{ var("bq_dataset_id") }}.campaigns` c
  LEFT JOIN {{ ref('campaigns') }} c
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
