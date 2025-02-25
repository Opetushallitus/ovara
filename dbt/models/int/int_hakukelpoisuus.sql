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
                kasittelymerkinnat,
                '$.hakukohde'
            ) ->> 0
        ) as hakukohde_oid,
        (
            jsonb_path_query(
                kasittelymerkinnat,
                '$[*] ? (@.requirement == "eligibility-state")'
            ) ->> 'state'
        ) as hakukelpoisuus,
        (
            jsonb_path_query(
                kasittelymerkinnat,
                '$[*] ? (@.requirement == "payment-obligation")'
            ) ->> 'state'
        ) = 'obligated' as maksuvelvollisuus,
        (
            jsonb_path_query(
                kasittelymerkinnat,
                '$[*] ? (@.requirement == "payment-obligation")'
            ) ->> 'state'
        ) as maksuvelvollisuus_text
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
