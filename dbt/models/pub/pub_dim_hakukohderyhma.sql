{{
  config(
    materialized = 'table'
  )
}}

with hakukohderyhma as (
    select * from {{ ref('int_hakukohderyhma_hakukohde') }}
),

final as (
    select distinct
        hakukohderyhma_oid,
        hakukohderyhma_nimi
    from hakukohderyhma
)

select * from final
