/*
  Staging model for Allied Team Google Ads (YouTube) data

  Data Sources:
  1. allied_team.google_ads_funnel (Funnel.io via Fivetran) - WFP campaigns
  2. google_ads_allied_team.ad_stats (Fivetran direct) - CSAH 2026 campaigns

  Supports multiple campaigns:
  - WFP campaigns (23202415135, 23198130224, 23211264475)
  - CSAH 2026 campaigns (campaign name starts with 2026_A001_CSAH)

  Media channel mapping:
  - WFP: Based on campaign_id
  - CSAH: Based on advertising_channel_subtype

  Plan section mapping:
  - WFP: Based on audience field
  - CSAH: Based on ad_group_name (beltway → Contextual, geofence → Zipcode)
*/

-- Legacy Funnel.io source for WFP campaigns
with funnel_source as (
    select * from {{ source('allied_team', 'google_ads_funnel') }}
    where campaign_id in (23202415135, 23198130224, 23211264475)
),

funnel_mapped as (
    select
        -- Date & IDs
        date,
        cast(campaign_id as string) as campaign_id,
        cast(ad_group_id as string) as ad_group_id,
        cast(ad_id as string) as ad_id,

        -- Platform identification
        'Google YouTube' as platform_source,
        'Google Youtube' as partner_platform,

        -- Media channel mapping for WFP
        case
            when campaign_id = 23202415135 then 'Youtube Nonskip Video Ads'
            when campaign_id = 23198130224 then 'Youtube SHORTS'
            when campaign_id = 23211264475 then 'Youtube Skippable'
            else traffic_source
        end as media_channel,

        -- Plan section mapping for WFP
        case
            when audience = 'Geo Targeting College Campus' then 'Geo-Target College Campus'
            when audience is not null and audience != '' then audience
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
        cast(null as float64) as video_quartile_p_100_rate,
        cast(engagements as int64) as engagements,
        cast(interactions as int64) as interactions,

        -- Reach not available in Google Ads data
        cast(null as int64) as reach,

        -- Metadata
        currency,
        _fivetran_synced

    from funnel_source
),

-- New Fivetran direct source for CSAH 2026 campaigns
-- Using video_ad_stats for video quartile metrics
fivetran_stats as (
    select
        s.date,
        s.campaign_id,
        s.ad_group_id,
        s.ad_id,
        s.impressions,
        s.clicks,
        s.cost_micros,
        s.video_trueview_views,
        s.video_quartile_p_100_rate,
        s._fivetran_synced
    from {{ source('google_ads_allied_team', 'video_ad_stats') }} s
),

fivetran_campaigns as (
    select distinct
        id as campaign_id,
        name as campaign_name,
        advertising_channel_subtype
    from {{ source('google_ads_allied_team', 'campaign_history') }}
    where name like '2026_A001_CSAH%'
),

fivetran_ad_groups as (
    select distinct
        id as ad_group_id,
        campaign_id,
        name as ad_group_name
    from {{ source('google_ads_allied_team', 'ad_group_history') }}
),

fivetran_joined as (
    select
        s.date,
        s.campaign_id,
        s.ad_group_id,
        s.ad_id,
        s.impressions,
        s.clicks,
        s.cost_micros,
        s.video_trueview_views,
        s.video_quartile_p_100_rate,
        s._fivetran_synced,
        c.campaign_name,
        c.advertising_channel_subtype,
        ag.ad_group_name
    from fivetran_stats s
    inner join fivetran_campaigns c on s.campaign_id = c.campaign_id
    left join fivetran_ad_groups ag on s.ad_group_id = ag.ad_group_id
),

fivetran_mapped as (
    select
        -- Date & IDs
        date,
        cast(campaign_id as string) as campaign_id,
        cast(ad_group_id as string) as ad_group_id,
        cast(ad_id as string) as ad_id,

        -- Platform identification
        'Google YouTube' as platform_source,
        'Google Youtube' as partner_platform,

        -- Media channel mapping for CSAH based on advertising_channel_subtype
        case
            when advertising_channel_subtype = 'VIDEO_NON_SKIPPABLE' then 'YouTube Nonskip Video Ads'
            when advertising_channel_subtype = 'VIDEO_NON_SKIPPABLE_IN_STREAM' then 'YouTube Nonskip Video Ads'
            when advertising_channel_subtype = 'VIDEO_OUTSTREAM' then 'YouTube Outstream'
            when advertising_channel_subtype = 'VIDEO_ACTION' then 'YouTube Video Action'
            when advertising_channel_subtype like '%SKIPPABLE%' then 'YouTube Skippable Video Ads'
            else coalesce(advertising_channel_subtype, 'YouTube Video')
        end as media_channel,

        -- Plan section mapping for CSAH based on ad_group_name
        case
            when lower(ad_group_name) like '%beltway%' then 'Contextual Targeting'
            when lower(ad_group_name) like '%geofence%' then 'Zipcode Targeting'
            when lower(ad_group_name) like '%datamatch%' then 'Data Match'
            else coalesce(ad_group_name, 'Other')
        end as plan_section,

        -- Creative (use ad_group_name for now since ad names may not be meaningful)
        ad_group_name as creative,

        -- Original values for reference
        campaign_name as campaign,
        ad_group_name,
        cast(null as string) as original_ad_name,
        cast(null as string) as device,  -- Not available in video_ad_stats

        -- Metrics
        impressions,
        clicks,
        cost_micros / 1000000.0 as spend,
        -- For non-skippable video, completions = impressions (viewers must watch)
        case
            when advertising_channel_subtype in ('VIDEO_NON_SKIPPABLE', 'VIDEO_NON_SKIPPABLE_IN_STREAM')
            then impressions
            else video_trueview_views
        end as completions,
        video_trueview_views as video_views,
        cast(null as int64) as video_views_25pct,
        cast(null as int64) as video_views_50pct,
        cast(null as int64) as video_views_75pct,
        cast(null as int64) as video_views_100pct,
        video_quartile_p_100_rate,
        cast(null as int64) as engagements,
        cast(clicks as int64) as interactions,

        -- Reach not available in Google Ads data
        cast(null as int64) as reach,

        -- Metadata
        'USD' as currency,
        _fivetran_synced

    from fivetran_joined
),

-- Union both sources
combined as (
    select * from funnel_mapped
    union all
    select * from fivetran_mapped
)

select * from combined
order by date desc
