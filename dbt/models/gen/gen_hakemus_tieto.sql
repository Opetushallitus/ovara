{{
  config(
    materialized = 'table',
    indexes = [
        {'columns' : ['hakemus_oid'] }
    ],
    pre_hook=[
        "set work_mem = '1GB';"
        "set maintenance_work_mem = '1GB';",
        "set max_parallel_maintenance_workers = 4;",
    ]
    )
}}
with source as not materialized (
    select * from {{ ref('int_hakemus_tiedot') }}
)

select * from source
