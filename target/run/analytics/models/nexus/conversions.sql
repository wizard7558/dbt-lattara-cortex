
  
    

    create or replace table `res-analytics`.`com_allied`.`conversions`
      
    
    

    
    OPTIONS()
    as (
      

WITH



google_conv AS (
     
     SELECT
          CAST(NULL AS STRING) as ad_network_id,
          CAST(NULL AS STRING) as account_id,
          CAST(NULL AS STRING) as conversion_name,
          CAST(NULL AS INTEGER) as count
     FROM (SELECT 1) WHERE FALSE
     
),





facebook_conv AS (
     
     SELECT
          CAST(NULL AS STRING) as ad_network_id,
          CAST(NULL AS STRING) as account_id,
          CAST(NULL AS STRING) as conversion_name,
          CAST(NULL AS INTEGER) as count
     FROM (SELECT 1) WHERE FALSE
     
),



linkedin_conv as (
     
     SELECT
          CAST(NULL AS STRING) as ad_network_id,
          CAST(NULL AS STRING) as account_id,
          CAST(NULL AS STRING) as conversion_name,
          CAST(NULL AS INTEGER) as count
     FROM (SELECT 1) WHERE FALSE
     
),



tiktok_conv as (

SELECT
     CAST(NULL AS STRING) as ad_network_id,
     CAST(NULL AS STRING) as account_id,
     CAST(NULL AS STRING) as conversion_name,
     CAST(NULL AS INTEGER) as count
FROM (SELECT 1) WHERE FALSE

),



bing_conv as (

SELECT
     CAST(NULL AS STRING) as ad_network_id,
     CAST(NULL AS STRING) as account_id,
     CAST(NULL AS STRING) as conversion_name,
     CAST(NULL AS INTEGER) as count
FROM (SELECT 1) WHERE FALSE

)

select * from google_conv

union all

select * from facebook_conv

union all

select * from linkedin_conv

union all

select * from tiktok_conv

union all

select * from bing_conv
    );
  