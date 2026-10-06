{{
  config(
    materialized = 'table',
    indexes = [
    ]
    )
}}

with haut as (
    select haku_oid from {{ ref('int_sure_haut') }}
),


matching_hakemukset as (
    select hake.hakemus_oid
    from {{ ref('int_ataru_hakemus') }} as hake
    where
        exists (
            select 1 from haut
            where hake.haku_oid = haut.haku_oid
        )
),

raw as (
    select
        hava.hakutoive_id,
        hava.hakemus_oid,
        hava.hakukohde_oid,
        hava.harkinnanvaraisuuden_syy
    from {{ ref('int_sure_harkinnanvaraisuus') }} as hava
    where
        exists (
            select 1 from matching_hakemukset as maha
            where hava.hakemus_oid = maha.hakemus_oid
        )

    union all
    select
        havp.hakutoive_id,
        havp.hakemus_oid,
        havp.hakukohde_oid,
        havp.harkinnanvaraisuus_syy
    from {{ ref('int_supa_harkinnanvaraisuus') }} as havp
    where not exists (
        select 1 from matching_hakemukset as mah2
        where havp.hakemus_oid = mah2.hakemus_oid
    )
)


select * from raw
