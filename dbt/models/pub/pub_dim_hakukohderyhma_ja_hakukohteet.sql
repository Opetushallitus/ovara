{{
  config(
    materialized = 'table'
  )
}}

with hakukohderyhma as (
    select * from {{ ref('int_hakukohderyhma_hakukohde') }}
),

haku as (
    select
        hakukohde_oid,
        haku_oid
    from {{ ref('int_kouta_hakukohde') }}
),

final as (
    select
        hary.hakukohderyhma_id,
        hary.hakukohderyhma_oid,
        hary.hakukohde_oid,
        haku.haku_oid
    from hakukohderyhma as hary
    left join haku on hary.hakukohde_oid = haku.hakukohde_oid
)

select * from final
where hakukohde_oid is not null
