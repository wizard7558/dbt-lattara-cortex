/*
  Staging model for Allied Team Magnite data
  Source: allied_team.magnite_funnel (Funnel.io via Fivetran)
  
  Mapping applied per client spec:
  - Campaign ID 110167 → Premium CTV, Top Tier CTV/OTT, 1:1 Voter File Match
  
  Note: Campaign ID not present in source data. Mapping based on traffic_source 
  and audience fields. All Magnite data appears to be WFP Voter Match campaign.
*/

with source as (
    select * from {{ source('allied_team', 'magnite_funnel') }}
),

mapped as (
    select
        -- Date
        date,
        
        -- Platform identification
        'Magnite' as platform_source,
        'Top Tier CTV/OTT' as partner_platform,
        
        -- Media channel
        'Premium CTV' as media_channel,
        
        -- Plan section mapping
        case
            when audience = '1:1 Voter File Match' then '1:1 Voter File Match'
            when audience is null and creative is null then '1:1 Voter File Match'  -- Default for aggregated rows
            else coalesce(audience, '1:1 Voter File Match')
        end as plan_section,
        
        -- Creative (already mapped correctly in source)
        creative,
        
        -- Original campaign reference
        campaign,
        
        -- Metrics
        impressions,
        cast(null as int64) as clicks,  -- Not available in Magnite
        cost_ as spend,
        completions,
        reach,
        
        -- Metadata
        currency,
        _fivetran_synced
        
    from source
    where campaign is null or campaign != 'AMC 2025'  -- Exclude non-WFP campaigns
)

select * from mapped
