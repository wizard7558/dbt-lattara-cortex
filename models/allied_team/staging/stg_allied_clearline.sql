/*
  Staging model for Allied Team ClearLine data
  Source: allied_team.raw_clearline_metrics (sync-clearline Edge Function)

  Mapping applied per client spec:
  - ClearLine data maps to "Premium CTV/OTT Streaming" media channel
  - Partner "Top Tier CTV/OTT" (Magnite/ClearLine aggregated inventory)
  - Frequency calculated as impressions / reach (when reach > 0)
  - Spend calculated using target CPM: $29.78 * (impressions / 1000)
*/

{% set raw_col_names = [] %}
{% for c in adapter.get_columns_in_relation(source('allied_team', 'raw_clearline_metrics')) %}
  {% do raw_col_names.append(c.name | lower) %}
{% endfor %}

{% set rf_col_names = [] %}
{% for c in adapter.get_columns_in_relation(source('allied_team', 'clearline_reach_frequency')) %}
  {% do rf_col_names.append(c.name | lower) %}
{% endfor %}

with source as (
    -- 2026+ data: synced from two ClearLine APIs, includes join observability fields
    select
        date,
        platform_source,
        partner_platform,
        media_channel,
        plan_section,
        creative,
        campaign,
        impressions,
        clicks,
        spend,
        completions,
        reach,
        cookie_reach,
        ip_reach,
        device_reach,
        {% if 'demand_tag_id' in raw_col_names %}
        demand_tag_id,
        {% else %}
        cast(null as int64) as demand_tag_id,
        {% endif %}
        {% if 'clearline_campaign_id' in raw_col_names %}
        clearline_campaign_id,
        {% else %}
        cast(null as int64) as clearline_campaign_id,
        {% endif %}
        demand_tag_label,
        {% if 'clearline_connection_id' in raw_col_names %}
        clearline_connection_id,
        {% else %}
        cast(null as string) as clearline_connection_id,
        {% endif %}
        {% if 'rf_snapshot_ingested_at' in raw_col_names %}
        rf_snapshot_ingested_at,
        {% else %}
        cast(null as timestamp) as rf_snapshot_ingested_at,
        {% endif %}
        {% if 'rf_window_start_date' in raw_col_names %}
        rf_window_start_date,
        {% else %}
        cast(null as date) as rf_window_start_date,
        {% endif %}
        {% if 'rf_window_end_date' in raw_col_names %}
        rf_window_end_date,
        {% else %}
        cast(null as date) as rf_window_end_date,
        {% endif %}
        {% if 'rf_matched' in raw_col_names %}
        rf_matched,
        {% else %}
        cast(null as bool) as rf_matched,
        {% endif %}
        {% if 'join_status' in raw_col_names %}
        join_status,
        {% else %}
        cast(null as string) as join_status,
        {% endif %}
        publisher,
        duplicate_impressions,
        expired_impressions,
        device_platform,
        device_os,
        country,
        total_cost,
        cpm,
        fill_rate,
        completion_rate,
        ingested_at
    from {{ source('allied_team', 'raw_clearline_metrics') }}
    union all
    -- 2025 archive: static table (legacy rows do not include new join observability columns)
    select
        date,
        platform_source,
        partner_platform,
        media_channel,
        plan_section,
        creative,
        campaign,
        impressions,
        clicks,
        spend,
        completions,
        reach,
        cookie_reach,
        ip_reach,
        device_reach,
        cast(null as int64) as demand_tag_id,
        cast(null as int64) as clearline_campaign_id,
        demand_tag_label,
        cast(null as string) as clearline_connection_id,
        cast(null as timestamp) as rf_snapshot_ingested_at,
        cast(null as date) as rf_window_start_date,
        cast(null as date) as rf_window_end_date,
        cast(null as bool) as rf_matched,
        cast(null as string) as join_status,
        publisher,
        duplicate_impressions,
        expired_impressions,
        device_platform,
        device_os,
        country,
        total_cost,
        cpm,
        fill_rate,
        completion_rate,
        ingested_at
    from {{ source('allied_team', 'raw_clearline_metrics_2025') }}
),

-- ClearLine can emit aggregate rollup rows (publisher null) alongside
-- publisher-level rows for the same key. Keep null-publisher rows only when
-- they are not near-duplicates of the summed publisher-level metrics.
publisher_rollup_keys as (
    select
        date,
        campaign,
        coalesce(creative, '') as creative_key,
        device_platform,
        device_os,
        country
    from source
    group by 1, 2, 3, 4, 5, 6
    having
        countif(publisher is null) > 0
        and countif(publisher is not null) > 0
        and sum(if(publisher is not null, impressions, 0)) > 0
        and safe_divide(
            sum(if(publisher is null, impressions, 0)),
            sum(if(publisher is not null, impressions, 0))
        ) between 0.98 and 1.02
        and (
            sum(if(publisher is not null, completions, 0)) = 0
            or safe_divide(
                sum(if(publisher is null, completions, 0)),
                sum(if(publisher is not null, completions, 0))
            ) between 0.98 and 1.02
        )
),

