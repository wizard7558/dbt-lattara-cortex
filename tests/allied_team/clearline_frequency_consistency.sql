with demand_tag_rollup as (
    select
        campaign,
        creative,
        coalesce(demand_tag_id, -1) as demand_tag_key,
        sum(impressions) as impressions,
        max(reach) as demand_tag_reach
    from {{ ref('stg_allied_clearline') }}
    group by campaign, creative, demand_tag_key
),
expected as (
    select
        campaign,
        creative,
        round(safe_divide(sum(impressions), nullif(sum(demand_tag_reach), 0)), 2) as expected_frequency
    from demand_tag_rollup
    group by campaign, creative
),
observed as (
    select
        campaign,
        creative,
        max(frequency) as model_frequency
    from {{ ref('stg_allied_clearline') }}
    group by campaign, creative
)
select
    o.campaign,
    o.creative,
    o.model_frequency,
    e.expected_frequency
from observed o
join expected e
  on o.campaign = e.campaign
 and o.creative = e.creative
where abs(coalesce(o.model_frequency, 0) - coalesce(e.expected_frequency, 0)) > 0.05
