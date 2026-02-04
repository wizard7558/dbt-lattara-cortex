/*
  Staging model for Allied Team ClearLine data
  Source: allied_team.raw_clearline_metrics (sync-clearline Edge Function)

  Mapping applied per client spec:
  - ClearLine data maps to "Premium CTV/OTT Streaming" media channel
  - Partner "Top Tier CTV/OTT" (Magnite/ClearLine aggregated inventory)
  - Frequency calculated as impressions / reach (when reach > 0)
*/

with source as (
    select * from {{ source('allied_team', 'raw_clearline_metrics') }}
    where date >= current_date() - 365
),

-- Aggregate by creative to get total reach per line item
-- This gives us better frequency calculation
creative_totals as (
    select
        creative,
        sum(impressions) as total_impressions,
        sum(coalesce(reach, 0)) as total_reach
    from source
    group by creative
),

mapped as (
    select
        -- Date
        s.date,

        -- Platform identification
        'ClearLine' as platform_source,

        -- Partner/Platform mapping (ClearLine is aggregated CTV inventory)
        'Top Tier CTV/OTT' as partner_platform,

        -- Media channel mapping
        'Premium CTV/OTT Streaming' as media_channel,

        -- Plan section mapping
        coalesce(
            s.demand_tag_label,
            case
                when s.creative like '%Healthcare%' then 'Healthcare Policy Makers'
                when s.creative like '%Contextual%' then 'Contextual Targeting'
                when s.creative like '%Zipcode%' then 'Zipcode Targeting'
                when s.creative like '%Conquesting%' then 'Conquesting'
                else 'Plan Section/DMA'
            end
        ) as plan_section,

        -- Creative (demand_tag_name from API)
        s.creative,

        -- Campaign
        s.campaign,

        -- Core metrics
        s.impressions,
        coalesce(s.clicks, 0) as clicks,
        s.spend,
        s.completions,

        -- Reach (use daily reach, aggregated for frequency calc)
        coalesce(s.reach, 0) as reach,

        -- Frequency: calculated from aggregated totals per creative
        case
            when ct.total_reach > 0 then round(ct.total_impressions / ct.total_reach, 2)
            else null
        end as frequency,

        -- Device/Geo dimensions
        s.device_platform,
        s.device_os,
        s.country,

        -- Calculated metrics
        s.cpm,
        s.fill_rate,
        s.completion_rate as vcr,

        -- Metadata
        s.ingested_at,
        current_timestamp() as _processed_at

    from source s
    left join creative_totals ct
        on s.creative = ct.creative
)

select * from mapped
