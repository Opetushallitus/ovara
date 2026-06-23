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

matching_hakemukset AS (
    select b.hakemus_oid
    from {{ ref('int_ataru_hakemus') }} b
    join haut h
      on h.haku_oid = b.haku_oid
),
raw as (
    select
        a.hakutoive_id,
        a.hakemus_oid,
        a.hakukohde_oid,
        a.harkinnanvaraisuuden_syy
    from {{ ref('int_sure_harkinnanvaraisuus') }} a
    join matching_hakemukset b on a.hakemus_oid=b.hakemus_oid

    union all
    select
        a.hakutoive_id,
        a.hakemus_oid,
        a.hakukohde_oid,
        a.harkinnanvaraisuus_syy
    from {{ ref('int_supa_harkinnanvaraisuus') }} a
    where not exists (
        select 1 from matching_hakemukset b where a.hakemus_oid=b.hakemus_oid
    )
)


select * from raw
