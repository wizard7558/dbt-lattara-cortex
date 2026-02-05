{{
  config(
    materialized='view',
    schema='allied_team'
  )
}}

/*
  Google Ads (YouTube) Enhanced Staging Model

  Uses hardcoded frequencies from Google Ads reporting to scale impressions
  and preserve reach.

  Sources (Fivetran):
  - video_ad_stats: Ad-level video quartiles, impressions, spend

  Calculation Logic:
    impressions = raw_impressions * frequency (total scaled impressions)
    reach = raw_impressions (original impressions = unique reach)
    frequency = hardcoded per targeting type

  Frequency values (from Google Ads campaign reporting):
    - Beltway targeting: 1.5
    - Geofence targeting: 1.2
    - Default: 1.0

  Completions Calculation:
    completions = raw_impressions * video_quartile_p100_rate
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
        impressions as raw_impressions,
        clicks,
        cost_micros / 1000000.0 as spend,
        -- Completions = impressions * video completion rate
        cast(round(impressions * coalesce(video_quartile_p_100_rate, 0)) as int64) as completions,
        video_quartile_p_100_rate as video_quartile_p100_rate
    from {{ source('google_ads_allied_team', 'video_ad_stats') }}
    where date >= current_date() - 365
),

-- Apply hardcoded frequencies from Google Ads reporting
with_frequency as (
    select
        a.*,
        -- Frequency based on ad_group targeting
        case
            when lower(ad_group_name) like '%beltway%' then 1.5
            when lower(ad_group_name) like '%geofence%' then 1.2
            else 1.0  -- Default fallback
        end as frequency
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

        -- Media channel (simplified - use General, let campaign mappings handle display)
        'General' as media_channel,

        -- Plan section from ad_group_name
        ad_group_name as plan_section,

        -- Creative identifier
        creative,

        -- Campaign (name-based for LIKE filtering)
        campaign_name as campaign,

        -- Core metrics
        -- Impressions = raw * frequency (total impressions)
        cast(round(raw_impressions * frequency) as int64) as impressions,
        clicks,
        spend,
        completions,

        -- Reach = raw impressions
        raw_impressions as reach,

        -- Frequency (hardcoded per targeting)
        frequency,

        -- Video completion rate
        video_quartile_p100_rate,

        -- Data quality
        case
            when raw_impressions = 0 then true
            when video_quartile_p100_rate is null then true
            else false
        end as is_data_quality_issue,

        'hardcoded-frequency' as reach_methodology

    from with_frequency
)

select * from final
