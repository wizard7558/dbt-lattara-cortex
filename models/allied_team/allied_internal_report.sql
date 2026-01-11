/*
  Allied Team Internal Report
  Full report with pacing calculations (requires allied_campaign_orders seed)
  
  This model produces the internal pivot-table style report requested by client.
*/

with funnel as (
    select * from {{ ref('allied_unified_funnel') }}
),

orders as (
    select * from {{ ref('allied_campaign_orders') }}
),

joined as (
    select
        f.platform_source,
        f.media_channel,
        f.partner_platform,
        f.plan_section,
        f.creative,
        f.publisher,
        
        -- Core metrics
        f.impressions,
        f.completions,
        f.vcr_pct,
        f.reach,
        f.frequency,
        f.gross_spend,
        f.cpm,
        f.clicks,
        f.ctr_pct,
        
        -- Order data
        o.impressions_ordered,
        o.budget,
        o.campaign_start_date,
        o.campaign_end_date,
        
        -- Calculated: Total campaign length
        date_diff(o.campaign_end_date, o.campaign_start_date, day) + 1 as total_campaign_length_days,
        
        -- Calculated: Days running (from start to last data date)
        date_diff(f.last_date, o.campaign_start_date, day) + 1 as days_running,
        
        -- Calculated: Delivery percentage
        case
            when o.impressions_ordered > 0 
            then round(safe_divide(f.impressions, o.impressions_ordered) * 100, 2)
            else null
        end as delivery_pct,
        
        -- Calculated: Time elapsed percentage
        case
            when o.campaign_start_date is not null and o.campaign_end_date is not null
            then round(
                safe_divide(
                    date_diff(f.last_date, o.campaign_start_date, day) + 1,
                    date_diff(o.campaign_end_date, o.campaign_start_date, day) + 1
                ) * 100, 2
            )
            else null
        end as time_elapsed_pct,
        
        f.first_date,
        f.last_date,
        f.days_with_data
        
    from funnel f
    left join orders o
        on f.platform_source = o.platform_source
        and f.media_channel = o.media_channel
        and f.plan_section = o.plan_section
        and f.creative = o.creative
),

final as (
    select
        platform_source,
        media_channel,
        partner_platform,
        plan_section,
        creative,
        publisher,
        
        impressions,
        completions,
        vcr_pct,
        reach,
        frequency,
        gross_spend,
        cpm,
        
        impressions_ordered,
        total_campaign_length_days,
        days_running,
        delivery_pct,
        
        -- Pacing: Delivery % / Time elapsed %
        -- >100 = ahead of pace, <100 = behind pace
        case
            when time_elapsed_pct > 0 
            then round(safe_divide(delivery_pct, time_elapsed_pct) * 100, 2)
            else null
        end as pacing_pct,
        
        budget,
        first_date,
        last_date,
        days_with_data
        
    from joined
)

select * from final
order by platform_source, media_channel, plan_section, creative
