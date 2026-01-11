/*
  Staging model for Allied Team Jamloop data (via Snowflake)
  Source: allied_team.snowflake_funnel (Funnel.io via Fivetran)
  
  Mapping applied per client spec:
  - Source renamed from "Snowflake" to "Jamloop"
  - Creative renaming applied
  
  KNOWN LIMITATION: 
  The mapping document specifies line item level granularity (JL37726-01 for CTV, 
  JL37726-02 for Pre-Roll) but the source data only has campaign-level detail.
  Cannot distinguish Premium CTV vs Digital Pre-Roll without line item data.
  
  Currently defaulting all to Premium CTV based on traffic_source field.
  TODO: Update once Snowflake source includes line item identifier.
  
  Two source tables with complementary data:
  - ALLIED_SERVICES_LLD: Has impressions, no reach
  - ALLIED_SERVICES_CREATIVE_AGG: Has reach, no impressions
*/

with source as (
    select * from {{ source('allied_team', 'snowflake_funnel') }}
),

-- Separate the two data sources for proper aggregation
lld_data as (
    select
        date,
        -- Normalize campaign names (remove inconsistent prefixes)
        case
            when campaign like '%JL37725%' then 'JL37725 NYC Mayoral WFP'
            when campaign like '%JL37726%' then 'JL37726 NYC Campus Geofence WFP'
            when campaign like '%JL38043%' then 'JL38043 TN-07 Congressional'
            else campaign
        end as campaign_normalized,
        audience,
        creative,
        publisher,
        impressions,
        clicks,
        completions,
        cast(null as int64) as reach
    from source
    where data_source_name = 'ALLIED_SERVICES_LLD'
),

creative_agg_data as (
    select
        date,
        case
            when campaign like '%JL37725%' then 'JL37725 NYC Mayoral WFP'
            when campaign like '%JL37726%' then 'JL37726 NYC Campus Geofence WFP'
            when campaign like '%JL38043%' then 'JL38043 TN-07 Congressional'
            else campaign
        end as campaign_normalized,
        audience,
        creative,
        publisher,
        cast(null as int64) as impressions,
        cast(null as int64) as clicks,
        cast(null as int64) as completions,
        reach
    from source
    where data_source_name = 'ALLIED_SERVICES_CREATIVE_AGG'
),

-- Combine and aggregate the two sources
combined as (
    select * from lld_data
    union all
    select * from creative_agg_data
),

aggregated as (
    select
        date,
        campaign_normalized,
        audience,
        creative,
        publisher,
        sum(impressions) as impressions,
        sum(clicks) as clicks,
        sum(completions) as completions,
        sum(reach) as reach
    from combined
    group by 1, 2, 3, 4, 5
),

mapped as (
    select
        -- Date
        date,
        
        -- Platform identification (renamed per client request)
        'Jamloop' as platform_source,
        
        -- Partner/Platform mapping
        -- LIMITATION: Cannot distinguish CTV vs OLV without line item data
        'Top Tier CTV/OTT' as partner_platform,  -- Default, needs line item granularity
        
        -- Media channel mapping
        -- LIMITATION: All defaulting to Premium CTV, should split CTV vs Digital Pre-Roll
        'Premium CTV' as media_channel,  -- TODO: Update when line item data available
        
        -- Plan section mapping
        case
            when audience = '1:1 Voter File Match' then '1:1 Voter File Match'
            when audience = 'Geo Targeting College Campus' then 'Geo-Target College Campus'
            else audience
        end as plan_section,
        
        -- Creative renaming per client spec
        case
            when creative = 'AlliedServices_WFPVOTE_15_NYCMayoral.mp4' then ':15 VOTE'
            when creative = 'AlliedServices_WFPVOTE_30_NYCMayoral.mp4' then ':30 VOTE'
            when creative = 'AlliedServices_15_WFPNEWDAY_COLLEGENYCMayoral.mp4' then ':15 New Day'
            when creative = ':15 College' then ':15 New Day'  -- Align with Google naming
            else creative
        end as creative,
        
        -- Publisher detail (Jamloop specific)
        publisher,
        
        -- Original campaign for reference
        campaign_normalized as campaign,
        
        -- Metrics
        impressions,
        clicks,
        cast(null as float64) as spend,  -- Not available in Snowflake source
        completions,
        reach,
        
        -- Metadata
        current_timestamp() as _processed_at
        
    from aggregated
    where campaign_normalized like 'JL37725%' 
       or campaign_normalized like 'JL37726%'  -- WFP campaigns only
)

select * from mapped
