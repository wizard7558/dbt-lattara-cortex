{{config(materialized = "table")}} 

select Date
     , "Meta" as Platform
     , Account
     , Campaign
     , sum(Spend) as Spend
     , sum(Impressions) as Impressions
     , sum(Clicks) as Clicks
     , sum(revenue) as Revenue
from {{ ref('facebook_ads_performance') }}
group by 1,2,3,4
union all
select date_day
     , "Google" as Platform
     , account_name
     , campaign_name
     , sum(spend) as Spend
     , sum(impressions) as Impressions
     , sum(clicks) as Clicks
     , sum(conversions_value) as Revenue
from `google_ads_v2_google_ads.google_ads__campaign_report`
group by 1,2,3,4
union all
select date
     , "TikTok" as Platform
     , account
     , campaign
     , sum(Spend) as Spend
     , sum(Impressions) as Impressions
     , sum(Clicks) as Clicks
     , sum(total_purchase_value) as Revenue
from {{ ref('tiktok_ads_performance') }}
group by 1,2,3,4
union all
select Date
     , "LinkedIn" as Platform
     , Account
     , Campaign
     , sum(Spend) as Spend
     , sum(Impressions) as Impressions
     , sum(Clicks) as Clicks
     , sum(Revenue) as Revenue
from {{ ref('linkedin_ads_performance') }}
where Spend > 0 
group by 1,2,3,4
order by 1 desc, 2 asc, 5 desc