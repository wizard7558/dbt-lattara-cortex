{{
    config(
        materialized = "table",
        database=var("bq_project_id"),
        schema=var("bq_dataset_id"),
    )
}}

WITH


{% set google_keyword_conversions = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_google_dataset"),
      identifier="keyword_conversions"
) %}
google_conv AS (
     {% if google_keyword_conversions is not none %}
     SELECT
          "google_ads" as ad_network_id,
          CONCAT("google_ads_", customer_id) as account_id,
          conversion_action_name as conversion_name,
          COUNT(*) as count
     FROM {{ google_keyword_conversions}}
     GROUP BY account_id, conversion_action_name
     {% else %}
     SELECT
          CAST(NULL AS STRING) as ad_network_id,
          CAST(NULL AS STRING) as account_id,
          CAST(NULL AS STRING) as conversion_name,
          CAST(NULL AS INTEGER) as count
     FROM (SELECT 1) WHERE FALSE
     {% endif %}
),


{% set facebook_basic_ad_actions = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_facebook_dataset"),
      identifier="basic_ad_actions"
) %}
{% set facebook_basic_ad = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_facebook_dataset"),
      identifier="basic_ad"
) %}

facebook_conv AS (
     {% if facebook_basic_ad_actions is not none and facebook_basic_ad is not none %}
     WITH facebook_ad_conversions AS (
     SELECT
          ad_id,
          action_type as conversion_name,
          COUNT(*) as count
     FROM {{ facebook_basic_ad_actions }}
     GROUP BY ad_id, action_type
     ),

     facebook_ad_accounts AS (
     SELECT
          ad_id,
          account_id
     FROM {{ facebook_basic_ad }}
     GROUP BY ad_id, account_id
     ),

     facebook_ad_accounts_conversions AS (
     SELECT
          "facebook_ads" as ad_network_id,
          CONCAT("facebook_ads_",aa.account_id) as account_id,
          ac.conversion_name,
          COALESCE(ac.count, 0) as count

     FROM facebook_ad_accounts aa
     JOIN facebook_ad_conversions ac
          ON aa.ad_id = ac.ad_id
     )

     SELECT
          faac.ad_network_id,
          faac.account_id,
          faac.conversion_name,
          SUM(faac.count) AS count
          FROM facebook_ad_accounts_conversions faac
          GROUP BY faac.ad_network_id, faac.account_id, faac.conversion_name

     {% else %}
     SELECT
          CAST(NULL AS STRING) as ad_network_id,
          CAST(NULL AS STRING) as account_id,
          CAST(NULL AS STRING) as conversion_name,
          CAST(NULL AS INTEGER) as count
     FROM (SELECT 1) WHERE FALSE
     {% endif %}
),


{% set linkedin_conversion_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_linkedin_dataset"),
      identifier="conversion_history"
) %}
linkedin_conv as (
     {% if linkedin_conversion_history %}
     SELECT
          "linkedin_ads" as ad_network_id,
          CONCAT("linkedin_ads_",account_id) as account_id,
          name as conversion_name,
          COUNT(*) as count
     FROM {{ linkedin_conversion_history }}
     GROUP BY account_id, name
     {% else %}
     SELECT
          CAST(NULL AS STRING) as ad_network_id,
          CAST(NULL AS STRING) as account_id,
          CAST(NULL AS STRING) as conversion_name,
          CAST(NULL AS INTEGER) as count
     FROM (SELECT 1) WHERE FALSE
     {% endif %}
),

{% set tiktok_ad_report_hourly = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_tiktok_dataset"),
      identifier="ad_report_hourly"
) %}
{% set tiktok_ad_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_tiktok_dataset"),
      identifier="ad_history"
) %}
tiktok_conv as (
{% if tiktok_ad_report_hourly is not none and tiktok_ad_history is not none %}
-- TikTok stores conversions as inline columns, unpivot to get conversion_name/count format
select "tiktok_ads" as ad_network_id
     , CONCAT("tiktok_ads_", CAST(ah.advertiser_id AS STRING)) as account_id
     , conversion_name
     , sum(conversion_count) as count
from (
  select ad_id, conversion_name, conversion_count
  from {{ tiktok_ad_report_hourly }}
  unpivot (conversion_count for conversion_name in (
    on_web_subscribe, user_registration, purchase, checkout, initiate_checkout,
    complete_payment, view_content, add_to_wishlist, page_event_search, download_start,
    web_event_add_to_cart, app_event_add_to_cart, registration, sales_lead, conversion,
    on_web_add_to_wishlist
  ))
) unpivoted
left join (
  select distinct ad_id
       , first_value(advertiser_id) over(partition by ad_id order by create_time desc) as advertiser_id
  from {{ tiktok_ad_history }}
) ah on unpivoted.ad_id = ah.ad_id
where conversion_count > 0
group by 1,2,3
{% else %}
SELECT
     CAST(NULL AS STRING) as ad_network_id,
     CAST(NULL AS STRING) as account_id,
     CAST(NULL AS STRING) as conversion_name,
     CAST(NULL AS INTEGER) as count
FROM (SELECT 1) WHERE FALSE
{% endif %}
),


{% set bing_destination_url_performance_daily_report = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_bingads_dataset"),
      identifier="destination_url_performance_daily_report"
) %}
bing_conv as (
{% if bing_destination_url_performance_daily_report is not none %}
-- Bing/Microsoft Ads conversions from destination_url_performance_daily_report (ad-level with goal names)
select "bingads" as ad_network_id
     , CONCAT("bingads_", CAST(account_id AS STRING)) as account_id
     , goal as conversion_name
     , sum(conversions) as count
from {{ bing_destination_url_performance_daily_report }}
where goal is not null and goal != ''
group by 1,2,3
{% else %}
SELECT
     CAST(NULL AS STRING) as ad_network_id,
     CAST(NULL AS STRING) as account_id,
     CAST(NULL AS STRING) as conversion_name,
     CAST(NULL AS INTEGER) as count
FROM (SELECT 1) WHERE FALSE
{% endif %}
)

select * from google_conv

union all

select * from facebook_conv

union all

select * from linkedin_conv

union all

select * from tiktok_conv

union all

select * from bing_conv
