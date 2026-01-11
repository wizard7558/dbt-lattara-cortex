{% macro generate_schema_name(custom_schema_name, node) -%}
    {#-
        Multi-tenant schema name generation.
        Priority:
        1. If target_dataset variable is set, use it (for per-client deployment)
        2. Otherwise fall back to custom_schema_name or target.schema
    -#}
    {%- set target_dataset = var('target_dataset', none) -%}

    {%- if target_dataset is not none and target_dataset != '' and target_dataset != 'cortex' -%}
        {#- Use the client-specific target dataset -#}
        {{ target_dataset | trim }}
    {%- elif custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}