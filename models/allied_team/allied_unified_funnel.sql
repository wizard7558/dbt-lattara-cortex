/*
  Allied Team Unified Funnel Report
  Combines Google Ads (YouTube), Magnite, and Jamloop data
  
  Output columns per client wishlist:
  - Platform Source
  - Media Channel
  - Partner/Platform
  - Plan Section
  - Creative
  - Impressions
  - Completions
  - VCR % (Video Completion Rate)
  - Reach
  - Frequency (Impressions / Reach)
  - Gross Spend
  - CPM (Spend / Impressions * 1000)
  
  MISSING DATA (requires external input):
  - Impressions Ordered
  - Total Campaign Length
  - Days Running
  - Delivery Percentage
  - Pacing
  
  KNOWN LIMITATIONS:
  1. Jamloop cannot distinguish Premium CTV vs Digital Pre-Roll (missing line item data)
  2. Jamloop has no spend data
  3. Google Ads has no reach data
  4. Publisher-level detail only available for Jamloop
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
        campaign,
        impressions,
        clicks,
        spend,
        completions,
        reach,
        currency
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
        campaign,
        impressions,
        clicks,
        spend,
        completions,
        reach,
        currency
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
        campaign,
        impressions,
        clicks,
        spend,
        completions,
        reach,
        'USD' as currency
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
        campaign,
        impressions,
        clicks,
        spend,
        completions,
        reach,
        'USD' as currency
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

aggregated as (
    select
        platform_source,
        media_channel,
        partner_platform,
        plan_section,
        creative,
        publisher,
        
        -- Metrics
        sum(impressions) as impressions,
        sum(completions) as completions,
        case
            -- ClearLine reach is a line-item unique audience repeated across rows.
            when platform_source = 'ClearLine' then max(reach)
            else sum(reach)
        end as reach,
        sum(spend) as gross_spend,
        sum(clicks) as clicks,
        
        -- Date range for reference
        min(date) as first_date,
        max(date) as last_date,
        count(distinct date) as days_with_data
        
    from unioned
    group by 1, 2, 3, 4, 5, 6
),

final as (
    select
        -- Dimension columns (ordered per client request)
        platform_source,
        media_channel,
        partner_platform,
        plan_section,
        creative,
        publisher,
        
        -- Metric columns
        impressions,
        completions,
        
        -- VCR % (Video Completion Rate)
        case 
            when impressions > 0 then round(safe_divide(completions, impressions) * 100, 2)
            else null
        end as vcr_pct,
        
        reach,
        
        -- Frequency (Impressions / Reach)
        case
            when reach > 0 then round(safe_divide(impressions, reach), 2)
            else null
        end as frequency,
        
        gross_spend,
        
        -- CPM (Cost per 1000 impressions)
        case
            when impressions > 0 then round(safe_divide(gross_spend, impressions) * 1000, 2)
            else null
        end as cpm,
        
        clicks,
        
        -- CTR (Click-through rate)
        case
            when impressions > 0 then round(safe_divide(clicks, impressions) * 100, 4)
            else null
        end as ctr_pct,
        
        -- Date range metadata
        first_date,
        last_date,
        days_with_data,
        
        -- Placeholder columns for future data (requires external input)
        cast(null as int64) as impressions_ordered,
        cast(null as int64) as total_campaign_length_days,
        cast(null as int64) as days_running,
        cast(null as float64) as delivery_pct,
        cast(null as float64) as pacing
        
    from aggregated
)

select * from final
order by platform_source, media_channel, plan_section, creative
