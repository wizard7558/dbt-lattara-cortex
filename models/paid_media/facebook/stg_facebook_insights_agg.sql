select ad_id
     , date
     , account_id
     , adset_id
     , campaign_id
     , sum(inline_link_clicks) as total_clicks
     , sum(impressions) as total_impressions
     , sum(spend) as total_spend
from `facebook_ads.ads_insights`
group by ad_id
     , date
     , account_id
     , adset_id
     , campaign_id