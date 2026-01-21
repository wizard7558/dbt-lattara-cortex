{#-
  get_customer_schemas - Returns list of customer schemas for a platform

  Queries the user_schema_mapping table from cortex_metadata dataset
  to dynamically discover all active Fivetran schemas for a given platform.

  Usage:
    {% set schemas = get_customer_schemas('META_ADS') %}
    {% for schema in schemas %}
      -- do something with each schema
    {% endfor %}

  Parameters:
    platform: Ad platform to filter by (e.g., 'META_ADS', 'GOOGLE_ADS', 'LINKEDIN_ADS')

  Returns:
    List of schema names (strings) for active connectors on the specified platform
-#}

{% macro get_customer_schemas(platform) %}
  {% set query %}
    SELECT DISTINCT schema_name
    FROM `{{ var('gcp_project') }}.cortex_metadata.user_schema_mapping`
    WHERE platform = '{{ platform }}'
      AND is_active = true
    ORDER BY schema_name
  {% endset %}

  {% set results = run_query(query) %}

  {% if execute %}
    {% set schemas = results.columns[0].values() %}
  {% else %}
    {# During dbt parse phase, return empty list #}
    {% set schemas = [] %}
  {% endif %}

  {{ return(schemas) }}
{% endmacro %}