source_cleaned as (
    select s.*
    from source s
    left join publisher_rollup_keys k
        on s.date = k.date
        and s.campaign = k.campaign
        and coalesce(s.creative, '') = k.creative_key
        and s.device_platform = k.device_platform
        and s.device_os = k.device_os
        and s.country = k.country
    where not (s.publisher is null and k.date is not null)
),

rf_latest as (
    select
        {% if 'clearline_connection_id' in rf_col_names %}
        clearline_connection_id,
        {% else %}
        cast(null as string) as clearline_connection_id,
        {% endif %}
        demand_tag_id,
        demand_tag_label,
        unique_ips,
        unique_cookies,
        unique_devices,
        ingested_at,
        date_end
    from {{ source('allied_team', 'clearline_reach_frequency') }}
    qualify row_number() over (
        partition by clearline_connection_id, demand_tag_id
        order by date_end desc, ingested_at desc
    ) = 1
),

enriched as (
    select
        s.*,
        rf.demand_tag_label as rf_demand_tag_label,
        rf.unique_ips as rf_unique_ips,
        rf.unique_cookies as rf_unique_cookies,
        rf.unique_devices as rf_unique_devices,
        rf.ingested_at as rf_row_ingested_at,
        rf.demand_tag_id is not null as rf_joined
    from source_cleaned s
    left join rf_latest rf
        on s.demand_tag_id = rf.demand_tag_id
        and coalesce(s.clearline_connection_id, '') = coalesce(rf.clearline_connection_id, '')
),

line_item_totals as (
    select
        campaign,
        creative,
        coalesce(demand_tag_id, -1) as demand_tag_key,
        sum(impressions) as total_impressions,
        -- R&F reach is repeated across publisher/day rows, so take MAX per demand tag.
        max(coalesce(nullif(rf_unique_ips, 0), nullif(ip_reach, 0), nullif(reach, 0), 0)) as total_reach
    from enriched
    group by campaign, creative, demand_tag_key
),

creative_totals as (
    select
        campaign,
        creative,
        sum(total_impressions) as total_impressions,
        sum(total_reach) as total_reach
    from line_item_totals
    group by campaign, creative
),

mapped as (
    select
        -- Date
        e.date,

        -- Platform identification
        'ClearLine' as platform_source,

        -- Partner/Platform mapping (ClearLine is aggregated CTV inventory)
        'Top Tier CTV/OTT' as partner_platform,

        -- Media channel mapping
        'Premium CTV/OTT Streaming' as media_channel,

        -- Plan section mapping
        -- HealthcareAdjacent creative check takes priority over demand_tag_label
        -- because ClearLine R&F API may label both regular and expanded healthcare
        -- demand tags as "Healthcare Policy Makers", losing the distinction
        case
            when e.creative like '%HealthcareAdjacent%' then 'Expanded Healthcare Policy and Decision Makers'
            else coalesce(
                nullif(e.rf_demand_tag_label, 'Unknown'),
                nullif(e.demand_tag_label, 'Unknown'),
                case
                    when e.creative like '%Healthcare%' then 'Healthcare Policy Makers'
                    when e.creative like '%Contextual%' then 'Contextual Targeting'
                    when e.creative like '%Zipcode%' then 'Zipcode Targeting'
                    when e.creative like '%Conquesting%' then 'Conquesting'
                    else 'Plan Section/DMA'
                end
            )
        end as plan_section,

        -- Creative (demand_tag_name from API)
        e.creative,

        -- Campaign
        e.campaign,

        -- Publisher name from ClearLine app_name (TubiTV, Samsung Ads, etc.)
        e.publisher,

        -- Core metrics
        e.impressions,
        coalesce(e.clicks, 0) as clicks,
        -- Spend = $29.78 CPM * (impressions / 1000)
        round(29.78 * e.impressions / 1000, 2) as spend,
        e.completions,

        -- Reach from explicit R&F join, then raw IP reach, then legacy reach.
        coalesce(nullif(e.rf_unique_ips, 0), nullif(e.ip_reach, 0), nullif(e.reach, 0), 0) as reach,

        -- Frequency: calculated from campaign+creative totals (prevents cross-campaign bleed)
        case
            when ct.total_reach > 0 then round(ct.total_impressions / ct.total_reach, 2)
            else null
        end as frequency,

        -- Deterministic join/audit fields
        e.demand_tag_id,
        e.clearline_campaign_id,
        e.clearline_connection_id,
        coalesce(e.rf_snapshot_ingested_at, e.rf_row_ingested_at) as rf_snapshot_ingested_at,
        coalesce(e.rf_matched, e.rf_joined) as rf_matched,
        coalesce(
            e.join_status,
            case
                when e.rf_joined then 'direct_match'
                when e.demand_tag_id is null then 'missing_demand_tag'
                else 'rf_unmatched'
            end
        ) as join_status,

        -- Device/Geo dimensions
        e.device_platform,
        e.device_os,
        e.country,

        -- Calculated metrics
        29.78 as cpm,
        e.fill_rate,
        e.completion_rate as vcr,

        -- Metadata
        e.ingested_at,
        current_timestamp() as _processed_at

    from enriched e
    left join creative_totals ct
        on e.campaign = ct.campaign
        and e.creative = ct.creative
)

select * from mapped
