{% macro generate_schema_name(custom_schema_name, node) -%}
    {#-
        Multi-tenant schema name generation.
        Priority:
        1. If target_dataset variable is set to a client-specific value, use it
        2. Otherwise fall back to custom_schema_name or target.schema

        This macro allows per-client deployment by overriding target_dataset:
        dbt run --vars '{"target_dataset": "com_client_cortex"}'
    -#}
    {%- set target_dataset = var('target_dataset', 'cortex') -%}

    {#- Only override schema for nexus models (custom_schema_name = 'cortex') -#}
    {%- if custom_schema_name == 'cortex' and target_dataset != 'cortex' -%}
        {#- Use the client-specific target dataset -#}
        {{ target_dataset | trim }}
    {%- elif custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}