{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakukohde_oid']}
    ]
    )
}}

with valintakoe as (
    select * from {{ ref('int_valintaperusteet_valintakoe') }}
)

select * from valintakoe
