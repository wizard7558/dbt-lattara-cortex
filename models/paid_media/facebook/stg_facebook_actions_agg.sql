WITH all_actions AS (
    SELECT DATE
         , AD_ID
         , ACTION_TYPE
         , VALUE
    FROM {{ source('facebook_ads', 'ads_insights_actions') }}

    UNION ALL

    SELECT DATE
         , AD_ID
         , ACTION_TYPE
         , VALUE
    FROM {{ source('facebook_ads', 'ads_insights_conversions') }}
)

select ad_id,
        date,
        action_type,
        sum(value) as total_value,
        count(*) over (partition by ad_id, date) as action_count
    from all_actions
    group by ad_id, date, action_type