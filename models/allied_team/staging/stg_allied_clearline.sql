/*
  Staging model for Allied Team ClearLine data
  Source: allied_team.raw_clearline_metrics (sync-clearline Edge Function)

  Joins with clearline_reach_frequency for accurate R&F metrics.

  Mapping applied per client spec:
  - ClearLine data maps to "Premium CTV/OTT Streaming" media channel
  - Partner "Top Tier CTV/OTT" (Magnite/ClearLine aggregated inventory)
  - Reach uses IP-based calculation from R&F API (most reliable for CTV)

  Reach Types (from dedicated R&F API):
  - ip_frequency: IP-based frequency (recommended for CTV - cookies unreliable)
  - cookie_frequency: Cookie-based frequency (useful for web campaigns)
  - device_frequency: Device-based frequency (CTV device fingerprinting)
*/

with source as (
    select * from {{ source('allied_team', 'raw_clearline_metrics') }}
    where date >= current_date() - 365
),

-- R&F data from dedicated api/v0/reports endpoint
-- Join on creative name which matches demand_tag_label
rf_data as (
    select
        demand_tag_label,
        unique_ips,
        unique_cookies,
        unique_devices,
        ip_frequency,
        cookie_frequency,
        device_frequency
    from {{ source('allied_team', 'clearline_reach_frequency') }}
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

        -- Plan section mapping (use R&F demand_tag_label if available)
        coalesce(
            rf.demand_tag_label,
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

        -- Reach metrics from R&F table (IP-based is primary for CTV)
        coalesce(rf.unique_ips, s.ip_reach, s.reach, 0) as reach,
        coalesce(rf.unique_ips, s.ip_reach, 0) as ip_reach,
        coalesce(rf.unique_cookies, s.cookie_reach, 0) as cookie_reach,
        coalesce(rf.unique_devices, s.device_reach, 0) as device_reach,

        -- Frequency from R&F table
        rf.ip_frequency,
        rf.cookie_frequency,
        rf.device_frequency,

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
    left join rf_data rf
        on s.creative = rf.demand_tag_label
        or s.demand_tag_label = rf.demand_tag_label
)

select * from mapped
