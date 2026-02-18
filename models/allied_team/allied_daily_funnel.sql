/*
  Allied Team Daily Funnel Report
  Daily grain version for time-series analysis and pacing calculations
*/

with google_ads as (
    select
        date,
        platform_source,
        media_channel,
        partner_platform,
        plan_section,
        creative,
        cast(null as string) as publisher,
        impressions,
        clicks,
        spend,
        completions,
        reach
    from {{ ref('stg_allied_google_ads') }}
),

magnite as (
    select
        date,
        platform_source,
        media_channel,
        partner_platform,
        plan_section,
        creative,
        cast(null as string) as publisher,
        impressions,
        clicks,
        spend,
        completions,
        reach
    from {{ ref('stg_allied_magnite') }}
),

jamloop as (
    select
        date,
        platform_source,
        media_channel,
        partner_platform,
        plan_section,
        creative,
        publisher,
        impressions,
        clicks,
        spend,
        completions,
        reach
    from {{ ref('stg_allied_jamloop') }}
),

clearline as (
    select
        date,
        platform_source,
        media_channel,
        partner_platform,
        plan_section,
        creative,
        publisher,
        impressions,
        clicks,
        spend,
        completions,
        reach
    from {{ ref('stg_allied_clearline') }}
),

unioned as (
    select * from google_ads
    union all
    select * from magnite
    union all
    select * from jamloop
    union all
    select * from clearline
),

daily_aggregated as (
    select
        date,
        platform_source,
        media_channel,
        partner_platform,
        plan_section,
        creative,
        
        -- Daily metrics
        sum(impressions) as impressions,
        sum(completions) as completions,
        case
            -- ClearLine reach is a line-item unique audience repeated across rows.
            when platform_source = 'ClearLine' then max(reach)
            else sum(reach)
        end as reach,
        sum(spend) as gross_spend,
        sum(clicks) as clicks
        
    from unioned
    group by 1, 2, 3, 4, 5, 6
),

with_calcs as (
    select
        date,
        platform_source,
        media_channel,
        partner_platform,
        plan_section,
        creative,
        
        impressions,
        completions,
        
        case 
            when impressions > 0 then round(safe_divide(completions, impressions) * 100, 2)
            else null
        end as vcr_pct,
        
        reach,
        
        case
            when reach > 0 then round(safe_divide(impressions, reach), 2)
            else null
        end as frequency,
        
        gross_spend,
        
        case
            when impressions > 0 then round(safe_divide(gross_spend, impressions) * 1000, 2)
            else null
        end as cpm,
        
        clicks,
        
        -- Running totals partitioned by line item
        sum(impressions) over (
            partition by platform_source, media_channel, plan_section, creative 
            order by date
        ) as impressions_cumulative,
        
        sum(gross_spend) over (
            partition by platform_source, media_channel, plan_section, creative 
            order by date
        ) as spend_cumulative
        
    from daily_aggregated
)

select * from with_calcs
order by date desc, platform_source, media_channel
