select 
        ad_id,
        date,
        action_type,
        sum(value) as revenue,
        sum(case when action_type = 'omni_purchase' then value else 0 end) as purchase_revenue
    from `facebook_ads.ads_insights_action_values`
    group by ad_id, date, action_type