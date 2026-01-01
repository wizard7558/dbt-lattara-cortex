-- with google_conv as (

-- select "google_ads" as ad_network_id
--      , CONCAT("google_ads_",customer_id) as account_id
--      , conversion_action_name as conversion_name
--      , sum(conversions) as count
-- from {{ ref('google_conversions') }}
-- group by 1,2,3
-- ),

with facebook_conv as (

select "facebook_ads" as ad_network_id
     , CONCAT("facebook_ads_",act.accountid) as account_id
     , act.conversionname as conversion_name
     , sum(allconv) as count
from {{ ref('facebook_ads_performance') }} act
group by 1,2,3
)
-- ),

-- linkedin_conv as (

-- select "linkedin_ads" as ad_network_id
--      , CONCAT("linkedin_ads_",account_id) as account_id
--      , conversion as conversion_name
--      , sum(external_website_conversions) as count
-- from {{ ref('stg_linkedin_conversions') }}
-- group by 1,2,3
-- ),

-- tiktok_conv as (
-- -- TikTok stores conversions as inline columns, unpivot to get conversion_name/count format
-- select "tiktok_ads" as ad_network_id
--      , CONCAT("tiktok_ads_", CAST(ah.advertiser_id AS STRING)) as account_id
--      , conversion_name
--      , sum(conversion_count) as count
-- from (
--   select ad_id, conversion_name, conversion_count
--   from `mavan-analytics.tiktok_ads.ad_report_hourly`
--   unpivot (conversion_count for conversion_name in (
--     on_web_subscribe, user_registration, purchase, checkout, initiate_checkout,
--     complete_payment, view_content, add_to_wishlist, page_event_search, download_start,
--     web_event_add_to_cart, app_event_add_to_cart, registration, sales_lead, conversion,
--     on_web_add_to_wishlist
--   ))
-- ) unpivoted
-- left join (
--   select distinct ad_id
--        , first_value(advertiser_id) over(partition by ad_id order by create_time desc) as advertiser_id
--   from `mavan-analytics.tiktok_ads.ad_history`
-- ) ah on unpivoted.ad_id = ah.ad_id
-- where conversion_count > 0
-- group by 1,2,3
-- ),

-- bing_conv as (
-- -- Bing/Microsoft Ads conversions from destination_url_performance_daily_report (ad-level with goal names)
-- select "bingads" as ad_network_id
--      , CONCAT("bingads_", CAST(account_id AS STRING)) as account_id
--      , goal as conversion_name
--      , sum(conversions) as count
-- from `mavan-analytics.bingads.destination_url_performance_daily_report`
-- where goal is not null and goal != ''
-- group by 1,2,3
-- )

-- select * from google_conv

-- union all

select * from facebook_conv

-- union all

-- select * from linkedin_conv

-- union all

-- select * from tiktok_conv

-- union all

-- select * from bing_conv