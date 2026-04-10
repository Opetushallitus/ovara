{{
  config(
    materialized = 'table',
    indexes = [
        {'columns' : ['hakemus_oid'] }
    ],
    post_hook=[
        "{{ disable_autovacuum_if_not_incremental() }}"
    ]
    )
}}
with source as not materialized (
    select * from {{ ref('int_hakemus_tiedot') }}
)

select * from source
