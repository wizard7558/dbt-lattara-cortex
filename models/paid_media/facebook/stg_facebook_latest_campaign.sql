select id, name
    from (
        select 
            id,
            name,
            row_number() over(partition by id order by updated_time desc) as rn
        from `facebook_ads.campaign_history`
    )
    where rn = 1