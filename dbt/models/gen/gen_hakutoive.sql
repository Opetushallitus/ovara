{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['henkilo_oid, hakukohde_oid']}
    ]
  )
}}

with source as (
    select * from {{ ref('int_hakutoive') }}
)

select * from source
