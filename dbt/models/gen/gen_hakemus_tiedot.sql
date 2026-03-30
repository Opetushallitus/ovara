{{
  config(
    materialized = 'table',
    indexes = [
        {'columns' : ['hakemus_oid'] }
    ]
    )
}}
with source as not materialized(
    select * from {{ ref('int_hakemus_tiedot') }}
)

select * from source
