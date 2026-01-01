{{config(materialized = "table")}} 

with base_data as (
select coalesce(s.date, c.date) as date
     , coalesce(s.account, c.account) as account
     , coalesce(s.campaigngroup, c.campaign_group) as campaign_group
     , coalesce(s.campaign, c.campaign) as campaign
     , coalesce(s.campaignid, c.campaign_id) as campaign_id
     , coalesce(s.creativeid, c.creative_id) as creative_id
     , c.conversion
     , s.cost as spend
     , s.impressions
     , s.reach
     , s.clicks
     , c.external_website_conversions as conversions
     , c.revenue
     , s.leads
     , s.opens
     , s.leadformopens
from {{ ref('stg_linkedin_spend') }} s
full outer join {{ ref('stg_linkedin_conversions') }} c
             on s.creativeid = c.creative_id
            and s.date = c.date
            and s.campaignid = c.campaign_id
)
select date as date
     , cast(date_trunc(date, week) as date) + 1 as weekstart
     , date_trunc(date, month) as month
     , account as account
     , campaign_group as campaigngroup
     , campaign as campaign
     , campaign_id as campaignid
     , creative_id as creativeid
     , conversion as conversion
     , sum(coalesce(spend, 0)) as spend
     , sum(coalesce(impressions, 0)) as impressions
     , sum(coalesce(reach, 0)) as reach
     , sum(coalesce(clicks, 0)) as clicks
     , sum(coalesce(conversions, 0)) as conversions
     , sum(coalesce(revenue, 0)) as revenue
     , sum(coalesce(leads, 0)) as leads
     , sum(coalesce(opens, 0)) as opens
     , sum(coalesce(leadformopens, 0)) as leadformopens
     , safe_divide(sum(coalesce(spend, 0)), sum(coalesce(clicks, 0))) as cpc
     , safe_divide(sum(coalesce(spend, 0)), sum(coalesce(conversions, 0))) as cpa
     , safe_divide(sum(coalesce(clicks, 0)), sum(coalesce(impressions, 0))) * 100 as ctr
     , safe_divide(sum(coalesce(conversions, 0)), sum(coalesce(clicks, 0))) * 100 as cvr
from base_data
group by 1
       , 2
       , 3
       , 4
       , 5
       , 6
       , 7
       , 8
       , 9