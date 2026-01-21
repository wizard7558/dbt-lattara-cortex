# Cortex V2 Models

Multi-tenant dbt models for Cortex ad analytics platform.

## Structure

```
cortex_v2/
├── staging/fivetran/     # Multi-tenant Fivetran staging
│   ├── stg_all_meta__*.sql
│   ├── stg_all_google__*.sql
│   ├── stg_all_linkedin__*.sql
│   └── stg_all_tiktok__*.sql
├── intermediate/
│   ├── int_all_ads_unified.sql
│   └── int_all_conversions_unified.sql
└── marts/
    ├── mart_kpi_daily.sql
    ├── mart_campaigns.sql
    └── mart_conversion_events.sql
```

## Key Features

- Uses `union_all_schemas` macro to dynamically union all Fivetran customer schemas
- Extracts `user_id` from schema naming convention: `cortex_{user_id}_{platform}`
- Tables partitioned by date, clustered by user_id for efficient multi-tenant queries

## Dependencies

Requires macros in `macros/cortex_v2/`:
- `get_customer_schemas.sql`
- `union_all_schemas.sql`

## Running

```bash
# Run all cortex_v2 models
dbt run --select cortex_v2

# Run just the marts
dbt run --select cortex_v2.marts

# Run conversion events and dependencies
dbt run --select +mart_conversion_events
```
