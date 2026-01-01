WITH
active_ads AS (
    SELECT
        ad_id
    FROM `mavan-analytics.nexus.kpi_creative_daily`
    WHERE 
        latest_date = DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY) -- Always process from the last full day.
),

kpi AS (
    SELECT
    DATE(date) AS date,
    organization_id,
    product_id,
    ad_network_id,
    account_id,
    SUM(spend) AS spend,
    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks,
    SUM(fatigue_score) AS fatigue_score,

    SUM(kpi_1_count) AS kpi_1_count,
    SUM(kpi_1_value) AS kpi_1_value,

    SUM(kpi_2_count) AS kpi_2_count,
    SUM(kpi_2_value) AS kpi_2_value,

    SUM(kpi_3_count) AS kpi_3_count,
    SUM(kpi_3_value) AS kpi_3_value,

    SUM(kpi_4_count) AS kpi_4_count,
    SUM(kpi_4_value) AS kpi_4_value,

    SUM(kpi_5_count) AS kpi_5_count,
    SUM(kpi_5_value) AS kpi_5_value,

    SUM(kpi_6_count) AS kpi_6_count,
    SUM(kpi_6_value) AS kpi_6_value,

    SUM(kpi_7_count) AS kpi_7_count,
    SUM(kpi_7_value) AS kpi_7_value,

    SUM(kpi_8_count) AS kpi_8_count,
    SUM(kpi_8_value) AS kpi_8_value,

    SUM(kpi_9_count) AS kpi_9_count,
    SUM(kpi_9_value) AS kpi_9_value,

    SUM(kpi_10_count) AS kpi_10_count,
    SUM(kpi_10_value) AS kpi_10_value,

    FROM `mavan-analytics.nexus.kpi_creative_daily`

    WHERE ad_id IN (SELECT ad_id FROM active_ads)

    GROUP BY date, organization_id, product_id, ad_network_id, account_id

),

kpi_metadata AS (
    SELECT DISTINCT
        organization_id,
        product_id,
        ad_network_id,
        account_id
    FROM kpi
),

f_spend AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'spend',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_impressions AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'impressions',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_clicks AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'clicks',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_fatigue_score AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'fatigue_score',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),


f_kpi_1_count AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_1_count',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_kpi_1_value AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_1_value',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),


f_kpi_2_count AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_2_count',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_kpi_2_value AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_2_value',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),


f_kpi_3_count AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_3_count',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_kpi_3_value AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_3_value',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),


f_kpi_4_count AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_4_count',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_kpi_4_value AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_4_value',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),


f_kpi_5_count AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_5_count',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_kpi_5_value AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_5_value',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),


f_kpi_6_count AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_6_count',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_kpi_6_value AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_6_value',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),


f_kpi_7_count AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_7_count',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_kpi_7_value AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_7_value',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),


f_kpi_8_count AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_8_count',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_kpi_8_value AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_8_value',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),


f_kpi_9_count AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_9_count',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_kpi_9_value AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_9_value',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),


f_kpi_10_count AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_10_count',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),

f_kpi_10_value AS (
    SELECT
        forecast_timestamp,
        organization_id,
        product_id,
        ad_network_id,
        account_id,
        forecast_value,
        confidence_level,
        prediction_interval_lower_bound,
        prediction_interval_upper_bound
    FROM
        AI.FORECAST((
            SELECT * FROM kpi
        ),
        data_col => 'kpi_10_value',
        timestamp_col => 'date',
        id_cols => ['organization_id', 'product_id', 'ad_network_id', 'account_id'],
        horizon=> 7,
        model=>'TimesFM 2.5'

        )
),


