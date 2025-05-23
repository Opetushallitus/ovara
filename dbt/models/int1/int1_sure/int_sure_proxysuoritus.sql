{{
  config (
    materialized = 'table',
    indexes = [
        {'columns': ['keyvalues'], 'type': 'gin'}
    ]
    )
}}

with source as (
    select * from {{ ref('dw_sure_proxysuoritus') }}
)

select * from source
