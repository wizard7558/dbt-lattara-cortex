/*
  Staging model for Allied Team Google Ads (YouTube) data
  Source: allied_team.google_ads_funnel (Funnel.io via Fivetran)

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

with source as (
    select * from {{ source('allied_team', 'google_ads_funnel') }}
),

mapped as (
    select
        -- Date & IDs
        date,
        cast(campaign_id as string) as campaign_id,
        ad_group_id,
        ad_id,

        -- Platform identification
        'Google YouTube' as platform_source,
        'Google Youtube' as partner_platform,

        -- Media channel mapping
        case
            -- WFP campaigns - map by campaign_id
            when campaign_id = 23202415135 then 'Youtube Nonskip Video Ads'
            when campaign_id = 23198130224 then 'Youtube SHORTS'
            when campaign_id = 23211264475 then 'Youtube Skippable'
            -- CSAH campaigns - map by advertising_channel_subtype
            when campaign like '2026_A001_CSAH%' then
                case
                    when advertising_channel_subtype = 'VIDEO_NON_SKIPPABLE_IN_STREAM' then 'YouTube Nonskip Video Ads'
                    when advertising_channel_subtype = 'VIDEO_OUTSTREAM' then 'YouTube Outstream'
                    when advertising_channel_subtype = 'VIDEO_ACTION' then 'YouTube Video Action'
                    when advertising_channel_subtype like '%SKIPPABLE%' then 'YouTube Skippable Video Ads'
                    else coalesce(advertising_channel_subtype, traffic_source)
                end
            else traffic_source
        end as media_channel,

        -- Plan section mapping
        case
            -- WFP campaigns - use audience
            when audience = 'Geo Targeting College Campus' then 'Geo-Target College Campus'
            when audience is not null and audience != '' then audience
            -- CSAH campaigns - map ad_group_name
            when campaign like '2026_A001_CSAH%' then
                case
                    when lower(ad_group_name) like '%beltway%' then 'Contextual Targeting'
                    when lower(ad_group_name) like '%geofence%' then 'Zipcode Targeting'
                    else coalesce(ad_group_name, 'Other')
                end
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
    -- Include WFP campaigns OR CSAH campaigns
    where campaign_id in (23202415135, 23198130224, 23211264475)
       or campaign like '2026_A001_CSAH%'
)

select * from mapped
