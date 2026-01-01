    SELECT id as criterion_id
         , ad_group_id
         , keyword_text
         , keyword_match_type
    FROM (
        SELECT id
             , ad_group_id
             , keyword_text
             , keyword_match_type
             , type
             , ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) as rn
        FROM `mavan-analytics.google_ads_v2.ad_group_criterion_history`
        WHERE type = 'KEYWORD'
    )
    WHERE rn = 1