{{
  config(
    materialized = 'table'
  )
}}

with ryhma as (
    select * from {{ ref('int_organisaatio_ryhma') }}
),

hakukohteet as (
    select * from {{ ref('int_hakukohderyhma_hakukohde') }}
),

final as (
    select
        hako.hakukohderyhma_id,
        ryhm.hakukohderyhma_oid,
        ryhm.hakukohderyhma_nimi,
        hako.hakukohde_oid
    from ryhma as ryhm
    left join hakukohteet as hako on ryhm.hakukohderyhma_oid = hako.hakukohderyhma_oid
)

select * from final
where hakukohde_oid is not null
