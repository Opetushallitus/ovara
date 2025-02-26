{{
  config(
    materialized = 'table',
    indexes = [
        {'columns':['hakutoive_id']}
    ]
    )
}}

with hakemus as (
    select * from {{ ref('int_ataru_hakemus') }}
),

haku as (
    select * from {{ ref('int_kouta_haku') }}
),

final as (
    select
        hakemus_oid,
        (
            jsonb_path_query(
                hake.kasittelymerkinnat,
                '$.hakukohde'
            ) ->> 0
        ) as hakukohde_oid,
        (
            jsonb_path_query(
                hake.kasittelymerkinnat,
                '$[*] ? (@.requirement == "eligibility-state")'
            ) ->> 'state'
        ) as hakukelpoisuus,
        (
            jsonb_path_query(
                hake.kasittelymerkinnat,
                '$[*] ? (@.requirement == "payment-obligation")'
            ) ->> 'state'
        ) as maksuvelvollisuus,
        hake.tiedot -> 'higher-completed-base-education' as pohjakoulutus
    from hakemus as hake
    inner join haku on hake.haku_oid = haku.haku_oid and haku.haun_tyyppi = 'korkeakoulu'
)

select
    {{ hakutoive_id() }},
    *
from final
where
    hakukelpoisuus is not null
    and maksuvelvollisuus is not null
    and maksuvelvollisuus is not null