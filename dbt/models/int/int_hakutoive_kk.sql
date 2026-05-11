{{
  config(
materialized = 'incremental',
    incremental_strategy= 'delete+insert',
    unique_key = 'hakemus_oid',
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['dw_metadata_dw_stored_at']}
    ]
    )
}}

with haku as (
    select haku_oid from {{ ref('int_kouta_haku') }}
    where haun_tyyppi = 'korkeakoulu'
),

hakemus as (
    select
        hakemus_oid,
        haku_oid,
        kasittelymerkinnat,
        tiedot,
        dw_metadata_dw_stored_at,
        tila
    from {{ ref('int_ataru_hakemus') }} as hake
    where exists (
        select 1 from haku
        where hake.haku_oid = haku.haku_oid
    )
    {% if is_incremental() %}
        and dw_metadata_dw_stored_at >= coalesce(
                (select max(dw_metadata_dw_stored_at) from {{ this }}),
                '1900-01-01'::timestamptz
        )
    {% endif %}
    and kasittelymerkinnat @> '[{"requirement": "eligibility-state"}]'
    and tiedot ? 'higher-completed-base-education'
),

hakutoive as (
    select
        hakutoive_id,
        hakemus_oid,
        hakukohde_oid
    from {{ ref('int_hakutoive') }}
),

final as (
    select
        hato.hakutoive_id,
        hato.hakemus_oid,
        hato.hakukohde_oid,
        elem.value ->> 'state' as hakukelpoisuus,
        replace(hake.tiedot ->> 'higher-completed-base-education', 'pohjakoulutus_', '')::jsonb as pohjakoulutus,
        hake.dw_metadata_dw_stored_at
    from
        hakemus as hake
    join hakutoive as hato on hake.hakemus_oid = hato.hakemus_oid
    left join lateral (
        select elem.value from jsonb_array_elements(hake.kasittelymerkinnat) as elem
        where
            elem.value ->> 'requirement' = 'eligibility-state' and elem.value ->> 'hakukohde' = hato.hakukohde_oid
        limit 1
    ) as elem on true
    where hake.tila <> 'inactivated'
)

select * from final
