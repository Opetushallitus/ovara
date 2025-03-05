{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakutoive_id']},
        {'columns':['henkilo_oid']}
    ]
    )
}}

with haku as (
    select * from {{ ref('int_kouta_haku') }}
),

hakutoive as (
    select
        hakutoive_id,
        hakukohde_henkilo_id,
        hakemus_oid,
        henkilo_oid,
        hakukohde_oid
    from {{ ref('int_hakutoive') }} as hate
    inner join haku on hate.haku_oid = haku.haku_oid and haku.haun_tyyppi = 'korkeakoulu'
),

hakemus as (
    select * from {{ ref('int_hakemus_kk') }}
),

final as (
    select
        hato.hakutoive_id,
        hato.henkilo_oid,
        hake.hakukelpoisuus,
        hake.pohjakoulutus,
        hake.maksuvelvollisuus
    from hakutoive as hato
    left join hakemus as hake on hato.hakutoive_id = hake.hakutoive_id


)

select * from final
