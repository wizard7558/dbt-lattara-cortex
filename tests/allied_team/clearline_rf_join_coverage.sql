with stats as (
    select
        countif(demand_tag_id is not null) as eligible_rows,
        countif(demand_tag_id is not null and coalesce(rf_matched, false)) as matched_rows
    from {{ ref('stg_allied_clearline') }}
    where date >= date_sub(current_date(), interval 7 day)
)
select *
from stats
where eligible_rows >= 100
  and safe_divide(matched_rows, eligible_rows) < 0.95
