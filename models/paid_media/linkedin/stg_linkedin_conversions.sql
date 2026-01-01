
with campaigns as (
select cast(day as date) as date
     , creative_id
     , conversion_id
     , sum(external_website_conversions) as external_website_conversions
     , sum(conversion_value_in_local_currency) as revenue
from `linkedin_ads.ad_analytics_by_creative_with_conversion_breakdown`
where external_website_conversions > 0
group by 1
       , 2
       , 3
),
latest_entities as (
select cr.id as creative_id
     , cr.campaign_id
     , camp.name as campaign_name
     , camp.id as campaign_id_final
     , camp.campaign_group_id
     , cg.name as campaign_group_name
     , cg.account_id
     , a.name as account_name
from (
    select id
         , campaign_id
    from `linkedin_ads.creative_history`
    qualify row_number() over(partition by id order by last_modified_at desc) = 1
) cr
left join (
    select id
         , name
         , campaign_group_id
    from `linkedin_ads.campaign_history`
    qualify row_number() over(partition by id order by last_modified_time desc) = 1
) camp
       on camp.id = cr.campaign_id
left join (
    select id
         , name
         , account_id
    from `linkedin_ads.campaign_group_history`
    qualify row_number() over(partition by id order by last_modified_time desc) = 1
) cg
       on cg.id = camp.campaign_group_id
left join (
    select id
         , name
    from `linkedin_ads.account_history`
    qualify row_number() over(partition by id order by last_modified_time desc) = 1
) a
       on a.id = cg.account_id
),
latest_conversion as (
select id
     , name
from `linkedin_ads.conversion_history`
qualify row_number() over(partition by id order by last_modified desc) = 1
)
select c.date
     , le.account_id as account_id
     , le.account_name as account
     , le.campaign_group_name as campaign_group
     , le.campaign_name as campaign
     , le.campaign_id_final as campaign_id
     , c.creative_id
     , conv.name as conversion
     , c.external_website_conversions
     , c.revenue
from campaigns c
left join latest_entities le
       on le.creative_id = c.creative_id
left join latest_conversion conv
       on c.conversion_id = conv.id
where le.campaign_id_final is not null