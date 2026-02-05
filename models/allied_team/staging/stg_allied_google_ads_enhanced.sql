{{
  config(
    materialized='view',
    schema='allied_team'
  )
}}

/*
  Google Ads (YouTube) Enhanced Staging Model

  Joins ad-level video metrics with campaign-level reach to calculate
  estimated reach per creative using engagement-based frequency adjustment.

  Sources (Fivetran):
  - video_ad_stats: Ad-level video quartiles, impressions, spend
  - video_campaign_stats: Campaign-level unique_users and frequency

  Reach Estimation Formula:
    engagement_factor = creative_p100_rate / campaign_avg_p100_rate
    adjusted_frequency = campaign_frequency * engagement_factor
    estimated_reach = creative_impressions / adjusted_frequency

  Rationale:
    Higher video completion suggests more engaged/repeated viewers,
    implying higher frequency for that creative. This creates natural
    variation in estimated reach across creatives within a campaign.

  Note: unique_users is only available at campaign level in Google Ads API
  (92-day max range). Per-creative reach is estimated, not measured.

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
        video_trueview_views as video_views,
        video_quartile_p_100_rate as video_quartile_p100_rate
    from {{ source('google_ads_allied_team', 'video_ad_stats') }}
    where date >= current_date() - 365
),

-- Campaign-level reach from Fivetran
campaign_reach as (
    select
        date,
        id as campaign_id,
        name as campaign_name,
        unique_users as campaign_reach,
        average_impression_frequency_per_user as campaign_frequency,
        impressions as campaign_impressions
    from {{ source('google_ads_allied_team', 'video_campaign_stats') }}
    where date >= current_date() - 365
),

-- Calculate weighted average video completion rate per campaign per day
-- Uses impression-weighted average to avoid bias from low-volume creatives
campaign_avg_completion as (
    select
        date,
        campaign_id,
        safe_divide(
            sum(video_quartile_p100_rate * impressions),
            nullif(sum(impressions), 0)
        ) as avg_p100_rate
    from ad_metrics
    group by 1, 2
),

-- Join all data and calculate engagement-based reach estimation
enriched as (
    select
        a.date,
        a.campaign_id,
        a.campaign_name,
        a.ad_group_id,
        a.ad_group_name,
        a.ad_id,
        a.creative,
        a.impressions,
        a.clicks,
        a.spend,
        a.video_views,
        a.video_quartile_p100_rate,
        r.campaign_reach,
        r.campaign_frequency,
        c.avg_p100_rate as campaign_avg_p100_rate,

        -- Engagement factor: creative completion vs campaign average
        -- Values > 1 indicate above-average engagement
        case
            when c.avg_p100_rate > 0
            then a.video_quartile_p100_rate / c.avg_p100_rate
            else 1.0
        end as engagement_factor,

        -- Adjusted frequency based on engagement
        -- Higher engagement = higher frequency assumption
        r.campaign_frequency * (
            case
                when c.avg_p100_rate > 0
                then a.video_quartile_p100_rate / c.avg_p100_rate
                else 1.0
            end
        ) as estimated_frequency,

        -- Estimated reach = impressions / adjusted frequency
        -- Null if frequency is 0 to avoid division errors
        case
            when r.campaign_frequency > 0 and c.avg_p100_rate > 0
            then a.impressions / (
                r.campaign_frequency * (a.video_quartile_p100_rate / c.avg_p100_rate)
            )
            when r.campaign_frequency > 0
            then a.impressions / r.campaign_frequency
            else null
        end as estimated_reach

    from ad_metrics a
    left join campaign_reach r
        on a.date = r.date and a.campaign_id = r.campaign_id
    left join campaign_avg_completion c
        on a.date = c.date and a.campaign_id = c.campaign_id
),

-- Map ad_group targeting to media_channel and plan_section
-- Uses same targeting label mapping as existing Google Ads model
final as (
    select
        -- Date dimension
        date,

        -- Source identification
        'Google Ads' as platform_source,
        'Google Youtube' as partner_platform,

        -- Targeting breakdown from ad_group_name
        -- Convention: ad_group_name contains targeting type
        case
            when ad_group_name like '%HCP%' or ad_group_name like '%Healthcare%' then 'Healthcare HCPs'
            when ad_group_name like '%Policy%' or ad_group_name like '%Policymaker%' then 'Healthcare Policy Makers'
            when ad_group_name like '%Patient%' or ad_group_name like '%Caregiver%' then 'Patients and Caregivers'
            when ad_group_name like '%Short%' or ad_group_name like '%SHORTS%' then 'Youtube SHORTS'
            when ad_group_name like '%Skippable%' then 'Youtube Skippable'
            when ad_group_name like '%NonSkip%' or ad_group_name like '%Non-Skip%' then 'Youtube Nonskip Video Ads'
            else 'General'
        end as media_channel,

        case
            when ad_group_name like '%HCP%' or ad_group_name like '%Healthcare%' then 'Healthcare HCPs'
            when ad_group_name like '%Policy%' or ad_group_name like '%Policymaker%' then 'Healthcare Policy Makers'
            when ad_group_name like '%Patient%' or ad_group_name like '%Caregiver%' then 'Patients and Caregivers'
            when ad_group_name like '%Short%' or ad_group_name like '%SHORTS%' then 'SHORTS'
            when ad_group_name like '%Skippable%' then 'Skippable'
            when ad_group_name like '%NonSkip%' or ad_group_name like '%Non-Skip%' then 'Non-Skippable'
            else ad_group_name
        end as plan_section,

        -- Creative identifier
        creative,

        -- Campaign (name-based for LIKE filtering)
        campaign_name as campaign,

        -- Core metrics
        impressions,
        clicks,
        spend,
        round(impressions * video_quartile_p100_rate,0) as completions,

        -- Reach metrics
        estimated_reach as reach,
        estimated_frequency as frequency,
        video_quartile_p100_rate,

        -- Engagement calculation details (for debugging/analysis)
        engagement_factor,
        campaign_reach,
        campaign_frequency,
        campaign_avg_p100_rate,

        -- Data quality
        case
            when impressions = 0 then true
            when video_quartile_p100_rate is null then true
            else false
        end as is_data_quality_issue,

        'engagement-based-estimation' as reach_methodology

    from enriched
)

select * from final
