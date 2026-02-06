{{
  config(
    materialized='view',
    schema='allied_team'
  )
}}

/*
  Google Ads (YouTube) Enhanced Staging Model

  Sources (Fivetran):
  - video_ad_stats: Ad-level video quartiles, impressions

  Calculation Logic:
    impressions = Google Ads impressions (already total, not unique)
    reach = impressions / frequency (approximate unique users)
    spend = target_cpm * (impressions / 1000)
    frequency = hardcoded per targeting type (from Google Ads campaign reporting)

  Frequency values (from Google Ads campaign reporting):
    - Beltway targeting: 1.6, CPM $19.50
    - Geofence targeting: 1.3, CPM $19.50
    - Default: 1.0, CPM $19.50

  Completions Calculation:
    completions = impressions * video_quartile_p100_rate
    (video_trueview_views is often 0 for non-skippable ads)

  Schema matches ALLIED_UNIFIED_CTE for direct UNION ALL.
*/

-- Ad-level video metrics from Fivetran
with ad_metrics as (
    select
        date,
        campaign_id,
        campaign_name,
        ad_group_id,
        ad_group_name,
        ad_id,
        ad_name as creative,
        impressions,
        clicks,
        -- Completions = impressions * video completion rate
        cast(round(impressions * coalesce(video_quartile_p_100_rate, 0)) as int64) as completions,
        video_quartile_p_100_rate as video_quartile_p100_rate
    from {{ source('google_ads_allied_team', 'video_ad_stats') }}
    where date >= current_date() - 365
),

-- Apply hardcoded frequencies and CPMs from Google Ads reporting
with_targeting as (
    select
        a.*,
        -- Frequencies from Google Ads campaign reporting (actual values)
        case
            when lower(ad_group_name) like '%beltway%' then 1.6
            when lower(ad_group_name) like '%geofence%' then 1.3
            else 1.0
        end as frequency,
        19.50 as target_cpm
    from ad_metrics a
),

-- Final output with calculated metrics
final as (
    select
        -- Date dimension
        date,

        -- Source identification
        'Google Ads' as platform_source,
        'Google Youtube' as partner_platform,

        -- Media channel
        'YouTube Nonskip Video Ads' as media_channel,

        -- Plan section from ad_group_name
        ad_group_name as plan_section,

        -- Creative identifier
        creative,

        -- Campaign (name-based for LIKE filtering)
        campaign_name as campaign,

        -- Core metrics
        -- Impressions are already total from Google Ads (not unique)
        impressions,
        clicks,
        -- Spend = target_cpm * (impressions / 1000)
        round(target_cpm * impressions / 1000, 2) as spend,
        completions,

        -- Reach = impressions / frequency (approximate unique users)
        cast(round(impressions / frequency) as int64) as reach,

        -- Frequency (hardcoded per targeting)
        frequency,

        -- Video completion rate
        video_quartile_p100_rate,

        -- Target CPM for reference
        target_cpm,

        -- Data quality
        case
            when impressions = 0 then true
            when video_quartile_p100_rate is null then true
            else false
        end as is_data_quality_issue,

        'hardcoded-frequency' as reach_methodology

    from with_targeting
)

select * from final
