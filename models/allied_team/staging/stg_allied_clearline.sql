/*
  Staging model for Allied Team ClearLine data
  Source: allied_team.raw_clearline_metrics (sync-clearline Edge Function)

  Mapping applied per client spec:
  - ClearLine data maps to "Premium CTV/OTT Streaming" media channel
  - Partner "Top Tier CTV/OTT" (Magnite/ClearLine aggregated inventory)
  - Reach uses IP-based calculation from R&F API (most reliable for CTV)

  Reach Types (from dedicated R&F API):
  - ip_reach: IP-based frequency (recommended for CTV - cookies unreliable)
  - cookie_reach: Cookie-based frequency (useful for web campaigns)
  - device_reach: Device-based frequency (CTV device fingerprinting)
*/

with source as (
    select * from {{ source('allied_team', 'raw_clearline_metrics') }}
),

mapped as (
    select
        -- Date
        date,

        -- Platform identification
        'ClearLine' as platform_source,

        -- Partner/Platform mapping (ClearLine is aggregated CTV inventory)
        'Top Tier CTV/OTT' as partner_platform,

        -- Media channel mapping
        'Premium CTV/OTT Streaming' as media_channel,

        -- Plan section mapping (use demand_tag_label if available, else derive from creative)
        coalesce(
            demand_tag_label,
            case
                when creative like '%Healthcare%' then 'Healthcare Policy Makers'
                when creative like '%Contextual%' then 'Contextual Targeting'
                when creative like '%Zipcode%' then 'Zipcode Targeting'
                when creative like '%Conquesting%' then 'Conquesting'
                else 'Plan Section/DMA'
            end
        ) as plan_section,

        -- Creative (demand_tag_name from API)
        creative,

        -- Campaign
        campaign,

        -- Core metrics
        impressions,
        coalesce(clicks, 0) as clicks,
        spend,
        completions,

        -- Reach metrics (IP-based is primary for CTV)
        coalesce(ip_reach, reach, 0) as reach,
        coalesce(ip_reach, 0) as ip_reach,
        coalesce(cookie_reach, 0) as cookie_reach,
        coalesce(device_reach, 0) as device_reach,

        -- Device/Geo dimensions
        device_platform,
        device_os,
        country,

        -- Calculated metrics
        cpm,
        fill_rate,
        completion_rate as vcr,

        -- Metadata
        ingested_at,
        current_timestamp() as _processed_at

    from source

    -- Reasonable date filter for performance
    where date >= current_date() - 365
)

select * from mapped
