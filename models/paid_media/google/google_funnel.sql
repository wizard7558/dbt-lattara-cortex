select
  s.date,
  s.account,
  s.customer_id,
  s.campaign,
  s.campaign_id,
  s.adgroup,
  s.ad_group_id,
  s.keyword,
  s.match_type,
  s.spend / NULLIF(c.conversion_actions_count, 0) as spend,
  s.impressions / NULLIF(c.conversion_actions_count, 0) as impressions,
  s.clicks / NULLIF(c.conversion_actions_count, 0) as clicks,
  c.conversion_action_name,
  c.conversions,
  c.conversion_value
from {{ ref('google_spend') }} s
left join {{ ref('google_conversions') }} c
  on s.date = c.date  -- ADD THIS
  and s.campaign_id = c.campaign_id
  and s.ad_group_id = c.ad_group_id
  and s.keyword = c.keyword
  and s.match_type = c.match_type
order by 1 desc,2,3,4,5,6,7