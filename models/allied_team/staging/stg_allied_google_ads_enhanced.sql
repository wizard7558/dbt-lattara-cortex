{{
  config(
    materialized='view',
    schema='allied_team'
  )
}}

/*
  Google Ads (YouTube) Enhanced Staging Model

  Joins ad-level video metrics with campaign-level reach to calculate
  reach per creative using engagement-weighted scaling.

  Sources (Fivetran):
  - video_ad_stats: Ad-level video quartiles, impressions, spend
  - video_campaign_stats: Campaign-level unique_users and frequency

  Reach Calculation (engagement-weighted scaling):
    1. engagement_weight = impressions / (freq * (ad_vcr / avg_vcr))
    2. total_weight = SUM(engagement_weight) per campaign per day
    3. reach = campaign_reach * (engagement_weight / total_weight)

  Rationale:
    - Lower VCR creatives get higher reach weight (less engaged users saw fewer ads)
    - Higher VCR creatives get lower reach weight (more engaged users saw more ads)
    - SUM(reach) = campaign_reach (rolls up exactly to actual measured reach)

  Completions Calculation:
    completions = impressions * video_quartile_p100_rate
    (video_trueview_views is often 0 for non-skippable ads)

  Note: unique_users is only available at campaign level in Google Ads API.
  Per-creative reach is distributed using engagement-weighted proportions.

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
        cost_micros / 1000000.0 as spend,
        -- Completions = impressions * video completion rate
        cast(round(impressions * coalesce(video_quartile_p_100_rate, 0)) as int64) as completions,
        video_quartile_p_100_rate as video_quartile_p100_rate
    from {{ source('google_ads_allied_team', 'video_ad_stats') }}
    where date >= current_date() - 365
),

-- Campaign-level reach from Fivetran
campaign_reach as (
    select
        date,
        id as campaign_id,
        unique_users as campaign_reach,
        average_impression_frequency_per_user as campaign_freq
    from {{ source('google_ads_allied_team', 'video_campaign_stats') }}
    where date >= current_date() - 365
),

-- Calculate weighted average video completion rate per campaign per day
campaign_avg as (
    select
        date,
        campaign_id,
        safe_divide(
            sum(video_quartile_p100_rate * impressions),
            nullif(sum(impressions), 0)
        ) as avg_vcr
    from ad_metrics
    group by 1, 2
),

-- Join and calculate engagement weights
with_weights as (
    select
        a.*,
        c.avg_vcr,
        r.campaign_reach,
        r.campaign_freq,
        -- Engagement weight: lower VCR = higher reach weight
        a.impressions / (r.campaign_freq * coalesce(safe_divide(a.video_quartile_p100_rate, c.avg_vcr), 1.0)) as engagement_weight
    from ad_metrics a
    left join campaign_avg c on a.date = c.date and a.campaign_id = c.campaign_id
    left join campaign_reach r on a.date = r.date and a.campaign_id = r.campaign_id
),

-- Calculate total weight per campaign per day for scaling
with_totals as (
    select *,
           sum(engagement_weight) over (partition by date, campaign_id) as total_weight
    from with_weights
),

-- Final output with scaled reach
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
        impressions,
        clicks,
        spend,
        completions,

        -- Scaled reach = campaign_reach * (this_ad_weight / total_weight)
        cast(round(campaign_reach * safe_divide(engagement_weight, total_weight)) as int64) as reach,

        -- Frequency from campaign level
        coalesce(campaign_freq, 1.0) as frequency,

        -- Video completion rate
        video_quartile_p100_rate,

        -- Engagement factor for debugging
        safe_divide(video_quartile_p100_rate, avg_vcr) as engagement_factor,

        -- Campaign-level metrics for reference
        campaign_reach,
        campaign_freq as campaign_frequency,
        avg_vcr as campaign_avg_p100_rate,

        -- Data quality
        case
            when impressions = 0 then true
            when video_quartile_p100_rate is null then true
            else false
        end as is_data_quality_issue,

        'engagement-weighted-scaling' as reach_methodology

    from with_totals
)

select * from final
