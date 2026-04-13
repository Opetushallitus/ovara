{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakukohde_oid']}
    ]
    )
}}

with source as (
    select * from {{ ref('int_valintaperusteet_valintatapajono') }}
)

select * from source
