--{{ ref('pub_dim_hakukohde') }}
--{{ ref('pub_fct_hakemus') }}
{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakemus_oid']},
        {'columns':['hakukohde_oid']},
    ]
    )
}}

with hakutoive as (
    select
        hakutoive_id,
        hakemus_oid,
        hakukohde_oid,
        hakutoivenumero,
        poistettu,
        muokattu
    from {{ ref('int_ataru_hakutoive') }}
    where not poistettu
),

sora as (
    select
        hakutoive_id,
        sora_terveys,
        sora_aiempi
    from {{ ref('int_ataru_soratietoja') }}
),

maksuvelvollisuus as (
    select
        hakutoive_id,
        tila as maksuvelvollinen
    from {{ ref('int_ataru_maksuvelvollisuus') }}
),

final as (
    select
        hato.hakutoive_id,
        hato.hakemus_oid,
        hato.hakukohde_oid,
        hato.hakutoivenumero,
        hato.poistettu,
        sora.sora_terveys,
        sora.sora_aiempi,
        mave.maksuvelvollinen
    from hakutoive as hato
    left join sora on hato.hakutoive_id = sora.hakutoive_id
    left join maksuvelvollisuus as mave on hato.hakutoive_id = mave.hakutoive_id
)

select * from final
order by haku_oid