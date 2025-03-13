{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakutoive_id']}
    ]
    )
}}

with hakemus as not materialized (
    select * from {{ ref('int_ataru_hakemus') }}
    where
        kasittelymerkinnat @? '$[*] ? (@.requirement == "eligibility-state")'
        and kasittelymerkinnat @? '$[*] ? (@.requirement == "payment-obligation")'
        and tiedot ? 'higher-completed-base-education'
),

hakutoive as (
    select * from {{ ref('int_hakutoive') }}
),

haku as (
    select * from {{ ref('int_kouta_haku') }}
),

maksuvelvollisuus as (
    select
		{{ hakutoive_id() }},
        maksuvelvollinen
        from
            (
                select hakemus_oid,
                (
                    jsonb_path_query(
                    hake.kasittelymerkinnat,
                    '$[*] ? (@.requirement == "payment-obligation")'
                    ) ->> 'hakukohde'
                ) as hakukohde_oid,
                (
                    jsonb_path_query(
                    hake.kasittelymerkinnat,
                    '$[*] ? (@.requirement == "payment-obligation")'
                    ) ->> 'state'
                ) as maksuvelvollinen
            from hakemus as hake
        ) as maksuvelvollisuus
),

hakukelpoisuus as (
    select
		{{ hakutoive_id() }},
        hakukelpoinen
        from
            (
                select hakemus_oid,
                (
                jsonb_path_query(
                    hake.kasittelymerkinnat,
                    '$[*] ? (@.requirement == "eligibility-state")'
                    ) ->> 'hakukohde'
                ) as hakukohde_oid,
                (
                jsonb_path_query(
                    hake.kasittelymerkinnat,
                    '$[*] ? (@.requirement == "eligibility-state")'
                    ) ->> 'state'
                ) as hakukelpoinen
            from hakemus as hake
        ) as hakukelpoisuus

),

pohjakoulutus as (
    select
        hakemus_oid,
        tiedot -> 'higher-completed-base-education' as pohjakoulutus
    from hakemus

),

final as (
    select
        hato.hakutoive_id,
        hato.hakemus_oid,
        hato.hakukohde_oid,
        mave.maksuvelvollinen as maksuvelvollisuus,
        hake.hakukelpoinen as hakukelpoisuus,
        poko.pohjakoulutus
    from hakutoive as hato
    left join maksuvelvollisuus as mave on hato.hakutoive_id = mave.hakutoive_id
    left join hakukelpoisuus as hake on hato.hakutoive_id = hake.hakutoive_id
    left join pohjakoulutus as poko on hato.hakemus_oid = poko.hakemus_oid
    --inner join haku on hato.haku_oid = haku.haku_oid and haku.haun_tyyppi = 'korkeakoulu'
)

select
    *
from final

