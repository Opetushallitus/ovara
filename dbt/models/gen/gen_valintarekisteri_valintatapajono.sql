{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['valintatapajono_oid']}
    ]
    )
}}

with source as (
    select * from {{ ref('int_valintarekisteri_valintatapajono') }}
)

select * from source
