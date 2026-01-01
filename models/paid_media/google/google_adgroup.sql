    SELECT id as ad_group_id
         , campaign_id
         , name as ad_group_name
    FROM (
        SELECT id
             , campaign_id
             , name
             , ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) as rn
        FROM `mavan-analytics.google_ads_v2.ad_group_history`
    )
    WHERE rn = 1