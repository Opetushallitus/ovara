{{
  config(
    materialized = 'table',
    indexes = [
        {'columns': ['hakukohderyhma_oid'] }
    ]
    )
}}


with source as (
    select
        oid as hakukohderyhma_oid,
        muokattu,
        hakukohde_oid
    from {{ ref('int_hakukohderyhmapalvelu_ryhma') }}

),

hakukohde as (
    select
        hakukohderyhma_oid,
        jsonb_array_elements_text(hakukohde_oid) as hakukohde_oid,
        muokattu
    from source
),

ryhma as (
    select * from {{ ref('int_organisaatio_ryhma') }}
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['hako.hakukohderyhma_oid','hako.hakukohde_oid']) }} as hakukohderyhma_id,
        hako.hakukohderyhma_oid,
        ryhm.hakukohderyhma_nimi,
        hako.hakukohde_oid,
        hako.muokattu
    from hakukohde as hako
    left join ryhma as ryhm on hako.hakukohderyhma_oid = ryhm.hakukohderyhma_oid
)

select * from final
