/*
  Staging model for Allied Team Google Ads (YouTube) data
  Source: allied_team.google_ads_funnel (Funnel.io via Fivetran)
  
  Mapping applied per client spec:
  - Campaign 23202415135 (Z_YT_NonSkip_WFP) → YouTube Nonskip Video Ads
  - Campaign 23198130224 (Z_WFP_Shorts) → YouTube SHORTS  
  - Campaign 23211264475 (Z_WFP_Skippable_EfficientReach) → YouTube Skippable
  
  Creative renaming:
  - "Ad #1" → ":15 New Day"
  - "Z_WFP_Reach" → ":15 New Day"
*/

with source as (
    select * from {{ source('allied_team', 'google_ads_funnel') }}
),

mapped as (
    select
        -- Date & IDs
        date,
        campaign_id,
        ad_group_id,
        ad_id,
        
        -- Platform identification
        'Google YouTube' as platform_source,
        'Google Youtube' as partner_platform,
        
        -- Media channel mapping based on campaign_id
        case 
            when campaign_id = 23202415135 then 'Youtube Nonskip Video Ads'
            when campaign_id = 23198130224 then 'Youtube SHORTS'
            when campaign_id = 23211264475 then 'Youtube Skippable'
            else traffic_source
        end as media_channel,
        
        -- Plan section (audience)
        case
            when audience = 'Geo Targeting College Campus' then 'Geo-Target College Campus'
            else audience
        end as plan_section,
        
        -- Creative renaming per client spec
        case
            when ad_name = 'Ad #1' then ':15 New Day'
            when ad_name = 'Z_WFP_Reach' then ':15 New Day'
            when ad_name = ':15 NewDay' then ':15 New Day'
            else coalesce(creative, ad_name)
        end as creative,
        
        -- Original values for reference
        campaign,
        ad_group_name,
        ad_name as original_ad_name,
        device,
        
        -- Metrics
        impressions,
        clicks,
        coalesce(cost, cost_) as spend,
        completions,
        video_views,
        views_25_ as video_views_25pct,
        views_50_ as video_views_50pct,
        views_75_ as video_views_75pct,
        views_100_ as video_views_100pct,
        engagements,
        interactions,
        
        -- Reach not available in Google Ads data
        cast(null as int64) as reach,
        
        -- Metadata
        currency,
        _fivetran_synced
        
    from source
    where campaign_id in (23202415135, 23198130224, 23211264475)  -- WFP campaigns only
)

select * from mapped
