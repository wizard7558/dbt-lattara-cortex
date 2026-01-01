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
        , sum(cost_micros)/1000000 as spend
        , sum(impressions) as impressions
        , sum(clicks) as clicks
FROM `mavan-analytics.google_ads_v2.keyword_stats` kws
LEFT JOIN {{ ref('google_accounts') }} acc
on acc.customer_id = kws.customer_id
LEFT JOIN {{ ref('google_campaigns') }} cam
on cam.campaign_id = kws.campaign_id
LEFT JOIN {{ ref('google_adgroup') }} adg
on adg.ad_group_id = kws.ad_group_id
LEFT JOIN {{ ref('google_keyword') }} kw
on kw.criterion_id = kws.ad_group_criterion_criterion_id
GROUP BY 1,2,3,4,5,6,7,8,9
ORDER BY 1 DESC