select id, name
    from (
        select 
            id,
            name,
            row_number() over(partition by id order by _fivetran_synced desc) as rn
        from `facebook_ads.account_history`
    )
    where rn = 1