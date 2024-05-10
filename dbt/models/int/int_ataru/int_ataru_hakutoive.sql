with raw as (
    select
        oid,
        hakukohde,
        row_number() over (partition by oid order by versio_id desc, muokattu desc) as row_nr
    from {{ ref('dw_ataru_hakemus') }}
),

latest_hakemus as (
    select
        oid,
        hakukohde
    from raw
    where row_nr = 1
),

hakutoive_raw as (
    select
        oid,
        jsonb_array_elements_text(hakukohde) as hakukohde_oid
    from latest_hakemus
),

hakutoivenro as (
    select
        oid as hakemus_oid,
        hakukohde_oid,
        row_number() over (partition by oid) as hakutoivenumero
    from hakutoive_raw
),

final as (
    select
        {{ dbt_utils.generate_surrogate_key(
            ['hakemus_oid',
            'hakukohde_oid']
            ) }} as hakutoive_id,
        hakemus_oid,
        hakukohde_oid,
        hakutoivenumero
    from hakutoivenro
)

select * from final
