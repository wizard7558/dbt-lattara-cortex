    SELECT id as campaign_id
         , customer_id
         , name as campaign_name
    FROM (
        SELECT id
             , customer_id
             , name
             , ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) as rn
        FROM `mavan-analytics.google_ads_v2.campaign_history`
    )
    WHERE rn = 1