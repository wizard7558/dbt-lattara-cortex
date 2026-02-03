SELECT
  id,
  official_connector_name AS name
FROM `fivetran_metadata.connector_type`
WHERE deleted = FALSE
  AND type = 'Marketing'

UNION ALL

-- Manual additions not in Fivetran
SELECT 'bingads' AS id, 'Bing/Microsoft Ads' AS name