{#-
  union_all_schemas - Generates UNION ALL SQL across all customer schemas

  Uses get_customer_schemas macro to discover active schemas for a platform,
  then generates UNION ALL SQL to combine data from all schemas.

  Usage:
    {{ union_all_schemas('META_ADS', 'ad_insights') }}

  Parameters:
    platform: Ad platform to query (e.g., 'META_ADS', 'GOOGLE_ADS')
    table_name: Name of the table to union across schemas

  Returns:
    SQL that unions the specified table from all active customer schemas
-#}

{% macro union_all_schemas(platform, table_name) %}
  {% set schemas = get_customer_schemas(platform) %}

  {% if schemas | length == 0 %}
    {#- Return empty result during parse or if no schemas exist -#}
    SELECT
      CAST(NULL AS STRING) AS source_schema
    WHERE FALSE
  {% else %}
    {% for schema in schemas %}
      SELECT
        '{{ schema }}' AS source_schema,
        *
      FROM `{{ var('gcp_project') }}.{{ schema }}.{{ table_name }}`
      {% if not loop.last %}UNION ALL{% endif %}
    {% endfor %}
  {% endif %}
{% endmacro %}


{#-
  union_all_schemas_with_user - Like union_all_schemas but extracts user_id from schema name

  Schema naming convention: cortex_{userId}_{platform}
  Example: cortex_cmknnba6_metaads -> user_id = cmknnba6

  Usage:
    {{ union_all_schemas_with_user('META_ADS', 'ad_insights') }}

  Parameters:
    platform: Ad platform to query
    table_name: Name of the table to union

  Returns:
    SQL with source_schema and user_id columns plus all table columns
-#}

{% macro union_all_schemas_with_user(platform, table_name) %}
  {% set schemas = get_customer_schemas(platform) %}

  {% if schemas | length == 0 %}
    {#- Return empty result during parse or if no schemas exist -#}
    SELECT
      CAST(NULL AS STRING) AS source_schema,
      CAST(NULL AS STRING) AS user_id
    WHERE FALSE
  {% else %}
    {% for schema in schemas %}
      SELECT
        '{{ schema }}' AS source_schema,
        {#- Extract user_id from schema name (cortex_{userId}_{platform}) -#}
        REGEXP_EXTRACT('{{ schema }}', r'cortex_([^_]+)_') AS user_id,
        *
      FROM `{{ var('gcp_project') }}.{{ schema }}.{{ table_name }}`
      {% if not loop.last %}UNION ALL{% endif %}
    {% endfor %}
  {% endif %}
{% endmacro %}


{#-
  union_all_platforms_with_user - Union a table across all platforms for all customers

  Useful for creating cross-platform unified tables where all users and platforms
  are combined in a single query.

  Usage:
    {{ union_all_platforms_with_user(['META_ADS', 'GOOGLE_ADS'], 'campaign_history') }}

  Parameters:
    platforms: List of platform names to include
    table_name: Name of the table to union

  Returns:
    SQL with source_schema, user_id, and platform columns plus all table columns
-#}

{% macro union_all_platforms_with_user(platforms, table_name) %}
  {% set all_platform_queries = [] %}

  {% for platform in platforms %}
    {% set schemas = get_customer_schemas(platform) %}
    {% for schema in schemas %}
      {% set query %}
      SELECT
        '{{ schema }}' AS source_schema,
        REGEXP_EXTRACT('{{ schema }}', r'cortex_([^_]+)_') AS user_id,
        '{{ platform }}' AS source_platform,
        *
      FROM `{{ var('gcp_project') }}.{{ schema }}.{{ table_name }}`
      {% endset %}
      {% do all_platform_queries.append(query) %}
    {% endfor %}
  {% endfor %}

  {% if all_platform_queries | length == 0 %}
    {#- Return empty result during parse or if no schemas exist -#}
    SELECT
      CAST(NULL AS STRING) AS source_schema,
      CAST(NULL AS STRING) AS user_id,
      CAST(NULL AS STRING) AS source_platform
    WHERE FALSE
  {% else %}
    {{ all_platform_queries | join('\nUNION ALL\n') }}
  {% endif %}
{% endmacro %}
