SELECT id as customer_id
         , descriptive_name as account_name
    FROM (
        SELECT id
             , descriptive_name
             , ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) as rn
        FROM `mavan-analytics.google_ads_v2.account_history`
    )
    WHERE rn = 1