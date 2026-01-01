{{config(materialized = "table")}} 

with latest_history as (
select distinct ad_id
     , first_value(advertiser_id) over(partition by ad_id order by create_time desc) as advertiser_id
     , first_value(campaign_id) over(partition by ad_id order by updated_at desc) as campaign_id
     , first_value(adgroup_id) over(partition by ad_id order by updated_at desc) as adgroup_id
     , first_value(video_id) over(partition by ad_id order by updated_at desc) as video_id
     , first_value(ad_name) over(partition by ad_id order by updated_at desc) as ad_name
     , first_value(ad_format) over(partition by ad_id order by updated_at desc) as ad_format
     , first_value(creative_type) over(partition by ad_id order by updated_at desc) as creative_type
     , first_value(optimization_event) over(partition by ad_id order by updated_at desc) as optimization_event
from `tiktok_ads.ad_history`
),
advertiser_latest as (
select distinct id
     , first_value(name) over(partition by id order by create_time desc) as advertiser_name
from `tiktok_ads.advertiser`
),
campaign_latest as (
select distinct campaign_id
     , first_value(campaign_name) over(partition by campaign_id order by updated_at desc) as campaign_name
from `tiktok_ads.campaign_history`
),
adgroup_latest as (
select distinct adgroup_id
     , first_value(adgroup_name) over(partition by adgroup_id order by updated_at desc) as adgroup_name
from `tiktok_ads.adgroup_history`
)
select date(p.stat_time_day) as date
     , p.ad_id
     , ah.ad_name
     , ah.advertiser_id as accountid
     , adv.advertiser_name as account
     , ah.campaign_id
     , c.campaign_name as campaign
     , ah.adgroup_id
     , ag.adgroup_name
     , ah.video_id
     , ah.ad_format
     , ah.creative_type
     , ah.optimization_event
     , sum(p.impressions) as impressions
     , sum(p.clicks) as clicks
     , sum(p.spend) as spend
     , sum(p.reach) as reach
     , avg(p.ctr) as avg_ctr
     , avg(p.cpm) as avg_cpm
     , avg(p.cpc) as avg_cpc
     , sum(p.video_views_p_25) as video_views_25_percent
     , sum(p.video_views_p_50) as video_views_50_percent
     , sum(p.video_views_p_75) as video_views_75_percent
     , sum(p.video_views_p_100) as video_views_100_percent
     , sum(p.video_watched_2_s) as video_watched_2_seconds
     , sum(p.video_watched_6_s) as video_watched_6_seconds
     , avg(p.average_video_play) as avg_video_play_time
     , sum(p.video_play_actions) as video_play_actions
     , sum(p.likes) as likes
     , sum(p.comments) as comments
     , sum(p.shares) as shares
     , sum(p.follows) as follows
     , sum(p.profile_visits) as profile_visits
     , sum(p.engagements) as total_engagements
     , avg(p.engagement_rate) as avg_engagement_rate
     , sum(p.conversion) as conversions
     , avg(p.conversion_rate) as avg_conversion_rate
     , avg(p.cost_per_conversion) as avg_cost_per_conversion
     , sum(p.purchase) as purchases
     , avg(p.purchase_rate) as avg_purchase_rate
     , avg(p.cost_per_purchase) as avg_cost_per_purchase
     , sum(p.total_purchase_value) as total_purchase_value
     , sum(p.registration) as registrations
     , avg(p.registration_rate) as avg_registration_rate
     , avg(p.cost_per_registration) as avg_cost_per_registration
     , sum(p.user_registration) as user_registrations
     , sum(p.add_to_wishlist) as add_to_wishlist
     , sum(p.app_event_add_to_cart) as app_add_to_cart
     , sum(p.web_event_add_to_cart) as web_add_to_cart
     , sum(p.initiate_checkout) as initiate_checkout
     , sum(p.checkout) as checkouts
     , sum(p.complete_payment) as complete_payments
     , sum(p.product_details_page_browse) as product_page_views
     , sum(p.total_add_to_wishlist_value) as total_wishlist_value
     , sum(p.total_app_event_add_to_cart_value) as total_app_cart_value
     , sum(p.total_web_event_add_to_cart_value) as total_web_cart_value
     , sum(p.total_initiate_checkout_value) as total_initiate_checkout_value
     , sum(p.total_checkout_value) as total_checkout_value
     , sum(p.total_complete_payment_rate) as total_payment_value
     , sum(p.total_landing_page_view) as landing_page_views
     , avg(p.landing_page_view_rate) as avg_landing_page_view_rate
     , avg(p.cost_per_landing_page_view) as avg_cost_per_landing_page_view
     , sum(p.cta_app_install) as cta_app_installs
     , sum(p.vta_app_install) as vta_app_installs
     , sum(p.download_start) as download_starts
     , avg(p.download_start_rate) as avg_download_start_rate
     , sum(p.anchor_clicks) as anchor_clicks
     , sum(p.clicks_on_music_disc) as music_disc_clicks
     , sum(p.sound_usage_clicks) as sound_usage_clicks
     , sum(p.clicks_on_hashtag_challenge) as hashtag_challenge_clicks
     , sum(p.duet_clicks) as duet_clicks
     , sum(p.stitch_clicks) as stitch_clicks
     , sum(p.skan_conversion) as skan_conversions
     , avg(p.skan_cost_per_conversion) as avg_skan_cost_per_conversion
     , sum(p.skan_sales_lead) as skan_sales_leads
     , sum(p.skan_total_sales_lead_value) as skan_total_sales_lead_value
     , case
           when sum(p.spend) > 0 then sum(p.total_purchase_value) / sum(p.spend)
           else 0
       end as roas
     , avg(p.total_active_pay_roas) as avg_active_pay_roas
     , sum(p.result) as results
     , avg(p.result_rate) as avg_result_rate
     , avg(p.cost_per_result) as avg_cost_per_result
     , count(distinct p.ad_id) as active_ads_count
from `tiktok_ads.ad_report_daily` p
left join latest_history ah
       on p.ad_id = ah.ad_id
left join advertiser_latest adv
       on ah.advertiser_id = adv.id
left join campaign_latest c
       on ah.campaign_id = c.campaign_id
left join adgroup_latest ag
       on ah.adgroup_id = ag.adgroup_id
group by p.stat_time_day
       , p.ad_id
       , ah.ad_name
       , ah.advertiser_id
       , adv.advertiser_name
       , ah.campaign_id
       , c.campaign_name
       , ah.adgroup_id
       , ag.adgroup_name
       , ah.video_id
       , ah.ad_format
       , ah.creative_type
       , ah.optimization_event
order by p.stat_time_day desc
       , sum(p.spend) desc