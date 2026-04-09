{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['henkilo_oid']},
        {'columns':['hakukohde_oid']}
    ],
    pre_hook=[
        "set maintenance_work_mem = '1GB';",
        "set max_parallel_maintenance_workers = 4;",
    ]
  )
}}

with source as (
    select * from {{ ref('int_hakutoive') }}
)

select * from source
