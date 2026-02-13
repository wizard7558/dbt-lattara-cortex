{{
  config(
    materialized='incremental',
    unique_key='id'
  )
}}

-- Keywords dimension table (Google Ads only for now)
-- Keywords are stored in ad_group_criterion_history with type = 'KEYWORD'

{% set google_ad_group_criterion_history = adapter.get_relation(
      database=var("bq_project_id"),
      schema=var("source_google_dataset"),
      identifier="ad_group_criterion_history"
) %}
WITH google_keyword_latest AS (
  {% if google_ad_group_criterion_history is not none %}
  SELECT
    id AS criterion_id,
    ad_group_id,
    keyword_text,
    keyword_match_type,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) AS rn
  FROM {{ google_ad_group_criterion_history }}
  WHERE type = 'KEYWORD'
  {% else %}
  SELECT
    CAST(NULL AS STRING) AS criterion_id,
    CAST(NULL AS STRING) AS ad_group_id,
    CAST(NULL AS STRING) AS keyword_text,
    CAST(NULL AS STRING) AS keyword_match_type,
    CAST(NULL AS INT64) AS rn
  FROM (SELECT 1) WHERE FALSE
  {% endif %}
),

google_keywords AS (
  SELECT
    criterion_id,
    ad_group_id,
    keyword_text,
    keyword_match_type
  FROM google_keyword_latest
  WHERE rn = 1
),

all_keywords AS (
  SELECT
    CONCAT('google_ads_', CAST(criterion_id AS STRING)) AS id,
    keyword_text AS keyword_name,
    keyword_match_type AS match_type,
    CONCAT('google_ads_', CAST(ad_group_id AS STRING)) AS adset_id,
    'google_ads' AS ad_network_id
  FROM google_keywords
)

SELECT
  k.id,
  k.keyword_name,
  k.match_type,
  k.adset_id,
  adset.adset_name,
  adset.campaign_id,
  c.campaign_name,
  k.ad_network_id,
  c.account_id,
  c.organization_id,
  c.product_id
FROM all_keywords k
LEFT JOIN {{ ref('adsets') }} adset
  ON k.adset_id = adset.id
LEFT JOIN {{ ref('campaigns') }} c
  ON adset.campaign_id = c.id

{% if is_incremental() %}
WHERE k.id NOT IN (SELECT id FROM {{ this }})
{% endif %}
