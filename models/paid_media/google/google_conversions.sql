{{config(materialized = "table")}} 

SELECT date
        , acc.account_name as account
        , kws.customer_id
        , cam.campaign_name as campaign
        , kws.campaign_id
        , adg.ad_group_name as adgroup
        , adg.ad_group_id
        , kw.keyword_text as keyword
        , kw.keyword_match_type as match_type
        , conversion_action_name
        , sum(all_conversions) as conversions
        , sum(all_conversions_value) as conversion_value
        , COUNT(*) OVER (
            PARTITION BY 
                date,
                acc.account_name,
                kws.customer_id,
                cam.campaign_name,
                kws.campaign_id,
                adg.ad_group_name,
                adg.ad_group_id,
                kw.keyword_text,
                kw.keyword_match_type
          ) as conversion_actions_count
FROM `mavan-analytics.google_ads_v2.keyword_conversions` kws
LEFT JOIN {{ ref('google_accounts') }} acc
on acc.customer_id = kws.customer_id
LEFT JOIN {{ ref('google_campaigns') }} cam
on cam.campaign_id = kws.campaign_id
LEFT JOIN {{ ref('google_adgroup') }} adg
on adg.ad_group_id = kws.ad_group_id
LEFT JOIN {{ ref('google_keyword') }} kw
on kw.criterion_id = kws.ad_group_criterion_criterion_id
GROUP BY 1,2,3,4,5,6,7,8,9,10
ORDER BY 1 DESC