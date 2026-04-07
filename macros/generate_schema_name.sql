{% macro generate_schema_name(custom_schema_name, node) -%}
    {#-
        Multi-tenant schema name generation.
        Priority:
        1. For MODELS with schema='cortex' and a client-specific target_dataset,
           redirect to the per-tenant dataset (e.g., cortex_com_splitero).
        2. SEEDS are always treated as shared reference data and stay at
           custom_schema_name (e.g., 'cortex'), regardless of target_dataset.
           They are referenced cross-dataset from per-tenant models.
        3. If custom_schema_name is not set, fall back to target.schema.
        4. Otherwise pass custom_schema_name through unchanged.

        This macro allows per-client deployment by overriding target_dataset:
        dbt run --vars '{"target_dataset": "com_client_cortex"}'

        The seed exclusion prevents reference tables (country_codes,
        google_geo_targets, linkedin_geo_urn) from being multi-tenant-ified.
        Seeds are identical for every tenant, so loading them once to the
        shared `cortex` dataset and referencing cross-dataset is correct.
    -#}
    {%- set target_dataset = var('target_dataset', 'cortex') -%}

    {#- Only override schema for nexus MODELS (not seeds) -#}
    {%- if custom_schema_name == 'cortex' and target_dataset != 'cortex' and node.resource_type != 'seed' -%}
        {#- Use the client-specific target dataset -#}
        {{ target_dataset | trim }}
    {%- elif custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
