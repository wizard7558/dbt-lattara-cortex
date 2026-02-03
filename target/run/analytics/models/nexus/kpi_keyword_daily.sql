
  
    

    create or replace table `res-analytics`.`cortex`.`kpi_keyword_daily`
      
    partition by date
    

    
    OPTIONS()
    as (
      

-- KPI Keyword Daily: Daily keyword-level performance metrics with KPI mapping
-- Currently Google Ads only (keywords are specific to search campaigns)

WITH
inputs AS (
  SELECT at_date
  FROM UNNEST(
    GENERATE_DATE_ARRAY(
      DATE('2026-01-25'),
      DATE('2026-02-01'),
      INTERVAL 1 DAY
    )
  ) AS at_date
),

--------------------------------------------------------------------
-- Google Keyword Performance
--------------------------------------------------------------------
google_keyword_dates AS (
  SELECT
    inputs.at_date,
    ad_group_criterion_criterion_id AS keyword_id,
    MIN(date) AS earliest_date,
    LEAST(MAX(date), inputs.at_date) AS latest_date
  FROM `res-analytics`.`google_ads_v2`.`keyword_stats`
  CROSS JOIN inputs
  GROUP BY ad_group_criterion_criterion_id, inputs.at_date
),

google_keyword_conversions AS (
  SELECT
    date,
    CONCAT('google_ads_', CAST(ad_group_criterion_criterion_id AS STRING)) AS keyword_id,
    conversion_action_name AS conversion_name,
    SUM(all_conversions) AS conversion_count,
    SUM(all_conversions_value) AS conversion_value
  FROM `res-analytics`.`google_ads_v2`.`keyword_conversions`
  WHERE conversion_action_name IS NOT NULL
  GROUP BY date, ad_group_criterion_criterion_id, conversion_action_name
),

google_keyword_base AS (
  SELECT
    ks.date,
    gd.earliest_date,
    gd.latest_date,
    CONCAT('google_ads_', CAST(ks.ad_group_criterion_criterion_id AS STRING)) AS keyword_id,
    CONCAT('google_ads_', CAST(ks.ad_group_id AS STRING)) AS adset_id,
    CONCAT('google_ads_', CAST(ks.campaign_id AS STRING)) AS campaign_id,
    CONCAT('google_ads_', CAST(ks.customer_id AS STRING)) AS account_id,
    SUM(COALESCE(ks.cost_micros, 0)) / 1000000.0 AS spend,
    SUM(COALESCE(ks.impressions, 0)) AS impressions,
    SUM(COALESCE(ks.clicks, 0)) AS clicks
  FROM `res-analytics`.`google_ads_v2`.`keyword_stats` ks
  CROSS JOIN inputs
  INNER JOIN google_keyword_dates gd
    ON ks.ad_group_criterion_criterion_id = gd.keyword_id
    AND gd.at_date = inputs.at_date
  WHERE ks.date = inputs.at_date
  GROUP BY ks.date, gd.earliest_date, gd.latest_date, ks.ad_group_criterion_criterion_id, ks.ad_group_id, ks.campaign_id, ks.customer_id
),

google_keyword_performance AS (
  SELECT
    gb.date,
    gb.earliest_date,
    gb.latest_date,
    gb.keyword_id,
    gb.adset_id,
    gb.campaign_id,
    gb.account_id,
    MAX(gb.spend) AS spend,
    MAX(gb.impressions) AS impressions,
    MAX(gb.clicks) AS clicks,

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

  FROM google_keyword_base gb
  LEFT JOIN google_keyword_conversions gc
    ON gb.date = gc.date
    AND gb.keyword_id = gc.keyword_id
  LEFT JOIN `res-analytics`.`com_allied`.`accounts` a
    ON gb.account_id = a.id
  GROUP BY gb.date, gb.earliest_date, gb.latest_date, gb.keyword_id, gb.adset_id, gb.campaign_id, gb.account_id
),

--------------------------------------------------------------------
-- All Keyword Performance
--------------------------------------------------------------------
all_performance AS (
  SELECT * FROM google_keyword_performance
),

--------------------------------------------------------------------
-- Join with dimension tables
--------------------------------------------------------------------
joined_data AS (
  SELECT
    p.date,
    p.earliest_date,
    p.latest_date,
    DATE_DIFF(p.date, p.earliest_date, DAY) AS age_days,

    p.keyword_id,
    kw.keyword_name,
    kw.match_type,
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
    p.clicks,

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

  FROM all_performance p
  LEFT JOIN `res-analytics`.`cortex`.`keywords` kw
    ON p.keyword_id = kw.id
  LEFT JOIN `res-analytics`.`com_allied`.`adsets` adset
    ON p.adset_id = adset.id
  LEFT JOIN `res-analytics`.`com_allied`.`campaigns` c
    ON p.campaign_id = c.id
),

final AS (
  SELECT
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
    keyword_id,
    keyword_name,
    match_type,
    spend,
    impressions,
    clicks,

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
    keyword_id,
    keyword_name,
    match_type,
    spend,
    impressions,
    clicks,
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
    );
  