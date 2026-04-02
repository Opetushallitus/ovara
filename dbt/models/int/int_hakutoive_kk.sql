{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakutoive_id']}
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
        tiedot
    from {{ ref('int_ataru_hakemus') }} as hake
    where exists (
        select 1 from haku
        where hake.haku_oid = haku.haku_oid
    )
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
        replace(h.tiedot ->> 'higher-completed-base-education', 'pohjakoulutus_', '')::jsonb as pohjakoulutus
    from
        hakemus as h
    left join hakutoive as hato on h.hakemus_oid = hato.hakemus_oid
    left join lateral (
        select elem.value from jsonb_array_elements(h.kasittelymerkinnat) as elem
        where
            elem.value ->> 'requirement' = 'eligibility-state' and elem.value ->> 'hakukohde' = hato.hakukohde_oid
        limit 1
    ) as elem on true
)

select * from final
