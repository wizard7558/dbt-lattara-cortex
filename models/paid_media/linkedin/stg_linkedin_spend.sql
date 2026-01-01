with campaigns as (
select cast(day as date) as date
     , creative_id as creativeid
     , cost_in_usd as cost
     , sends + impressions as impressions
     , clicks as clicks
     , one_click_leads as leads
     , opens as opens
     , one_click_lead_form_opens as leadformopens
     , approximate_member_reach as reach
from `linkedin_ads.ad_analytics_by_creative`
),
latest_creative as (
select id
     , campaign_id
     , row_number() over(partition by id order by last_modified_at desc) as version_rank
from `linkedin_ads.creative_history`
qualify row_number() over(partition by id order by last_modified_at desc) = 1
),
latest_campaign as (
select id
     , name
     , campaign_group_id
     , row_number() over(partition by id order by last_modified_time desc) as version_rank
from `linkedin_ads.campaign_history`
qualify row_number() over(partition by id order by last_modified_time desc) = 1
),
latest_campaign_group as (
select id
     , name
     , account_id
     , row_number() over(partition by id order by last_modified_time desc) as version_rank
from `linkedin_ads.campaign_group_history`
qualify row_number() over(partition by id order by last_modified_time desc) = 1
),
latest_account as (
select id
     , name
     , row_number() over(partition by id order by last_modified_time desc) as version_rank
from `linkedin_ads.account_history`
qualify row_number() over(partition by id order by last_modified_time desc) = 1
)
select c.date
     , a.name as account
     , cg.name as campaigngroup
     , camp.name as campaign
     , camp.id as campaignid
     , c.creativeid
     , coalesce(c.cost,0) as cost
     , coalesce(c.impressions,0) as impressions
     , coalesce(c.clicks,0) as clicks
     , coalesce(c.leads,0) as leads
     , c.opens
     , coalesce(c.leadformopens,0) as leadformopens
     , c.reach
from campaigns c
left join latest_creative cr
       on cr.id = c.creativeid
left join latest_campaign camp
       on camp.id = cr.campaign_id
left join latest_campaign_group cg
       on cg.id = camp.campaign_group_id
left join latest_account a
       on a.id = cg.account_id
order by c.date desc