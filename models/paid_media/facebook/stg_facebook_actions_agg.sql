select ad_id,
        date,
        action_type,
        sum(value) as total_value,
        count(*) over (partition by ad_id, date) as action_count
    from `facebook_ads.ads_insights_actions`
    group by ad_id, date, action_type