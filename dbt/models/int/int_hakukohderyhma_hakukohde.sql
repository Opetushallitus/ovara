with source as (
    select
        oid as hakukohderyhma_oid,
        muokattu,
        row_number () over (partition by oid order by muokattu desc) as rownr,
        hakukohde_oid
    from {{ ref('dw_hakukohderyhmapalvelu_ryhma') }}
),

raw as (
    select
        hakukohderyhma_oid,
        jsonb_array_elements_text(hakukohde_oid) as hakukohde_oid,
        muokattu
    from source
    where rownr=1
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(['hakukohderyhma_oid','hakukohde_oid']) }} as hakukohderyhma_id,
        hakukohderyhma_oid,
        hakukohde_oid,
        muokattu
    from raw
)

select * from final
