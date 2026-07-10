{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakemus_oid']},
        {'columns': ['hakija_oid']}
    ]
    )
}}

with source as (
    select * from {{ ref('int_valintalaskenta_jonosija_funktiotulokset') }}
)

select * from source
