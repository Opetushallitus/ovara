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
        and tiedot ? 'higher-completed-base-education'
),

hakutoive as (
    select * from {{ ref('int_hakutoive') }}
),

hakukelpoisuus as (
    select
        {{ hakutoive_id() }},
        hakemus_oid,
        hakukohde_oid,
        hakukelpoinen
    from
        (
            select
                hakemus_oid,
                (
                    jsonb_path_query(
                        kasittelymerkinnat,
                        '$[*] ? (@.requirement == "eligibility-state")'
                    ) ->> 'hakukohde'
                ) as hakukohde_oid,
                (
                    jsonb_path_query(
                        kasittelymerkinnat,
                        '$[*] ? (@.requirement == "eligibility-state")'
                    ) ->> 'state'
                ) as hakukelpoinen
            from hakemus
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
        hake.hakukelpoinen as hakukelpoisuus,
        poko.pohjakoulutus
    from hakutoive as hato
    left join hakukelpoisuus as hake on hato.hakutoive_id = hake.hakutoive_id
    left join pohjakoulutus as poko on hato.hakemus_oid = poko.hakemus_oid

)

select * from final
