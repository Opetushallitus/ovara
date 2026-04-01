{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['valintatapajono_oid']}
    ]
    )
}}

with source as (
    select * from {{ ref('int_valintaperusteet_valintatapajono') }}
)

select * from source
