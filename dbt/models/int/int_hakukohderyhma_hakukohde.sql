with source as (
    select
        oid as hakukohderyhma_oid,
        muokattu,
        row_number() over (partition by oid order by muokattu desc) as rownr,
        hakukohde_oid
    from {{ ref('dw_hakukohderyhmapalvelu_ryhma') }}
),

hakukohde as (
    select
        hakukohderyhma_oid,
        jsonb_array_elements_text(hakukohde_oid) as hakukohde_oid,
        muokattu
    from source
    where rownr = 1
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
