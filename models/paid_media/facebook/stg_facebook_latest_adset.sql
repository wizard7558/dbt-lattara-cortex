select id, name, campaign_id
    from (
        select 
            id,
            name,
            campaign_id,
            row_number() over(partition by id order by updated_time desc) as rn
        from `facebook_ads.ad_set_history`
    )
    where rn = 1