joined AS (
    SELECT
        DATE(f_spend.forecast_timestamp) as date,
        kpi_metadata.organization_id,
        kpi_metadata.product_id,
        kpi_metadata.ad_network_id,
        kpi_metadata.account_id,

        -- Spend forecast
        f_spend.forecast_value as spend,
        f_spend.confidence_level as spend_confidence_level,
        f_spend.prediction_interval_lower_bound as spend_lower_bound,
        f_spend.prediction_interval_upper_bound as spend_upper_bound,

        -- Impressions forecast
        f_impressions.forecast_value as impressions,
        f_impressions.confidence_level as impressions_confidence_level,
        f_impressions.prediction_interval_lower_bound as impressions_lower_bound,
        f_impressions.prediction_interval_upper_bound as impressions_upper_bound,

        -- Clicks forecast
        f_clicks.forecast_value as clicks,
        f_clicks.confidence_level as clicks_confidence_level,
        f_clicks.prediction_interval_lower_bound as clicks_lower_bound,
        f_clicks.prediction_interval_upper_bound as clicks_upper_bound,

        -- Fatigue Score forecast
        f_fatigue_score.forecast_value as fatigue_score,
        f_fatigue_score.confidence_level as fatigue_score_confidence_level,
        f_fatigue_score.prediction_interval_lower_bound as fatigue_score_lower_bound,
        f_fatigue_score.prediction_interval_upper_bound as fatigue_score_upper_bound,

        -- kpi_1_count forecast
        f_kpi_1_count.forecast_value as kpi_1_count,
        f_kpi_1_count.confidence_level as kpi_1_count_confidence_level,
        f_kpi_1_count.prediction_interval_lower_bound as kpi_1_count_lower_bound,
        f_kpi_1_count.prediction_interval_upper_bound as kpi_1_count_upper_bound,

        -- kpi_1_value forecast
        f_kpi_1_value.forecast_value as kpi_1_value,
        f_kpi_1_value.confidence_level as kpi_1_value_confidence_level,
        f_kpi_1_value.prediction_interval_lower_bound as kpi_1_value_lower_bound,
        f_kpi_1_value.prediction_interval_upper_bound as kpi_1_value_upper_bound,



        -- kpi_2_count forecast
        f_kpi_2_count.forecast_value as kpi_2_count,
        f_kpi_2_count.confidence_level as kpi_2_count_confidence_level,
        f_kpi_2_count.prediction_interval_lower_bound as kpi_2_count_lower_bound,
        f_kpi_2_count.prediction_interval_upper_bound as kpi_2_count_upper_bound,

        -- kpi_2_value forecast
        f_kpi_2_value.forecast_value as kpi_2_value,
        f_kpi_2_value.confidence_level as kpi_2_value_confidence_level,
        f_kpi_2_value.prediction_interval_lower_bound as kpi_2_value_lower_bound,
        f_kpi_2_value.prediction_interval_upper_bound as kpi_2_value_upper_bound,



        -- kpi_3_count forecast
        f_kpi_3_count.forecast_value as kpi_3_count,
        f_kpi_3_count.confidence_level as kpi_3_count_confidence_level,
        f_kpi_3_count.prediction_interval_lower_bound as kpi_3_count_lower_bound,
        f_kpi_3_count.prediction_interval_upper_bound as kpi_3_count_upper_bound,

        -- kpi_3_value forecast
        f_kpi_3_value.forecast_value as kpi_3_value,
        f_kpi_3_value.confidence_level as kpi_3_value_confidence_level,
        f_kpi_3_value.prediction_interval_lower_bound as kpi_3_value_lower_bound,
        f_kpi_3_value.prediction_interval_upper_bound as kpi_3_value_upper_bound,


        -- kpi_4_count forecast
        f_kpi_4_count.forecast_value as kpi_4_count,
        f_kpi_4_count.confidence_level as kpi_4_count_confidence_level,
        f_kpi_4_count.prediction_interval_lower_bound as kpi_4_count_lower_bound,
        f_kpi_4_count.prediction_interval_upper_bound as kpi_4_count_upper_bound,

        -- kpi_4_value forecast
        f_kpi_4_value.forecast_value as kpi_4_value,
        f_kpi_4_value.confidence_level as kpi_4_value_confidence_level,
        f_kpi_4_value.prediction_interval_lower_bound as kpi_4_value_lower_bound,
        f_kpi_4_value.prediction_interval_upper_bound as kpi_4_value_upper_bound,



        -- kpi_5_count forecast
        f_kpi_5_count.forecast_value as kpi_5_count,
        f_kpi_5_count.confidence_level as kpi_5_count_confidence_level,
        f_kpi_5_count.prediction_interval_lower_bound as kpi_5_count_lower_bound,
        f_kpi_5_count.prediction_interval_upper_bound as kpi_5_count_upper_bound,

        -- kpi_5_value forecast
        f_kpi_5_value.forecast_value as kpi_5_value,
        f_kpi_5_value.confidence_level as kpi_5_value_confidence_level,
        f_kpi_5_value.prediction_interval_lower_bound as kpi_5_value_lower_bound,
        f_kpi_5_value.prediction_interval_upper_bound as kpi_5_value_upper_bound,



        -- kpi_6_count forecast
        f_kpi_6_count.forecast_value as kpi_6_count,
        f_kpi_6_count.confidence_level as kpi_6_count_confidence_level,
        f_kpi_6_count.prediction_interval_lower_bound as kpi_6_count_lower_bound,
        f_kpi_6_count.prediction_interval_upper_bound as kpi_6_count_upper_bound,

        -- kpi_6_value forecast
        f_kpi_6_value.forecast_value as kpi_6_value,
        f_kpi_6_value.confidence_level as kpi_6_value_confidence_level,
        f_kpi_6_value.prediction_interval_lower_bound as kpi_6_value_lower_bound,
        f_kpi_6_value.prediction_interval_upper_bound as kpi_6_value_upper_bound,



        -- kpi_7_count forecast
        f_kpi_7_count.forecast_value as kpi_7_count,
        f_kpi_7_count.confidence_level as kpi_7_count_confidence_level,
        f_kpi_7_count.prediction_interval_lower_bound as kpi_7_count_lower_bound,
        f_kpi_7_count.prediction_interval_upper_bound as kpi_7_count_upper_bound,

        -- kpi_7_value forecast
        f_kpi_7_value.forecast_value as kpi_7_value,
        f_kpi_7_value.confidence_level as kpi_7_value_confidence_level,
        f_kpi_7_value.prediction_interval_lower_bound as kpi_7_value_lower_bound,
        f_kpi_7_value.prediction_interval_upper_bound as kpi_7_value_upper_bound,



        -- kpi_8_count forecast
        f_kpi_8_count.forecast_value as kpi_8_count,
        f_kpi_8_count.confidence_level as kpi_8_count_confidence_level,
        f_kpi_8_count.prediction_interval_lower_bound as kpi_8_count_lower_bound,
        f_kpi_8_count.prediction_interval_upper_bound as kpi_8_count_upper_bound,

        -- kpi_8_value forecast
        f_kpi_8_value.forecast_value as kpi_8_value,
        f_kpi_8_value.confidence_level as kpi_8_value_confidence_level,
        f_kpi_8_value.prediction_interval_lower_bound as kpi_8_value_lower_bound,
        f_kpi_8_value.prediction_interval_upper_bound as kpi_8_value_upper_bound,



        -- kpi_9_count forecast
        f_kpi_9_count.forecast_value as kpi_9_count,
        f_kpi_9_count.confidence_level as kpi_9_count_confidence_level,
        f_kpi_9_count.prediction_interval_lower_bound as kpi_9_count_lower_bound,
        f_kpi_9_count.prediction_interval_upper_bound as kpi_9_count_upper_bound,

        -- kpi_9_value forecast
        f_kpi_9_value.forecast_value as kpi_9_value,
        f_kpi_9_value.confidence_level as kpi_9_value_confidence_level,
        f_kpi_9_value.prediction_interval_lower_bound as kpi_9_value_lower_bound,
        f_kpi_9_value.prediction_interval_upper_bound as kpi_9_value_upper_bound,



        -- kpi_10_count forecast
        f_kpi_10_count.forecast_value as kpi_10_count,
        f_kpi_10_count.confidence_level as kpi_10_count_confidence_level,
        f_kpi_10_count.prediction_interval_lower_bound as kpi_10_count_lower_bound,
        f_kpi_10_count.prediction_interval_upper_bound as kpi_10_count_upper_bound,

        -- kpi_10_value forecast
        f_kpi_10_value.forecast_value as kpi_10_value,
        f_kpi_10_value.confidence_level as kpi_10_value_confidence_level,
        f_kpi_10_value.prediction_interval_lower_bound as kpi_10_value_lower_bound,
        f_kpi_10_value.prediction_interval_upper_bound as kpi_10_value_upper_bound


    FROM f_spend
    
    INNER JOIN f_impressions
      ON f_spend.organization_id = f_impressions.organization_id
      AND f_spend.product_id = f_impressions.product_id
      AND f_spend.ad_network_id = f_impressions.ad_network_id
      AND f_spend.account_id = f_impressions.account_id
      AND f_spend.forecast_timestamp = f_impressions.forecast_timestamp
    
    INNER JOIN f_clicks
      ON f_spend.organization_id = f_clicks.organization_id
      AND f_spend.product_id = f_clicks.product_id
      AND f_spend.ad_network_id = f_clicks.ad_network_id
      AND f_spend.account_id = f_clicks.account_id
      AND f_spend.forecast_timestamp = f_clicks.forecast_timestamp

    INNER JOIN f_fatigue_score
      ON f_spend.organization_id = f_fatigue_score.organization_id
      AND f_spend.product_id = f_fatigue_score.product_id
      AND f_spend.ad_network_id = f_fatigue_score.ad_network_id
      AND f_spend.account_id = f_fatigue_score.account_id
      AND f_spend.forecast_timestamp = f_fatigue_score.forecast_timestamp

    INNER JOIN f_kpi_1_count
      ON f_spend.organization_id = f_kpi_1_count.organization_id
      AND f_spend.product_id = f_kpi_1_count.product_id
      AND f_spend.ad_network_id = f_kpi_1_count.ad_network_id
      AND f_spend.account_id = f_kpi_1_count.account_id
      AND f_spend.forecast_timestamp = f_kpi_1_count.forecast_timestamp

    INNER JOIN f_kpi_1_value
      ON f_spend.organization_id = f_kpi_1_value.organization_id
      AND f_spend.product_id = f_kpi_1_value.product_id
      AND f_spend.ad_network_id = f_kpi_1_value.ad_network_id
      AND f_spend.account_id = f_kpi_1_value.account_id
      AND f_spend.forecast_timestamp = f_kpi_1_value.forecast_timestamp



    INNER JOIN f_kpi_2_count
      ON f_spend.organization_id = f_kpi_2_count.organization_id
      AND f_spend.product_id = f_kpi_2_count.product_id
      AND f_spend.ad_network_id = f_kpi_2_count.ad_network_id
      AND f_spend.account_id = f_kpi_2_count.account_id
      AND f_spend.forecast_timestamp = f_kpi_2_count.forecast_timestamp

    INNER JOIN f_kpi_2_value
      ON f_spend.organization_id = f_kpi_2_value.organization_id
      AND f_spend.product_id = f_kpi_2_value.product_id
      AND f_spend.ad_network_id = f_kpi_2_value.ad_network_id
      AND f_spend.account_id = f_kpi_2_value.account_id
      AND f_spend.forecast_timestamp = f_kpi_2_value.forecast_timestamp


    INNER JOIN f_kpi_3_count
      ON f_spend.organization_id = f_kpi_3_count.organization_id
      AND f_spend.product_id = f_kpi_3_count.product_id
      AND f_spend.ad_network_id = f_kpi_3_count.ad_network_id
      AND f_spend.account_id = f_kpi_3_count.account_id
      AND f_spend.forecast_timestamp = f_kpi_3_count.forecast_timestamp

    INNER JOIN f_kpi_3_value
      ON f_spend.organization_id = f_kpi_3_value.organization_id
      AND f_spend.product_id = f_kpi_3_value.product_id
      AND f_spend.ad_network_id = f_kpi_3_value.ad_network_id
      AND f_spend.account_id = f_kpi_3_value.account_id
      AND f_spend.forecast_timestamp = f_kpi_3_value.forecast_timestamp


    INNER JOIN f_kpi_4_count
      ON f_spend.organization_id = f_kpi_4_count.organization_id
      AND f_spend.product_id = f_kpi_4_count.product_id
      AND f_spend.ad_network_id = f_kpi_4_count.ad_network_id
      AND f_spend.account_id = f_kpi_4_count.account_id
      AND f_spend.forecast_timestamp = f_kpi_4_count.forecast_timestamp

    INNER JOIN f_kpi_4_value
      ON f_spend.organization_id = f_kpi_4_value.organization_id
      AND f_spend.product_id = f_kpi_4_value.product_id
      AND f_spend.ad_network_id = f_kpi_4_value.ad_network_id
      AND f_spend.account_id = f_kpi_4_value.account_id
      AND f_spend.forecast_timestamp = f_kpi_4_value.forecast_timestamp


    INNER JOIN f_kpi_5_count
      ON f_spend.organization_id = f_kpi_5_count.organization_id
      AND f_spend.product_id = f_kpi_5_count.product_id
      AND f_spend.ad_network_id = f_kpi_5_count.ad_network_id
      AND f_spend.account_id = f_kpi_5_count.account_id
      AND f_spend.forecast_timestamp = f_kpi_5_count.forecast_timestamp

    INNER JOIN f_kpi_5_value
      ON f_spend.organization_id = f_kpi_5_value.organization_id
      AND f_spend.product_id = f_kpi_5_value.product_id
      AND f_spend.ad_network_id = f_kpi_5_value.ad_network_id
      AND f_spend.account_id = f_kpi_5_value.account_id
      AND f_spend.forecast_timestamp = f_kpi_5_value.forecast_timestamp


    INNER JOIN f_kpi_6_count
      ON f_spend.organization_id = f_kpi_6_count.organization_id
      AND f_spend.product_id = f_kpi_6_count.product_id
      AND f_spend.ad_network_id = f_kpi_6_count.ad_network_id
      AND f_spend.account_id = f_kpi_6_count.account_id
      AND f_spend.forecast_timestamp = f_kpi_6_count.forecast_timestamp

    INNER JOIN f_kpi_6_value
      ON f_spend.organization_id = f_kpi_6_value.organization_id
      AND f_spend.product_id = f_kpi_6_value.product_id
      AND f_spend.ad_network_id = f_kpi_6_value.ad_network_id
      AND f_spend.account_id = f_kpi_6_value.account_id
      AND f_spend.forecast_timestamp = f_kpi_6_value.forecast_timestamp


    INNER JOIN f_kpi_7_count
      ON f_spend.organization_id = f_kpi_7_count.organization_id
      AND f_spend.product_id = f_kpi_7_count.product_id
      AND f_spend.ad_network_id = f_kpi_7_count.ad_network_id
      AND f_spend.account_id = f_kpi_7_count.account_id
      AND f_spend.forecast_timestamp = f_kpi_7_count.forecast_timestamp

    INNER JOIN f_kpi_7_value
      ON f_spend.organization_id = f_kpi_7_value.organization_id
      AND f_spend.product_id = f_kpi_7_value.product_id
      AND f_spend.ad_network_id = f_kpi_7_value.ad_network_id
      AND f_spend.account_id = f_kpi_7_value.account_id
      AND f_spend.forecast_timestamp = f_kpi_7_value.forecast_timestamp


    INNER JOIN f_kpi_8_count
      ON f_spend.organization_id = f_kpi_8_count.organization_id
      AND f_spend.product_id = f_kpi_8_count.product_id
      AND f_spend.ad_network_id = f_kpi_8_count.ad_network_id
      AND f_spend.account_id = f_kpi_8_count.account_id
      AND f_spend.forecast_timestamp = f_kpi_8_count.forecast_timestamp

    INNER JOIN f_kpi_8_value
      ON f_spend.organization_id = f_kpi_8_value.organization_id
      AND f_spend.product_id = f_kpi_8_value.product_id
      AND f_spend.ad_network_id = f_kpi_8_value.ad_network_id
      AND f_spend.account_id = f_kpi_8_value.account_id
      AND f_spend.forecast_timestamp = f_kpi_8_value.forecast_timestamp


    INNER JOIN f_kpi_9_count
      ON f_spend.organization_id = f_kpi_9_count.organization_id
      AND f_spend.product_id = f_kpi_9_count.product_id
      AND f_spend.ad_network_id = f_kpi_9_count.ad_network_id
      AND f_spend.account_id = f_kpi_9_count.account_id
      AND f_spend.forecast_timestamp = f_kpi_9_count.forecast_timestamp

    INNER JOIN f_kpi_9_value
      ON f_spend.organization_id = f_kpi_9_value.organization_id
      AND f_spend.product_id = f_kpi_9_value.product_id
      AND f_spend.ad_network_id = f_kpi_9_value.ad_network_id
      AND f_spend.account_id = f_kpi_9_value.account_id
      AND f_spend.forecast_timestamp = f_kpi_9_value.forecast_timestamp


    INNER JOIN f_kpi_10_count
      ON f_spend.organization_id = f_kpi_10_count.organization_id
      AND f_spend.product_id = f_kpi_10_count.product_id
      AND f_spend.ad_network_id = f_kpi_10_count.ad_network_id
      AND f_spend.account_id = f_kpi_10_count.account_id
      AND f_spend.forecast_timestamp = f_kpi_10_count.forecast_timestamp

    INNER JOIN f_kpi_10_value
      ON f_spend.organization_id = f_kpi_10_value.organization_id
      AND f_spend.product_id = f_kpi_10_value.product_id
      AND f_spend.ad_network_id = f_kpi_10_value.ad_network_id
      AND f_spend.account_id = f_kpi_10_value.account_id
      AND f_spend.forecast_timestamp = f_kpi_10_value.forecast_timestamp

    LEFT JOIN kpi_metadata
      ON f_spend.organization_id = kpi_metadata.organization_id
      AND f_spend.product_id = kpi_metadata.product_id
      AND f_spend.ad_network_id = kpi_metadata.ad_network_id
      AND f_spend.account_id = kpi_metadata.account_id
    
    ORDER BY account_id, date
)

SELECT * FROM joined
