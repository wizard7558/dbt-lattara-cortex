{{config(materialized = "table")}} 

select 
    i.ad_id as AdID,
    i.date as Date,
    cast(date_trunc(cast(i.date as timestamp), week) as date) + 1 as Week_Start,
    i.account_id as AccountID,
    acc.name as Account,
    ad.name as Ad,
    i.adset_id as AdsetID,
    ads.name as Adset,
    i.campaign_id as CampaignID,
    c.name as Campaign,
    a.action_type as conversionname,
    a.total_value as allconv,
    coalesce(cv.revenue, 0) as revenue,
    coalesce(cv.purchase_revenue, 0) as purchase_revenue,
    case 
        when a.action_count is null then i.total_clicks
        else i.total_clicks / a.action_count 
    end as Clicks,
    case 
        when a.action_count is null then i.total_impressions
        else i.total_impressions / a.action_count 
    end as Impressions,
    case 
        when a.action_count is null then i.total_spend
        else i.total_spend / a.action_count 
    end as Spend
from {{ ref('stg_facebook_insights_agg') }} i
left join {{ ref('stg_facebook_actions_agg') }} a on i.ad_id = a.ad_id and i.date = a.date
left join {{ ref('stg_facebook_conversion_values_agg') }} cv on i.ad_id = cv.ad_id and i.date = cv.date and a.action_type = cv.action_type
left join {{ ref('stg_facebook_latest_ad') }} ad on cast(i.ad_id as int64) = cast(ad.id as int64)
left join {{ ref('stg_facebook_latest_adset') }} ads on cast(i.adset_id as int64) = cast(ads.id as int64)
left join {{ ref('stg_facebook_latest_campaign') }} c on cast(i.campaign_id as int64) = cast(c.id as int64)
left join {{ ref('stg_facebook_latest_account') }} acc on cast(i.account_id as string) = cast(acc.id as string)